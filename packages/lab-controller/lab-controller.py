#!/usr/bin/env python3
"""
AI Agents Lab Controller
A comprehensive tool for students and instructors to manage the educational lab environment.

Usage:
    lab-ctl student start lab-01              # Start a lab exercise
    lab-ctl student verify                    # Check if objectives are met
    lab-ctl student submit                    # Submit completion
    lab-ctl student chat red "scan the target" # Interact with red agent
    
    lab-ctl instructor dashboard              # Launch web dashboard
    lab-ctl instructor monitor student-01     # Watch student progress
    lab-ctl instructor grade student-01       # Generate grade report
    lab-ctl instructor reset student-01       # Reset environment
"""

import sys
import os
import json
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
import requests

# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Lab configuration and paths"""
    LAB_ROOT = Path("/var/lib/ai-agents-lab")
    LABS_DIR = Path(__file__).parent / "labs"
    STATE_DIR = LAB_ROOT / "state"
    LOGS_DIR = LAB_ROOT / "logs"
    OLLAMA_URL = "http://localhost:11434"
    
    # VM network configuration
    RED_TEAM_IP = "10.0.0.101"
    BLUE_TEAM_IP = "10.0.0.102"
    TARGET_IP = "10.0.0.103"
    
    # Model names
    RED_MODEL = "red-qwen-agent"
    BLUE_MODEL = "blue-llama-agent"
    
    @classmethod
    def ensure_dirs(cls):
        """Create necessary directories"""
        for directory in [cls.STATE_DIR, cls.LOGS_DIR]:
            directory.mkdir(parents=True, exist_ok=True)

# ============================================================================
# Ollama Client
# ============================================================================

class OllamaClient:
    """Simplified Ollama API client"""
    
    def __init__(self, base_url: str = Config.OLLAMA_URL):
        self.base_url = base_url
    
    def chat(self, model: str, message: str, system: Optional[str] = None) -> str:
        """Send a chat message to a model"""
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": message})
        
        try:
            response = requests.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": False
                },
                timeout=60
            )
            response.raise_for_status()
            return response.json()["message"]["content"]
        except Exception as e:
            return f"Error communicating with {model}: {e}"
    
    def generate(self, model: str, prompt: str) -> str:
        """Generate text from a model"""
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=60
            )
            response.raise_for_status()
            return response.json()["response"]
        except Exception as e:
            return f"Error: {e}"
    
    def list_models(self) -> List[str]:
        """List available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            response.raise_for_status()
            return [model["name"] for model in response.json()["models"]]
        except Exception as e:
            print(f"Error listing models: {e}")
            return []

# ============================================================================
# Lab Definition System
# ============================================================================

class LabDefinition:
    """Defines a lab exercise"""
    
    def __init__(self, lab_id: str, config: Dict):
        self.lab_id = lab_id
        self.title = config.get("title", "Untitled Lab")
        self.description = config.get("description", "")
        self.difficulty = config.get("difficulty", "beginner")
        self.objectives = config.get("objectives", [])
        self.hints = config.get("hints", [])
        self.time_limit = config.get("time_limit", None)
        self.verification_script = config.get("verification_script", None)
    
    @classmethod
    def load(cls, lab_id: str) -> Optional['LabDefinition']:
        """Load lab definition from file"""
        lab_file = Config.LABS_DIR / lab_id / "lab.json"
        if not lab_file.exists():
            print(f"Lab {lab_id} not found")
            return None
        
        with open(lab_file) as f:
            config = json.load(f)
        return cls(lab_id, config)
    
    def get_starter_code(self) -> Optional[str]:
        """Get starter code for the lab"""
        starter_file = Config.LABS_DIR / self.lab_id / "starter.py"
        if starter_file.exists():
            return starter_file.read_text()
        return None
    
    def get_verification_script(self) -> Optional[Path]:
        """Get path to verification script"""
        verify_file = Config.LABS_DIR / self.lab_id / "verify.py"
        return verify_file if verify_file.exists() else None

# ============================================================================
# Student Session Management
# ============================================================================

class StudentSession:
    """Manages a student's lab session"""
    
    def __init__(self, student_id: str):
        self.student_id = student_id
        self.session_file = Config.STATE_DIR / f"{student_id}.json"
        self.data = self._load_or_create()
    
    def _load_or_create(self) -> Dict:
        """Load existing session or create new one"""
        if self.session_file.exists():
            with open(self.session_file) as f:
                return json.load(f)
        return {
            "student_id": self.student_id,
            "created_at": datetime.now().isoformat(),
            "current_lab": None,
            "completed_labs": [],
            "attempts": {},
            "score": 0
        }
    
    def save(self):
        """Save session to disk"""
        with open(self.session_file, 'w') as f:
            json.dump(self.data, f, indent=2)
    
    def start_lab(self, lab_id: str):
        """Start a new lab"""
        self.data["current_lab"] = lab_id
        self.data["attempts"][lab_id] = self.data["attempts"].get(lab_id, 0) + 1
        self.data["lab_start_time"] = datetime.now().isoformat()
        self.save()
    
    def complete_lab(self, lab_id: str, score: int):
        """Mark lab as complete"""
        if lab_id not in self.data["completed_labs"]:
            self.data["completed_labs"].append(lab_id)
        self.data["score"] += score
        self.data["current_lab"] = None
        self.save()
    
    def get_progress(self) -> Dict:
        """Get student progress summary"""
        return {
            "student_id": self.student_id,
            "current_lab": self.data["current_lab"],
            "completed_labs": len(self.data["completed_labs"]),
            "total_score": self.data["score"],
            "attempts": self.data["attempts"]
        }

