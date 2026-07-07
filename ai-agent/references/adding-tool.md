# Adding New Tool

## All tools are Python functions with @tool decorator

NO YAML tools. All registered in `engine/app/tools/tool_registry.py`.

## Step 1: Create Tool Function

```python
# engine/app/tools/my_tools.py
import os
import httpx
from langchain_core.tools import tool


@tool
def my_new_tool(param1: str, param2: int = 10) -> str:
    """Deskripsi yang jelas untuk LLM — kapan tool ini digunakan.
    
    Args:
        param1: Penjelasan parameter 1
        param2: Penjelasan parameter 2 (default 10)
    """
    # Implementation
    try:
        # Example: call external API
        resp = httpx.get(f"https://api.example.com/data?q={param1}", timeout=10)
        resp.raise_for_status()
        data = resp.json()
        
        # Return PLAIN TEXT (not markdown) — LLM will format
        return f"Found {len(data)} results: ..."
    except Exception as e:
        return f"Error: {str(e)}"
```

## Step 2: Register in Tool Registry

```python
# engine/app/tools/tool_registry.py
_TOOL_MAP = {
    ...existing tools...
    "my_new_tool": "app.tools.my_tools:my_new_tool",
}
```

## Step 3: Assign to Specialist

```yaml
# configs/agent.yaml
specialists:
  - name: relevant_specialist
    tools:
      - my_new_tool
```

## Step 4: Test

```bash
curl -X POST http://localhost:8000/chat \
  -d '{"session_id":"test","message":"something that triggers the tool"}'
```

Check trace → should see `type: "tool_call"` with your tool name.

## Rules

1. **Return plain text** — never return markdown. LLM formats per output_format.
2. **Error handling** — always try/except, return error message string (don't raise).
3. **No hardcoded IDs** — fetch from API or Qdrant dynamically.
4. **Timeout** — always set explicit timeout on HTTP calls.
5. **Credentials from env** — use `os.getenv("VARIABLE")`.
6. **Docstring is critical** — LLM decides WHEN to call based on description.
7. **Args description** — LLM uses these to determine WHAT to pass.

## Tool Categories

| Category | File | Auth | Example |
|----------|------|------|---------|
| Partner API | `mika_partner_tools.py` | Token + Basic | find_user, create_user |
| Enriched (API+Qdrant) | `clinic_tools.py` | Public API + Qdrant | list_clinics_by_city |
| Internal (Go API) | `conversation.py` | X-Internal-Key | get_conversation_history |
| Ticketing | `mika_partner_tools.py` | Bearer token | create_ticket |

## Auth Patterns for Tools

### MIKA Partner API (token + basic auth):
```python
def _partner_headers():
    return {
        "token": os.getenv("MIKA_ACCESS_TOKEN", ""),
        "Authorization": f"Basic {os.getenv('MIKA_BASIC_AUTH', '')}",
    }
```

### Public API (no auth):
```python
headers = {"x-platform": "apps", "x-app-channel": "web", "content-language": "id"}
```

### Go Internal API:
```python
headers = {"X-Internal-Key": os.getenv("INTERNAL_API_KEY", "")}
```
