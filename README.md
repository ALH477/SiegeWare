# AI Agents Educational Lab

A comprehensive, declarative cybersecurity lab environment where AI agents engage in red team vs blue team simulations for educational purposes.

## 🎯 What is This?

This lab provides a safe, isolated environment where you can:
- Learn cybersecurity concepts through AI-powered simulations
- Practice penetration testing with AI assistance (red team)
- Master defensive security monitoring (blue team)
- Understand how AI can be used in both offensive and defensive cybersecurity

### Key Features

✅ **Fully Reproducible** - Built with Nix for 100% consistent environments  
✅ **Multi-Platform** - Runs on x86_64 (Intel/AMD/NVIDIA) and ARM64 (Apple Silicon)  
✅ **GPU Accelerated** - Supports NVIDIA, AMD ROCm, Intel Arc, and Apple Silicon  
✅ **Isolated Environment** - Safe to experiment without breaking your system  
✅ **Progressive Learning** - 5 labs from beginner to advanced  
✅ **AI-Powered** - Uses local LLMs (Ollama) for agent intelligence  

---

## 🚀 Quick Start

### For Students

1. **Deploy the lab** (first time only):
   ```bash
   nix run .#deploy
   ```

2. **Start using the lab**:
   ```bash
   nix run .#student-quickstart
   ```

3. **List available labs**:
   ```bash
   lab-ctl student list
   ```

4. **Start your first lab**:
   ```bash
   lab-ctl student start lab-01-recon
   ```

5. **Get help when stuck**:
   ```bash
   lab-ctl student hint
   ```

6. **Check your progress**:
   ```bash
   lab-ctl student verify
   ```

### For Instructors

1. **Deploy the lab**:
   ```bash
   nix run .#deploy
   ```

2. **Set up student environments**:
   ```bash
   nix run .#instructor-setup
   ```

3. **Monitor students**:
   ```bash
   lab-ctl instructor monitor student-01
   ```

4. **View overall statistics**:
   ```bash
   lab-ctl instructor stats
   ```

5. **Generate grade reports**:
   ```bash
   lab-ctl instructor grade student-01
   ```

---

## 📚 Available Labs

### Lab 01: Basic Network Reconnaissance
**Difficulty**: Beginner | **Time**: 30-45 minutes | **Points**: 100

Learn to use AI agents for network enumeration and service discovery.

**Objectives**:
- Identify open ports on target systems
- Determine operating system and versions
- Enumerate running services
- Practice basic reconnaissance techniques

**What you'll learn**:
- Network scanning fundamentals
- AI-assisted penetration testing
- How to interpret scan results
- Operational security considerations

---

### Lab 02: Privilege Escalation Simulation
**Difficulty**: Intermediate | **Time**: 60-90 minutes | **Points**: 150

Discover and exploit common privilege escalation vectors.

**Objectives**:
- Find SUID binaries and misconfigurations
- Identify weak file permissions
- Exploit service vulnerabilities
- Gain elevated privileges safely

**What you'll learn**:
- Linux privilege escalation techniques
- Security misconfiguration identification
- AI-guided exploitation strategies
- Risk assessment and prioritization

---

### Lab 03: Security Monitoring and Detection
**Difficulty**: Intermediate | **Time**: 45-60 minutes | **Points**: 125

Switch sides and use the blue team agent to detect attacks.

**Objectives**:
- Monitor system logs for anomalies
- Detect port scanning attempts
- Identify suspicious network activity
- Create alerting rules

**What you'll learn**:
- Security monitoring fundamentals
- Log analysis techniques
- Anomaly detection with AI
- Incident response basics

---

### Lab 04: Advanced Penetration Testing
**Difficulty**: Advanced | **Time**: 90-120 minutes | **Points**: 200

Execute a complete attack campaign with multiple stages.

**Objectives**:
- Perform stealthy reconnaissance
- Establish persistence mechanisms
- Simulate lateral movement
- Exfiltrate data while evading detection

**What you'll learn**:
- Advanced penetration testing methodology
- Operational security (OpSec) practices
- Multi-stage attack campaigns
- Evasion techniques

---

### Lab 05: AI Red vs Blue Competition
**Difficulty**: Advanced | **Time**: 120+ minutes | **Points**: 300

Autonomous AI agents compete - you optimize their strategies.