# ============================================================================
# Lab Verification System
# ============================================================================

class LabVerifier:
    """Verifies if student completed lab objectives"""
    
    def __init__(self, lab: LabDefinition):
        self.lab = lab
    
    def verify(self) -> Dict[str, any]:
        """Run verification checks"""
        results = {
            "lab_id": self.lab.lab_id,
            "timestamp": datetime.now().isoformat(),
            "objectives_met": [],
            "objectives_failed": [],
            "score": 0,
            "feedback": []
        }
        
        # Run custom verification script if exists
        verify_script = self.lab.get_verification_script()
        if verify_script:
            try:
                output = subprocess.run(
                    ["python3", str(verify_script)],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if output.returncode == 0:
                    # Parse verification output
                    verify_data = json.loads(output.stdout)
                    results.update(verify_data)
                else:
                    results["feedback"].append(f"Verification failed: {output.stderr}")
            except Exception as e:
                results["feedback"].append(f"Verification error: {e}")
        else:
            # Generic verification based on objectives
            results["feedback"].append("No automated verification available")
        
        return results

# ============================================================================
# Agent Interaction System
# ============================================================================

class AgentController:
    """Controls and monitors AI agents"""
    
    def __init__(self):
        self.ollama = OllamaClient()
        self.log_file = Config.LOGS_DIR / f"agent_interactions_{datetime.now().strftime('%Y%m%d')}.log"
    
    def send_to_red_agent(self, instruction: str) -> str:
        """Send instruction to red team agent"""
        self._log("RED", instruction)
        response = self.ollama.chat(
            Config.RED_MODEL,
            instruction,
            system="Execute the requested reconnaissance or attack simulation."
        )
        self._log("RED_RESPONSE", response)
        return response
    
    def send_to_blue_agent(self, instruction: str) -> str:
        """Send instruction to blue team agent"""
        self._log("BLUE", instruction)
        response = self.ollama.chat(
            Config.BLUE_MODEL,
            instruction,
            system="Analyze security events and provide defensive recommendations."
        )
        self._log("BLUE_RESPONSE", response)
        return response
    
    def get_agent_status(self) -> Dict:
        """Get status of all agents"""
        models = self.ollama.list_models()
        return {
            "red_agent": Config.RED_MODEL in models,
            "blue_agent": Config.BLUE_MODEL in models,
            "models_loaded": models
        }
    
    def _log(self, tag: str, message: str):
        """Log agent interaction"""
        with open(self.log_file, 'a') as f:
            timestamp = datetime.now().isoformat()
            f.write(f"[{timestamp}] [{tag}] {message}\n")

# ============================================================================
# Student CLI Interface
# ============================================================================

class StudentCLI:
    """Student command-line interface"""
    
    def __init__(self, student_id: str = "student-01"):
        self.student_id = student_id
        self.session = StudentSession(student_id)
        self.agent = AgentController()
    
    def cmd_list(self):
        """List available labs"""
        print("\n📚 Available Labs:\n")
        labs_dir = Config.LABS_DIR
        if not labs_dir.exists():
            print("No labs directory found. Creating example structure...")
            self._create_example_labs()
            return
        
        for lab_dir in sorted(labs_dir.iterdir()):
            if lab_dir.is_dir() and (lab_dir / "lab.json").exists():
                lab = LabDefinition.load(lab_dir.name)
                if lab:
                    status = "✓" if lab_dir.name in self.session.data["completed_labs"] else "○"
                    print(f"  {status} {lab.lab_id}: {lab.title}")
                    print(f"     Difficulty: {lab.difficulty}")
                    print(f"     Objectives: {len(lab.objectives)}")
                    print()
    
    def cmd_start(self, lab_id: str):
        """Start a lab exercise"""
        lab = LabDefinition.load(lab_id)
        if not lab:
            return
        
        print(f"\n🚀 Starting Lab: {lab.title}\n")
        print(f"Difficulty: {lab.difficulty}")
        print(f"Description: {lab.description}\n")
        
        print("📋 Objectives:")
        for i, obj in enumerate(lab.objectives, 1):
            print(f"  {i}. {obj}")
        print()
        
        starter = lab.get_starter_code()
        if starter:
            print("📝 Starter code available. Run: lab-ctl student code")
        
        self.session.start_lab(lab_id)
        print(f"✓ Lab started. Good luck!\n")
        print("Hints available: lab-ctl student hint")
        print("Verify progress: lab-ctl student verify")
    
    def cmd_hint(self):
        """Show hint for current lab"""
        if not self.session.data["current_lab"]:
            print("No active lab. Start one with: lab-ctl student start <lab-id>")
            return
        
        lab = LabDefinition.load(self.session.data["current_lab"])
        if not lab or not lab.hints:
            print("No hints available for this lab")
            return
        
        attempt = self.session.data["attempts"].get(lab.lab_id, 1)
        hint_index = min(attempt - 1, len(lab.hints) - 1)
        
        print(f"\n💡 Hint #{hint_index + 1}:")
        print(f"   {lab.hints[hint_index]}\n")
    
    def cmd_verify(self):
        """Verify lab completion"""
        if not self.session.data["current_lab"]:
            print("No active lab")
            return
        
        lab = LabDefinition.load(self.session.data["current_lab"])
        if not lab:
            return
        
        print(f"\n🔍 Verifying {lab.title}...\n")
        
        verifier = LabVerifier(lab)
        results = verifier.verify()
        
        print("Results:")
        for obj in results["objectives_met"]:
            print(f"  ✓ {obj}")
        for obj in results["objectives_failed"]:
            print(f"  ✗ {obj}")
        
        print(f"\nScore: {results['score']}/100")
        
        if results["feedback"]:
            print("\nFeedback:")
            for fb in results["feedback"]:
                print(f"  • {fb}")
        
        if results["score"] >= 70:
            print("\n🎉 Lab completed!")
            self.session.complete_lab(lab.lab_id, results["score"])
        else:
            print("\n⚠️  Not quite there yet. Keep trying!")
    
    def cmd_chat(self, agent: str, message: str):
        """Chat with an agent"""
        print(f"\n💬 Sending to {agent} agent: {message}\n")
        
        if agent.lower() == "red":
            response = self.agent.send_to_red_agent(message)
        elif agent.lower() == "blue":
            response = self.agent.send_to_blue_agent(message)
        else:
            print(f"Unknown agent: {agent}. Use 'red' or 'blue'")
            return
        
        print(f"Response:\n{response}\n")
    
    def cmd_status(self):
        """Show student status"""
        progress = self.session.get_progress()
        agent_status = self.agent.get_agent_status()
        
        print(f"\n📊 Student Status: {self.student_id}\n")
        print(f"Current Lab: {progress['current_lab'] or 'None'}")
        print(f"Completed Labs: {progress['completed_labs']}")
        print(f"Total Score: {progress['total_score']}")
        print(f"\nAgent Status:")
        print(f"  Red Team: {'✓' if agent_status['red_agent'] else '✗'}")
        print(f"  Blue Team: {'✓' if agent_status['blue_agent'] else '✗'}")
        print()
    
    def _create_example_labs(self):
        """Create example lab structure"""
        Config.LABS_DIR.mkdir(parents=True, exist_ok=True)
        example_lab = Config.LABS_DIR / "lab-01-recon"
        example_lab.mkdir(exist_ok=True)
        
        lab_config = {
            "title": "Basic Network Reconnaissance",
            "description": "Learn to enumerate network services using AI agents",
            "difficulty": "beginner",
            "objectives": [
                "Identify all open ports on the target",
                "Determine the operating system",
                "Find the SSH version"
            ],
            "hints": [
                "Try asking the red agent to scan for open ports",
                "Use nmap or similar tools through the agent",
                "Check common ports: 22, 80, 443"
            ],
            "time_limit": 3600
        }
        
        (example_lab / "lab.json").write_text(json.dumps(lab_config, indent=2))
        print(f"Created example lab: {example_lab}")

# ============================================================================
# Instructor CLI Interface
# ============================================================================

class InstructorCLI:
    """Instructor command-line interface"""
    
    def cmd_dashboard(self):
        """Launch web dashboard"""
        print("🌐 Launching instructor dashboard...")
        print("(Dashboard server not yet implemented - placeholder)")
        print("Would show:")
        print("  - All student progress")
        print("  - Real-time agent activity")
        print("  - Lab completion rates")
        print("  - Network traffic visualization")
    
    def cmd_monitor(self, student_id: str):
        """Monitor a specific student"""
        session = StudentSession(student_id)
        progress = session.get_progress()
        
        print(f"\n👀 Monitoring: {student_id}\n")
        print(f"Current Lab: {progress['current_lab']}")
        print(f"Completed: {progress['completed_labs']}")
        print(f"Score: {progress['total_score']}")
        print(f"Attempts: {progress['attempts']}")
        
        # Show recent logs
        log_file = Config.LOGS_DIR / f"agent_interactions_{datetime.now().strftime('%Y%m%d')}.log"
        if log_file.exists():
            print("\n📝 Recent Activity:")
            lines = log_file.read_text().splitlines()
            for line in lines[-10:]:
                print(f"  {line}")
    
    def cmd_grade(self, student_id: str):
        """Generate grade report"""
        session = StudentSession(student_id)
        progress = session.get_progress()
        
        print(f"\n📊 Grade Report: {student_id}\n")
        print(f"Total Score: {progress['total_score']}")
        print(f"Labs Completed: {progress['completed_labs']}")
        print(f"\nDetailed Breakdown:")
        for lab_id, attempts in progress['attempts'].items():
            status = "✓" if lab_id in session.data['completed_labs'] else "○"
            print(f"  {status} {lab_id}: {attempts} attempts")
    
    def cmd_reset(self, student_id: str):
        """Reset student environment"""
        print(f"⚠️  Resetting environment for {student_id}...")
        print("This will:")
        print("  - Clear student session data")
        print("  - Reset all VMs to clean state")
        print("  - Preserve logs for record-keeping")
        
        confirm = input("\nProceed? (yes/no): ")
        if confirm.lower() == "yes":
            session = StudentSession(student_id)
            session.session_file.unlink(missing_ok=True)
            print(f"✓ {student_id} reset complete")
        else:
            print("Cancelled")
    
    def cmd_stats(self):
        """Show overall statistics"""
        print("\n📈 Lab Statistics\n")
        
        all_sessions = []
        for session_file in Config.STATE_DIR.glob("*.json"):
            with open(session_file) as f:
                all_sessions.append(json.load(f))
        
        if not all_sessions:
            print("No student data yet")
            return
        
        total_students = len(all_sessions)
        total_completions = sum(len(s['completed_labs']) for s in all_sessions)
        avg_score = sum(s['score'] for s in all_sessions) / total_students
        
        print(f"Total Students: {total_students}")
        print(f"Total Lab Completions: {total_completions}")
        print(f"Average Score: {avg_score:.1f}")
        print(f"\nMost Popular Labs:")
        # Could add more detailed stats here

# ============================================================================
# Main CLI Entry Point
# ============================================================================

def main():
    Config.ensure_dirs()
    
    if len(sys.argv) < 2:
        print(__doc__)
        return
    
    mode = sys.argv[1]
    
    if mode == "student":
        cli = StudentCLI()
        if len(sys.argv) < 3:
            print("Student commands: list, start, verify, hint, chat, status")
            return
        
        command = sys.argv[2]
        
        if command == "list":
            cli.cmd_list()
        elif command == "start" and len(sys.argv) > 3:
            cli.cmd_start(sys.argv[3])
        elif command == "verify":
            cli.cmd_verify()
        elif command == "hint":
            cli.cmd_hint()
        elif command == "chat" and len(sys.argv) > 4:
            cli.cmd_chat(sys.argv[3], " ".join(sys.argv[4:]))
        elif command == "status":
            cli.cmd_status()
        else:
            print("Unknown command or missing arguments")
    
    elif mode == "instructor":
        cli = InstructorCLI()
        if len(sys.argv) < 3:
            print("Instructor commands: dashboard, monitor, grade, reset, stats")
            return
        
        command = sys.argv[2]
        
        if command == "dashboard":
            cli.cmd_dashboard()
        elif command == "monitor" and len(sys.argv) > 3:
            cli.cmd_monitor(sys.argv[3])
        elif command == "grade" and len(sys.argv) > 3:
            cli.cmd_grade(sys.argv[3])
        elif command == "reset" and len(sys.argv) > 3:
            cli.cmd_reset(sys.argv[3])
        elif command == "stats":
            cli.cmd_stats()
        else:
            print("Unknown command or missing arguments")
    
    else:
        print("Mode must be 'student' or 'instructor'")

if __name__ == "__main__":
    main()
