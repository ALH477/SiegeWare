# AI Agents Educational Lab

A declarative, reproducible cybersecurity simulation environment for studying AI-assisted offensive and defensive security practices.

## Introducing SiegeWare

### The Concept

**SiegeWare** (noun) /siːdʒˈwɛər/  
A term coined by DeMoD LLC in 2025 to describe **AI-powered autonomous cyber warfare simulation platforms** designed for controlled, ethical, and educational replication of real-world offensive and defensive cybersecurity operations.

SiegeWare platforms are defined by:

- Autonomous or semi-autonomous AI agents performing red team (offensive) and blue team (defensive) roles
- Realistic, isolated network topology built with reproducible infrastructure
- Hardware-accelerated local large language model (LLM) inference for agent reasoning and decision-making
- Progressive, outcome-focused learning modules with verifiable assessment
- Strict safety boundaries that prevent any real-world harm or external impact
- Explicit emphasis on both technical mastery and ethical responsibility

### Why "SiegeWare"?

The name combines two evocative elements:

- **Siege** — referencing the historical military tactic of surrounding and methodically reducing a fortified position, paralleling modern cyber campaigns that involve reconnaissance, persistence, lateral movement, and objective achievement.
- **Ware** — derived from "software" and "malware", underscoring that this is a purely software-defined, AI-augmented simulation environment, not physical warfare.

SiegeWare represents the responsible convergence of artificial intelligence, cybersecurity training, and ethical simulation technology — a digital training platform that prepares defenders and helps students understand adversary tactics without ever crossing into real-world harm.

### This Lab as a SiegeWare Simulator

The **Universal Educational AI Agents Lab** is intentionally engineered as a **full-featured SiegeWare simulator**, with the core mission of preparing the next generation of IT security professionals.

Key SiegeWare characteristics implemented in this platform:

1. **Autonomous Agent Behavior**  
   Red and blue team agents leverage local LLMs to independently reason, plan, and execute actions within the simulation.

2. **Realistic Attack/Defense Lifecycle**  
   Five progressive labs mirror actual cyber kill chains, defensive workflows, and incident response processes.

3. **Isolated, High-Fidelity Environment**  
   MicroVMs, containerized services, and virtual networking create production-like conditions while guaranteeing complete isolation.

4. **Hardware-Agnostic Scalability**  
   Runs natively on consumer laptops (Apple Silicon via Asahi Linux, Intel/AMD/NVIDIA GPUs) and scales to classroom servers or research clusters.

5. **Verifiable Educational Outcomes**  
   Structured objectives, automated verification scripts, progress tracking, and instructor oversight tools.

6. **Ethical & Safety Framework**  
   Explicit system prompts, network containment, no external connectivity, and repeated emphasis on responsible use and simulation-only actions.

### Target Audience & Educational Impact

This SiegeWare simulator is designed for:

- University cybersecurity programs (undergraduate and graduate levels)
- Professional training organizations (SANS, Offensive Security, EC-Council, etc.)
- Corporate red team / blue team / purple team training programs
- Independent learners preparing for certifications (OSCP, PNPT, CRTP, CEH, etc.)
- AI security researchers studying agent behavior in adversarial environments

By releasing this platform as free, open-source software under GPL-3.0, DeMoD LLC seeks to:

- Democratize access to high-fidelity AI-augmented cybersecurity training
- Accelerate the development of AI-literate security professionals
- Promote ethical understanding of both offensive and defensive capabilities
- Establish a widely adopted reference platform for modern AI-security education

**SiegeWare is not entertainment. It is a professional training environment.**

The future of cybersecurity will be shaped by those who understand both how AI can attack systems and how AI can defend them. This lab exists to train that next generation — safely, responsibly, and effectively.

## Overview

This lab offers a secure, fully isolated environment to study the application of artificial intelligence in cybersecurity through structured red team vs. blue team simulations. Built with Nix and NixOS, it ensures complete reproducibility across deployments and supports a wide range of hardware platforms.

### Learning Objectives

By completing the full lab series, participants will be able to:

1. Use AI-assisted methods to perform network reconnaissance and asset enumeration
2. Identify and safely simulate exploitation of privilege escalation vectors
3. Implement defensive monitoring, anomaly detection, and incident response using AI agents
4. Execute multi-stage attack campaigns while practicing operational security
5. Optimize autonomous AI agents for competitive red vs. blue scenarios
6. Critically evaluate the role, strengths, limitations, and ethical implications of AI in security operations

### Core Capabilities

