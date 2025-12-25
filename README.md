# SiegeWare Educational AI Agents Lab

A declarative, reproducible cybersecurity simulation environment for studying AI-assisted offensive and defensive security practices.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Host Machine (NixOS)                                  │
│                                                                             │
│  ┌─────────────────────────────┐                                            │
│  │ Ollama Container            │   ← GPU/CPU • Runs red & blue agents       │
│  │ (localhost:11434)           │                                            │
│  └─────────────────────────────┘                                            │
│                                                                             │
│  ┌───────────────┐   ┌───────────────┐   ┌───────────────┐                  │
│  │ Red Team VM   │   │ Blue Team VM  │   │ Target VM     │                  │
│  │ 10.0.0.101    │   │ 10.0.0.102    │   │ 10.0.0.103    │                  │
│  │ Offensive     │   │ Defensive     │   │ Victim        │                  │
│  └───────────────┘   └───────────────┘   └───────────────┘                  │
│         │                   │                   │                           │
│         └───────────────────┴───────────────────┘                           │
│                    br0 bridge (10.0.0.1/24)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Option 1: Nix Flakes (Recommended - Bit-for-Bit Reproducible)

```bash
# Enter development environment
nix develop github:ALH477/ai-agents-lab

# Deploy lab infrastructure
nix run github:ALH477/ai-agents-lab#deploy

# Check status
nix run github:ALH477/ai-agents-lab#status

# Start using
lab-ctl student list
lab-ctl student start lab-01-recon
```

### Option 2: Clone & Develop

```bash
git clone https://github.com/ALH477/ai-agents-lab.git
cd ai-agents-lab

# Enter development shell
nix develop

# Deploy
nix run .#deploy

# Start first lab
lab-ctl student start lab-01-recon
```

### Option 3: NixOS Module

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    siegeware.url = "github:ALH477/ai-agents-lab";
  };
  
  outputs = { nixpkgs, siegeware, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        siegeware.nixosModules.default
        {
          services.siegeware = {
            enable = true;
            enableOllama = true;
            enableNvidia = true;  # For GPU acceleration
          };
        }
      ];
    };
  };
}
```

### Option 4: Docker (Non-NixOS Systems)

```bash
# Build and run with Docker Compose
docker-compose up -d

# Enter red team container
docker-compose exec red bash
```

## 📚 Lab Exercises

| Lab | Name | Difficulty | Points | Duration |
|-----|------|------------|--------|----------|
| 01 | Network Reconnaissance | Foundational | 100 | 45 min |
| 02 | Privilege Escalation | Intermediate | 150 | 90 min |
| 03 | Security Monitoring | Intermediate | 125 | 60 min |
| 04 | Advanced Red Team | Advanced | 200 | 120 min |
| 05 | AI Red vs Blue | Advanced | 300 | 180 min |

## 🛠️ Available Commands

### Student Commands
```bash
lab-ctl student list                    # List available labs
lab-ctl student start lab-01-recon      # Start a lab
lab-ctl student status                  # Check progress
lab-ctl student hint                    # Get hints
lab-ctl student verify                  # Verify completion
lab-ctl student chat red "scan target"  # Chat with red agent
lab-ctl student chat blue "check logs"  # Chat with blue agent
```

### Instructor Commands
```bash
lab-ctl instructor dashboard            # Overview of all students
lab-ctl instructor monitor student-01   # Watch specific student
lab-ctl instructor reset student-01     # Reset student environment
lab-ctl instructor stats                # Lab statistics
lab-ctl instructor grade student-01     # Generate grade report
```

### Nix App Commands
```bash
nix run .#deploy              # Deploy infrastructure
nix run .#status              # Check system status
nix run .#student-quickstart  # Show student guide
nix run .#instructor-setup    # Setup instructor environment
nix run .#lab-ctl             # Run lab controller
```

## 📁 Project Structure

```
ai-agents-lab/
├── flake.nix                    # Nix flake (entry point)
├── modules/
│   └── ai-agents-env.nix        # NixOS module for lab environment
├── packages/
│   └── lab-controller/
│       └── lab-controller.py    # Student/instructor CLI tool
├── agent-tools/
│   ├── __init__.py              # Package exports
│   ├── base.py                  # Base tool classes and utilities
│   ├── registry.py              # Tool registry and executor
│   └── tools/
│       ├── port_scanner.py      # TCP port scanning
│       ├── web_request.py       # HTTP requests
│       ├── dns_lookup.py        # DNS queries
│       ├── service_detector.py  # Service fingerprinting
│       └── log_analyzer.py      # Log analysis (blue team)
└── docs/                        # Documentation
```

## 🔧 Components

### Lab Controller (`lab-ctl`)

Command-line interface for students and instructors.

**Student Commands:**
```bash
lab-ctl student list              # List available labs
lab-ctl student start lab-01-recon  # Start a lab
lab-ctl student hint              # Get hints
lab-ctl student verify            # Check progress
lab-ctl student chat red "scan the target"   # Talk to red agent
lab-ctl student chat blue "analyze logs"     # Talk to blue agent
lab-ctl student status            # View your progress
```

**Instructor Commands:**
```bash
lab-ctl instructor dashboard      # Overview of all students
lab-ctl instructor monitor <id>   # Watch specific student
lab-ctl instructor grade <id>     # Generate grade report
lab-ctl instructor reset <id>     # Reset student environment
lab-ctl instructor stats          # Lab statistics
```

### Agent Tools

Extensible toolkit for AI agents with safety controls.

```python
from agent_tools import registry

