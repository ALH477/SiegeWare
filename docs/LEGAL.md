**Legal Disclaimer**

**AI Agents Educational Lab**  
**SiegeWare™ Simulator**  
**Developed by DeMoD LLC**  
**Version 1.0 – December 23, 2025**

### 1. Nature of the Software

This software (“the Lab”, “SiegeWare simulator”, “AI Agents Educational Lab”) is a **purely educational and research-oriented simulation platform**. It is designed exclusively for:

- academic instruction in cybersecurity
- professional training in red team / blue team operations
- ethical AI-security research
- controlled, non-commercial self-study

The Lab intentionally simulates offensive and defensive cybersecurity techniques using artificial intelligence agents within a fully isolated, virtualized environment. **No functionality exists that allows, enables, or facilitates real-world unauthorized access, exploitation, data theft, denial of service, or any other unlawful activity.**

### 2. No Warranty – Provided “As Is”

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND ACCURACY OF SIMULATION RESULTS.

IN NO EVENT SHALL DEMOD LLC, ITS OFFICERS, EMPLOYEES, CONTRIBUTORS, OR AFFILIATES BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### 3. Educational & Research Use Only

This software must be used **exclusively for lawful educational, academic, or authorized professional training purposes**. Any use outside these contexts — including but not limited to:

- testing, probing, scanning, attacking, or exploiting any system, network, or service without explicit written permission from the owner
- conducting unauthorized penetration testing
- developing, refining, or deploying malware, exploits, or attack tools for malicious purposes
- attempting to apply knowledge gained here to real-world targets without proper authorization

is **strictly prohibited** and may constitute a criminal offense under applicable national and international laws (including but not limited to the U.S. Computer Fraud and Abuse Act 18 U.S.C. § 1030, EU Directive 2013/40/EU on attacks against information systems, and equivalent statutes worldwide).

### 4. User Responsibility & Mandatory Ethical Compliance

By downloading, installing, building, running, or using any part of this software, you represent and warrant that:

1. You will use it solely for authorized educational or research purposes.
2. You will never use knowledge, techniques, prompts, tool outputs, agent behavior, or lab outcomes to harm, damage, disrupt, or gain unauthorized access to any real system, network, or data.
3. You have read, understand, and agree to comply with all applicable laws, institutional policies, and ethical guidelines governing cybersecurity research and offensive security training.
4. You will immediately cease use and destroy all copies if you intend to use the knowledge gained for any unlawful purpose.
5. You will not redistribute modified versions that weaken or remove safety constraints, ethical prompts, network isolation, or simulation boundaries.

### 5. Simulation Boundaries & Containment

The Lab enforces multiple layers of containment:

- Kernel-level isolation via MicroVMs
- Network confinement to a virtual bridge (10.0.0.0/24) with no external connectivity
- Explicit system-prompt prohibitions against breakout, real harm, or illegal actions
- No privileged container capabilities beyond what is pedagogically necessary
- No host-level access granted to VMs except controlled Ollama API

Any attempt to circumvent these boundaries (whether successful or not) voids all permissions to use the software and may be reported to appropriate authorities.

### 6. Third-Party Dependencies & Compliance

This software uses open-source components including (but not limited to):

- Nix & NixOS ecosystem
- Ollama (local LLM inference)
- MicroVM.nix (virtualization)
- BIND9 (DNS authority)
- Alpine Linux images
- Python libraries (requests, pyyaml, etc.)

All third-party components retain their original licenses. Users are responsible for complying with those licenses.

### 7. Instructor / Institutional Obligations

If you deploy this lab in an educational or training setting, you must:

- Inform all participants of this disclaimer
- Require explicit acceptance of these terms before granting access
- Maintain records of participant acknowledgment
- Supervise usage to ensure compliance with ethical and legal standards
- Immediately revoke access if misuse is suspected

### 8. Reporting Obligations

If you discover any vulnerability, unintended capability, or potential for misuse:

- Report it immediately and exclusively to DeMoD LLC via security@demod.llc
- Do not publicly disclose until a coordinated disclosure process is completed

### 9. Governing Law & Jurisdiction

This disclaimer and any use of the software are governed by the laws of the State of Delaware, United States, without regard to conflict-of-law principles. Any dispute shall be resolved exclusively in the state or federal courts located in Delaware.

### 10. Acceptance of Terms

By building, running, using, modifying, distributing, or otherwise interacting with this software, you acknowledge that you have read, understood, and agree to be bound by this entire disclaimer.

**If you do not agree with every provision, you are not authorized to use the software in any way.**

**DeMoD LLC**  
**Training Tomorrow's Guardians Today**  
**December 23, 2025**  
**Licensed under GPL-3.0 with this additional legal disclaimer**
