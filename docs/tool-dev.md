# AI Agent Tools Development Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Tool Development Fundamentals](#tool-development-fundamentals)
4. [Creating Your First Tool](#creating-your-first-tool)
5. [Tool Registry System](#tool-registry-system)
6. [Advanced Tool Patterns](#advanced-tool-patterns)
7. [Security Considerations](#security-considerations)
8. [Testing and Validation](#testing-and-validation)
9. [Deployment with Nix](#deployment-with-nix)
10. [Best Practices](#best-practices)
11. [Example Tools](#example-tools)
12. [Troubleshooting](#troubleshooting)

---

## Introduction

### What Are Agent Tools?

Agent tools are callable functions that AI agents can use to interact with systems, execute commands, and gather information. They bridge the gap between natural language AI reasoning and concrete system actions.

**Example Flow:**
```
Student: "Scan the target for open ports"
    ↓
Red Agent: "I'll use the port_scanner tool with target 10.0.0.103"
    ↓
Tool Execution: nmap -sT 10.0.0.103
    ↓
Result: Ports 22, 80, 443 are open
    ↓
Red Agent: "I found three open ports: SSH (22), HTTP (80), and HTTPS (443)"
```

### Why Build Custom Tools?

1. **Educational Control**: Tailor capabilities to learning objectives
2. **Safety Constraints**: Limit dangerous operations in student environments
3. **Instrumentation**: Log all actions for assessment and debugging
4. **Progressive Disclosure**: Unlock advanced tools as students progress
5. **Custom Scenarios**: Build tools for specific lab exercises

### Tool Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| **Reconnaissance** | Information gathering | Port scanners, DNS enumeration, service fingerprinting |
| **Exploitation** | Vulnerability testing | Exploit runners, payload generators, brute forcers |
| **Post-Exploitation** | Maintain access | Persistence mechanisms, privilege escalation helpers |
| **Defense** | Blue team operations | Log analyzers, IDS alert parsers, baseline comparators |
| **Utility** | Support functions | File operations, network connectivity tests, data parsers |

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Student Interface                         │
│                     (lab-ctl student chat)                       │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Ollama API Server                           │
│                      (localhost:11434)                           │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      AI Agent (LLM)                              │
│                  (red-qwen-agent / blue-llama-agent)            │
│                                                                  │
│  System Prompt: "You have access to these tools: ..."           │
│  Tool Definitions: JSON schemas for each tool                    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Tool Execution Layer                        │
│                   (agent-tools/executor.py)                      │
│                                                                  │
│  • Validates tool calls                                          │
│  • Enforces security policies                                    │
│  • Logs all actions                                              │
│  • Executes in sandboxed environment                             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Individual Tools                            │
│                   (agent-tools/tools/*.py)                       │
│                                                                  │
│  port_scanner.py  │  exploit_runner.py  │  log_analyzer.py     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Target Environment                          │
│                   (MicroVMs, Network, Files)                     │
└─────────────────────────────────────────────────────────────────┘
```

### Tool Lifecycle

1. **Definition**: Tool is defined with schema (inputs, outputs, description)
2. **Registration**: Tool is registered in the tool registry
3. **Discovery**: Agent receives list of available tools during initialization
4. **Invocation**: Agent decides to use a tool based on context
5. **Validation**: Tool executor validates parameters and permissions
6. **Execution**: Tool code runs with proper sandboxing
7. **Result**: Output is returned to agent for interpretation
8. **Logging**: All actions are logged for auditing

---

## Tool Development Fundamentals

### Tool Structure

Every tool must implement this interface:

```python
from typing import Dict, List, Any, Optional
from dataclasses import dataclass

@dataclass
class ToolParameter:
    """Definition of a tool parameter"""
    name: str
    type: str  # "string", "number", "boolean", "array", "object"
    description: str
    required: bool = True
    enum: Optional[List[str]] = None
    default: Any = None

@dataclass
class ToolDefinition:
    """Complete tool definition"""
    name: str
    description: str
    parameters: List[ToolParameter]
    category: str
    risk_level: str  # "safe", "moderate", "dangerous"
    requires_approval: bool = False
    
class BaseTool:
    """Base class all tools must inherit from"""
    
    def get_definition(self) -> ToolDefinition:
        """Return the tool's schema definition"""
        raise NotImplementedError
    
    def validate(self, **kwargs) -> bool:
        """Validate input parameters"""
        raise NotImplementedError
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute the tool's main logic"""
        raise NotImplementedError
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        """Return safety limits and constraints"""
        return {
            "max_execution_time": 30,
            "max_memory_mb": 512,
            "allowed_network_ranges": ["10.0.0.0/24"],
            "blocked_commands": []
        }
```

### OpenAI Function Calling Format

Tools use OpenAI's function calling specification for compatibility:

```json
{
  "type": "function",
  "function": {
    "name": "port_scanner",
    "description": "Scan a target for open TCP ports",
    "parameters": {
      "type": "object",
      "properties": {
        "target": {
          "type": "string",
          "description": "IP address or hostname to scan"
        },
        "ports": {
          "type": "string",
          "description": "Port range (e.g., '1-1000' or '22,80,443')",
          "default": "1-1000"
        },
        "scan_type": {
          "type": "string",
          "enum": ["tcp_connect", "syn_scan", "service_detection"],
          "description": "Type of scan to perform",
          "default": "tcp_connect"
        }
      },
      "required": ["target"]
    }
  }
}
```

### Tool Response Format

Tools must return structured responses:

```python
{
    "success": True,                    # Whether execution succeeded
    "data": {                          # Main result data
        "open_ports": [22, 80, 443],
        "scan_duration": 2.3,
        "services": {
            "22": "ssh",
            "80": "http",
            "443": "https"
        }
    },
    "metadata": {                      # Execution metadata
        "tool_name": "port_scanner",
        "execution_time": 2.3,
        "timestamp": "2025-12-23T10:30:00Z",
        "agent_id": "red-team-01"
    },
    "warnings": [],                    # Non-fatal warnings
    "errors": []                       # Error messages if any
}
```

---

## Creating Your First Tool

### Step 1: Plan Your Tool

**Tool Name**: `web_request`  
**Purpose**: Make HTTP requests to target systems  
**Category**: Reconnaissance  
**Risk Level**: Moderate  

**Parameters**:
- `url` (string, required): Target URL
- `method` (string, optional): HTTP method (GET, POST, HEAD)
- `headers` (object, optional): Custom headers
- `timeout` (number, optional): Request timeout in seconds

### Step 2: Create the Tool File

Create `agent-tools/tools/web_request.py`:

```python
#!/usr/bin/env python3
"""
Web Request Tool
Allows agents to make HTTP requests for reconnaissance and testing
"""

import requests
import time
from typing import Dict, Any, Optional
from urllib.parse import urlparse

from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class WebRequestTool(BaseTool):
    """Tool for making HTTP requests"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="web_request",
            description="Make HTTP requests to target URLs for reconnaissance",
            category="reconnaissance",
            risk_level="moderate",
            requires_approval=False,
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="Target URL to request",
                    required=True
                ),
                ToolParameter(
                    name="method",
                    type="string",
                    description="HTTP method to use",
                    required=False,
                    enum=["GET", "POST", "HEAD", "OPTIONS"],
                    default="GET"
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="Custom HTTP headers",
                    required=False,
                    default={}
                ),
                ToolParameter(
                    name="timeout",
                    type="number",
                    description="Request timeout in seconds",
                    required=False,
                    default=10
                ),
                ToolParameter(
                    name="follow_redirects",
                    type="boolean",
                    description="Follow HTTP redirects",
                    required=False,
                    default=True
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate input parameters"""
        url = kwargs.get("url")
        if not url:
            raise ValueError("URL is required")
        
        # Parse and validate URL
        try:
            parsed = urlparse(url)
            if parsed.scheme not in ["http", "https"]:
                raise ValueError("URL must use http or https scheme")
        except Exception as e:
            raise ValueError(f"Invalid URL: {e}")
        
        # Validate method
        method = kwargs.get("method", "GET")
        if method not in ["GET", "POST", "HEAD", "OPTIONS"]:
            raise ValueError(f"Invalid HTTP method: {method}")
        
        # Validate timeout
        timeout = kwargs.get("timeout", 10)
        if not isinstance(timeout, (int, float)) or timeout <= 0:
            raise ValueError("Timeout must be a positive number")
        
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute the HTTP request"""
        start_time = time.time()
        
        url = kwargs["url"]
        method = kwargs.get("method", "GET")
        headers = kwargs.get("headers", {})
        timeout = kwargs.get("timeout", 10)
        follow_redirects = kwargs.get("follow_redirects", True)
        
        # Add user agent if not specified
        if "User-Agent" not in headers:
            headers["User-Agent"] = "AI-Agent-Lab/1.0 (Educational Tool)"
        
        try:
            response = requests.request(
                method=method,
                url=url,
                headers=headers,
                timeout=timeout,
                allow_redirects=follow_redirects,
                verify=True  # Always verify SSL in production
            )
            
            execution_time = time.time() - start_time
            
            return {
                "success": True,
                "data": {
                    "status_code": response.status_code,
                    "headers": dict(response.headers),
                    "body": response.text[:5000],  # Limit response size
                    "body_length": len(response.text),
                    "url": response.url,
                    "redirects": len(response.history)
                },
                "metadata": {
                    "tool_name": "web_request",
                    "execution_time": execution_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "method": method
                },
                "warnings": [],
                "errors": []
            }
            
        except requests.exceptions.Timeout:
            return {
                "success": False,
                "data": {},
                "metadata": {
                    "tool_name": "web_request",
                    "execution_time": time.time() - start_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [],
                "errors": [f"Request timed out after {timeout} seconds"]
            }
            
        except requests.exceptions.ConnectionError as e:
            return {
                "success": False,
                "data": {},
                "metadata": {
                    "tool_name": "web_request",
                    "execution_time": time.time() - start_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [],
                "errors": [f"Connection error: {str(e)}"]
            }
            
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {
                    "tool_name": "web_request",
                    "execution_time": time.time() - start_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [],
                "errors": [f"Unexpected error: {str(e)}"]
            }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        """Define safety limits"""
        return {
            "max_execution_time": 30,
            "max_memory_mb": 256,
            "allowed_network_ranges": ["10.0.0.0/24"],
            "rate_limit": {
                "requests_per_minute": 60,
                "requests_per_hour": 1000
            },
            "blocked_domains": [
                "localhost",
                "127.0.0.1",
                "169.254.0.0/16"  # Link-local
            ]
        }
```

### Step 3: Register the Tool

Add to `agent-tools/registry.py`:

```python
from agent_tools.tools.web_request import WebRequestTool

TOOL_REGISTRY = {
    "web_request": WebRequestTool(),
    # ... other tools
}
```

### Step 4: Test the Tool

Create `tests/test_web_request.py`:

```python
#!/usr/bin/env python3
"""Tests for web_request tool"""

import pytest
from agent_tools.tools.web_request import WebRequestTool

def test_tool_definition():
    """Test tool definition is valid"""
    tool = WebRequestTool()
    definition = tool.get_definition()
    
    assert definition.name == "web_request"
    assert definition.category == "reconnaissance"
    assert len(definition.parameters) == 5

def test_validation_success():
    """Test validation with valid parameters"""
    tool = WebRequestTool()
    assert tool.validate(
        url="http://10.0.0.103",
        method="GET"
    )

def test_validation_failure():
    """Test validation catches invalid parameters"""
    tool = WebRequestTool()
    
    with pytest.raises(ValueError):
        tool.validate(url="ftp://example.com")  # Invalid scheme
    
    with pytest.raises(ValueError):
        tool.validate(url="http://10.0.0.103", method="DELETE")  # Invalid method

def test_execution():
    """Test actual execution (requires test server)"""
    tool = WebRequestTool()
    result = tool.execute(
        url="http://10.0.0.103",
        method="GET",
        timeout=5
    )
    
    assert "success" in result
    assert "data" in result
    assert "metadata" in result
```

### Step 5: Document the Tool

Add to `agent-tools/docs/web_request.md`:

```markdown
# Web Request Tool

## Overview
Makes HTTP requests to target systems for reconnaissance and testing.

## Parameters
- **url** (string, required): Target URL
- **method** (string, optional): HTTP method (GET, POST, HEAD, OPTIONS)
- **headers** (object, optional): Custom headers
- **timeout** (number, optional): Timeout in seconds (default: 10)
- **follow_redirects** (boolean, optional): Follow redirects (default: true)

## Usage Examples

### Basic GET Request
```python
result = tool.execute(url="http://10.0.0.103")
```

### Custom Headers
```python
result = tool.execute(
    url="http://10.0.0.103",
    headers={"X-Custom": "value"}
)
```

### HEAD Request for Headers Only
```python
result = tool.execute(
    url="http://10.0.0.103",
    method="HEAD"
)
```

## Security Notes
- Only http/https schemes allowed
- Cannot access localhost or link-local addresses
- Rate limited to 60 requests/minute
- SSL certificate validation enforced
- Response body limited to 5000 characters

## Educational Use Cases
- Banner grabbing
- Service identification
- Web application reconnaissance
- HTTP header analysis
```

---

## Tool Registry System

### Registry Architecture

The registry manages all available tools and their lifecycle:

```python
# agent-tools/registry.py
"""
Tool Registry
Central registration and management of all agent tools
"""

import logging
from typing import Dict, List, Optional
from agent_tools.base import BaseTool, ToolDefinition

logger = logging.getLogger(__name__)

class ToolRegistry:
    """Manages registration and access to tools"""
    
    def __init__(self):
        self._tools: Dict[str, BaseTool] = {}
        self._categories: Dict[str, List[str]] = {}
        self._risk_levels: Dict[str, List[str]] = {}
    
    def register(self, tool: BaseTool) -> None:
        """Register a new tool"""
        definition = tool.get_definition()
        name = definition.name
        
        if name in self._tools:
            logger.warning(f"Tool {name} already registered, overwriting")
        
        self._tools[name] = tool
        
        # Index by category
        category = definition.category
        if category not in self._categories:
            self._categories[category] = []
        self._categories[category].append(name)
        
        # Index by risk level
        risk = definition.risk_level
        if risk not in self._risk_levels:
            self._risk_levels[risk] = []
        self._risk_levels[risk].append(name)
        
        logger.info(f"Registered tool: {name} (category: {category}, risk: {risk})")
    
    def get_tool(self, name: str) -> Optional[BaseTool]:
        """Get a tool by name"""
        return self._tools.get(name)
    
    def get_tools_by_category(self, category: str) -> List[BaseTool]:
        """Get all tools in a category"""
        tool_names = self._categories.get(category, [])
        return [self._tools[name] for name in tool_names]
    
    def get_tools_by_risk(self, risk_level: str) -> List[BaseTool]:
        """Get all tools at a risk level"""
        tool_names = self._risk_levels.get(risk_level, [])
        return [self._tools[name] for name in tool_names]
    
    def get_all_definitions(self) -> List[Dict]:
        """Get OpenAI function definitions for all tools"""
        definitions = []
        for tool in self._tools.values():
            definition = tool.get_definition()
            definitions.append(self._to_openai_format(definition))
        return definitions
    
    def get_definitions_for_agent(self, agent_type: str, lab_level: int = 1) -> List[Dict]:
        """Get tool definitions filtered for agent type and lab level"""
        definitions = []
        
        for tool in self._tools.values():
            definition = tool.get_definition()
            
            # Filter by agent type
            if agent_type == "red" and definition.category == "defense":
                continue
            if agent_type == "blue" and definition.category == "exploitation":
                continue
            
            # Filter by lab level (progressive disclosure)
            tool_level = self._get_tool_level(definition.name)
            if tool_level > lab_level:
                continue
            
            definitions.append(self._to_openai_format(definition))
        
        return definitions
    
    def _to_openai_format(self, definition: ToolDefinition) -> Dict:
        """Convert tool definition to OpenAI function format"""
        properties = {}
        required = []
        
        for param in definition.parameters:
            prop = {
                "type": param.type,
                "description": param.description
            }
            
            if param.enum:
                prop["enum"] = param.enum
            if param.default is not None:
                prop["default"] = param.default
            
            properties[param.name] = prop
            
            if param.required:
                required.append(param.name)
        
        return {
            "type": "function",
            "function": {
                "name": definition.name,
                "description": definition.description,
                "parameters": {
                    "type": "object",
                    "properties": properties,
                    "required": required
                }
            }
        }
    
    def _get_tool_level(self, tool_name: str) -> int:
        """Determine lab level required for tool"""
        # Tools available at different lab levels
        level_map = {
            "web_request": 1,
            "port_scanner": 1,
            "dns_lookup": 1,
            "ssh_connect": 2,
            "exploit_runner": 3,
            "privilege_escalation": 4,
            "lateral_movement": 5
        }
        return level_map.get(tool_name, 1)

# Global registry instance
registry = ToolRegistry()

# Auto-register tools
def auto_register_tools():
    """Automatically discover and register all tools"""
    import os
    import importlib
    
    tools_dir = os.path.join(os.path.dirname(__file__), "tools")
    
    for filename in os.listdir(tools_dir):
        if filename.endswith(".py") and not filename.startswith("__"):
            module_name = filename[:-3]
            try:
                module = importlib.import_module(f"agent_tools.tools.{module_name}")
                
                # Find tool class (assumes one per file)
                for attr_name in dir(module):
                    attr = getattr(module, attr_name)
                    if (isinstance(attr, type) and 
                        issubclass(attr, BaseTool) and 
                        attr != BaseTool):
                        tool_instance = attr()
                        registry.register(tool_instance)
                        break
            except Exception as e:
                logger.error(f"Failed to load tool from {filename}: {e}")

auto_register_tools()
```

### Tool Execution Engine

```python
# agent-tools/executor.py
"""
Tool Execution Engine
Safely executes tool calls with validation, sandboxing, and logging
"""

import time
import logging
import subprocess
from typing import Dict, Any
from agent_tools.registry import registry
from agent_tools.sandbox import Sandbox
from agent_tools.audit import AuditLogger

logger = logging.getLogger(__name__)
audit = AuditLogger()

class ToolExecutor:
    """Executes tool calls with safety constraints"""
    
    def __init__(self, agent_id: str, lab_id: str):
        self.agent_id = agent_id
        self.lab_id = lab_id
        self.sandbox = Sandbox()
        self.execution_history = []
    
    def execute(self, tool_name: str, **parameters) -> Dict[str, Any]:
        """Execute a tool with given parameters"""
        
        # Log the call
        audit.log_tool_call(
            agent_id=self.agent_id,
            lab_id=self.lab_id,
            tool_name=tool_name,
            parameters=parameters
        )
        
        # Get tool from registry
        tool = registry.get_tool(tool_name)
        if not tool:
            return {
                "success": False,
                "data": {},
                "metadata": {
                    "tool_name": tool_name,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [],
                "errors": [f"Tool '{tool_name}' not found"]
            }
        
        try:
            # Validate parameters
            tool.validate(**parameters)
            
            # Check safety constraints
            constraints = tool.get_safety_constraints()
            if not self._check_constraints(constraints):
                return {
                    "success": False,
                    "data": {},
                    "metadata": {"tool_name": tool_name},
                    "warnings": [],
                    "errors": ["Tool execution blocked by safety constraints"]
                }
            
            # Execute in sandbox
            result = self.sandbox.run(
                func=tool.execute,
                kwargs=parameters,
                timeout=constraints.get("max_execution_time", 30),
                memory_limit_mb=constraints.get("max_memory_mb", 512)
            )
            
            # Log result
            audit.log_tool_result(
                agent_id=self.agent_id,
                lab_id=self.lab_id,
                tool_name=tool_name,
                result=result
            )
            
            # Track in history
            self.execution_history.append({
                "tool": tool_name,
                "parameters": parameters,
                "result": result,
                "timestamp": time.time()
            })
            
            return result
            
        except Exception as e:
            logger.error(f"Tool execution error: {e}")
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": tool_name},
                "warnings": [],
                "errors": [f"Execution failed: {str(e)}"]
            }
    
    def _check_constraints(self, constraints: Dict[str, Any]) -> bool:
        """Verify safety constraints are met"""
        # Check rate limits
        rate_limit = constraints.get("rate_limit", {})
        if rate_limit:
            recent_calls = self._count_recent_calls(60)  # Last minute
            if recent_calls >= rate_limit.get("requests_per_minute", float('inf')):
                logger.warning("Rate limit exceeded")
                return False
        
        return True
    
    def _count_recent_calls(self, seconds: int) -> int:
        """Count tool calls in recent time window"""
        cutoff = time.time() - seconds
        return sum(1 for call in self.execution_history 
                   if call["timestamp"] > cutoff)
```

---

## Advanced Tool Patterns

### Pattern 1: Multi-Stage Tools

Tools that perform complex operations in stages:

```python
class AdvancedReconTool(BaseTool):
    """Multi-stage reconnaissance"""
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        target = kwargs["target"]
        results = {"stages": {}}
        
        # Stage 1: Port scan
        ports_result = self._stage_port_scan(target)
        results["stages"]["port_scan"] = ports_result
        
        if not ports_result["success"]:
            return self._build_response(results, success=False)
        
        # Stage 2: Service detection (only on open ports)
        open_ports = ports_result["data"]["open_ports"]
        services_result = self._stage_service_detection(target, open_ports)
        results["stages"]["service_detection"] = services_result
        
        # Stage 3: Vulnerability assessment
        vuln_result = self._stage_vuln_scan(target, services_result["data"])
        results["stages"]["vulnerability_scan"] = vuln_result
        
        return self._build_response(results, success=True)
```

### Pattern 2: Stateful Tools

Tools that maintain state across invocations:

```python
class PersistenceManagerTool(BaseTool):
    """Manages persistence mechanisms"""
    
    def __init__(self):
        self.active_mechanisms = {}
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        action = kwargs["action"]
        
        if action == "establish":
            return self._establish_persistence(kwargs)
        elif action == "check":
            return self._check_persistence()
        elif action == "remove":
            return self._remove_persistence(kwargs["id"])
```

### Pattern 3: Interactive Tools

Tools that require multi-step interaction:

```python
class InteractiveExploitTool(BaseTool):
    """Interactive exploit with multiple steps"""
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        step = kwargs.get("step", 1)
        session_id = kwargs.get("session_id")
        
        if step == 1:
            # Initial exploitation
            result = self._initial_exploit(kwargs)
            return {
                "success": True,
                "data": result,
                "next_step": 2,
                "session_id": self._create_session(),
                "prompt": "Exploit successful. What payload should I deploy?"
            }
        elif step == 2:
            # Payload deployment
            result = self._deploy_payload(session_id, kwargs["payload"])
            return {
                "success": True,
                "data": result,
                "next_step": 3,
                "session_id": session_id,
                "prompt": "Payload deployed. Execute post-exploitation?"
            }
```

### Pattern 4: Cooperative Tools

Tools that work together:

```python
class ToolChain:
    """Chain multiple tools together"""
    
    def __init__(self, tools: List[str]):
        self.tools = [registry.get_tool(name) for name in tools]
    
    def execute(self, initial_input: Dict) -> Dict:
        """Execute tools in sequence, piping output to next"""
        current_data = initial_input
        
        for tool in self.tools:
            result = tool.execute(**current_data)
            if not result["success"]:
                return result
            current_data = result["data"]
        
        return {"success": True, "data": current_data}

# Usage
recon_chain = ToolChain(["port_scanner", "service_detector", "vulnerability_scanner"])
result = recon_chain.execute({"target": "10.0.0.103"})
```

---

## Security Considerations

### Sandboxing

All tool executions run in a restricted environment:

```python
# agent-tools/sandbox.py
"""
Execution Sandbox
Provides isolated, resource-limited execution environment
"""

import resource
import signal
import multiprocessing
from typing import Callable, Any, Dict

class Sandbox:
    """Sandboxed execution environment"""
    
    def run(self, func: Callable, kwargs: Dict, timeout: int, memory_limit_mb: int) -> Any:
        """Run function with resource limits"""
        
        def worker(queue, func, kwargs):
            try:
                # Set resource limits
                resource.setrlimit(
                    resource.RLIMIT_AS,
                    (memory_limit_mb * 1024 * 1024, memory_limit_mb * 1024 * 1024)
                )
                
                # Execute function
                result = func(**kwargs)
                queue.put({"success": True, "result": result})
                
            except Exception as e:
                queue.put({"success": False, "error": str(e)})
        
        # Run in separate process with timeout
        queue = multiprocessing.Queue()
        process = multiprocessing.Process(target=worker, args=(queue, func, kwargs))
        
        process.start()
        process.join(timeout=timeout)
        
        if process.is_alive():
            process.terminate()
            process.join()
            raise TimeoutError(f"Execution exceeded {timeout} seconds")
        
        if queue.empty():
            raise RuntimeError("Worker process failed")
        
        result = queue.get()
        if not result["success"]:
            raise RuntimeError(result["error"])
        
        return result["result"]
```

### Input Validation

Never trust agent input:

```python
def validate_ip_address(ip: str) -> bool:
    """Validate IP address is within allowed range"""
    import ipaddress
    
    try:
        addr = ipaddress.ip_address(ip)
        
        # Only allow lab network
        lab_network = ipaddress.ip_network("10.0.0.0/24")
        
        if addr not in lab_network:
            raise ValueError(f"IP {ip} outside allowed network")
        
        # Block host access
        if addr == ipaddress.ip_address("10.0.0.1"):
            raise ValueError("Cannot target host system")
        
        return True
        
    except Exception as e:
        raise ValueError(f"Invalid IP address: {e}")
```

### Command Injection Prevention

Sanitize all shell commands:

```python
import shlex
import subprocess

def safe_shell_execute(command: str, allowed_commands: List[str]) -> str:
    """Safely execute shell command"""
    
    # Parse command
    parts = shlex.split(command)
    if not parts:
        raise ValueError("Empty command")
    
    # Check if command is allowed
    base_command = parts[0]
    if base_command not in allowed_commands:
        raise ValueError(f"Command '{base_command}' not allowed")
    
    # Execute with proper escaping
    try:
        result = subprocess.run(
            parts,
            capture_output=True,
            text=True,
            timeout=30,
            check=False
        )
        return result.stdout
    except subprocess.TimeoutExpired:
        raise TimeoutError("Command execution timeout")
```

### Audit Logging

Log everything for security and education:

```python
# agent-tools/audit.py
"""
Audit Logging System
Records all tool executions for security and educational purposes
"""

import json
import logging
from pathlib import Path
from datetime import datetime

class AuditLogger:
    """Comprehensive audit logging"""
    
    def __init__(self, log_dir: Path = Path("/var/lib/ai-agents-lab/audit")):
        self.log_dir = log_dir
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        self.logger = logging.getLogger("audit")
        handler = logging.FileHandler(log_dir / "audit.log")
        handler.setFormatter(logging.Formatter(
            '%(asctime)s [%(levelname)s] %(message)s'
        ))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)
    
    def log_tool_call(self, agent_id: str, lab_id: str, tool_name: str, parameters: Dict):
        """Log tool invocation"""
        entry = {
            "event": "tool_call",
            "timestamp": datetime.now().isoformat(),
            "agent_id": agent_id,
            "lab_id": lab_id,
            "tool_name": tool_name,
            "parameters": parameters
        }
        self.logger.info(json.dumps(entry))
        
        # Write detailed log
        detail_file = self.log_dir / agent_id / f"{lab_id}.jsonl"
        detail_file.parent.mkdir(exist_ok=True)
        with open(detail_file, 'a') as f:
            f.write(json.dumps(entry) + "\n")
    
    def log_tool_result(self, agent_id: str, lab_id: str, tool_name: str, result: Dict):
        """Log tool result"""
        entry = {
            "event": "tool_result",
            "timestamp": datetime.now().isoformat(),
            "agent_id": agent_id,
            "lab_id": lab_id,
            "tool_name": tool_name,
            "success": result.get("success"),
            "errors": result.get("errors", [])
        }
        self.logger.info(json.dumps(entry))
```

---

## Testing and Validation

### Unit Tests

Test each tool in isolation:

```python
# tests/test_port_scanner.py
import pytest
from agent_tools.tools.port_scanner import PortScannerTool

class TestPortScanner:
    
    @pytest.fixture
    def tool(self):
        return PortScannerTool()
    
    def test_definition(self, tool):
        """Test tool definition is complete"""
        definition = tool.get_definition()
        assert definition.name == "port_scanner"
        assert len(definition.parameters) > 0
    
    def test_validation_valid_input(self, tool):
        """Test validation accepts valid input"""
        assert tool.validate(
            target="10.0.0.103",
            ports="22,80,443"
        )
    
    def test_validation_invalid_target(self, tool):
        """Test validation rejects invalid targets"""
        with pytest.raises(ValueError):
            tool.validate(target="192.168.1.1")  # Outside lab network
    
    def test_execution_success(self, tool, mocker):
        """Test successful execution"""
        # Mock subprocess call
        mocker.patch('subprocess.run', return_value=mocker.Mock(
            stdout="22/tcp open ssh\n80/tcp open http\n",
            returncode=0
        ))
        
        result = tool.execute(target="10.0.0.103", ports="22,80")
        
        assert result["success"]
        assert len(result["data"]["open_ports"]) == 2
    
    def test_execution_timeout(self, tool, mocker):
        """Test timeout handling"""
        mocker.patch('subprocess.run', side_effect=subprocess.TimeoutExpired("cmd", 30))
        
        result = tool.execute(target="10.0.0.103")
        
        assert not result["success"]
        assert "timeout" in str(result["errors"]).lower()
```

### Integration Tests

Test tools in realistic scenarios:

```python
# tests/integration/test_recon_workflow.py
import pytest
from agent_tools.registry import registry
from agent_tools.executor import ToolExecutor

class TestReconWorkflow:
    """Test complete reconnaissance workflow"""
    
    @pytest.fixture
    def executor(self):
        return ToolExecutor(agent_id="test-agent", lab_id="lab-01")
    
    def test_full_recon_chain(self, executor):
        """Test complete reconnaissance sequence"""
        
        # Step 1: Port scan
        scan_result = executor.execute(
            "port_scanner",
            target="10.0.0.103",
            ports="1-1000"
        )
        assert scan_result["success"]
        open_ports = scan_result["data"]["open_ports"]
        assert len(open_ports) > 0
        
        # Step 2: Service detection
        for port in open_ports:
            service_result = executor.execute(
                "service_detector",
                target="10.0.0.103",
                port=port
            )
            assert service_result["success"]
        
        # Step 3: Vulnerability scan
        vuln_result = executor.execute(
            "vulnerability_scanner",
            target="10.0.0.103",
            services=scan_result["data"]["services"]
        )
        assert vuln_result["success"]
```

### Security Tests

Verify security constraints:

```python
# tests/security/test_sandbox.py
import pytest
from agent_tools.sandbox import Sandbox

class TestSandbox:
    
    def test_memory_limit_enforced(self):
        """Test memory limit prevents excessive allocation"""
        sandbox = Sandbox()
        
        def allocate_memory():
            # Try to allocate 1GB
            data = bytearray(1024 * 1024 * 1024)
            return len(data)
        
        with pytest.raises(MemoryError):
            sandbox.run(
                func=allocate_memory,
                kwargs={},
                timeout=10,
                memory_limit_mb=100
            )
    
    def test_timeout_enforced(self):
        """Test timeout prevents long-running operations"""
        sandbox = Sandbox()
        
        def infinite_loop():
            while True:
                pass
        
        with pytest.raises(TimeoutError):
            sandbox.run(
                func=infinite_loop,
                kwargs={},
                timeout=2,
                memory_limit_mb=512
            )
    
    def test_network_isolation(self):
        """Test network access is restricted"""
        sandbox = Sandbox()
        
        def test_external_access():
            import requests
            requests.get("https://google.com")
        
        # Should fail due to network restrictions
        result = sandbox.run(
            func=test_external_access,
            kwargs={},
            timeout=5,
            memory_limit_mb=256
        )
        assert not result["success"]
```

---

## Deployment with Nix

### Tool Package Structure

```
agent-tools/
├── flake.nix              # Nix flake for tool management
├── default.nix            # Package definition
├── agent_tools/
│   ├── __init__.py
│   ├── base.py           # Base tool class
│   ├── registry.py       # Tool registry
│   ├── executor.py       # Execution engine
│   ├── sandbox.py        # Sandboxing
│   ├── audit.py          # Audit logging
│   └── tools/            # Individual tools
│       ├── __init__.py
│       ├── port_scanner.py
│       ├── web_request.py
│       ├── dns_lookup.py
│       ├── ssh_client.py
│       └── log_analyzer.py
├── tests/                # Test suite
├── docs/                 # Documentation
└── examples/             # Usage examples
```

### Nix Flake for Tools

Create `agent-tools/flake.nix`:

```nix
{
  description = "AI Agent Tools Collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Individual tool packages
        portScannerTool = pkgs.python3Packages.buildPythonPackage {
          pname = "port-scanner-tool";
          version = "1.0.0";
          src = ./agent_tools/tools/port_scanner.py;
          propagatedBuildInputs = with pkgs; [ nmap netcat ];
        };
        
        # Main agent-tools package
        agentTools = pkgs.python3Packages.buildPythonApplication {
          pname = "agent-tools";
          version = "1.0.0";
          src = ./.;
          
          propagatedBuildInputs = with pkgs.python3Packages; [
            requests
            pyyaml
            pytest
            pytest-mock
          ];
          
          # Include system tools
          buildInputs = with pkgs; [
            nmap
            netcat
            curl
            dig
            whois
            sshpass
          ];
          
          checkPhase = ''
            pytest tests/
          '';
          
          postInstall = ''
            # Install tool documentation
            mkdir -p $out/share/doc/agent-tools
            cp -r docs/* $out/share/doc/agent-tools/
            
            # Install examples
            mkdir -p $out/share/examples/agent-tools
            cp -r examples/* $out/share/examples/agent-tools/
          '';
        };
        
        # Development shell
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pytest
            python3Packages.pytest-mock
            python3Packages.requests
            nmap
            netcat
          ];
          
          shellHook = ''
            echo "Agent Tools Development Environment"
            echo "  pytest tests/          → Run tests"
            echo "  python -m agent_tools  → Run tool registry"
          '';
        };
        
      in {
        packages = {
          default = agentTools;
          agent-tools = agentTools;
          port-scanner = portScannerTool;
        };
        
        devShells.default = devShell;
        
        # Apps for easy tool testing
        apps = {
          test-port-scanner = {
            type = "app";
            program = toString (pkgs.writeShellScript "test-port-scanner" ''
              ${agentTools}/bin/agent-tool-test port_scanner \
                --target 10.0.0.103 \
                --ports 22,80,443
            '');
          };
          
          list-tools = {
            type = "app";
            program = toString (pkgs.writeShellScript "list-tools" ''
              ${agentTools}/bin/agent-tool-list
            '');
          };
        };
      }
    );
}
```

### Integration with Main Flake

Update main `flake.nix`:

```nix
{
  inputs = {
    # ... existing inputs
    agent-tools = {
      url = "path:./agent-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agent-tools, ... }:
    # ... 
    {
      # Include agent-tools in VMs
      labVmModule = { config, pkgs, ... }: {
        environment.systemPackages = [
          agent-tools.packages.${system}.default
        ];
        
        # Configure tool paths
        environment.variables = {
          AGENT_TOOLS_PATH = "${agent-tools.packages.${system}.default}/lib/python3.11/site-packages/agent_tools";
        };
      };
    };
}
```

---

## Best Practices

### 1. Design Principles

**Single Responsibility**
- Each tool does one thing well
- Compose complex operations from simple tools

**Fail Gracefully**
- Always return structured responses
- Provide actionable error messages
- Never crash the agent

**Be Observable**
- Log all actions
- Include timing information
- Provide progress feedback

**Stay Idempotent**
- Same input = same output (when possible)
- Safe to retry operations
- No unexpected side effects

### 2. Documentation Standards

Every tool must have:

```python
"""
Tool Name: port_scanner
Category: reconnaissance
Risk Level: moderate

Description:
    Scans a target system for open TCP ports to identify network services.
    Uses TCP connect scanning by default for reliability.

Parameters:
    target (string, required): IP address or hostname to scan
    ports (string, optional): Port range or list (default: "1-1000")
    scan_type (string, optional): Type of scan (default: "tcp_connect")

Returns:
    {
        "open_ports": [22, 80, 443],
        "services": {"22": "ssh", "80": "http"},
        "scan_duration": 2.3
    }

Examples:
    # Basic scan
    result = tool.execute(target="10.0.0.103")
    
    # Specific ports
    result = tool.execute(target="10.0.0.103", ports="22,80,443")
    
    # Custom range
    result = tool.execute(target="10.0.0.103", ports="1-10000")

Educational Notes:
    - Teaches network service enumeration
    - Demonstrates TCP/IP fundamentals
    - Shows importance of port security

Security Considerations:
    - Rate limited to prevent DOS
    - Only allows lab network targets
    - Logs all scan attempts
"""
```

### 3. Error Handling

```python
def execute(self, **kwargs) -> Dict[str, Any]:
    try:
        # Validate
        self.validate(**kwargs)
        
        # Execute
        result = self._do_work(**kwargs)
        
        return {
            "success": True,
            "data": result,
            "metadata": self._get_metadata(),
            "warnings": [],
            "errors": []
        }
        
    except ValueError as e:
        # Validation error
        return self._error_response(f"Invalid input: {e}")
        
    except TimeoutError as e:
        # Timeout
        return self._error_response(f"Operation timed out: {e}")
        
    except PermissionError as e:
        # Security violation
        return self._error_response(f"Permission denied: {e}")
        
    except Exception as e:
        # Unexpected error
        logger.exception("Unexpected tool error")
        return self._error_response(f"Unexpected error: {e}")
```

### 4. Performance Optimization

```python
class CachedTool(BaseTool):
    """Tool with result caching"""
    
    def __init__(self):
        self.cache = {}
        self.cache_ttl = 300  # 5 minutes
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        # Generate cache key
        cache_key = self._make_cache_key(kwargs)
        
        # Check cache
        if cache_key in self.cache:
            cached_result, timestamp = self.cache[cache_key]
            if time.time() - timestamp < self.cache_ttl:
                cached_result["metadata"]["from_cache"] = True
                return cached_result
        
        # Execute and cache
        result = self._do_work(**kwargs)
        self.cache[cache_key] = (result, time.time())
        
        return result
```

### 5. Progressive Disclosure

Start with safe tools, unlock advanced ones:

```python
TOOL_LEVELS = {
    1: [  # Beginner - Lab 01
        "ping",
        "dns_lookup",
        "web_request",
        "port_scanner"
    ],
    2: [  # Intermediate - Lab 02
        "ssh_client",
        "file_transfer",
        "service_detector"
    ],
    3: [  # Advanced - Lab 03-04
        "exploit_runner",
        "privilege_escalation",
        "persistence_manager"
    ],
    4: [  # Expert - Lab 05
        "lateral_movement",
        "data_exfiltration",
        "anti_forensics"
    ]
}
```

---

## Example Tools

### Complete Port Scanner

See `agent-tools/tools/port_scanner.py` in the repository.

### Complete Service Detector

See `agent-tools/tools/service_detector.py` in the repository.

### Complete Log Analyzer (Blue Team)

See `agent-tools/tools/log_analyzer.py` in the repository.

---

## Troubleshooting

### Tool Not Found

```bash
# Check tool registration
python3 -c "from agent_tools.registry import registry; print(registry._tools.keys())"

# Verify import
python3 -c "from agent_tools.tools.port_scanner import PortScannerTool"
```

### Execution Failures

```bash
# Check logs
tail -f /var/lib/ai-agents-lab/logs/agent_interactions_*.log

# Test tool directly
python3 -m agent_tools.tools.port_scanner --target 10.0.0.103
```

### Permission Errors

```bash
# Check sandbox configuration
python3 -c "from agent_tools.sandbox import Sandbox; print(Sandbox().get_limits())"

# Verify file permissions
ls -la /var/lib/ai-agents-lab/
```

### Network Issues

```bash
# Test connectivity
ping -c 1 10.0.0.103

# Check firewall
sudo iptables -L -n -v

# Verify VM networking
sudo virsh net-list --all
```

---

## Contributing Tools

### Submission Process

1. Fork the repository
2. Create tool in `agent-tools/tools/your_tool.py`
3. Add tests in `tests/test_your_tool.py`
4. Add documentation in `docs/your_tool.md`
5. Update `TOOL_LEVELS` if needed
6. Submit pull request

### Review Checklist

- [ ] Tool follows `BaseTool` interface
- [ ] Comprehensive input validation
- [ ] Proper error handling
- [ ] Security constraints defined
- [ ] Unit tests with >80% coverage
- [ ] Integration test included
- [ ] Documentation complete
- [ ] Examples provided
- [ ] Educational value clear

---

## Appendix: Tool Template

```python
#!/usr/bin/env python3
"""
[Tool Name]
[One-line description]
"""

from typing import Dict, Any, List
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class [ToolName]Tool(BaseTool):
    """[Detailed description]"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="[tool_name]",
            description="[Description for AI agent]",
            category="[reconnaissance|exploitation|defense|utility]",
            risk_level="[safe|moderate|dangerous]",
            requires_approval=False,
            parameters=[
                ToolParameter(
                    name="[param_name]",
                    type="[string|number|boolean|array|object]",
                    description="[Parameter description]",
                    required=True
                ),
                # ... more parameters
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate input parameters"""
        # Validation logic
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute the tool's main logic"""
        try:
            # Execution logic
            result = {}
            
            return {
                "success": True,
                "data": result,
                "metadata": {
                    "tool_name": "[tool_name]",
                    "timestamp": "...",
                },
                "warnings": [],
                "errors": []
            }
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "[tool_name]"},
                "warnings": [],
                "errors": [str(e)]
            }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        """Define safety limits"""
        return {
            "max_execution_time": 30,
            "max_memory_mb": 512,
            "allowed_network_ranges": ["10.0.0.0/24"],
            "rate_limit": {
                "requests_per_minute": 60
            }
        }
```

---

## Quick Reference

### Common Tool Methods

| Method | Purpose | Required |
|--------|---------|----------|
| `get_definition()` | Return tool schema | Yes |
| `validate(**kwargs)` | Validate parameters | Yes |
| `execute(**kwargs)` | Main execution logic | Yes |
| `get_safety_constraints()` | Security limits | Yes |
| `cleanup()` | Resource cleanup | No |

### Response Structure

```python
{
    "success": bool,           # Required
    "data": dict,             # Required
    "metadata": dict,         # Required
    "warnings": list,         # Optional
    "errors": list            # Optional
}
```

### Testing Commands

```bash
# Run all tests
pytest tests/

# Test specific tool
pytest tests/test_port_scanner.py -v

# Run with coverage
pytest --cov=agent_tools tests/

# Integration tests
pytest tests/integration/

# Security tests
pytest tests/security/
```

### Deployment Commands

```bash
# Build tool package
nix build .#agent-tools

# Test in development
nix develop

# Deploy to lab
nix run .#deploy-tools

# List available tools
nix run .#list-tools
```

---

**Ready to create your first tool?** Start with the template above and refer to the examples in `agent-tools/tools/`!
