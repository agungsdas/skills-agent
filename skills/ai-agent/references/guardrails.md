# Guardrails

## Input Guardrails (before AI processing)

Checked at beginning of `engine.chat()`. If blocked, returns immediately without calling LLM.

### Types:
1. **Prompt injection** — regex patterns detecting manipulation attempts
2. **Competitor hospitals** — block questions about other RS (Siloam, Hermina, etc.)
3. **Off-topic** — politics, religion, gambling, drugs, self-harm
4. **Message length** — too long (>5000 chars) or too short (<2 chars)

### Adding new input guardrail:

Edit `engine/app/agents/guardrails.py`:

```python
# Add to pattern list
COMPETITOR_PATTERNS = [
    r"\b(siloam|hermina|...)\b",
    r"\b(new_competitor)\b",  # ← add here
]

# Or add new check in check_input_guardrails():
def check_input_guardrails(message: str) -> GuardrailResult:
    # ...existing checks...
    
    # New check
    if some_condition(message):
        return GuardrailResult(passed=False, reason="my_reason", action="block")
```

### Response messages:

```python
BLOCKED_RESPONSES = {
    "prompt_injection_detected": "Maaf, saya tidak bisa...",
    "competitor_hospital": "Maaf, saya hanya melayani Mitra Keluarga...",
    "my_reason": "Custom response here",  # ← add
}
```

## Output Guardrails (before sending to user)

Checked after LLM generates response, before returning.

### Types:
1. **Internal info leak** — system prompt, API keys, passwords
2. **Medical advice** — diagnoses, prescriptions
3. **Guarantees** — "pasti sembuh", "100% berhasil"
4. **Response length** — flag if >3000 chars (don't block, just flag)

### Actions:
- `block` — replace response with safe message
- `flag` — log warning but still send response

## PII Masking (for logs/traces)

Before saving to trace, PII is masked:
- KTP numbers (16 digits) → `[KTP_MASKED]`
- Credit cards → `[CREDIT_CARD_MASKED]`
- Emails → `[EMAIL_MASKED]`

Only in logs — original message still processed by LLM.

## Guardrails Config

`configs/guardrails.yaml` — declarative config (not fully used yet, code-first approach):
```yaml
input:
  block_injection: true
  block_competitors: true
  max_message_length: 5000

output:
  block_medical_advice: true
  block_guarantees: true
```
