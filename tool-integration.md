# Integration Guide: Agent Tools with Main Lab

## Overview

This guide shows how to integrate the agent-tools flake with the main AI Agents Lab, enabling AI agents to use the tools for educational cybersecurity exercises.

## Directory Structure

```
ai-agents-lab/
├── flake.nix                      # Main lab flake
├── modules/
│   └── ai-agents-env.nix         # VM configuration
├── packages/
│   └── lab-controller/           # Student/instructor CLI
├── agent-tools/                  # NEW: Tools flake
│   ├── flake.nix                # Tools management
│   ├── agent_tools/
│   │   ├── base.py              # Base tool class
│   │   ├── registry.py          # Tool registry
│   │   ├── executor.py          # Execution engine
│   │   ├── sandbox.py           # Sandboxing
│   │   ├── audit.py             # Audit logging
│   │   └── tools/               # Individual tools
│   │       ├── port_scanner.py
│   │       ├── web_request.py
│   │       ├── dns_lookup.py
│   │       ├── service_detector.py
│   │       └── log_analyzer.py
│   ├── tests/                   # Test suite
│   ├── docs/                    # Documentation
│   └── examples/                # Usage examples
└── agent-sources/               # Agent implementation
    ├── red/
    │   ├── agent.py             # Red team agent
    │   └── config.py
    └── blue/
        ├── agent.py             # Blue team agent
        └── config.py
```

## Step 1: Update Main Flake

Update `flake.nix` to include agent-tools:

```nix
{
  description = "Universal Educational AI Agents Lab with Tools";

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
    
    # NEW: Agent tools input
    agent-tools = {
      url = "path:./agent-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, microvm, nixos-generators, agent-tools, ... }:
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

        # Get agent tools package
        agentTools = agent-tools.packages.${system}.default;

        # ... rest of configuration
        
        labVmModule = import ./modules/ai-agents-env.nix { 
          inherit pkgs lib system isArm agentTools;  # Pass tools
        };
        
      # ... rest of flake
    });
}
```

## Step 2: Update VM Module

Update `modules/ai-agents-env.nix` to install tools:

```nix
{ config, pkgs, lib, system, isArm, agentTools }:

{
  # ... existing configuration ...

  # Install agent tools in all VMs
  environment.systemPackages = with pkgs; [
    agentTools
    curl
    ollama
    docker
    git
    htop
    jq
  ];

  # Configure tool paths
  environment.variables = {
    AGENT_TOOLS_PATH = "${agentTools}/lib/python3.11/site-packages/agent_tools";
    PYTHONPATH = "${agentTools}/lib/python3.11/site-packages";
  };

  # Create tool audit directory
  systemd.tmpfiles.rules = [
    "d /var/lib/ai-agents-lab/audit 0755 root root -"
  ];

  # ... rest of configuration ...
}
```

## Step 3: Create Agent Implementation

Create `agent-sources/red/agent.py`:

