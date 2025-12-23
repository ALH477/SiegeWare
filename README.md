# AI Agents Educational Lab

A declarative, reproducible cybersecurity simulation environment for studying AI-assisted offensive and defensive security practices.

## Introducing SiegeWare

### The Concept

**SiegeWare** (noun) /siːdʒˈwɛər/  
A new term coined by DeMoD LLC in 2025 to describe **AI-powered autonomous cyber warfare simulation platforms** that replicate real-world offensive and defensive cybersecurity operations in a controlled, ethical, and educational environment.

SiegeWare platforms are characterized by:

- Autonomous or semi-autonomous AI agents acting as red team (attackers) and blue team (defenders)
- Realistic network topology with isolated, reproducible infrastructure
- Hardware-accelerated local LLM inference for agent decision-making
- Progressive, structured learning objectives with verifiable outcomes
- Strong safety boundaries preventing real-world harm
- Focus on teaching both technical skills and ethical considerations

### Why "SiegeWare"?

The name draws from two roots:

- **Siege** — evoking the classical military concept of surrounding and systematically reducing a fortified position, mirroring modern cyber operations that involve reconnaissance, persistence, lateral movement, and eventual objective capture.
- **Ware** — from "software" and "malware", emphasizing that this is a software-defined, AI-augmented simulation environment rather than physical warfare.

SiegeWare thus represents the convergence of artificial intelligence, cybersecurity training, and ethical simulation — a digital "siege engine" used to train defenders and understand attackers without real-world consequences.

### This Lab as a SiegeWare Simulator

This project — the **Universal Educational AI Agents Lab** — is intentionally designed as a **full-featured SiegeWare simulator** whose primary mission is to prepare the next generation of IT security professionals.

Key SiegeWare characteristics implemented here:

1. **Autonomous Agent Behavior**  
   Red and blue team agents use local LLMs to reason, plan, and execute actions in real time.

2. **Realistic Attack/Defense Cycle**  
   Progressive labs mirror actual cyber kill chains and defensive workflows.

3. **Isolated, High-Fidelity Environment**  
   MicroVMs + containerized services + virtual networking create production-like conditions safely.

4. **Hardware-Agnostic Scalability**  
   Supports consumer laptops (Apple Silicon, Intel/AMD/NVIDIA) → classroom servers → research clusters.

5. **Verifiable Educational Outcomes**  
   Structured objectives, automated verification, progress tracking, and instructor oversight.

6. **Ethical Framework**  
   Explicit focus on responsible use, isolation from real networks, and emphasis on defense-in-depth.

### Target Audience & Impact

This SiegeWare simulator is built for:

- **University cybersecurity programs** (undergraduate & graduate)
- **Professional training organizations** (SANS, Offensive Security, etc.)
- **Corporate security awareness & red/blue team training**
- **Independent learners** preparing for OSCP, PNPT, CRTP, etc.
- **AI security researchers** studying agent behavior in adversarial settings

By providing a free, open-source, reproducible SiegeWare platform, DeMoD LLC aims to:

- Democratize access to high-quality cybersecurity simulation
- Accelerate the development of AI-literate security professionals
- Foster ethical understanding of offensive security capabilities
- Create a standard reference platform for AI-security education

**SiegeWare is not a game. It is a training ground.**

Future defenders must understand how future attackers think — and future attackers must learn the consequences of their actions. This lab bridges that understanding in a controlled, responsible way.

## Overview

This lab provides a secure, isolated platform to explore the intersection of artificial intelligence and cybersecurity through structured, AI-driven red team vs. blue team exercises. Built entirely with Nix and NixOS, it guarantees identical environments across machines and supports multiple hardware platforms.

### Learning Objectives

Upon completion of the lab series, participants will be able to:

1. Apply AI-assisted techniques to perform network reconnaissance and enumeration
2. Identify and exploit common privilege escalation vectors in controlled settings
3. Implement defensive monitoring and anomaly detection using AI agents
4. Execute multi-stage attack campaigns while practicing operational security
5. Design and optimize autonomous AI agents for competitive red-blue scenarios
6. Understand the strengths, limitations, and ethical considerations of AI in security operations

### Core Capabilities

- **Declarative infrastructure** — 100% reproducible via Nix flakes
- **Cross-platform support** — x86_64 (NVIDIA, AMD ROCm, Intel Arc) and aarch64 (Apple Silicon Metal)
- **GPU acceleration** — Local LLM inference with Ollama
- **Strong isolation** — MicroVM-based execution environments
- **Progressive curriculum** — Five structured labs from foundational to advanced
- **Integrated tooling** — Student and instructor CLI (`lab-ctl`)