**Objectives**:
- Tune red agent for maximum effectiveness
- Optimize blue agent detection capabilities
- Balance stealth vs speed in attacks
- Minimize detection while achieving goals

**What you'll learn**:
- AI agent prompt engineering
- Strategic thinking in cybersecurity
- Attack/defense trade-offs
- Competitive security scenarios

---

## 🛠️ Lab Controller Reference

### Student Commands

```bash
# List all available labs
lab-ctl student list

# Start a specific lab
lab-ctl student start <lab-id>

# Check your current status
lab-ctl student status

# Get a hint for the current lab
lab-ctl student hint

# Verify if you've completed objectives
lab-ctl student verify

# Chat directly with an AI agent
lab-ctl student chat red "scan the target for open ports"
lab-ctl student chat blue "analyze recent login attempts"

# Submit lab completion
lab-ctl student submit
```

### Instructor Commands

```bash
# Launch monitoring dashboard (web UI)
lab-ctl instructor dashboard

# View overall statistics
lab-ctl instructor stats

# Monitor a specific student's progress
lab-ctl instructor monitor <student-id>

# Generate grade report for a student
lab-ctl instructor grade <student-id>

# Reset a student's environment
lab-ctl instructor reset <student-id>

# Export all grades to CSV
lab-ctl instructor export-grades grades.csv
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Host System                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Ollama Container (GPU Accelerated)                    │ │
│  │  - red-qwen-agent   (Red Team AI)                      │ │
│  │  - blue-llama-agent (Blue Team AI)                     │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Red Team   │  │  Blue Team  │  │   Target    │        │
│  │  MicroVM    │  │  MicroVM    │  │   MicroVM   │        │
│  │             │  │             │  │             │        │
│  │ 10.0.0.101  │  │ 10.0.0.102  │  │ 10.0.0.103  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                 │                 │               │
│         └─────────────────┴─────────────────┘               │
│                     br0 (10.0.0.1/24)                       │
└─────────────────────────────────────────────────────────────┘
```

### Components

1. **Host System**: Runs Docker and MicroVMs, provides network isolation
2. **Ollama Container**: Hosts AI models with GPU acceleration
3. **Red Team VM**: Offensive security agent and tools
4. **Blue Team VM**: Defensive monitoring and detection
5. **Target VM**: Simulated vulnerable system
6. **Lab Controller**: Python-based CLI for students/instructors

---

## 🔒 Security Considerations

### Safe to Experiment

This lab is designed for safe experimentation:
- ✅ All VMs are isolated from your host system
- ✅ Network traffic is contained within virtual bridge
- ✅ No external network access from VMs
- ✅ State can be reset at any time
- ✅ Everything is declarative and reproducible

### What You Can Do

- Run any penetration testing tools inside VMs
- Intentionally create vulnerabilities for learning
- Practice exploits in a legal, controlled environment
- Break and rebuild the environment

### What You Should NOT Do

- ❌ Use techniques learned here on systems you don't own
- ❌ Share exploits outside educational contexts
- ❌ Attempt to break out of the VM isolation
- ❌ Use the lab for actual malicious purposes

**Remember**: Knowledge is powerful. Use it responsibly and ethically.

---

## 📖 Learning Path

### Week 1: Foundations
- Complete Lab 01 (Reconnaissance)
- Understand AI agent interaction
- Learn basic networking concepts

### Week 2: Offensive Security
- Complete Lab 02 (Privilege Escalation)
- Practice exploitation techniques
- Understand Linux security model

### Week 3: Defensive Security
- Complete Lab 03 (Detection)
- Learn log analysis
- Implement monitoring strategies

### Week 4: Advanced Techniques
- Complete Lab 04 (Advanced Red Team)
- Master multi-stage attacks
- Practice operational security

### Week 5: Competition
- Complete Lab 05 (AI vs AI)
- Optimize agent strategies
- Competitive scenario practice

---

## 🎓 Educational Outcomes

By completing this lab series, you will:

1. **Technical Skills**
   - Network reconnaissance and enumeration
   - Vulnerability identification and exploitation
   - Security monitoring and log analysis
   - Incident detection and response

2. **Conceptual Understanding**
   - Attack surface analysis
   - Defense in depth principles
   - Risk assessment methodologies
   - Security operations workflows

3. **AI Security Skills**
   - AI-assisted penetration testing
   - Automated threat detection
   - Prompt engineering for security tasks
   - Understanding AI limitations in security

