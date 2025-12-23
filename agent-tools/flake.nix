# agent-tools/flake.nix
# Complete tool management system for AI agents

{
  description = "AI Agent Tools Collection - Extensible toolkit for educational cybersecurity agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = nixpkgs.lib;
        python = pkgs.python3;

        # Tool source files
        toolSources = pkgs.runCommand "agent-tool-sources" {} ''
          mkdir -p $out/agent_tools/{tools,tests}
          
          # Copy base infrastructure
          cp ${./base.py} $out/agent_tools/base.py
          cp ${./registry.py} $out/agent_tools/registry.py
          cp ${./executor.py} $out/agent_tools/executor.py
          cp ${./sandbox.py} $out/agent_tools/sandbox.py
          cp ${./audit.py} $out/agent_tools/audit.py
          
          # Copy tools
          cp ${./tools}/*.py $out/agent_tools/tools/
          
          # Copy tests
          cp ${./tests}/*.py $out/agent_tools/tests/
          
          # Create __init__.py files
          cat > $out/agent_tools/__init__.py << 'EOF'
"""AI Agent Tools - Educational cybersecurity toolkit"""
__version__ = "1.0.0"

from agent_tools.registry import registry, ToolRegistry
from agent_tools.executor import ToolExecutor
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

__all__ = [
    "registry",
    "ToolRegistry", 
    "ToolExecutor",
    "BaseTool",
    "ToolDefinition",
    "ToolParameter"
]
EOF

          cat > $out/agent_tools/tools/__init__.py << 'EOF'
"""Tool implementations"""
EOF

          cat > $out/agent_tools/tests/__init__.py << 'EOF'
"""Test suite"""
EOF
        '';

        # Main agent-tools package
        agentToolsPackage = python.pkgs.buildPythonApplication {
          pname = "agent-tools";
          version = "1.0.0";
          
          src = toolSources;
          
          format = "other";

          propagatedBuildInputs = with python.pkgs; [
            requests
            pyyaml
            pytest
            pytest-mock
            pytest-cov
          ];

          buildInputs = with pkgs; [
            # Network tools
            nmap
            netcat
            curl
            dnsutils
            whois
            
            # SSH tools
            openssh
            sshpass
            
            # Analysis tools
            jq
            file
            
            # Exploitation tools (educational)
            metasploit
            
            # Blue team tools
            tcpdump
            wireshark-cli
          ];

          installPhase = ''
            mkdir -p $out/${python.sitePackages}
            cp -r agent_tools $out/${python.sitePackages}/
            
            # Create CLI entry points
            mkdir -p $out/bin
            
            # Tool test utility
            cat > $out/bin/agent-tool-test << 'EOF'
#!/usr/bin/env python3
import sys
import json
from agent_tools.registry import registry

if len(sys.argv) < 2:
    print("Usage: agent-tool-test <tool_name> [--param=value ...]")
    sys.exit(1)

tool_name = sys.argv[1]
tool = registry.get_tool(tool_name)

if not tool:
    print(f"Tool '{tool_name}' not found")
    print("Available tools:", list(registry._tools.keys()))
    sys.exit(1)

# Parse parameters
params = {}
for arg in sys.argv[2:]:
    if arg.startswith("--"):
        key, value = arg[2:].split("=", 1)
        params[key] = value

# Execute tool
print(f"Executing {tool_name} with parameters: {params}")
result = tool.execute(**params)
print(json.dumps(result, indent=2))
EOF
            chmod +x $out/bin/agent-tool-test
            
            # Tool list utility
            cat > $out/bin/agent-tool-list << 'EOF'
#!/usr/bin/env python3
from agent_tools.registry import registry

print("Available Tools:\n")
for tool_name, tool in registry._tools.items():
    definition = tool.get_definition()
    print(f"  {tool_name}")
    print(f"    Category: {definition.category}")
    print(f"    Risk: {definition.risk_level}")
    print(f"    Description: {definition.description}")
    print()
EOF
            chmod +x $out/bin/agent-tool-list
            
            # Tool documentation generator
            cat > $out/bin/agent-tool-docs << 'EOF'
#!/usr/bin/env python3
import sys
from agent_tools.registry import registry

tool_name = sys.argv[1] if len(sys.argv) > 1 else None

if not tool_name:
    print("Usage: agent-tool-docs <tool_name>")
    sys.exit(1)

tool = registry.get_tool(tool_name)
if not tool:
    print(f"Tool '{tool_name}' not found")
    sys.exit(1)

definition = tool.get_definition()
print(f"# {definition.name}\n")
print(f"**Category**: {definition.category}")
print(f"**Risk Level**: {definition.risk_level}\n")
print(f"## Description\n{definition.description}\n")
print("## Parameters\n")
for param in definition.parameters:
    req = "required" if param.required else "optional"
    print(f"- **{param.name}** ({param.type}, {req}): {param.description}")
    if param.enum:
        print(f"  - Allowed values: {', '.join(param.enum)}")
    if param.default is not None:
        print(f"  - Default: {param.default}")
EOF
            chmod +x $out/bin/agent-tool-docs
          '';

          checkPhase = ''
            export PYTHONPATH=$out/${python.sitePackages}:$PYTHONPATH
            pytest agent_tools/tests/ -v
          '';

          meta = with lib; {
            description = "Extensible toolkit for educational AI cybersecurity agents";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.linux;
          };
        };

        # Tool development environment
        toolDevShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pytest
            python3Packages.pytest-mock
            python3Packages.pytest-cov
            python3Packages.requests
            python3Packages.pyyaml
            python3Packages.black
            python3Packages.mypy
            python3Packages.pylint
            
            # System tools
            nmap
            netcat
            curl
            dnsutils
            whois
            openssh
            jq
          ];

          shellHook = ''
            export PYTHONPATH="$(pwd):$PYTHONPATH"
            
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║  Agent Tools Development Environment                       ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Development Commands:"
            echo "  pytest tests/                  → Run test suite"
            echo "  pytest --cov=agent_tools       → Run with coverage"
            echo "  black agent_tools/             → Format code"
            echo "  mypy agent_tools/              → Type checking"
            echo "  pylint agent_tools/            → Linting"
            echo ""
            echo "Tool Commands:"
            echo "  python -m agent_tools.tools.port_scanner  → Test tool directly"
            echo "  python -m agent_tools.registry             → List registered tools"
            echo ""
            echo "Quick Test:"
            echo "  python3 -c 'from agent_tools.registry import registry; print(list(registry._tools.keys()))'"
            echo ""
          '';
        };

        # Documentation package
        toolDocs = pkgs.runCommand "agent-tools-docs" {} ''
          mkdir -p $out/share/doc/agent-tools
          cp ${./README.md} $out/share/doc/agent-tools/README.md
          cp -r ${./docs}/* $out/share/doc/agent-tools/ || true
          cp -r ${./examples}/* $out/share/doc/agent-tools/examples/ || true
        '';

        # Integration tests
        integrationTest = pkgs.nixosTest {
          name = "agent-tools-integration";
          
          nodes.machine = { config, pkgs, ... }: {
            environment.systemPackages = [ agentToolsPackage ];
            
            # Set up test environment
            networking.firewall.enable = false;
            
            virtualisation.docker.enable = true;
            virtualisation.oci-containers.containers.test-target = {
              image = "nginx:alpine";
              ports = [ "80:80" ];
            };
          };

          testScript = ''
            machine.start()
            machine.wait_for_unit("docker.service")
            machine.wait_for_unit("docker-test-target.service")
            machine.wait_for_open_port(80)
            
            # Test tool listing
            output = machine.succeed("agent-tool-list")
            assert "port_scanner" in output
            
            # Test web request tool
            result = machine.succeed(
              "agent-tool-test web_request --url=http://localhost --method=GET"
            )
            assert '"success": true' in result
            
            # Test port scanner
            result = machine.succeed(
              "agent-tool-test port_scanner --target=127.0.0.1 --ports=80"
            )
            assert '"success": true' in result
            assert '80' in result
          '';
        };

      in {
        packages = {
          default = agentToolsPackage;
          agent-tools = agentToolsPackage;
          docs = toolDocs;
        };

        devShells = {
          default = toolDevShell;
        };

        checks = {
          integration = integrationTest;
        };

        apps = {
          # Test a specific tool
          test-tool = {
            type = "app";
            program = "${agentToolsPackage}/bin/agent-tool-test";
          };

          # List all tools
          list-tools = {
            type = "app";
            program = "${agentToolsPackage}/bin/agent-tool-list";
          };

          # Generate tool documentation
          docs = {
            type = "app";
            program = "${agentToolsPackage}/bin/agent-tool-docs";
          };

          # Quick port scan test
          test-port-scanner = {
            type = "app";
            program = toString (pkgs.writeShellScript "test-port-scanner" ''
              ${agentToolsPackage}/bin/agent-tool-test port_scanner \
                --target=10.0.0.103 \
                --ports=22,80,443
            '');
          };

          # Quick web request test
          test-web-request = {
            type = "app";
            program = toString (pkgs.writeShellScript "test-web-request" ''
              ${agentToolsPackage}/bin/agent-tool-test web_request \
                --url=http://10.0.0.103 \
                --method=GET
            '');
          };

          # Interactive tool builder wizard
          create-tool = {
            type = "app";
            program = toString (pkgs.writeShellScript "create-tool-wizard" ''
              #!/usr/bin/env bash
              set -e
              
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║  Agent Tool Creation Wizard                                ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              
              read -p "Tool name (snake_case): " tool_name
              read -p "Category (reconnaissance/exploitation/defense/utility): " category
              read -p "Risk level (safe/moderate/dangerous): " risk
              read -p "Short description: " description
              
              filename="agent_tools/tools/''${tool_name}.py"
              
              cat > "$filename" << EOF
#!/usr/bin/env python3
"""
$tool_name
$description
"""

from typing import Dict, Any
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class ''${tool_name^}Tool(BaseTool):
    """$description"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="$tool_name",
            description="$description",
            category="$category",
            risk_level="$risk",
            requires_approval=False,
            parameters=[
                # Add parameters here
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        # Add validation logic
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        # Add execution logic
        return {
            "success": True,
            "data": {},
            "metadata": {
                "tool_name": "$tool_name",
            },
            "warnings": [],
            "errors": []
        }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        return {
            "max_execution_time": 30,
            "max_memory_mb": 512,
            "allowed_network_ranges": ["10.0.0.0/24"],
        }
EOF
              
              echo ""
              echo "✓ Created $filename"
              echo ""
              echo "Next steps:"
              echo "  1. Edit $filename and implement your tool"
              echo "  2. Add tests in tests/test_''${tool_name}.py"
              echo "  3. Run: pytest tests/test_''${tool_name}.py"
              echo "  4. Test: agent-tool-test $tool_name"
              echo ""
            '');
          };
        };

        # Helper overlay for including in main flake
        overlays.default = final: prev: {
          agentTools = agentToolsPackage;
        };
      }
    );
}
