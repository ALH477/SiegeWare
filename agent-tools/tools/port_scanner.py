# agent-tools/tools/port_scanner.py
#!/usr/bin/env python3
"""
Port Scanner Tool
Scans target systems for open TCP ports
"""

import subprocess
import re
import ipaddress
from typing import Dict, Any, List
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class PortScannerTool(BaseTool):
    """Educational port scanning tool using nmap"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="port_scanner",
            description="Scan a target system for open TCP ports to identify network services",
            category="reconnaissance",
            risk_level="moderate",
            requires_approval=False,
            parameters=[
                ToolParameter(
                    name="target",
                    type="string",
                    description="IP address or hostname to scan (must be in lab network)",
                    required=True
                ),
                ToolParameter(
                    name="ports",
                    type="string",
                    description="Port specification (e.g., '22,80,443' or '1-1000')",
                    required=False,
                    default="1-1000"
                ),
                ToolParameter(
                    name="scan_type",
                    type="string",
                    description="Type of scan to perform",
                    required=False,
                    enum=["tcp_connect", "syn_scan", "quick"],
                    default="tcp_connect"
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate scan parameters"""
        target = kwargs.get("target")
        if not target:
            raise ValueError("Target is required")
        
        # Validate IP is in lab network
        try:
            ip = ipaddress.ip_address(target)
            lab_network = ipaddress.ip_network("10.0.0.0/24")
            
            if ip not in lab_network:
                raise ValueError(f"Target {target} is outside lab network (10.0.0.0/24)")
            
            # Prevent scanning the host
            if ip == ipaddress.ip_address("10.0.0.1"):
                raise ValueError("Cannot scan host system")
        
        except ValueError as e:
            raise ValueError(f"Invalid target: {e}")
        
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute port scan"""
        import time
        start_time = time.time()
        
        target = kwargs["target"]
        ports = kwargs.get("ports", "1-1000")
        scan_type = kwargs.get("scan_type", "tcp_connect")
        
        # Build nmap command
        nmap_args = ["nmap"]
        
        if scan_type == "syn_scan":
            nmap_args.extend(["-sS", "-Pn"])
        elif scan_type == "quick":
            nmap_args.extend(["-sT", "-T4", "--top-ports", "100"])
        else:  # tcp_connect
            nmap_args.extend(["-sT", "-Pn"])
        
        nmap_args.extend(["-p", ports, target])
        
        try:
            result = subprocess.run(
                nmap_args,
                capture_output=True,
                text=True,
                timeout=120
            )
            
            # Parse nmap output
            open_ports = []
            services = {}
            
            for line in result.stdout.split("\n"):
                # Match lines like: "22/tcp   open  ssh"
                match = re.match(r"(\d+)/tcp\s+open\s+(\S+)", line)
                if match:
                    port = int(match.group(1))
                    service = match.group(2)
                    open_ports.append(port)
                    services[str(port)] = service
            
            execution_time = time.time() - start_time
            
            return {
                "success": True,
                "data": {
                    "target": target,
                    "open_ports": open_ports,
                    "total_ports_scanned": len(ports.split(",")),
                    "services": services,
                    "scan_type": scan_type,
                    "scan_duration": round(execution_time, 2)
                },
                "metadata": {
                    "tool_name": "port_scanner",
                    "execution_time": execution_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [] if open_ports else ["No open ports found"],
                "errors": []
            }
            
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "port_scanner"},
                "warnings": [],
                "errors": ["Scan timed out after 120 seconds"]
            }
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "port_scanner"},
                "warnings": [],
                "errors": [f"Scan failed: {str(e)}"]
            }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        return {
            "max_execution_time": 120,
            "max_memory_mb": 256,
            "allowed_network_ranges": ["10.0.0.0/24"],
            "rate_limit": {
                "requests_per_minute": 10,
                "requests_per_hour": 100
            }
        }


# agent-tools/tools/web_request.py
#!/usr/bin/env python3
"""
Web Request Tool
Makes HTTP requests for reconnaissance and testing
"""

import requests
import time
from typing import Dict, Any
from urllib.parse import urlparse
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class WebRequestTool(BaseTool):
    """HTTP request tool for web reconnaissance"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="web_request",
            description="Make HTTP/HTTPS requests to target URLs for web reconnaissance",
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
                    description="HTTP method",
                    required=False,
                    enum=["GET", "POST", "HEAD", "OPTIONS"],
                    default="GET"
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="Custom HTTP headers as key-value pairs",
                    required=False,
                    default={}
                ),
                ToolParameter(
                    name="timeout",
                    type="number",
                    description="Request timeout in seconds",
                    required=False,
                    default=10
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate request parameters"""
        url = kwargs.get("url")
        if not url:
            raise ValueError("URL is required")
        
        try:
            parsed = urlparse(url)
            if parsed.scheme not in ["http", "https"]:
                raise ValueError("URL must use http or https scheme")
            
            # Validate hostname is in lab network
            hostname = parsed.hostname
            if hostname and not hostname.startswith("10.0.0."):
                raise ValueError("Can only request URLs in lab network (10.0.0.0/24)")
        
        except Exception as e:
            raise ValueError(f"Invalid URL: {e}")
        
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute HTTP request"""
        start_time = time.time()
        
        url = kwargs["url"]
        method = kwargs.get("method", "GET")
        headers = kwargs.get("headers", {})
        timeout = kwargs.get("timeout", 10)
        
        # Add user agent if not specified
        if "User-Agent" not in headers:
            headers["User-Agent"] = "AI-Agent-Lab/1.0 (Educational)"
        
        try:
            response = requests.request(
                method=method,
                url=url,
                headers=headers,
                timeout=timeout,
                allow_redirects=True,
                verify=False  # Allow self-signed certs in lab
            )
            
            execution_time = time.time() - start_time
            
            # Extract useful information
            content_type = response.headers.get("Content-Type", "")
            server = response.headers.get("Server", "Unknown")
            
            return {
                "success": True,
                "data": {
                    "status_code": response.status_code,
                    "status_text": response.reason,
                    "headers": dict(response.headers),
                    "body_preview": response.text[:1000],
                    "body_length": len(response.text),
                    "content_type": content_type,
                    "server": server,
                    "final_url": response.url,
                    "redirect_count": len(response.history)
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
                "metadata": {"tool_name": "web_request"},
                "warnings": [],
                "errors": [f"Request timed out after {timeout} seconds"]
            }
        except requests.exceptions.ConnectionError as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "web_request"},
                "warnings": [],
                "errors": [f"Connection failed: {str(e)}"]
            }
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "web_request"},
                "warnings": [],
                "errors": [f"Request failed: {str(e)}"]
            }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        return {
            "max_execution_time": 30,
            "max_memory_mb": 256,
            "allowed_network_ranges": ["10.0.0.0/24"],
            "rate_limit": {
                "requests_per_minute": 60,
                "requests_per_hour": 1000
            }
        }