- **Fully declarative infrastructure** — 100% reproducible via Nix flakes
- **Broad hardware compatibility** — x86_64 (NVIDIA CUDA, AMD ROCm, Intel Arc, CPU) and aarch64 (Apple Silicon Metal)
- **GPU-accelerated inference** — Local LLMs via Ollama
- **Strong isolation** — MicroVM-based execution environments with network containment
- **Structured curriculum** — Five progressive labs with clear objectives and verification
- **Integrated management tooling** — `lab-ctl` CLI for students and instructors

## Deployment Instructions

### Prerequisites

- Nix package manager (https://nixos.org/download)
- Hardware:
  - Minimum: 16 GB RAM, 4-core CPU
  - Recommended: 32+ GB RAM, GPU (NVIDIA/AMD/Intel) or Apple Silicon
- Basic Linux terminal proficiency

### Step-by-Step Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/demod-llc/ai-agents-lab.git
   cd ai-agents-lab
   ```

2. **Deploy the lab infrastructure**
   ```bash
   nix run .#deploy
   ```
   This command:
   - Builds and activates the NixOS configuration
   - Starts the Ollama inference container
   - Launches MicroVMs (red-team, blue-team, target, vulnerable-vm, dns-controller)
   - Configures isolated networking and DNS authority

3. **Verify deployment**
   ```bash
   nix run .#status
   ```
   Expected output includes:
   - Ollama service running
   - All MicroVMs active
   - DNS controller responding (dig @10.0.0.5 red.lab.local)
   - Loaded models listed

4. **Access student guide**
   ```bash
   nix run .#student-quickstart
   ```

5. **(Optional) Build portable Docker image**
   ```bash
   nix build .#inferenceImage
   docker load < result
   ```

### Post-Deployment Checks

- Ollama API: `curl http://localhost:11434/api/tags`
- DNS resolution: `dig @10.0.0.5 red.lab.local`
- VM connectivity: `ping 10.0.0.101` (from host or another VM)

## Laboratory Exercises

### Lab 01: Network Reconnaissance
**Level**: Foundational | **Duration**: 30–45 minutes | **Points**: 100

**Focus**: AI-assisted enumeration and intelligence gathering  
**Key Skills**: Port scanning, service fingerprinting, OS detection, banner grabbing  
**Learning Outcomes**: Understand reconnaissance phase of penetration testing; interpret scan results; apply AI for tool selection and analysis

### Lab 02: Privilege Escalation
**Level**: Intermediate | **Duration**: 60–90 minutes | **Points**: 150

**Focus**: Identification and simulation of privilege escalation vectors  
**Key Skills**: SUID/SGID binary analysis, permission misconfiguration, service exploitation  
**Learning Outcomes**: Recognize common escalation paths; assess risk of misconfigurations; practice controlled exploitation

### Lab 03: Security Monitoring & Detection
**Level**: Intermediate | **Duration**: 45–60 minutes | **Points**: 125

**Focus**: Defensive operations and anomaly detection  
**Key Skills**: Log analysis, network monitoring, alert rule creation  
**Learning Outcomes**: Build foundational detection capabilities; understand blue team workflows; apply AI to accelerate threat identification

### Lab 04: Advanced Red Team Operations
**Level**: Advanced | **Duration**: 90–120 minutes | **Points**: 200

**Focus**: Execution of multi-stage attack campaigns  
**Key Skills**: Stealth reconnaissance, persistence, lateral movement, data exfiltration  
**Learning Outcomes**: Conduct structured attacks; apply operational security practices; understand evasion techniques

### Lab 05: Autonomous AI Red vs Blue Competition
**Level**: Advanced | **Duration**: 120+ minutes | **Points**: 300

**Focus**: Strategy optimization for competing autonomous AI agents  
**Key Skills**: Prompt engineering, performance tuning, attack-defense balance  
**Learning Outcomes**: Explore emergent behavior in AI security systems; understand trade-offs between aggression and stealth

## Instructor Guide

### Role & Responsibilities

Instructors serve as facilitators of learning, not just content deliverers. Your role includes:

- Setting clear expectations for ethical use
- Monitoring student progress and intervening when needed
- Providing context and real-world relevance
- Assessing learning outcomes fairly and consistently
- Customizing labs to match course objectives

### Preparation Checklist

1. Deploy the lab on instructor workstation/server
   ```bash
   nix run .#deploy
   ```

2. Verify all components
   ```bash
   nix run .#status
   ```

3. Run instructor setup script
   ```bash
   nix run .#instructor-setup
   ```

4. Create student accounts or environments (future feature)
   - Current: single shared lab (recommended for initial classes)
   - Planned: per-student MicroVM cloning

5. Review lab materials
   - /var/lib/ai-agents-lab/labs/
   - Each lab has lab.json, starter.py, verify.py

### Class Session Structure (Recommended)

**Duration**: 2–3 hours per lab (including debrief)

1. **Introduction (10–15 min)**
   - State learning objectives
   - Review ethical guidelines
   - Explain lab controller commands

2. **Guided Start (15–20 min)**
   - Students run `lab-ctl student start <lab-id>`
   - Instructor walks through starter code

3. **Independent Work (60–120 min)**
   - Students interact with agents
   - Use `lab-ctl student status` and `verify`
   - Instructor circulates, answers questions

4. **Debrief & Discussion (20–30 min)**
   - Share findings (screenshots, agent conversations)
   - Discuss what worked, what failed
   - Highlight defensive lessons from offensive actions

5. **Assessment**
   - Run `lab-ctl student verify` on student machines
   - Instructor reviews outputs
   - Use `lab-ctl instructor grade <student-id>` (future)

### Monitoring & Intervention

- **Real-time monitoring**:
  ```bash
  lab-ctl instructor monitor student-01
  ```

- **Class-wide stats**:
  ```bash
  lab-ctl instructor stats
  ```

- **Reset stuck student**:
  ```bash
  lab-ctl instructor reset student-01
  ```

### Customization Tips

- Add new labs by creating directories under `packages/lab-controller/labs/`
- Modify objectives/hints in `lab.json`
- Extend verification logic in `verify.py`
- Adjust DNS records in `modules/ai-agents-env.nix` for custom domains

### Grading Recommendations

- 40% Objective completion (via `verify`)
- 30% Quality of documentation / notes
- 20% Ethical reasoning demonstrated
- 10% Creativity / sophistication of approach

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
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐
│  │  Red Team   │  │  Blue Team  │  │   Target    │  │  Vulnerable │  │ DNS Controller│
│  │  MicroVM    │  │  MicroVM    │  │   MicroVM   │  │     VM      │  │   (BIND9)     │
│  │  10.0.0.101 │  │  10.0.0.102 │  │  10.0.0.103 │  │  10.0.0.104 │  │   10.0.0.5    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────┘
│         │                 │                 │                 │                 │
│         └─────────────────┴─────────────────┴─────────────────┴─────────────────┘
│                     br0 (10.0.0.1/24) – Isolated Lab Network                   │
└─────────────────────────────────────────────────────────────┘
```

## Security & Ethical Considerations

### Isolation & Safety Features

- MicroVMs provide kernel-level isolation from host
- Network traffic confined to virtual bridge (br0)
- No direct Internet access from any VM
- DNS resolution controlled by isolated DNS controller
- Environment fully resettable via rebuild
- All configurations declarative and auditable

### Responsible Use Policy

Participants must:

- Use knowledge gained solely for authorized educational or professional purposes
- Never apply techniques to production systems without explicit permission
- Adhere strictly to ethical and legal guidelines
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
sudo systemctl status docker-inference-optimized
sudo journalctl -u docker-inference-optimized -f
sudo systemctl restart docker-inference-optimized
```

### MicroVMs Not Starting

```bash
systemctl list-units 'microvm@*' --no-pager
sudo systemctl start microvm@red-team
sudo systemctl start microvm@blue-team
sudo systemctl start microvm@target
sudo systemctl start microvm@vulnerable-vm
sudo systemctl start microvm@dns-controller
```

### DNS Resolution Issues

```bash
sudo systemctl status microvm@dns-controller
dig @10.0.0.5 red.lab.local
ssh root@10.0.0.101 "dig red.lab.local"
```

### Lab Controller Issues

```bash
which lab-ctl
ls -la /var/lib/ai-agents-lab/labs/
sudo chmod -R 755 /var/lib/ai-agents-lab/
```

### Network Connectivity

```bash
ip addr show br0
sudo systemctl status dhcpd4
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

Provide:
- Clear problem description
- Steps to reproduce
- Expected vs. observed behavior
- System info (architecture, Nix version, hardware)

## License

Copyright © 2025 DeMoD LLC  
Licensed under the GNU General Public License v3.0 (GPL-3.0)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Acknowledgments

- Ollama project — efficient local LLM inference
- MicroVM.nix — lightweight virtualization
- NixOS ecosystem — declarative system configuration
- Educational contributors and reviewers

## Contact & Support

- Documentation — This README
- Troubleshooting — See section above
- Issues — GitHub issue tracker
- Community — (Discord/forum link forthcoming)

This SiegeWare simulator is designed to support rigorous, structured learning in AI security. Feedback and contributions are welcome to enhance its educational impact.