## Getting Started

### Prerequisites

- Nix package manager installed
- Hardware with sufficient resources:
  - Minimum: 16 GB RAM, 4-core CPU
  - Recommended: 32+ GB RAM, GPU (NVIDIA/AMD/Intel/Apple Silicon)
- Basic familiarity with Linux command line

### Deployment (Students & Instructors)

1. Clone the repository and deploy the lab infrastructure:
   ```bash
   nix run .#deploy
   ```

2. Verify the environment:
   ```bash
   nix run .#status
   ```

3. Access student guidance:
   ```bash
   nix run .#student-quickstart
   ```

### Student Workflow

1. List available exercises:
   ```bash
   lab-ctl student list
   ```

2. Launch an exercise:
   ```bash
   lab-ctl student start lab-01-recon
   ```

3. Monitor progress:
   ```bash
   lab-ctl student status
   ```

4. Request guidance:
   ```bash
   lab-ctl student hint
   ```

5. Submit for verification:
   ```bash
   lab-ctl student verify
   ```

6. Interact directly with agents:
   ```bash
   lab-ctl student chat red "recommend stealthy scanning techniques"
   lab-ctl student chat blue "analyze recent authentication logs"
   ```

### Instructor Workflow

1. Prepare multiple student environments:
   ```bash
   nix run .#instructor-setup
   ```

2. Access monitoring and assessment tools:
   ```bash
   lab-ctl instructor dashboard
   lab-ctl instructor stats
   lab-ctl instructor monitor student-01
   lab-ctl instructor grade student-01
   lab-ctl instructor export-grades grades.csv
   ```

## Laboratory Exercises

### Lab 01: Network Reconnaissance
**Level**: Foundational | **Duration**: 30–45 minutes | **Points**: 100

**Focus**: AI-assisted enumeration and intelligence gathering  
**Key Skills**: Port scanning, service fingerprinting, OS detection, banner grabbing  
**Learning Outcomes**: Understand reconnaissance phase of penetration testing; interpret scan results; apply AI for tool selection and analysis

### Lab 02: Privilege Escalation
**Level**: Intermediate | **Duration**: 60–90 minutes | **Points**: 150

**Focus**: Identification and exploitation of privilege escalation vectors  
**Key Skills**: SUID binary analysis, permission misconfiguration, service exploitation  
**Learning Outcomes**: Recognize common escalation paths; evaluate risk of misconfigurations; practice controlled exploitation

### Lab 03: Security Monitoring & Detection
**Level**: Intermediate | **Duration**: 45–60 minutes | **Points**: 125

**Focus**: Defensive operations and anomaly detection  
**Key Skills**: Log analysis, network monitoring, alert rule creation  
**Learning Outcomes**: Build foundational detection capabilities; understand blue team workflows; apply AI to accelerate analysis

### Lab 04: Advanced Red Team Operations
**Level**: Advanced | **Duration**: 90–120 minutes | **Points**: 200

**Focus**: Multi-stage attack campaign execution  
**Key Skills**: Stealth reconnaissance, persistence, lateral movement, data exfiltration  
**Learning Outcomes**: Execute structured attacks; practice OpSec; understand evasion techniques

### Lab 05: Autonomous AI Red vs Blue Competition
**Level**: Advanced | **Duration**: 120+ minutes | **Points**: 300

**Focus**: Strategy optimization for competing AI agents  
**Key Skills**: Prompt engineering, performance tuning, attack-defense balance  
**Learning Outcomes**: Explore emergent behavior in AI security systems; understand trade-offs between aggression and stealth

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Host System                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Ollama Container (GPU-accelerated inference)          │ │
│  │  - red-qwen-agent   (Offensive AI)                     │ │
│  │  - blue-llama-agent (Defensive AI)                     │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Red Team   │  │  Blue Team  │  │   Target    │        │
│  │  MicroVM    │  │  MicroVM    │  │   MicroVM   │        │
│  │  10.0.0.101 │  │  10.0.0.102 │  │  10.0.0.103 │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                 │                 │               │
│         └─────────────────┴─────────────────┘               │
│                     br0 (10.0.0.1/24)                       │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