# agent-tools/tools/dns_lookup.py
#!/usr/bin/env python3
"""
DNS Lookup Tool
Performs DNS queries for reconnaissance
"""

import subprocess
import re
from typing import Dict, Any, List
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class DnsLookupTool(BaseTool):
    """DNS reconnaissance tool"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="dns_lookup",
            description="Perform DNS queries to gather information about target domains",
            category="reconnaissance",
            risk_level="safe",
            requires_approval=False,
            parameters=[
                ToolParameter(
                    name="domain",
                    type="string",
                    description="Domain name or IP address to query",
                    required=True
                ),
                ToolParameter(
                    name="record_type",
                    type="string",
                    description="DNS record type to query",
                    required=False,
                    enum=["A", "AAAA", "MX", "TXT", "NS", "PTR", "ANY"],
                    default="A"
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate DNS query parameters"""
        domain = kwargs.get("domain")
        if not domain:
            raise ValueError("Domain is required")
        
        # Basic domain validation
        if len(domain) > 253:
            raise ValueError("Domain name too long")
        
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute DNS lookup"""
        import time
        start_time = time.time()
        
        domain = kwargs["domain"]
        record_type = kwargs.get("record_type", "A")
        
        try:
            # Use dig for DNS queries
            result = subprocess.run(
                ["dig", "+short", domain, record_type],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            records = [line.strip() for line in result.stdout.split("\n") if line.strip()]
            
            execution_time = time.time() - start_time
            
            return {
                "success": True,
                "data": {
                    "domain": domain,
                    "record_type": record_type,
                    "records": records,
                    "record_count": len(records)
                },
                "metadata": {
                    "tool_name": "dns_lookup",
                    "execution_time": execution_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [] if records else ["No records found"],
                "errors": []
            }
            
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "dns_lookup"},
                "warnings": [],
                "errors": ["DNS query timed out"]
            }
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "dns_lookup"},
                "warnings": [],
                "errors": [f"DNS query failed: {str(e)}"]
            }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        return {
            "max_execution_time": 10,
            "max_memory_mb": 128,
            "rate_limit": {
                "requests_per_minute": 120
            }
        }


# agent-tools/tools/service_detector.py
#!/usr/bin/env python3
"""
Service Detection Tool
Identifies services running on open ports
"""

import subprocess
import re
from typing import Dict, Any
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class ServiceDetectorTool(BaseTool):
    """Service fingerprinting and version detection"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="service_detector",
            description="Detect and fingerprint services running on target ports",
            category="reconnaissance",
            risk_level="moderate",
            requires_approval=False,
            parameters=[
                ToolParameter(
                    name="target",
                    type="string",
                    description="Target IP address",
                    required=True
                ),
                ToolParameter(
                    name="port",
                    type="number",
                    description="Port number to probe",
                    required=True
                ),
                ToolParameter(
                    name="aggressive",
                    type="boolean",
                    description="Use aggressive detection methods",
                    required=False,
                    default=False
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate parameters"""
        import ipaddress
        
        target = kwargs.get("target")
        port = kwargs.get("port")
        
        if not target or not port:
            raise ValueError("Target and port are required")
        
        # Validate IP
        try:
            ip = ipaddress.ip_address(target)
            lab_network = ipaddress.ip_network("10.0.0.0/24")
            if ip not in lab_network:
                raise ValueError("Target must be in lab network")
        except ValueError as e:
            raise ValueError(f"Invalid target: {e}")
        
        # Validate port
        if not isinstance(port, int) or port < 1 or port > 65535:
            raise ValueError("Port must be between 1 and 65535")
        
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute service detection"""
        import time
        start_time = time.time()
        
        target = kwargs["target"]
        port = kwargs["port"]
        aggressive = kwargs.get("aggressive", False)
        
        try:
            # Use nmap for service detection
            nmap_args = ["nmap", "-sV"]
            
            if aggressive:
                nmap_args.append("-A")
            
            nmap_args.extend(["-p", str(port), target])
            
            result = subprocess.run(
                nmap_args,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            # Parse service information
            service_info = {
                "port": port,
                "service": "unknown",
                "version": "unknown",
                "product": "unknown"
            }
            
            for line in result.stdout.split("\n"):
                match = re.search(
                    rf"{port}/tcp\s+open\s+(\S+)\s*(.*)",
                    line
                )
                if match:
                    service_info["service"] = match.group(1)
                    version_info = match.group(2).strip()
                    if version_info:
                        service_info["version"] = version_info
            
            execution_time = time.time() - start_time
            
            return {
                "success": True,
                "data": service_info,
                "metadata": {
                    "tool_name": "service_detector",
                    "execution_time": execution_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [],
                "errors": []
            }
            
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "service_detector"},
                "warnings": [],
                "errors": ["Service detection timed out"]
            }
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "service_detector"},
                "warnings": [],
                "errors": [f"Detection failed: {str(e)}"]
            }
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        return {
            "max_execution_time": 60,
            "max_memory_mb": 256,
            "allowed_network_ranges": ["10.0.0.0/24"],
            "rate_limit": {
                "requests_per_minute": 20
            }
        }