# List available tools
print(registry.list_tools())

# Execute a tool
result = registry.execute(
    "port_scanner",
    target="10.0.0.103",
    ports="22,80,443"
)

print(result.data)  # {'open_ports': [22, 80], ...}
```

**Available Tools:**
| Tool | Category | Description |
|------|----------|-------------|
| `port_scanner` | Reconnaissance | TCP port scanning with nmap |
| `web_request` | Reconnaissance | HTTP/HTTPS requests |
| `dns_lookup` | Reconnaissance | DNS record queries |
| `service_detector` | Reconnaissance | Service version detection |
| `log_analyzer` | Defense | Log analysis and security events |

### NixOS Module

Deploy the complete lab environment:

```nix
# configuration.nix
{
  imports = [ ./modules/ai-agents-env.nix ];
  
  services.aiAgentsLab = {
    enable = true;
    enableNvidia = true;  # For NVIDIA GPUs
    sshAuthorizedKeys = [ "ssh-rsa AAAA..." ];
  };
}
```

**Module Options:**
| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable the lab environment |
| `hostIP` | `10.0.0.1` | Host IP in lab network |
| `redTeamIP` | `10.0.0.101` | Red team VM IP |
| `blueTeamIP` | `10.0.0.102` | Blue team VM IP |
| `targetIP` | `10.0.0.103` | Target VM IP |
| `ollamaPort` | `11434` | Ollama API port |
| `enableNvidia` | `false` | Enable NVIDIA GPU support |
| `enableAMD` | `false` | Enable AMD ROCm support |
| `enableIntel` | `false` | Enable Intel GPU support |
| `maxLoadedModels` | `5` | Max models in memory |
| `numParallel` | `8` | Parallel inference requests |

## 📚 Lab Exercises

### Lab 01: Basic Network Reconnaissance
- **Difficulty:** Beginner
- **Points:** 100
- **Objectives:** Port scanning, OS detection, service enumeration
- **Skills:** nmap, banner grabbing, network mapping

### Lab 02: Privilege Escalation Simulation
- **Difficulty:** Intermediate
- **Points:** 150
- **Prerequisites:** Lab 01
- **Objectives:** SUID discovery, permission analysis, privesc paths

### Lab 03: Security Monitoring and Detection
- **Difficulty:** Intermediate
- **Points:** 125
- **Prerequisites:** Lab 02
- **Objectives:** Log analysis, anomaly detection, alerting

### Lab 04: Advanced Penetration Testing
- **Difficulty:** Advanced
- **Points:** 200
- **Prerequisites:** Lab 03
- **Objectives:** Multi-stage attacks, persistence, evasion

### Lab 05: AI Agent Competition
- **Difficulty:** Advanced
- **Points:** 300
- **Prerequisites:** Lab 04
- **Objectives:** Red vs Blue competition with AI assistance

## 🔒 Security Features

- **Network Isolation:** All tools restricted to `10.0.0.0/24` lab network
- **Host Protection:** Host IP (`10.0.0.1`) blocked from all scans
- **Rate Limiting:** Per-tool request limits prevent abuse
- **Sandboxed Verification:** Lab verification scripts run in isolated environment
- **File Locking:** Thread-safe session management
- **Input Validation:** Strict parameter validation on all tools

## 🛠 Development

### Running Tests
```bash
nix develop
pytest agent-tools/tests/ -v
```

### Code Formatting
```bash
black agent-tools/
mypy agent-tools/
```

### Creating New Tools

1. Create a new file in `agent-tools/tools/`:

```python
from agent_tools.base import (
    BaseTool, ToolDefinition, ToolParameter, 
    ToolResult, SafetyConstraints, ToolCategory, RiskLevel
)

