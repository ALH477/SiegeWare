# ════════════════════════════════════════════════════════════════════════════
# SiegeWare Educational AI Agents Lab - Nix Flake
# 
# A declarative, reproducible cybersecurity simulation environment for 
# studying AI-assisted offensive and defensive security practices.
#
# Copyright (C) 2025 DeMoD LLC
# Licensed under GPL-3.0
#
# Usage:
#   nix develop              - Enter development shell
#   nix build                - Build all packages
#   nix run .#deploy         - Deploy full lab infrastructure
#   nix run .#status         - Check deployment status
#   nix run .#lab-ctl        - Run lab controller CLI
#
# NixOS Installation:
#   Add to flake.nix inputs:
#     siegeware.url = "github:ALH477/ai-agents-lab";
#   
#   Add to modules:
#     siegeware.nixosModules.default
#   
#   Enable in configuration.nix:
#     services.siegeware.enable = true;
#
# ════════════════════════════════════════════════════════════════════════════
{
  description = "SiegeWare - AI-powered cybersecurity training platform";

  # ══════════════════════════════════════════════════════════════════════════
  # Inputs - Pinned for bit-for-bit reproducibility
  # ══════════════════════════════════════════════════════════════════════════
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    flake-utils.url = "github:numtide/flake-utils";
    
    # MicroVM support for isolated VMs
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Rust toolchain for StreamDB optimizations (optional)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, microvm, rust-overlay }:
    let
      # Supported systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      
      # Version info
      version = "2.2.0";
      
      # Lab network configuration
      labNetwork = {
        bridge = "br0";
        subnet = "10.0.0.0/24";
        gateway = "10.0.0.1";
        dns = "10.0.0.5";
        hosts = {
          red-team = "10.0.0.101";
          blue-team = "10.0.0.102";
          target = "10.0.0.103";
          vulnerable = "10.0.0.104";
          dns-controller = "10.0.0.5";
          ollama = "10.0.0.20";
        };
      };
      
      # Lab definitions (embedded for reproducibility)
      labDefinitions = {
        lab-01-recon = {
          name = "Network Reconnaissance";
          description = "AI-assisted enumeration and intelligence gathering";
          difficulty = "foundational";
          duration_minutes = 45;
          points = 100;
          objectives = [
            "Discover all active hosts on the network"
            "Identify open ports on target systems"
            "Fingerprint services and OS versions"
            "Document findings in structured format"
          ];
          hints = [
            "Start with a ping sweep to find live hosts"
            "Use nmap for detailed port scanning"
            "Service banners often reveal version info"
          ];
        };
        
        lab-02-privesc = {
          name = "Privilege Escalation";
          description = "Identification and simulation of privilege escalation vectors";
          difficulty = "intermediate";
          duration_minutes = 90;
          points = 150;
          prerequisites = [ "lab-01-recon" ];
          objectives = [
            "Identify SUID/SGID binaries"
            "Find permission misconfigurations"
            "Discover credential exposure"
            "Achieve simulated root access"
          ];
          hints = [
            "Check for world-writable directories"
            "Look for credentials in config files"
            "SUID binaries can be exploited for escalation"
          ];
        };
        
        lab-03-defense = {
          name = "Security Monitoring & Detection";
          description = "Defensive operations and anomaly detection";
          difficulty = "intermediate";
          duration_minutes = 60;
          points = 125;
          prerequisites = [ "lab-01-recon" ];
          objectives = [
            "Set up log monitoring"
            "Create detection rules"
            "Identify simulated attack patterns"
            "Document incident response"
          ];
          hints = [
            "Focus on authentication logs first"
            "Look for unusual patterns in network traffic"
            "Correlate events across multiple sources"
          ];
        };
        
        lab-04-advanced = {
          name = "Advanced Red Team Operations";
          description = "Multi-stage attack campaign execution";
          difficulty = "advanced";
          duration_minutes = 120;
          points = 200;
          prerequisites = [ "lab-02-privesc" "lab-03-defense" ];
          objectives = [
            "Conduct stealth reconnaissance"
            "Establish persistence"
            "Perform lateral movement"
            "Achieve data exfiltration"
          ];
          hints = [
            "Minimize detection by limiting scan rates"
            "Use living-off-the-land techniques"
            "Document your attack chain"
          ];
        };
        
        lab-05-competition = {
          name = "Autonomous AI Red vs Blue";
          description = "Strategy optimization for competing AI agents";
          difficulty = "advanced";
          duration_minutes = 180;
          points = 300;
          prerequisites = [ "lab-04-advanced" ];
          objectives = [
            "Configure red team AI strategy"
            "Configure blue team AI strategy"
            "Run competitive simulation"
            "Analyze emergent behaviors"
          ];
          hints = [
            "Balance aggression with stealth"
            "Consider resource constraints"
            "Iterate on prompts based on results"
          ];
        };
      };
      
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        # Package sets with overlays
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
          config.allowUnfree = true;
        };
        
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        
        # Python environment
        python = pkgs.python311;
        pythonPackages = python.pkgs;
        
        # Platform checks
        isLinux = pkgs.stdenv.isLinux;
        isDarwin = pkgs.stdenv.isDarwin;
        
        # ════════════════════════════════════════════════════════════════════
        # StreamDB - C Library (thread-safe embedded database)
        # ════════════════════════════════════════════════════════════════════
        streamdb = pkgs.stdenv.mkDerivation {
          pname = "streamdb";
          inherit version;
          
          src = ./streamdb;
          
          nativeBuildInputs = with pkgs; [ gnumake ];
          
          buildPhase = ''
            make shared static CC=${pkgs.stdenv.cc}/bin/cc
          '';
          
          installPhase = ''
            mkdir -p $out/lib $out/include
            cp libstreamdb.* $out/lib/ 2>/dev/null || true
            cp *.h $out/include/
          '';
          
          # Ensure reproducibility
          enableParallelBuilding = true;
          
          meta = with pkgs.lib; {
            description = "Lightweight thread-safe embedded database using reverse trie";
            license = licenses.lgpl21Plus;
            platforms = platforms.unix;
            maintainers = [];
          };
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Agent Tools - Python Package
        # ════════════════════════════════════════════════════════════════════
        agentTools = pythonPackages.buildPythonPackage rec {
          pname = "agent-tools";
          inherit version;
          format = "setuptools";
          
          src = ./agent-tools;
          
          propagatedBuildInputs = with pythonPackages; [
            requests
          ];
          
          nativeBuildInputs = with pythonPackages; [
            setuptools
            wheel
          ];
          
          preBuild = ''
            cat > setup.py << 'SETUP'
from setuptools import setup, find_packages

setup(
    name="agent-tools",
    version="${version}",
    packages=find_packages(),
    install_requires=["requests"],
    python_requires=">=3.9",
    entry_points={
        "console_scripts": [
            "agent-tool-list=agent_tools.registry:main_list",
            "agent-tool-test=agent_tools.registry:main_test",
        ]
    },
    author="DeMoD LLC",
    description="Security tools for AI agents in SiegeWare lab",
    license="GPL-3.0",
)
SETUP
          '';
          
          # Skip tests during build
          doCheck = false;
          
          meta = with pkgs.lib; {
            description = "Security tools for AI agents";
            license = licenses.gpl3;
          };
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Lab Controller - CLI Application
        # ════════════════════════════════════════════════════════════════════
        labController = pkgs.stdenv.mkDerivation rec {
          pname = "lab-controller";
          inherit version;
          
          src = ./packages/lab-controller;
          
          nativeBuildInputs = [ pkgs.makeWrapper ];
          
          buildInputs = [
            python
            pythonPackages.requests
            agentTools
          ];
          
          runtimeInputs = with pkgs; [
            nmap
            netcat-openbsd
            curl
            dnsutils
            openssh
            jq
          ];
          
          installPhase = ''
            mkdir -p $out/bin $out/share/lab-controller $out/share/labs
            
            # Copy main script
            cp lab-controller.py $out/share/lab-controller/
            
            # Create wrapper with all dependencies
            makeWrapper ${python}/bin/python3 $out/bin/lab-ctl \
              --add-flags "$out/share/lab-controller/lab-controller.py" \
              --prefix PATH : "${pkgs.lib.makeBinPath runtimeInputs}" \
              --prefix PYTHONPATH : "${agentTools}/${python.sitePackages}" \
              --set LAB_CONTROLLER_DATA "$out/share/labs"
            
            # Write lab definitions
            cat > $out/share/labs/labs.json << 'LABS'
${builtins.toJSON labDefinitions}
LABS
          '';
          
          meta = with pkgs.lib; {
            description = "Lab controller CLI for SiegeWare AI Agents Lab";
            license = licenses.gpl3;
            mainProgram = "lab-ctl";
          };
        };
        
        # ════════════════════════════════════════════════════════════════════
        # HydraMesh Data (Lisp sources + Python bindings)
        # ════════════════════════════════════════════════════════════════════
        hydrameshData = pkgs.runCommand "hydramesh-data-${version}" {} ''
          mkdir -p $out/hydramesh $out/share/hydramesh
          
          # Copy Lisp sources
          cp -r ${./hydramesh}/* $out/hydramesh/ 2>/dev/null || true
          
          # Create symlink for share
          ln -s $out/hydramesh $out/share/hydramesh/lisp
          
          chmod -R +r $out
        '';
        
        # ════════════════════════════════════════════════════════════════════
        # Emacs Package
        # ════════════════════════════════════════════════════════════════════
        emacsHydramesh = pkgs.emacsPackages.trivialBuild {
          pname = "hydramesh";
          inherit version;
          src = ./emacs;
          
          meta = with pkgs.lib; {
            description = "Emacs interface for HydraMesh AI Agents Lab";
            license = licenses.gpl3;
          };
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Complete Bundle Package
        # ════════════════════════════════════════════════════════════════════
        siegewareFull = pkgs.symlinkJoin {
          name = "siegeware-${version}";
          paths = [
            streamdb
            agentTools
            labController
            hydrameshData
          ];
          
          postBuild = ''
            # Create combined binary directory
            mkdir -p $out/bin
            
            # Ensure lab-ctl is available
            ln -sf ${labController}/bin/lab-ctl $out/bin/lab-ctl 2>/dev/null || true
          '';
          
          meta = with pkgs.lib; {
            description = "SiegeWare - Complete AI Agents Lab bundle";
            license = licenses.gpl3;
          };
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Docker/OCI Image (for non-NixOS deployment)
        # ════════════════════════════════════════════════════════════════════
        dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "siegeware";
          tag = version;
          
          contents = [
            pkgs.bashInteractive
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.findutils
            pkgs.gawk
            pkgs.nmap
            pkgs.netcat-openbsd
            pkgs.curl
            pkgs.dnsutils
            pkgs.jq
            pkgs.openssh
            pkgs.cacert
            python
            agentTools
            labController
            streamdb
          ];
          
          config = {
            Env = [
              "PATH=/bin"
              "PYTHONPATH=${agentTools}/${python.sitePackages}"
              "LD_LIBRARY_PATH=${streamdb}/lib"
              "LAB_ROOT=/var/lib/ai-agents-lab"
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
            WorkingDir = "/home/siegeware";
            User = "1000:1000";
            Cmd = [ "/bin/bash" ];
            Labels = {
              "org.opencontainers.image.title" = "SiegeWare";
              "org.opencontainers.image.version" = version;
              "org.opencontainers.image.description" = "AI-powered cybersecurity training platform";
              "org.opencontainers.image.licenses" = "GPL-3.0";
              "org.opencontainers.image.source" = "https://github.com/ALH477/ai-agents-lab";
            };
          };
          
          # Create necessary directories
          extraCommands = ''
            mkdir -p home/siegeware var/lib/ai-agents-lab/{sessions,logs,labs}
            chmod 755 var/lib/ai-agents-lab
          '';
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Deployment Script
        # ════════════════════════════════════════════════════════════════════
        deployScript = pkgs.writeShellScriptBin "siegeware-deploy" ''
          set -euo pipefail
          
          echo "═══════════════════════════════════════════════════════════════════"
          echo "  SiegeWare Educational AI Agents Lab"
          echo "  Version: ${version}"
          echo "  Platform: ${system}"
          echo "═══════════════════════════════════════════════════════════════════"
          echo ""
          
          LAB_ROOT="''${LAB_ROOT:-/var/lib/ai-agents-lab}"
          
          # Detect environment
          if [ -f /etc/NIXOS ]; then
            echo "[INFO] NixOS detected"
            DEPLOY_MODE="nixos"
          elif [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
            echo "[INFO] Docker container detected"
            DEPLOY_MODE="docker"
          elif command -v nix &> /dev/null; then
            echo "[INFO] Nix available on non-NixOS system"
            DEPLOY_MODE="nix"
          else
            echo "[WARN] Nix not found - limited functionality"
            DEPLOY_MODE="standalone"
          fi
          
          echo "[INFO] Deploy mode: $DEPLOY_MODE"
          echo ""
          
          # Create directories
          echo "[STEP] Creating lab directories..."
          mkdir -p "$LAB_ROOT/sessions" "$LAB_ROOT/logs" "$LAB_ROOT/labs" 2>/dev/null || \
            sudo mkdir -p "$LAB_ROOT/sessions" "$LAB_ROOT/logs" "$LAB_ROOT/labs"
          
          # Copy lab definitions
          if [ -f "${labController}/share/labs/labs.json" ]; then
            echo "[STEP] Installing lab definitions..."
            cp "${labController}/share/labs/labs.json" "$LAB_ROOT/labs/" 2>/dev/null || \
              sudo cp "${labController}/share/labs/labs.json" "$LAB_ROOT/labs/"
          fi
          
          # Check Ollama
          echo "[STEP] Checking Ollama..."
          if command -v ollama &> /dev/null; then
            echo "  [OK] Ollama binary found"
            if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
              echo "  [OK] Ollama API responding"
            else
              echo "  [WARN] Ollama not running. Start with: ollama serve"
            fi
          else
            echo "  [INFO] Ollama not installed"
            if [ "$DEPLOY_MODE" = "nixos" ]; then
              echo "         Add to configuration.nix: services.ollama.enable = true;"
            else
              echo "         Install from: https://ollama.ai"
            fi
          fi
          
          echo ""
          echo "═══════════════════════════════════════════════════════════════════"
          echo "  Deployment Complete!"
          echo "═══════════════════════════════════════════════════════════════════"
          echo ""
          echo "Quick Start:"
          echo "  lab-ctl student list              # List available labs"
          echo "  lab-ctl student start lab-01-recon  # Start first lab"
          echo "  lab-ctl student hint              # Get hints"
          echo "  lab-ctl student verify            # Check progress"
          echo ""
        '';
        
        # ════════════════════════════════════════════════════════════════════
        # Status Script
        # ════════════════════════════════════════════════════════════════════
        statusScript = pkgs.writeShellScriptBin "siegeware-status" ''
          set -euo pipefail
          
          echo "═══════════════════════════════════════════════════════════════════"
          echo "  SiegeWare Status"
          echo "═══════════════════════════════════════════════════════════════════"
          echo ""
          
          # System info
          echo "System:"
          echo "  Platform: ${system}"
          echo "  Nix version: $(nix --version 2>/dev/null || echo 'not found')"
          echo ""
          
          # Ollama status
          echo "Ollama Service:"
          if curl -s --connect-timeout 2 http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo "  [OK] API responding at localhost:11434"
            MODELS=$(curl -s http://localhost:11434/api/tags | ${pkgs.jq}/bin/jq -r '.models[]?.name // empty' 2>/dev/null)
            if [ -n "$MODELS" ]; then
              echo "  Models loaded:"
              echo "$MODELS" | sed 's/^/    - /'
            else
              echo "  No models loaded. Pull with: ollama pull qwen2.5:7b"
            fi
          else
            echo "  [WARN] Not responding"
          fi
          echo ""
          
          # Lab data
          echo "Lab Data:"
          LAB_ROOT="''${LAB_ROOT:-/var/lib/ai-agents-lab}"
          if [ -d "$LAB_ROOT" ]; then
            echo "  [OK] Directory: $LAB_ROOT"
            echo "  Sessions: $(find "$LAB_ROOT/sessions" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
            echo "  Labs defined: $(${pkgs.jq}/bin/jq 'keys | length' "$LAB_ROOT/labs/labs.json" 2>/dev/null || echo '0')"
          else
            echo "  [WARN] Lab directory not found at $LAB_ROOT"
            echo "         Run: nix run .#deploy"
          fi
          echo ""
          
          # StreamDB
          echo "StreamDB Library:"
          if [ -f "${streamdb}/lib/libstreamdb.so" ] || [ -f "${streamdb}/lib/libstreamdb.dylib" ]; then
            echo "  [OK] Available at ${streamdb}/lib/"
          else
            echo "  [WARN] Not found"
          fi
          echo ""
          
          # Network (Linux only)
          if [ -f /etc/NIXOS ]; then
            echo "Network:"
            if ip link show br0 &> /dev/null 2>&1; then
              echo "  [OK] Bridge br0 configured"
              ip -4 addr show br0 2>/dev/null | grep inet | head -1 | awk '{print "       " $2}'
            else
              echo "  [INFO] Bridge br0 not configured (single-machine mode)"
            fi
            echo ""
            
            # MicroVMs
            if systemctl list-units 'microvm@*' --no-pager 2>/dev/null | grep -q running; then
              echo "MicroVMs:"
              systemctl list-units 'microvm@*' --no-pager 2>/dev/null | grep running | sed 's/^/  /'
            fi
          fi
        '';
        
        # ════════════════════════════════════════════════════════════════════
        # Student Quickstart Script
        # ════════════════════════════════════════════════════════════════════
        studentQuickstart = pkgs.writeShellScriptBin "student-quickstart" ''
          cat << 'EOF'
═══════════════════════════════════════════════════════════════════════════
  SiegeWare Student Quick Start Guide
═══════════════════════════════════════════════════════════════════════════

STEP 1: List Available Labs
─────────────────────────────────────────────────────────────────────────────
  $ lab-ctl student list

  This shows all available lab exercises with difficulty levels and points.

STEP 2: Start Your First Lab
─────────────────────────────────────────────────────────────────────────────
  $ lab-ctl student start lab-01-recon

  Initializes Lab 01: Network Reconnaissance
  You'll see objectives and can begin working.

STEP 3: Interact with AI Agents
─────────────────────────────────────────────────────────────────────────────
  Red Team (Offensive):
  $ lab-ctl student chat red "scan 10.0.0.103 for open ports"

  Blue Team (Defensive):
  $ lab-ctl student chat blue "analyze the auth logs for anomalies"

STEP 4: Get Hints When Stuck
─────────────────────────────────────────────────────────────────────────────
  $ lab-ctl student hint

  Provides progressive hints without giving away the answer.

STEP 5: Verify Your Progress
─────────────────────────────────────────────────────────────────────────────
  $ lab-ctl student verify

  Checks if you've completed the lab objectives.

STEP 6: Check Your Status
─────────────────────────────────────────────────────────────────────────────
  $ lab-ctl student status

  Shows current lab, elapsed time, and objectives completed.

═══════════════════════════════════════════════════════════════════════════
  Lab Progression Path:
  1. lab-01-recon     (Foundational)  - Network Reconnaissance
  2. lab-02-privesc   (Intermediate)  - Privilege Escalation
  3. lab-03-defense   (Intermediate)  - Security Monitoring
  4. lab-04-advanced  (Advanced)      - Red Team Operations
  5. lab-05-competition (Advanced)    - AI Red vs Blue
═══════════════════════════════════════════════════════════════════════════

REMEMBER: This is an educational simulation. All techniques learned here
should only be applied to systems you own or have explicit permission to test.

EOF
        '';
        
        # ════════════════════════════════════════════════════════════════════
        # Instructor Setup Script
        # ════════════════════════════════════════════════════════════════════
        instructorSetup = pkgs.writeShellScriptBin "instructor-setup" ''
          set -euo pipefail
          
          echo "═══════════════════════════════════════════════════════════════════"
          echo "  SiegeWare Instructor Setup"
          echo "═══════════════════════════════════════════════════════════════════"
          echo ""
          
          LAB_ROOT="''${LAB_ROOT:-/var/lib/ai-agents-lab}"
          
          # Create directories with proper permissions
          echo "[STEP] Creating lab infrastructure..."
          sudo mkdir -p "$LAB_ROOT/sessions" "$LAB_ROOT/logs" "$LAB_ROOT/labs" "$LAB_ROOT/students"
          sudo chmod 755 "$LAB_ROOT"
          sudo chmod 1777 "$LAB_ROOT/sessions"  # Sticky bit for multi-user
          
          # Copy lab definitions
          echo "[STEP] Installing lab definitions..."
          sudo cp "${labController}/share/labs/labs.json" "$LAB_ROOT/labs/"
          
          echo ""
          echo "[OK] Instructor setup complete!"
          echo ""
          echo "Instructor Commands:"
          echo "  lab-ctl instructor dashboard    - Overview of all students"
          echo "  lab-ctl instructor monitor ID   - Watch specific student"
          echo "  lab-ctl instructor reset ID     - Reset student environment"
          echo "  lab-ctl instructor stats        - Lab statistics"
          echo "  lab-ctl instructor grade ID     - Generate grade report"
          echo ""
          echo "Recommended Grading Rubric:"
          echo "  40% - Objective completion (automated via verify)"
          echo "  30% - Documentation quality"
          echo "  20% - Ethical reasoning demonstrated"
          echo "  10% - Creativity and sophistication"
          echo ""
        '';
        
        # ════════════════════════════════════════════════════════════════════
        # Development Shell
        # ════════════════════════════════════════════════════════════════════
        devShell = pkgs.mkShell {
          name = "siegeware-dev";
          
          packages = with pkgs; [
            # Python
            python
            pythonPackages.requests
            pythonPackages.pytest
            pythonPackages.black
            pythonPackages.mypy
            pythonPackages.setuptools
            pythonPackages.wheel
            
            # Security tools
            nmap
            netcat-openbsd
            curl
            dnsutils
            whois
            
            # Development
            git
            gnumake
            gcc
            jq
            
            # Lisp (for HydraMesh native)
            sbcl
            
            # Our packages
            labController
            streamdb
          ] ++ pkgs.lib.optionals isLinux [
            # Linux-specific tools
            tcpdump
            wireshark-cli
            pkgs-unstable.ollama
          ];
          
          shellHook = ''
            echo ""
            echo "═══════════════════════════════════════════════════════════════════"
            echo "  SiegeWare Development Shell"
            echo "  Version: ${version} | Platform: ${system}"
            echo "═══════════════════════════════════════════════════════════════════"
            echo ""
            echo "Commands:"
            echo "  lab-ctl           - Lab controller CLI"
            echo "  nix run .#deploy  - Deploy lab infrastructure"
            echo "  nix run .#status  - Check system status"
            echo ""
            echo "Security Tools: nmap, netcat, curl, dig"
            echo "Python: agent_tools module available"
            echo ""
            
            export PYTHONPATH="${agentTools}/${python.sitePackages}:''${PYTHONPATH:-}"
            export LD_LIBRARY_PATH="${streamdb}/lib:''${LD_LIBRARY_PATH:-}"
            export DYLD_LIBRARY_PATH="${streamdb}/lib:''${DYLD_LIBRARY_PATH:-}"
            export LAB_ROOT="''${LAB_ROOT:-/var/lib/ai-agents-lab}"
            export HYDRAMESH_HOME="${hydrameshData}/hydramesh"
          '';
        };
        
      in {
        # ════════════════════════════════════════════════════════════════════
        # Packages
        # ════════════════════════════════════════════════════════════════════
        packages = {
          default = siegewareFull;
          
          inherit streamdb agentTools labController hydrameshData;
          inherit siegewareFull dockerImage;
          
          emacs-hydramesh = emacsHydramesh;
          
          # Alias for backwards compatibility
          lab-controller = labController;
          agent-tools = agentTools;
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Apps
        # ════════════════════════════════════════════════════════════════════
        apps = {
          default = {
            type = "app";
            program = "${labController}/bin/lab-ctl";
          };
          
          lab-ctl = {
            type = "app";
            program = "${labController}/bin/lab-ctl";
          };
          
          deploy = {
            type = "app";
            program = "${deployScript}/bin/siegeware-deploy";
          };
          
          status = {
            type = "app";
            program = "${statusScript}/bin/siegeware-status";
          };
          
          student-quickstart = {
            type = "app";
            program = "${studentQuickstart}/bin/student-quickstart";
          };
          
          instructor-setup = {
            type = "app";
            program = "${instructorSetup}/bin/instructor-setup";
          };
        };
        
        # ════════════════════════════════════════════════════════════════════
        # Development Shell
        # ════════════════════════════════════════════════════════════════════
        devShells.default = devShell;
        
        # ════════════════════════════════════════════════════════════════════
        # Checks (CI/CD)
        # ════════════════════════════════════════════════════════════════════
        checks = {
          streamdb = streamdb;
          agentTools = agentTools;
          labController = labController;
          
          # Python import test
          python-import = pkgs.runCommand "python-import-test" {
            buildInputs = [ python agentTools ];
          } ''
            ${python}/bin/python3 << 'PYTEST'
import sys
try:
    from agent_tools import registry
    from agent_tools.base import BaseTool, ToolResult
    print("✓ agent_tools imports successfully")
except ImportError as e:
    print(f"✗ Import failed: {e}")
    sys.exit(1)
PYTEST
            touch $out
          '';
        };
      }
    ) // {
      # ════════════════════════════════════════════════════════════════════════
      # NixOS Module
      # ════════════════════════════════════════════════════════════════════════
      nixosModules = {
        default = self.nixosModules.siegeware;
        
        siegeware = { config, lib, pkgs, ... }:
          let
            cfg = config.services.siegeware;
            labPkgs = self.packages.${pkgs.system};
          in {
            options.services.siegeware = {
              enable = lib.mkEnableOption "SiegeWare AI Agents Lab";
              
              dataDir = lib.mkOption {
                type = lib.types.path;
                default = "/var/lib/ai-agents-lab";
                description = "Lab data directory";
              };
              
              hostIP = lib.mkOption {
                type = lib.types.str;
                default = "10.0.0.1";
                description = "Host IP on lab network bridge";
              };
              
              enableOllama = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable Ollama LLM service";
              };
              
              ollamaPort = lib.mkOption {
                type = lib.types.port;
                default = 11434;
                description = "Ollama API port";
              };
              
              enableNvidia = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable NVIDIA CUDA acceleration";
              };
              
              enableAMD = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable AMD ROCm acceleration";
              };
              
              enableBridge = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Create br0 bridge for lab network";
              };
              
              sshAuthorizedKeys = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
                description = "SSH authorized keys for lab access";
              };
            };
            
            config = lib.mkIf cfg.enable {
              # System packages
              environment.systemPackages = [
                labPkgs.labController
                labPkgs.agentTools
                labPkgs.streamdb
                pkgs.nmap
                pkgs.netcat-openbsd
                pkgs.curl
                pkgs.dnsutils
                pkgs.jq
              ];
              
              # Environment
              environment.variables = {
                LAB_ROOT = cfg.dataDir;
                OLLAMA_URL = "http://localhost:${toString cfg.ollamaPort}";
                LD_LIBRARY_PATH = "${labPkgs.streamdb}/lib";
              };
              
              # Create directories
              systemd.tmpfiles.rules = [
                "d ${cfg.dataDir} 0755 root root -"
                "d ${cfg.dataDir}/sessions 0755 root root -"
                "d ${cfg.dataDir}/logs 0755 root root -"
                "d ${cfg.dataDir}/labs 0755 root root -"
              ];
              
              # Ollama service
              services.ollama = lib.mkIf cfg.enableOllama {
                enable = true;
                acceleration = 
                  if cfg.enableNvidia then "cuda"
                  else if cfg.enableAMD then "rocm"
                  else null;
              };
              
              # GPU support
              hardware.graphics = lib.mkIf (cfg.enableNvidia || cfg.enableAMD) {
                enable = true;
              };
              
              hardware.nvidia = lib.mkIf cfg.enableNvidia {
                modesetting.enable = true;
                open = false;
              };
              
              services.xserver.videoDrivers = lib.mkIf cfg.enableNvidia [ "nvidia" ];
              
              # Network bridge
              networking = lib.mkIf cfg.enableBridge {
                bridges.br0.interfaces = [];
                interfaces.br0 = {
                  useDHCP = false;
                  ipv4.addresses = [{
                    address = cfg.hostIP;
                    prefixLength = 24;
                  }];
                };
                
                firewall = {
                  allowedTCPPorts = [ 22 cfg.ollamaPort ];
                  allowedUDPPorts = [ 7777 7778 ];
                };
              };
              
              # SSH
              services.openssh = {
                enable = true;
                settings.PasswordAuthentication = false;
              };
              
              users.users.root.openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
              
              # Init service
              systemd.services.siegeware-init = {
                description = "SiegeWare Lab Initialization";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                script = ''
                  if [ ! -f ${cfg.dataDir}/labs/labs.json ]; then
                    cp ${labPkgs.labController}/share/labs/labs.json ${cfg.dataDir}/labs/
                    echo "SiegeWare lab definitions installed"
                  fi
                '';
              };
            };
          };
      };
      
      # ════════════════════════════════════════════════════════════════════════
      # Overlays
      # ════════════════════════════════════════════════════════════════════════
      overlays.default = final: prev: {
        siegeware = self.packages.${prev.system}.siegewareFull;
        streamdb = self.packages.${prev.system}.streamdb;
        agent-tools = self.packages.${prev.system}.agentTools;
        lab-controller = self.packages.${prev.system}.labController;
      };
      
      # ════════════════════════════════════════════════════════════════════════
      # Templates
      # ════════════════════════════════════════════════════════════════════════
      templates.default = {
        path = ./.;
        description = "SiegeWare AI Agents Lab - cybersecurity training platform";
      };
    };
}
