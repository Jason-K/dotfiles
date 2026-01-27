import json
import os
import sys

# Mock env
os.environ["Z_AI_API_KEY"] = "key"

mcp_servers = {
    "zai-mcp-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@z_ai/mcp-server"],
      "env": {
        "Z_AI_API_KEY": os.environ.get("Z_AI_API_KEY", ""),
        "Z_AI_MODE": os.environ.get("Z_AI_MODE", "ZAI")
      }
    },
    "web-search-prime": {
      "type": "http",
      "url": os.environ.get("Z_WEBSEARCH_URL", "https://api.z.ai/api/mcp/web_search_prime/mcp"),
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\",\"Accept\":\"application/json, text/event-stream\"}' \"$Z_AI_API_KEY\""
    },
    "web-reader": {
      "type": "http",
      "url": "https://api.z.ai/api/mcp/web_reader/mcp",
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\",\"Accept\":\"application/json, text/event-stream\"}' \"$Z_AI_API_KEY\""
    },
    "zai-read": {
      "type": "http",
      "url": os.environ.get("Z_READ_URL", "https://api.z.ai/api/mcp/zread/mcp"),
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\",\"Accept\":\"application/json, text/event-stream\"}' \"$Z_AI_API_KEY\""
    },
    "context7-mcp": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\"}' \"$CONTEXT7_API_KEY\""
    }
}

print("Syntax OK")