- **Host System** — Orchestrates Docker containers and MicroVMs
- **Ollama Container** — Provides local LLM inference with hardware acceleration
- **Red Team MicroVM** — Offensive security environment and tools
- **Blue Team MicroVM** — Defensive monitoring and response environment
- **Target MicroVM** — Simulated vulnerable system
- **Lab Controller** — Python CLI for lab management and assessment

## Security & Ethical Considerations

### Isolation & Safety

- MicroVMs provide strong isolation from the host
- Network traffic is confined to virtual bridge
- VMs have no direct Internet access
- Environment state can be fully reset
- All configurations are declarative and auditable

### Responsible Use

Participants are expected to:

- Use acquired knowledge solely for authorized educational or professional purposes
- Never apply techniques to systems without explicit permission
- Maintain strict adherence to ethical guidelines
- Report discovered vulnerabilities responsibly

## Recommended Learning Path

### Module 1: Foundations (Weeks 1–2)
- Lab 01 – Network Reconnaissance
- Focus: AI-assisted enumeration, tool selection

### Module 2: Offensive Security (Weeks 3–4)
- Lab 02 – Privilege Escalation
- Focus: Vulnerability identification, exploitation techniques

### Module 3: Defensive Security (Weeks 5–6)
- Lab 03 – Security Monitoring & Detection
- Focus: Log analysis, anomaly detection, alerting

### Module 4: Advanced Operations (Weeks 7–8)
- Lab 04 – Multi-stage Attack Campaigns
- Focus: Persistence, lateral movement, evasion

### Module 5: Autonomous Systems (Weeks 9–10)
- Lab 05 – AI Red vs Blue Competition
- Focus: Strategy optimization, emergent behavior

## Educational Outcomes

By completing this lab series, participants will develop:

### Technical Competencies
- Network reconnaissance and enumeration
- Privilege escalation analysis
- Security monitoring and incident detection
- Multi-stage attack execution
- AI agent orchestration and tuning

### Conceptual Understanding
- Attack surface mapping
- Defense-in-depth principles
- Operational security (OpSec)
- AI limitations in security contexts
- Ethical considerations in offensive security

### Professional Skills
- Structured documentation and reporting
- Risk assessment and prioritization
- Responsible disclosure practices
- Prompt engineering for security tasks

## Troubleshooting Guide

### Ollama Not Responding

```bash
# Check container status
sudo systemctl status docker-inference-optimized

# View logs
sudo journalctl -u docker-inference-optimized -f

# Restart service
sudo systemctl restart docker-inference-optimized
```

### MicroVMs Not Starting

```bash
# Check status
systemctl list-units 'microvm@*' --no-pager

# Start manually
sudo systemctl start microvm@red-team
sudo systemctl start microvm@blue-team
sudo systemctl start microvm@target
```

### Models Not Loading

```bash
# List available models
curl http://localhost:11434/api/tags

# Manually pull a model
ollama pull qwen3:0.6b-instruct-q5_K_M

# Re-run setup
sudo systemctl restart ollama-full-setup
```

### Lab Controller Issues

```bash
# Verify installation
which lab-ctl

# Check data directory
ls -la /var/lib/ai-agents-lab/labs/

# Fix permissions if needed
sudo chmod -R 755 /var/lib/ai-agents-lab/
```

### Network Problems

```bash
# Verify bridge
ip addr show br0

# Check DHCP service
sudo systemctl status dhcpd4

# Restart networking
sudo systemctl restart systemd-networkd
```

## Contributing

### Adding New Labs

1. Create lab directory structure
2. Define `lab.json` metadata
3. Add optional `starter.py`, `verify.py`, `README.md`
4. Test with:
   ```bash
   lab-ctl student start <new-lab-id>
   lab-ctl student verify
   ```

### Reporting Issues

Please provide:
- Clear description of the problem
- Steps to reproduce
- Expected vs. observed behavior
- System information (architecture, Nix version, hardware)

## License

Copyright © 2025 DeMoD LLC  
Licensed under the GNU General Public License v3.0 (GPL-3.0)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Acknowledgments

- Ollama project – efficient local LLM inference
- MicroVM.nix – lightweight virtualization
- NixOS ecosystem – declarative system configuration
- Educational contributors and reviewers

## Contact & Support

- Documentation — This README
- Troubleshooting — See section above
- Issues — GitHub issue tracker
- Community — (Discord/forum link forthcoming)

This lab is designed to support structured learning in AI security. Feedback and contributions are welcome to enhance its educational impact.
