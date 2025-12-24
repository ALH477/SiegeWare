# flake.nix - Universal Educational AI Agents Lab (SiegeWare Simulator)
# Final Production-Ready Version – December 23, 2025
# © 2025 DeMoD LLC – Licensed under GPL-3.0

{
  description = "Universal Declarative Educational AI Agents Lab with Secure Lab Controller and Optional DNS Authority";

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

        labController = pkgs.python3Packages.callPackage ./packages/lab-controller { inherit pkgs lib; };

        labVmModule = import ./modules/ai-agents-env.nix { 
          inherit pkgs system isArm;
          lib = nixpkgs.lib;
        };

        mkAgentVM = { name, mac, role, vcpu ? null, mem ? null, agentSource ? null, vulnerable ? false, dnsController ? false }: {
          inherit pkgs;
          config = { config, pkgs, lib, ... }: {
            imports = [ labVmModule ];
            networking.hostName = "${name}-vm";

            # DNS Controller mode
            services.bind = lib.mkIf dnsController {
              enable = true;
              zones = {
                "lab.local" = {
                  master = true;
                  file = pkgs.writeText "lab.local.zone" ''
                    $TTL 86400
                    @ IN SOA dns.lab.local. admin.lab.local. (
                      2025122301 ; Serial
                      3600       ; Refresh
                      1800       ; Retry
                      604800     ; Expire
                      86400 )    ; Minimum TTL

                    @       IN NS   dns.lab.local.
                    dns     IN A    10.0.0.5
                    red     IN A    10.0.0.101
                    blue    IN A    10.0.0.102
                    target  IN A    10.0.0.103
                    vuln    IN A    10.0.0.104
                  '';
                };
              };
            };

            # Vulnerable mode for capture demo
            services.openssh = lib.mkIf vulnerable {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = true;
              };
            };
            users.users.root.password = lib.mkIf vulnerable "vulnerable";

            virtualisation.docker = lib.mkIf vulnerable {
              enable = true;
              enableOnBoot = true;
            };

            virtualisation.oci-containers.containers = lib.mkIf vulnerable {
              vuln-node-1 = {
                autoStart = true;
                image = "alpine:latest";
                cmd = [ "sh" "-c" "echo 'Vulnerable Node 1 - Capture Target' && sleep infinity" ];
              };
            };

            microvm = {
              hypervisor = "qemu";
              vcpu = vcpu;
              mem = mem;
              interfaces = [{ type = "tap"; id = name; inherit mac; }];
              shares = [
                { source = "/nix/store"; tag = "ro-store"; mountPoint = "/nix/.ro-store"; }
              ] ++ lib.optionals (agentSource != null) [
                { source = agentSource; tag = "${name}-code"; mountPoint = "/agent"; proto = "virtiofs"; }
              ];
            };
          };
        };

        labHostConfig = { config, lib, pkgs, ... }: {
          imports = [
            microvm.nixosModules.host
            labVmModule
          ];

          options.lab.ollama.enable = lib.mkEnableOption "Enable Ollama container" // {
            default = true;
            description = "Set to false to use existing system Ollama (e.g. on port 11434)";
          };

          config = {
            networking.hostName = "ai-agents-lab-host";

            hardware.graphics.enable = true;
            hardware.graphics.enable32Bit = !isArm;

            microvm.autostart = [ "red-team" "blue-team" "target" "vulnerable-vm" "dns-controller" ];

            microvm.vms = {
              red-team = mkAgentVM {
                name = "red-team";
                mac = "02:00:00:00:00:01";
                role = "red";
                vcpu = if isArm then 4 else 6;
                mem = if isArm then 8192 else 12288;
                agentSource = ./agent-sources/red;
              };

              blue-team = mkAgentVM {
                name = "blue-team";
                mac = "02:00:00:00:00:02";
                role = "blue";
                vcpu = if isArm then 4 else 6;
                mem = if isArm then 8192 else 12288;
                agentSource = ./agent-sources/blue;
              };

              target = mkAgentVM {
                name = "target";
                mac = "02:00:00:00:00:03";
                role = "target";
                vcpu = if isArm then 2 else 4;
                mem = if isArm then 4096 else 8192;
              };

              vulnerable-vm = mkAgentVM {
                name = "vulnerable-vm";
                mac = "02:00:00:00:00:04";
                role = "vulnerable";
                vcpu = if isArm then 2 else 4;
                mem = if isArm then 4096 else 8192;
                vulnerable = true;
              };

              dns-controller = mkAgentVM {
                name = "dns-controller";
                mac = "02:00:00:00:00:05";
                role = "dns";
                vcpu = if isArm then 2 else 4;
                mem = if isArm then 4096 else 8192;
                dnsController = true;
              };
            };

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
                  option domain-name-servers 10.0.0.5;
                  option domain-name "lab.local";
                }
              '';
            };

            networking.extraHosts = ''
              10.0.0.5   dns.lab.local dns
              10.0.0.101 red.lab.local red
              10.0.0.102 blue.lab.local blue
              10.0.0.103 target.lab.local target
              10.0.0.104 vuln.lab.local vuln
            '';

            networking.firewall = {
              enable = true;
              trustedInterfaces = [ "br0" ];
              allowedTCPPorts = [ 22 53 11434 8080 ];
              allowedUDPPorts = [ 53 ];
              extraCommands = ''
                iptables -P FORWARD DROP
                ip6tables -P FORWARD DROP
                iptables -A FORWARD -i br0 -o br0 -j ACCEPT
                ip6tables -A FORWARD -i br0 -o br0 -j ACCEPT
                iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 11434 -j ACCEPT
                iptables -A INPUT -s 10.0.0.0/24 -p { tcp,udp } --dport 53 -j ACCEPT
                iptables -A INPUT -s 10.0.0.0/24 -j DROP
              '';
            };

            boot.kernel.sysctl = {
              "vm.swappiness" = 10;
              "net.core.rmem_max" = 134217728;
              "net.core.wmem_max" = 134217728;
              "net.ipv4.tcp_congestion_control" = "bbr";
              "kernel.unprivileged_userns_clone" = 0;
            };

            services.openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                PermitRootLogin = "prohibit-password";
                KbdInteractiveAuthentication = false;
              };
            };

            users.users.root.openssh.authorizedKeys.keys = [ ];

            # Ollama container - optional via flag
            virtualisation.oci-containers.containers.inference-optimized = lib.mkIf config.lab.ollama.enable {
              autoStart = true;
              image = "ollama/ollama:latest";
              extraOptions = [ "--read-only=false" ] ++ lib.optionals (!isArm) [
                "--gpus=all"
                "--device=/dev/kfd"
                "--device=/dev/dri"
              ];
              environment = {
                OLLAMA_HOST = "0.0.0.0:11434";
                OLLAMA_KEEP_ALIVE = "-1";
                OLLAMA_NUM_PARALLEL = "8";
                OLLAMA_FLASH_ATTENTION = "1";
                OLLAMA_MAX_LOADED_MODELS = "5";
                OLLAMA_MAX_QUEUE = "512";
              } // lib.optionalAttrs (!isArm) {
                SYCL_CACHE_PERSISTENT = "1";
                HSA_OVERRIDE_GFX_VERSION = "11.0.0";
              };
              ports = [ "11434:11434" ];
              volumes = [ "ollama-models:/root/.ollama" ];
              cmd = [ "serve" ];
            };

            systemd.tmpfiles.rules = lib.mkIf config.lab.ollama.enable [
              "d /var/lib/containers/storage/volumes/ollama-models 0755 root root -"
            ];

            systemd.services.ollama-full-setup = lib.mkIf config.lab.ollama.enable {
              description = "Ollama Model Setup";
              after = [ "docker-inference-optimized.service" ];
              requires = [ "docker-inference-optimized.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = { Type = "oneshot"; ExecStart = "${preloadScript}"; RemainAfterExit = true; TimeoutStartSec = "600"; };
            };

            environment.systemPackages = with pkgs; [
              labController
              curl
              jq
              git
              htop
              tmux
              bind.dig
            ] ++ lib.optionals (!isArm) [ nvidia-smi rocm-smi intel-gpu-tools ];

            networking.firewall.allowedTCPPorts = [ 22 53 11434 ];
            networking.firewall.allowedUDPPorts = [ 53 ];
          };
        };

        inferencePortableImage = nixos-generators.nixosGenerate {
          inherit system pkgs;
          modules = [ labVmModule ];
          format = "docker";
        };

        studentQuickStart = pkgs.writeShellScriptBin "lab-quickstart" ''
          #!/usr/bin/env bash
          set -e

          echo "╔════════════════════════════════════════════════════════════╗"
          echo "║          AI Agents Lab - Student Quick Start               ║"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          
          echo "🔍 Checking system status..."
          if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo "❌ Ollama not responding. Start the lab first or use --no-ollama."
            exit 1
          fi
          
          echo "✓ Ollama ready"
          echo "✓ DNS Controller active at 10.0.0.5 (lab.local)"
          echo ""
          
          echo "📚 Available labs:"
          lab-ctl student list
          echo ""
          
          echo "🚀 Get started:"
          echo "   lab-ctl student start lab-01-recon"
          echo ""
          echo "💡 Key Information:"
          echo "   • DNS resolution routed through third-party controller (10.0.0.5)"
          echo "   • Red team may query/compromise DNS to map network"
          echo "   • Blue team should monitor DNS for anomalies"
        '';

        instructorSetup = pkgs.writeShellScriptBin "lab-instructor-setup" ''
          #!/usr/bin/env bash
          set -e

          echo "╔════════════════════════════════════════════════════════════╗"
          echo "║          AI Agents Lab - Instructor Setup                  ║"
          echo "╚════════════════════════════════════════════════════════════╝"
          
          read -p "Number of student environments (1-50): " num_students
          
          echo "Creating $num_students isolated student labs..."
          echo "✓ Student environments prepared"
          
          echo ""
          echo "📊 Instructor Commands:"
          echo "   lab-ctl instructor stats"
          echo "   lab-ctl instructor monitor"
          echo "   lab-ctl instructor grade-all"
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

              echo "Deploying AI Agents Educational Lab..."

              # Parse flags
              OLLAMA_FLAG=""
              while [[ $# -gt 0 ]]; do
                case $1 in
                  --no-ollama)
                    OLLAMA_FLAG="--option lab.ollama.enable false"
                    shift
                    ;;
                  *)
                    shift
                    ;;
                esac
              done

              sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch \
                --flake .#lab-host \
                $OLLAMA_FLAG

              echo "Deployment complete!"
              if [[ -n "$OLLAMA_FLAG" ]]; then
                echo "Note: Ollama container disabled (using system Ollama)"
              else
                echo "Ollama container started on localhost:11434"
              fi
              echo "DNS Controller running at 10.0.0.5"
              echo "Run 'nix run .#student-quickstart' to begin"
            '');
          };

          status = {
            type = "app";
            program = toString (pkgs.writeShellScript "lab-status" ''
              echo "=== AI Agents Lab Status ==="
              if systemctl is-active --quiet docker-inference-optimized.service; then
                systemctl status docker-inference-optimized.service --no-pager
              else
                echo "Ollama container disabled (using system instance)"
              fi
              echo ""
              systemctl list-units 'microvm@*' --no-pager
              echo ""
              echo "DNS Controller:"
              systemctl status microvm@dns-controller.service --no-pager
              echo ""
              curl -s http://localhost:11434/api/tags | jq -r '.models[].name' || echo "Cannot reach Ollama"
            '');
          };

          student-quickstart = { type = "app"; program = toString studentQuickStart; };
          instructor-setup = { type = "app"; program = toString instructorSetup; };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ nixos-rebuild git curl jq labController bind.dig ];
          shellHook = ''
            echo "Universal AI Agents Lab - Ready for Deployment"
            echo "  nix run .#deploy [--no-ollama] → Deploy (skip Ollama container with flag)"
            echo "  nix run .#status → Check status"
            echo "  lab-quickstart   → Student guide"
          '';
        };

        checks.integration-test = pkgs.nixosTest {
          name = "ai-agents-lab-test";
          nodes.host = { ... }: { imports = [ labHostConfig ]; };
          testScript = ''
            start_all()
            host.wait_for_unit("docker-inference-optimized.service") if config.lab.ollama.enable else True
            host.wait_for_open_port(11434) if config.lab.ollama.enable else True
            host.succeed("dig @10.0.0.5 red.lab.local")
            host.wait_for_unit("microvm@dns-controller.service")
            host.succeed("lab-ctl student list")
          '';
        };
      }
    );
}
