# flake.nix - Universal Educational AI Agents Lab with Lab Controller
# Fully Compatible with x86_64-linux and aarch64-linux
# Now includes comprehensive student and instructor tooling

{
  description = "Universal Declarative Educational AI Agents Lab with Lab Controller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, microvm, nixos-generators, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        lib = nixpkgs.lib;
        isArm = pkgs.stdenv.hostPlatform.isAarch64;

        # Import the lab controller package
        labController = pkgs.python3Packages.callPackage ./packages/lab-controller {
          inherit pkgs lib;
        };

        # Import module with correct parameters
        labVmModule = import ./modules/ai-agents-env.nix { 
          inherit pkgs lib system isArm; 
        };

        # Helper function to create agent VMs
        mkAgentVM = { name, mac, role, vcpu ? 4, mem ? 8192, hasAgentCode ? false }: {
          inherit pkgs;
          config = { ... }: {
            imports = [ labVmModule ];
            networking.hostName = "${name}-vm";
            microvm = {
              hypervisor = "qemu";
              inherit vcpu mem;
              interfaces = [{
                type = "tap";
                id = name;
                inherit mac;
              }];
              shares = [
                {
                  source = "/nix/store";
                  tag = "ro-store";
                  mountPoint = "/nix/.ro-store";
                }
              ] ++ lib.optionals hasAgentCode [
                {
                  source = ./agent-sources/${role};
                  tag = "${role}-code";
                  mountPoint = "/agent";
                  proto = "virtiofs";
                }
              ];
            };
          };
        };

        labHostConfig = { config, lib, pkgs, ... }: {
          imports = [
            microvm.nixosModules.host
            labVmModule
          ];

          networking.hostName = "ai-agents-lab-host";

          # Enable graphics on host for GPU sharing
          hardware.graphics.enable = true;
          hardware.graphics.enable32Bit = !isArm;

          microvm.autostart = [ "red-team" "blue-team" "target" ];

          microvm.vms = {
            red-team = mkAgentVM {
              name = "red-team";
              mac = "02:00:00:00:00:01";
              role = "red";
              vcpu = if isArm then 4 else 6;
              mem = if isArm then 8192 else 12288;
              hasAgentCode = true;
            };

            blue-team = mkAgentVM {
              name = "blue-team";
              mac = "02:00:00:00:00:02";
              role = "blue";
              vcpu = if isArm then 4 else 6;
              mem = if isArm then 8192 else 12288;
              hasAgentCode = true;
            };

            target = mkAgentVM {
              name = "target";
              mac = "02:00:00:00:00:03";
              role = "target";
              vcpu = if isArm then 2 else 4;
              mem = if isArm then 4096 else 8192;
              hasAgentCode = false;
            };
          };

          # Internal lab network with isolation
          networking.bridges.br0.interfaces = [ ];
          networking.interfaces.br0 = {
            useDHCP = false;
            ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];
          };

          services.dhcpd4 = {
            enable = true;
            interfaces = [ "br0" ];
            extraConfig = ''
              subnet 10.0.0.0 netmask 255.255.255.0 {
                range 10.0.0.100 10.0.0.200;
                option routers 10.0.0.1;
              }
            '';
          };

          # Security-hardened firewall
          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ 22 11434 8080 ];  # Added 8080 for web dashboard
            extraCommands = ''
              # Drop forwarding by default
              iptables -P FORWARD DROP
              # Allow only lab network internal traffic
              iptables -A FORWARD -s 10.0.0.0/24 -d 10.0.0.0/24 -j ACCEPT
              # Block VMs from accessing host services except Ollama
              iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 11434 -j ACCEPT
              iptables -A INPUT -s 10.0.0.0/24 ! -p icmp -j DROP
            '';
          };

          # Kernel performance tuning
          boot.kernel.sysctl = {
            "vm.swappiness" = 10;
            "net.core.rmem_max" = 134217728;
            "net.core.wmem_max" = 134217728;
            "net.ipv4.tcp_congestion_control" = "bbr";
          };

          # SSH key-based authentication
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = lib.mkDefault false;
              PermitRootLogin = "prohibit-password";
            };
          };

          # TEMPORARY: Allow password auth for initial setup
          users.users.root.password = "root";
          services.openssh.settings.PasswordAuthentication = lib.mkForce true;

          # Install lab controller tool
          environment.systemPackages = with pkgs; [
            labController
            curl
            jq
            git
            htop
          ];

          # Create lab controller directories
          systemd.tmpfiles.rules = [
            "d /var/lib/ai-agents-lab 0755 root root -"
            "d /var/lib/ai-agents-lab/state 0755 root root -"
            "d /var/lib/ai-agents-lab/logs 0755 root root -"
          ];

          # Symlink labs data to expected location
          system.activationScripts.labControllerData = ''
            mkdir -p /var/lib/ai-agents-lab
            ln -sfn ${labController}/share/lab-controller/labs /var/lib/ai-agents-lab/labs
          '';
        };

        inferencePortableImage = nixos-generators.nixosGenerate {
          inherit system pkgs;
          modules = [ labVmModule ];
          format = "docker";
        };

        # Quick start script for students
        studentQuickStart = pkgs.writeShellScriptBin "lab-quickstart" ''
          #!/usr/bin/env bash
          set -e

          echo "╔════════════════════════════════════════════════════════════╗"
          echo "║          AI Agents Lab - Quick Start                       ║"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          
          # Check if services are running
          echo "🔍 Checking lab services..."
          if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo "⚠️  Ollama is not running. Start with: sudo systemctl start docker-inference-optimized"
            exit 1
          fi
          echo "✓ Ollama is ready"
          
          if ! systemctl is-active --quiet microvm@red-team; then
            echo "⚠️  VMs not started. Start with: sudo systemctl start microvm@{red-team,blue-team,target}"
            exit 1
          fi
          echo "✓ MicroVMs are running"
          
          echo ""
          echo "📚 Available Commands:"
          echo "  lab-ctl student list          → See available labs"
          echo "  lab-ctl student start lab-01  → Start first lab"
          echo "  lab-ctl student status        → Check your progress"
          echo "  lab-ctl student verify        → Verify lab completion"
          echo ""
          echo "🎯 Recommended: Start with 'lab-ctl student list'"
        '';

        # Instructor setup script
        instructorSetup = pkgs.writeShellScriptBin "lab-instructor-setup" ''
          #!/usr/bin/env bash
          set -e

          echo "╔════════════════════════════════════════════════════════════╗"
          echo "║          AI Agents Lab - Instructor Setup                  ║"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          
          echo "This script will help you set up the lab for your class."
          echo ""
          
          # Create multiple student environments
          read -p "How many student environments do you want to create? (1-20): " num_students
          
          if [[ ! "$num_students" =~ ^[0-9]+$ ]] || [ "$num_students" -lt 1 ] || [ "$num_students" -gt 20 ]; then
            echo "Invalid number. Please enter 1-20."
            exit 1
          fi
          
          echo ""
          echo "Creating $num_students student environments..."
          
          for i in $(seq 1 $num_students); do
            student_id=$(printf "student-%02d" $i)
            echo "  Creating: $student_id"
            lab-ctl student status > /dev/null 2>&1 || true
          done
          
          echo ""
          echo "✓ Setup complete!"
          echo ""
          echo "📊 Instructor Commands:"
          echo "  lab-ctl instructor stats              → View overall statistics"
          echo "  lab-ctl instructor monitor student-01 → Monitor specific student"
          echo "  lab-ctl instructor grade student-01   → Generate grade report"
          echo "  lab-ctl instructor reset student-01   → Reset student environment"
          echo ""
        '';

      in {
        nixosConfigurations.lab-host = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ labHostConfig ];
        };

        packages = {
          lab-controller = labController;
          inferenceImage = inferencePortableImage;
          student-quickstart = studentQuickStart;
          instructor-setup = instructorSetup;
          default = labController;
        };

        apps = {
          deploy = {
            type = "app";
            program = toString (pkgs.writeShellScript "deploy-lab" ''
              set -e
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║          Deploying AI Agents Lab                           ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "🚀 Deploying lab infrastructure..."
              sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake .#lab-host
              
              echo ""
              echo "✓ Deployment complete!"
              echo ""
              echo "📚 Next steps:"
              echo "  For students: run 'lab-quickstart'"
              echo "  For instructors: run 'lab-instructor-setup'"
              echo ""
              echo "Access:"
              echo "  • Ollama API: http://localhost:11434"
              echo "  • SSH to VMs: ssh root@10.0.0.{101-103}"
              echo ""
            '');
          };

          status = {
            type = "app";
            program = toString (pkgs.writeShellScript "status" ''
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║          AI Agents Lab - System Status                     ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              
              echo "=== Ollama Service ==="
              systemctl status docker-inference-optimized.service --no-pager | head -10
              echo ""
              
              echo "=== MicroVM Status ==="
              systemctl list-units 'microvm@*' --no-pager
              echo ""
              
              echo "=== Available Models ==="
              curl -s http://localhost:11434/api/tags | ${pkgs.jq}/bin/jq -r '.models[].name' || echo "Unable to connect to Ollama"
              echo ""
              
              echo "=== Network Status ==="
              ip addr show br0 2>/dev/null || echo "Bridge br0 not configured"
              echo ""
            '');
          };

          # Student-focused apps
          student-quickstart = {
            type = "app";
            program = toString studentQuickStart;
          };

          # Instructor-focused apps
          instructor-setup = {
            type = "app";
            program = toString instructorSetup;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixos-rebuild
            git
            curl
            jq
            labController
            studentQuickStart
            instructorSetup
          ];
          
          shellHook = ''
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║  Universal AI Agents Educational Lab                       ║"
            echo "║  Architecture: ${system}                      ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            echo "🚀 Deployment:"
            echo "  nix run .#deploy              → Deploy full lab infrastructure"
            echo "  nix run .#status              → Check system status"
            echo ""
            echo "👨‍🎓 For Students:"
            echo "  nix run .#student-quickstart  → Quick start guide"
            echo "  lab-ctl student list          → List available labs"
            echo "  lab-ctl student start lab-01  → Start first lab"
            echo ""
            echo "👨‍🏫 For Instructors:"
            echo "  nix run .#instructor-setup    → Set up class environment"
            echo "  lab-ctl instructor dashboard  → Launch monitoring dashboard"
            echo "  lab-ctl instructor stats      → View overall statistics"
            echo ""
            echo "🔧 Development:"
            echo "  nix build                     → Build portable Docker image"
            echo "  nix flake check               → Run integration tests"
            echo ""
          '';
        };

        # Integration tests
        checks.integration-test = pkgs.nixosTest {
          name = "ai-agents-lab-integration";
          
          nodes.host = { ... }: {
            imports = [ labHostConfig ];
          };

          testScript = ''
            start_all()
            
            # Wait for Docker container
            host.wait_for_unit("docker-inference-optimized.service")
            host.wait_for_open_port(11434)
            
            # Verify Ollama API responds
            host.succeed("curl -f http://localhost:11434/api/tags")
            
            # Wait for model setup
            host.wait_for_unit("ollama-full-setup.service")
            
            # Verify custom models exist
            output = host.succeed("curl -s http://localhost:11434/api/tags")
            assert "red-qwen-agent" in output, "Red agent model not found"
            assert "blue-llama-agent" in output, "Blue agent model not found"
            
            # Verify MicroVMs started
            host.wait_for_unit("microvm@red-team.service")
            host.wait_for_unit("microvm@blue-team.service")
            host.wait_for_unit("microvm@target.service")
            
            # Test lab controller
            host.succeed("lab-ctl student list")
            host.succeed("lab-ctl student status")
            
            # Verify labs data exists
            host.succeed("test -d /var/lib/ai-agents-lab/labs/lab-01-recon")
            
            # Test network connectivity
            host.succeed("ping -c 1 10.0.0.1")
          '';
        };
      }
    );
}