class MyNewTool(BaseTool):
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="my_tool",
            description="What it does",
            category=ToolCategory.RECONNAISSANCE,
            risk_level=RiskLevel.LOW,
            parameters=[
                ToolParameter(
                    name="target",
                    type="string",
                    description="Target IP",
                    required=True
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        self.validate_target_ip(kwargs["target"])
        return True
    
    def execute(self, **kwargs) -> ToolResult:
        # Implementation
        return ToolResult.success_result({"result": "data"})
    
    def get_safety_constraints(self) -> SafetyConstraints:
        return SafetyConstraints()

def get_tool() -> BaseTool:
    return MyNewTool()
```

2. The tool will be auto-discovered on next import.

## 📊 Monitoring (Optional)

The module exposes metrics for Prometheus:
- Port 9090: Prometheus
- Port 3000: Grafana

## 🐛 Bug Fixes from Original

1. **NixOS Module (`ai-agents-env.nix`):**
   - Fixed undefined `config` reference (added proper module signature)
   - Fixed conflicting `hardware.graphics.extraPackages` with `lib.mkMerge`
   - Added proper SSH key configuration

2. **Lab Controller (`lab-controller.py`):**
   - Added file locking for concurrent session access
   - Sandboxed verification script execution
   - Proper port count calculation for ranges

3. **Port Scanner (`port_scanner.py`):**
   - Fixed port count for range specifications (e.g., "1-1000")
   - Added streaming/memory-efficient processing

4. **Log Analyzer:**
   - Memory-efficient file reading (no longer loads entire file)
   - Streaming tail implementation for large logs

## 🐳 Docker Deployment

The easiest way to run the lab without Nix packaging issues:

### Quick Start

```bash
# Build and start all containers
docker-compose up -d

# View status
docker-compose ps

# View logs
docker-compose logs -f red

# Enter red team container
docker-compose exec red bash

# Stop everything
docker-compose down
```

### Container Architecture

| Container | IP | Port | Purpose |
|-----------|-----|------|---------|
| `red` | 10.0.0.101 | 7777/udp | Red team agent |
| `blue` | 10.0.0.102 | 7778/udp | Blue team agent |
| `target` | 10.0.0.103 | 8080/tcp | Vulnerable web app (DVWA) |
| `controller` | 10.0.0.10 | 5000/tcp | Lab controller API |
| `ollama` | 10.0.0.20 | 11434/tcp | LLM inference (optional) |

### GPU Support

```bash
# With NVIDIA GPU
docker-compose --profile gpu up -d

# CPU only
docker-compose --profile cpu up -d
```

### Build StreamDB Library

```bash
cd streamdb
make
make install  # Installs to /usr/local/lib
make test     # Run tests
```

## 🖥️ Emacs Interface

Full-featured Emacs integration for the lab.

### Installation

```elisp
(use-package hydramesh
  :load-path "/path/to/ai-agents-lab/emacs"
  :bind ("C-c H" . hydramesh)
  :custom
  (hydramesh-home "/opt/hydramesh"))
```

### Key Commands

| Key | Command | Description |
|-----|---------|-------------|
| `C-c H` | `hydramesh` | Open Hydra menu |
| `C-c h t` | `hydramesh-tool-execute` | Execute security tool |
| `C-c h p` | `hydramesh-port-scan` | Quick port scan |
| `C-c h a` | `hydramesh-agent-chat` | Chat with agent |
| `C-c h s` | `hydramesh-lab-start` | Start a lab |

### SLIME Integration

```elisp
M-x slime                    ; Start Lisp REPL
M-x hydramesh-slime-load     ; Load HydraMesh
M-x hydramesh-slime-init     ; Initialize node
M-x hydramesh-slime-status   ; Check status
```

### Docker Control

```elisp
M-x hydramesh-docker-status  ; Container status
M-x hydramesh-docker-start   ; Start containers
M-x hydramesh-docker-stop    ; Stop containers
M-x hydramesh-docker-logs    ; View service logs
```

## 🔗 HydraMesh Integration

The lab integrates [HydraMesh](https://github.com/ALH477/DeMoD-Communication-Framework), a high-performance Lisp-based communication framework, for real-time agent coordination.

### Architecture

```
┌─────────────────┐     HydraMesh UDP      ┌─────────────────┐
│   Red Agent     │◄─────────────────────►│   Blue Agent    │
│   (10.0.0.101)  │    Binary Protocol     │   (10.0.0.102)  │
│   Port 7777     │                        │   Port 7778     │
└────────┬────────┘                        └────────┬────────┘
         │                                          │
         │         StreamDB Persistence             │
         └──────────────►◄──────────────────────────┘
                    hydramesh.db
```

### Features

- **UDP Transport**: Low-latency (<10ms) binary messaging
- **Reliable Delivery**: ACK-based retransmission for critical events
- **StreamDB**: Embedded key-value store for state persistence
- **Protocol Buffers**: 10-100x faster than JSON serialization

### Message Types

| Code | Type | Description | Reliable |
|------|------|-------------|----------|
| 1 | POSITION | Agent position updates | No |
| 3 | GAME_EVENT | Simulation events | Yes |
| 16 | AGENT_ACTION | Tool execution requests | Yes |
| 17 | AGENT_RESULT | Tool execution results | Yes |
| 18 | THREAT_ALERT | Blue team threat detection | Yes |
| 19 | RECON_DATA | Red team reconnaissance | Yes |

### Python API

```python
from agent_tools.hydramesh import HydraMeshNode, AgentCommunicationBridge

# Create a node
node = HydraMeshNode(node_id="red-agent", port=7777)
node.add_peer("blue-agent", "10.0.0.102", 7778)
node.start()

# Send position (unreliable, fast)
node.send_position(100.0, 50.0, 25.0)

# Send event (reliable)
node.send_event(3, "SCAN_COMPLETE|10.0.0.103")

# Share reconnaissance
node.send_recon_data("10.0.0.103", {
    "open_ports": [22, 80, 443],
    "os": "Linux"
})

node.stop()
```

### Lisp API (Native HydraMesh)

```lisp
;; Load HydraMesh
(load "hydramesh/hydramesh.lisp")

;; Initialize
(dcf-init "hydramesh/config.json")
(dcf-start)

;; Add peer
(dcf-add-peer "blue-agent" "10.0.0.102" 7778)

;; Send position
(dcf-send-position "red-agent" 100.0 50.0 25.0)

;; Send game event
(dcf-send-game-event 3 "SCAN_COMPLETE|10.0.0.103")

;; Get metrics
(dcf-get-metrics)

(dcf-stop)
```

### Tool Usage

```bash
# Initialize coordination
agent-tool-test agent_coordination --action=init --agent_type=red

# Connect to blue agent
agent-tool-test agent_coordination --action=connect \
    --peer_host=10.0.0.102 --peer_port=7778

# Share recon data
agent-tool-test agent_coordination --action=share_recon \
    --target=10.0.0.103 \
    --data='{"ports": [22, 80], "services": ["ssh", "http"]}'

# Get status
agent-tool-test agent_coordination --action=get_status
```

### StreamDB

HydraMesh uses StreamDB for persistent storage:

```python
from agent_tools.hydramesh import StreamDB

db = StreamDB("/var/lib/ai-agents-lab/hydramesh.db")

# Store data
db.insert("agent:red:state", '{"position": [100, 50, 25]}')

# Retrieve data
state = db.get("agent:red:state")

# Delete
db.delete("agent:red:state")

db.close()
```

### DSL Modules (hydramesh.core)

The `hydramesh.core` file provides composable domain-specific languages:

| DSL | Purpose |
|-----|---------|
| `hydramesh.game-net` | Multiplayer game networking |
| `hydramesh.audio-stream` | Real-time audio streaming |
| `hydramesh.sensor-net` | IoT sensor networks |
| `hydramesh.reliability` | Retry, circuit breaker patterns |
| `hydramesh.metrics` | Observability and monitoring |

## 📄 License

GPL-3.0 © 2025 DeMoD LLC

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests and linting
4. Submit a pull request