```python
#!/usr/bin/env python3
"""
Red Team Agent Implementation
Uses Ollama and agent-tools to perform offensive security tasks
"""

import requests
import json
from typing import Dict, List, Any
from agent_tools.registry import registry
from agent_tools.executor import ToolExecutor

class RedTeamAgent:
    """Offensive security AI agent"""
    
    def __init__(self, agent_id: str = "red-team-01", lab_id: str = "lab-01"):
        self.agent_id = agent_id
        self.lab_id = lab_id
        self.ollama_url = "http://10.0.0.1:11434"  # Host Ollama server
        self.model = "red-qwen-agent"
        self.executor = ToolExecutor(agent_id, lab_id)
        self.conversation_history = []
        
    def get_available_tools(self) -> List[Dict]:
        """Get tool definitions for the model"""
        # Get red team tools only
        return registry.get_definitions_for_agent("red", lab_level=1)
    
    def chat(self, message: str) -> str:
        """Send message to agent and get response"""
        
        # Add message to history
        self.conversation_history.append({
            "role": "user",
            "content": message
        })
        
        # Call Ollama with tool definitions
        response = requests.post(
            f"{self.ollama_url}/api/chat",
            json={
                "model": self.model,
                "messages": self.conversation_history,
                "tools": self.get_available_tools(),
                "stream": False
            }
        )
        
        response_data = response.json()
        assistant_message = response_data["message"]
        
        # Check if agent wants to use a tool
        if "tool_calls" in assistant_message:
            tool_results = []
            
            for tool_call in assistant_message["tool_calls"]:
                tool_name = tool_call["function"]["name"]
                tool_args = tool_call["function"]["arguments"]
                
                print(f"[Agent] Using tool: {tool_name}")
                print(f"[Agent] Parameters: {json.dumps(tool_args, indent=2)}")
                
                # Execute tool
                result = self.executor.execute(tool_name, **tool_args)
                tool_results.append(result)
                
                # Add tool result to conversation
                self.conversation_history.append({
                    "role": "tool",
                    "content": json.dumps(result)
                })
            
            # Get agent's interpretation of results
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": self.conversation_history,
                    "stream": False
                }
            )
            
            assistant_message = response.json()["message"]
        
        # Add assistant response to history
        self.conversation_history.append(assistant_message)
        
        return assistant_message["content"]
    
    def run_mission(self, objective: str):
        """Execute a mission with a specific objective"""
        print(f"[Mission] Objective: {objective}")
        print()
        
        response = self.chat(objective)
        print(f"[Agent] {response}")
        print()
        
        return response


def main():
    """Example usage"""
    agent = RedTeamAgent()
    
    # Example mission: Reconnaissance
    agent.run_mission(
        "Scan the target at 10.0.0.103 for open ports and identify running services. "
        "Provide a summary of your findings."
    )


if __name__ == "__main__":
    main()
```

## Step 4: Test the Integration

### Build everything:

```bash
cd ai-agents-lab
nix flake update
nix build .#agent-tools
nix build .#lab-host
```

### Deploy the lab:

```bash
nix run .#deploy
```

### Test tools directly:

```bash
# List available tools
agent-tool-list

# Test port scanner
agent-tool-test port_scanner --target=10.0.0.103 --ports=22,80,443

# Test web request
agent-tool-test web_request --url=http://10.0.0.103 --method=GET

# Generate tool documentation
agent-tool-docs port_scanner
```

### Run the agent:

```bash
# SSH into red team VM
ssh root@10.0.0.101

# Run agent
cd /agent
python3 agent.py
```

## Step 5: Verify Tool Execution

Check audit logs:

```bash
# View tool execution logs
tail -f /var/lib/ai-agents-lab/logs/agent_interactions_*.log

# View audit logs
tail -f /var/lib/ai-agents-lab/audit/audit.log

# Check specific agent's actions
cat /var/lib/ai-agents-lab/audit/red-team-01/lab-01.jsonl | jq
```

## Step 6: Student Workflow

Update `lab-ctl` to show available tools:

```bash
lab-ctl student start lab-01-recon

# Student can now:
# 1. See which tools are available for this lab
lab-ctl student tools

# 2. Get help on a specific tool
lab-ctl student tool-help port_scanner

# 3. Chat with agent that uses tools
lab-ctl student chat red "scan the target for web services"

# 4. View agent's tool usage
lab-ctl student activity
```

## Advanced: Custom Tool Integration

### Creating a Lab-Specific Tool

1. **Create the tool:**

```bash
cd agent-tools
nix run .#create-tool
# Follow wizard to create tool skeleton
```

2. **Implement the tool:**

```python
# agent-tools/tools/custom_exploit.py
class CustomExploitTool(BaseTool):
    def get_definition(self):
        return ToolDefinition(
            name="custom_exploit",
            description="Lab-specific exploit for educational purposes",
            category="exploitation",
            risk_level="dangerous",
            requires_approval=True,
            parameters=[...]
        )
    
    def execute(self, **kwargs):
        # Implementation
        pass
```