4. **Professional Practice**
   - Ethical hacking principles
   - Responsible disclosure
   - Documentation and reporting
   - Operational security awareness

---

## 🐛 Troubleshooting

### Ollama Not Responding

```bash
# Check if container is running
sudo systemctl status docker-inference-optimized

# Restart if needed
sudo systemctl restart docker-inference-optimized

# Check logs
sudo journalctl -u docker-inference-optimized -f
```

### VMs Won't Start

```bash
# Check VM status
systemctl list-units 'microvm@*'

# Start manually
sudo systemctl start microvm@red-team
sudo systemctl start microvm@blue-team
sudo systemctl start microvm@target

# Check logs
sudo journalctl -u microvm@red-team -f
```

### Models Not Loading

```bash
# Check available models
curl http://localhost:11434/api/tags

# Manually pull missing models
ollama pull qwen3:0.6b-instruct-q5_K_M
ollama pull llama3.2:3b-instruct-q5_K_M

# Recreate custom models
sudo systemctl restart ollama-full-setup
```

### Lab Controller Issues

```bash
# Check if lab data exists
ls -la /var/lib/ai-agents-lab/labs/

# Verify lab controller is installed
which lab-ctl

# Check permissions
sudo chmod -R 755 /var/lib/ai-agents-lab/
```

### Network Connectivity

```bash
# Check bridge status
ip addr show br0

# Verify DHCP is running
sudo systemctl status dhcpd4

# Restart networking
sudo systemctl restart systemd-networkd
```

---

## 🤝 Contributing

### Adding New Labs

1. Create lab directory:
   ```bash
   mkdir -p packages/lab-controller/labs/lab-06-custom
   ```

2. Create `lab.json`:
   ```json
   {
     "title": "Your Lab Title",
     "description": "Lab description",
     "difficulty": "beginner|intermediate|advanced",
     "objectives": ["Objective 1", "Objective 2"],
     "hints": ["Hint 1", "Hint 2"],
     "points": 100
   }
   ```

3. Create optional files:
   - `starter.py` - Template code for students
   - `verify.py` - Automated verification script
   - `solution.py` - Reference implementation
   - `README.md` - Detailed instructions

4. Test your lab:
   ```bash
   lab-ctl student start lab-06-custom
   lab-ctl student verify
   ```

### Reporting Issues

Found a bug or have a suggestion? Please open an issue with:
- Description of the problem
- Steps to reproduce
- Expected vs actual behavior
- System information (OS, architecture)

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🙏 Acknowledgments

- **Ollama** - Local LLM inference
- **MicroVM.nix** - Lightweight virtualization
- **NixOS** - Declarative system configuration
- **Anthropic Claude** - AI assistance in development

---

## 📞 Support

- **Documentation**: Read this README thoroughly
- **Troubleshooting**: See the troubleshooting section above
- **Community**: Join our discussion forum (link TBD)
- **Issues**: GitHub issue tracker

---

## 🗺️ Roadmap

### v1.0 (Current)
- ✅ Core infrastructure
- ✅ 5 complete labs
- ✅ Student CLI interface
- ✅ Instructor monitoring tools

### v1.1 (Planned)
- 🔲 Web-based dashboard
- 🔲 Real-time monitoring UI
- 🔲 Automated grading system
- 🔲 Competition mode

### v1.2 (Future)
- 🔲 Multi-player scenarios
- 🔲 Custom agent training
- 🔲 Integration with LMS
- 🔲 Video tutorials

### v2.0 (Vision)
- 🔲 Cloud deployment option
- 🔲 Mobile app companion
- 🔲 Community lab sharing
- 🔲 Certification program

---

## 💡 Tips for Success

### For Students

1. **Read Carefully**: Each lab has specific objectives - understand them first
2. **Use Hints Wisely**: Hints unlock after attempts, but try on your own first
3. **Document Everything**: Keep notes of what works and what doesn't
4. **Ask Questions**: Use the AI agents - they're there to help you learn
5. **Practice Ethics**: These skills are powerful - use them responsibly

### For Instructors

1. **Start Simple**: Have students complete labs in order
2. **Encourage Exploration**: Let students experiment and fail safely
3. **Monitor Progress**: Check on struggling students early
4. **Create Competitions**: Lab 05 works great for team competitions
5. **Customize Labs**: Add your own scenarios based on class needs

---

**Ready to begin?** Start with `lab-ctl student list` and choose your first challenge!
