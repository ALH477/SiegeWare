# packages/lab-controller/default.nix
# Nix package for the AI Agents Lab Controller tool

{ pkgs, lib, python3Packages }:

let
  # Lab definitions and exercises
  labsData = pkgs.runCommand "labs-data" {} ''
    mkdir -p $out/labs

    # Lab 01: Basic Reconnaissance
    mkdir -p $out/labs/lab-01-recon
    cat > $out/labs/lab-01-recon/lab.json << 'EOF'
    {
      "title": "Basic Network Reconnaissance",
      "description": "Use AI agents to enumerate network services and gather intelligence on the target system.",
      "difficulty": "beginner",
      "estimated_time": "30-45 minutes",
      "objectives": [
        "Identify all open TCP ports on the target (10.0.0.103)",
        "Determine the operating system of the target",
        "Find the version of SSH running on port 22",
        "Enumerate at least 3 running services"
      ],
      "hints": [
        "Ask the red agent: 'Scan the target at 10.0.0.103 for open ports'",
        "Common reconnaissance tools: nmap, netcat, curl",
        "Try banner grabbing: 'nc 10.0.0.103 22'",
        "OS detection often relies on TCP/IP fingerprinting"
      ],
      "time_limit": 3600,
      "points": 100
    }
    EOF

    cat > $out/labs/lab-01-recon/starter.py << 'EOF'
    #!/usr/bin/env python3
    """
    Starter code for Lab 01: Basic Reconnaissance
    
    Your task: Complete the reconnaissance functions below
    """
    import requests

    OLLAMA_URL = "http://localhost:11434"
    RED_MODEL = "red-qwen-agent"
    TARGET_IP = "10.0.0.103"

    def ask_agent(prompt: str) -> str:
        """Send a prompt to the red team agent"""
        response = requests.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": RED_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "stream": False
            }
        )
        return response.json()["message"]["content"]

    def scan_ports():
        """TODO: Use the agent to scan for open ports"""
        prompt = f"Scan {TARGET_IP} for open TCP ports. What tools should I use?"
        print(ask_agent(prompt))
        
        # Your code here: Parse response and execute scan
        pass

    def identify_os():
        """TODO: Determine the target operating system"""
        # Your code here
        pass

    def enumerate_services():
        """TODO: Identify running services"""
        # Your code here
        pass

    if __name__ == "__main__":
        print("=== Lab 01: Network Reconnaissance ===\n")
        print("Starting reconnaissance on", TARGET_IP)
        print()
        
        scan_ports()
        identify_os()
        enumerate_services()
    EOF

    cat > $out/labs/lab-01-recon/verify.py << 'EOF'
    #!/usr/bin/env python3
    """Verification script for Lab 01"""
    import json
    import subprocess
    import sys

    def verify_objectives():
        results = {
            "objectives_met": [],
            "objectives_failed": [],
            "score": 0,
            "feedback": []
        }
        
        # Check if student found open ports
        # This is a placeholder - real implementation would check student's findings
        results["objectives_met"].append("Port scanning attempted")
        results["score"] += 25
        
        # Additional checks would go here
        results["feedback"].append("Good start! Continue exploring the target.")
        
        return results

    if __name__ == "__main__":
        results = verify_objectives()
        print(json.dumps(results))
        sys.exit(0 if results["score"] >= 70 else 1)
    EOF

    # Lab 02: Privilege Escalation
    mkdir -p $out/labs/lab-02-privesc
    cat > $out/labs/lab-02-privesc/lab.json << 'EOF'
    {
      "title": "Privilege Escalation Simulation",
      "description": "Identify and exploit common privilege escalation vectors in a controlled environment.",
      "difficulty": "intermediate",
      "estimated_time": "60-90 minutes",
      "objectives": [
        "Find SUID binaries on the target system",
        "Identify misconfigured file permissions",
        "Discover running services with elevated privileges",
        "Simulate a privilege escalation attack"
      ],
      "hints": [
        "SUID binaries: find / -perm -4000 2>/dev/null",
        "Check for world-writable files in sensitive directories",
        "Look for services running as root with weak configurations",
        "The red agent can suggest exploitation techniques"
      ],
      "time_limit": 5400,
      "points": 150
    }
    EOF

    # Lab 03: Defense and Detection
    mkdir -p $out/labs/lab-03-defense
    cat > $out/labs/lab-03-defense/lab.json << 'EOF'
    {
      "title": "Security Monitoring and Detection",
      "description": "Use the blue team agent to detect and respond to simulated attacks.",
      "difficulty": "intermediate",
      "estimated_time": "45-60 minutes",
      "objectives": [
        "Monitor system logs for suspicious activity",
        "Detect port scanning attempts",
        "Identify anomalous network connections",
        "Create alerting rules for common attack patterns"
      ],
      "hints": [
        "Ask blue agent to analyze /var/log/auth.log",
        "Network monitoring: netstat, ss, tcpdump",
        "Look for failed login attempts and unusual user activity",
        "Compare current state to baseline"
      ],
      "time_limit": 3600,
      "points": 125
    }
    EOF

    # Lab 04: Advanced Red Team Operations
    mkdir -p $out/labs/lab-04-advanced
    cat > $out/labs/lab-04-advanced/lab.json << 'EOF'
    {
      "title": "Advanced Penetration Testing",
      "description": "Execute a multi-stage attack campaign using AI-assisted techniques.",
      "difficulty": "advanced",
      "estimated_time": "90-120 minutes",
      "objectives": [
        "Perform initial reconnaissance without alerting defenses",
        "Establish persistence on the target",
        "Perform lateral movement simulation",
        "Exfiltrate simulated sensitive data",
        "Evade blue team detection"
      ],
      "hints": [
        "Use stealthy scanning techniques (slow scans, randomized timing)",
        "Consider using encrypted channels for C2",
        "Think about operational security (OpSec)",
        "The blue team is actively monitoring - stay quiet!"
      ],
      "time_limit": 7200,
      "points": 200
    }
    EOF

    # Lab 05: AI Red vs Blue Competition
    mkdir -p $out/labs/lab-05-competition
    cat > $out/labs/lab-05-competition/lab.json << 'EOF'
    {
      "title": "AI Agent Competition: Red vs Blue",
      "description": "Both red and blue agents are fully autonomous. Your task is to optimize their strategies.",
      "difficulty": "advanced",
      "estimated_time": "120+ minutes",
      "objectives": [
        "Tune red agent prompts for maximum stealth",
        "Optimize blue agent detection algorithms",
        "Achieve objectives before blue team responds",
        "Minimize detection score while maximizing attack success"
      ],
      "hints": [
        "Red team: 'Be stealthy, use evasion techniques'",
        "Blue team: 'Monitor for anomalies, not just signatures'",
        "Consider the cat-and-mouse dynamic",
        "Iteratively improve based on what gets detected"
      ],
      "time_limit": 10800,
      "points": 300
    }
    EOF

    chmod -R +r $out
  '';

in python3Packages.buildPythonApplication rec {
  pname = "lab-controller";
  version = "1.0.0";

  src = ./.;

  propagatedBuildInputs = with python3Packages; [
    requests
    # Could add more dependencies as needed
  ];

  # Install the main script
  installPhase = ''
    mkdir -p $out/bin
    cp ${./lab-controller.py} $out/bin/lab-ctl
    chmod +x $out/bin/lab-ctl

    # Copy labs data
    mkdir -p $out/share/lab-controller
    cp -r ${labsData}/labs $out/share/lab-controller/
  '';

  # Make labs data available via environment variable
  postFixup = ''
    wrapProgram $out/bin/lab-ctl \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --set LAB_CONTROLLER_DATA $out/share/lab-controller
  '';

  meta = with lib; {
    description = "Educational AI Agents Lab Controller for students and instructors";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