# agent-tools/tools/log_analyzer.py
#!/usr/bin/env python3
"""
Log Analyzer Tool (Blue Team)
Analyzes system logs for security events
"""

import re
from typing import Dict, Any, List
from datetime import datetime, timedelta
from agent_tools.base import BaseTool, ToolDefinition, ToolParameter

class LogAnalyzerTool(BaseTool):
    """Blue team log analysis tool"""
    
    def get_definition(self) -> ToolDefinition:
        return ToolDefinition(
            name="log_analyzer",
            description="Analyze system logs to detect security events and anomalies",
            category="defense",
            risk_level="safe",
            requires_approval=False,
            parameters=[
                ToolParameter(
                    name="log_file",
                    type="string",
                    description="Path to log file to analyze",
                    required=True
                ),
                ToolParameter(
                    name="pattern",
                    type="string",
                    description="Pattern to search for (regex)",
                    required=False,
                    default=".*"
                ),
                ToolParameter(
                    name="time_range",
                    type="number",
                    description="Look back this many minutes",
                    required=False,
                    default=60
                )
            ]
        )
    
    def validate(self, **kwargs) -> bool:
        """Validate parameters"""
        log_file = kwargs.get("log_file")
        
        if not log_file:
            raise ValueError("Log file path is required")
        
        # Only allow specific log files
        allowed_logs = [
            "/var/log/auth.log",
            "/var/log/syslog",
            "/var/log/nginx/access.log",
            "/var/log/nginx/error.log"
        ]
        
        if log_file not in allowed_logs:
            raise ValueError(f"Log file must be one of: {', '.join(allowed_logs)}")
        
        return True
    
    def execute(self, **kwargs) -> Dict[str, Any]:
        """Analyze log file"""
        import time
        start_time = time.time()
        
        log_file = kwargs["log_file"]
        pattern = kwargs.get("pattern", ".*")
        time_range = kwargs.get("time_range", 60)
        
        try:
            # Read log file
            with open(log_file, 'r') as f:
                lines = f.readlines()
            
            # Filter by time and pattern
            cutoff_time = datetime.now() - timedelta(minutes=time_range)
            matches = []
            
            pattern_re = re.compile(pattern)
            
            for line in lines[-10000:]:  # Last 10k lines max
                if pattern_re.search(line):
                    matches.append(line.strip())
            
            # Detect common security events
            security_events = self._detect_security_events(matches)
            
            execution_time = time.time() - start_time
            
            return {
                "success": True,
                "data": {
                    "log_file": log_file,
                    "total_lines_scanned": len(lines[-10000:]),
                    "matches_found": len(matches),
                    "sample_matches": matches[:10],
                    "security_events": security_events
                },
                "metadata": {
                    "tool_name": "log_analyzer",
                    "execution_time": execution_time,
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                },
                "warnings": [] if not security_events else ["Security events detected!"],
                "errors": []
            }
            
        except FileNotFoundError:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "log_analyzer"},
                "warnings": [],
                "errors": [f"Log file not found: {log_file}"]
            }
        except Exception as e:
            return {
                "success": False,
                "data": {},
                "metadata": {"tool_name": "log_analyzer"},
                "warnings": [],
                "errors": [f"Analysis failed: {str(e)}"]
            }
    
    def _detect_security_events(self, lines: List[str]) -> List[Dict]:
        """Detect common security events in logs"""
        events = []
        
        # Failed login attempts
        failed_logins = len([l for l in lines if "Failed password" in l])
        if failed_logins > 5:
            events.append({
                "type": "brute_force_attempt",
                "severity": "high",
                "count": failed_logins,
                "description": f"Multiple failed login attempts detected ({failed_logins})"
            })
        
        # Port scans
        port_scan_indicators = ["SYN_RECV", "connection refused", "Connection reset"]
        scan_matches = sum(1 for l in lines for indicator in port_scan_indicators if indicator in l)
        if scan_matches > 10:
            events.append({
                "type": "port_scan",
                "severity": "medium",
                "count": scan_matches,
                "description": "Possible port scan detected"
            })
        
        # Privilege escalation attempts
        if any("sudo" in l and "incorrect password" in l for l in lines):
            events.append({
                "type": "privilege_escalation",
                "severity": "high",
                "description": "Failed sudo attempts detected"
            })
        
        return events
    
    def get_safety_constraints(self) -> Dict[str, Any]:
        return {
            "max_execution_time": 30,
            "max_memory_mb": 512,
            "rate_limit": {
                "requests_per_minute": 30
            }
        }