3. **Test the tool:**

```bash
pytest agent-tools/tests/test_custom_exploit.py
agent-tool-test custom_exploit --param=value
```

4. **Rebuild:**

```bash
nix build .#agent-tools
nix run .#deploy
```

## Monitoring and Debugging

### Enable verbose logging:

```nix
# In modules/ai-agents-env.nix
environment.variables = {
  AGENT_TOOLS_DEBUG = "1";
  AGENT_TOOLS_LOG_LEVEL = "DEBUG";
};
```

### Monitor tool execution in real-time:

```bash
# Terminal 1: Watch audit logs
watch -n 1 'tail -20 /var/lib/ai-agents-lab/audit/audit.log'

# Terminal 2: Monitor network activity
sudo tcpdump -i br0 -n

# Terminal 3: Run agent
python3 /agent/agent.py
```

### Debug tool failures:

```bash
# Check tool registry
python3 -c "from agent_tools.registry import registry; print(list(registry._tools.keys()))"

# Test tool directly
python3 -c "from agent_tools.tools.port_scanner import PortScannerTool; tool = PortScannerTool(); print(tool.execute(target='10.0.0.103'))"

# Check sandbox limits
python3 -c "from agent_tools.sandbox import Sandbox; print(Sandbox().get_limits())"
```

## Performance Optimization

### Caching tool results:

```python
# In agent.py
from functools import lru_cache

class RedTeamAgent:
    @lru_cache(maxsize=100)
    def cached_tool_call(self, tool_name: str, **kwargs):
        return self.executor.execute(tool_name, **kwargs)
```

### Parallel tool execution:

```python
from concurrent.futures import ThreadPoolExecutor

def execute_multiple_tools(self, tool_calls: List[Dict]):
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [
            executor.submit(self.executor.execute, call["name"], **call["args"])
            for call in tool_calls
        ]
        return [f.result() for f in futures]
```

## Security Checklist

Before deploying to students:

- [ ] All tools have proper input validation
- [ ] Sandbox limits are enforced
- [ ] Audit logging is enabled
- [ ] Rate limits are configured
- [ ] Network access is restricted to lab range
- [ ] Dangerous tools require approval
- [ ] Tool documentation includes security notes
- [ ] Tests cover security scenarios

## Troubleshooting

### Tools not found by agent:

```bash
# Check if tools are installed
ls -la /nix/store/*agent-tools*/lib/python3.11/site-packages/agent_tools/tools/

# Verify PYTHONPATH
echo $PYTHONPATH

# Test import
python3 -c "from agent_tools.tools.port_scanner import PortScannerTool"
```

### Tool execution fails:

```bash
# Check permissions
ls -la /var/lib/ai-agents-lab/

# Verify network connectivity
ping -c 1 10.0.0.1

# Test tool manually
agent-tool-test port_scanner --target=10.0.0.103
```

### Agent can't use tools:

```bash
# Verify Ollama has tool definitions
curl -s http://10.0.0.1:11434/api/show -d '{"name": "red-qwen-agent"}' | jq

# Check agent logs
tail -f /var/lib/ai-agents-lab/logs/red-team-01.log

# Test tool calling directly
python3 test_tool_calling.py
```

## Next Steps

1. **Create more tools** for your specific labs
2. **Implement blue team tools** for defensive exercises  
3. **Add tool chains** for complex multi-step operations
4. **Build web UI** for tool visualization
5. **Create tool marketplace** for sharing community tools

## Resources

- [Full Tool Development Guide](./agent-tools/README.md)
- [Example Tools](./agent-tools/agent_tools/tools/)
- [Test Suite](./agent-tools/tests/)
- [API Documentation](./agent-tools/docs/api.md)

---

**Ready to go!** Your agents now have a full toolkit for educational cybersecurity exercises.
