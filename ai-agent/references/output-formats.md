# Output Formats

## Three Formats

| Format | Channel | Characteristics |
|--------|---------|----------------|
| `MARKDOWN` | Web chat, dashboard | `**bold**`, `##` headings, tables, code blocks |
| `WHATSAPP` | WhatsApp | `*bold*` (single asterisk), emoji, no headings, mobile-friendly |
| `TEXT_ONLY` | SMS, plain terminal | Zero formatting, no special characters |

## How It Works

1. Client sends `output_format` in request
2. Go gateway passes to engine
3. Engine injects format instruction into specialist system prompt
4. LLM follows format instruction when generating response

## Format Instructions (in specialist prompt)

```python
FORMAT_INSTRUCTIONS = {
    "TEXT_ONLY": "Jawab dalam plain text tanpa formatting apapun...",
    "WHATSAPP": "Format untuk WhatsApp. Gunakan *bold* (satu asterisk), emoji...",
    "MARKDOWN": "Format dalam Markdown standar. Gunakan **bold**, heading, tables...",
}
```

## Adding New Format

1. Add to `FORMAT_INSTRUCTIONS` dict in `engine/app/agents/specialist.py`
2. Add to `SPECIALIST_PROMPT_TEMPLATE` (already uses `{format_instruction}`)
3. Document in API

## WhatsApp Specifics

- Bold: `*text*` (NOT `**text**`)
- Italic: `_text_`
- NO headings (#, ##, ###)
- NO tables
- NO code blocks
- Emoji for visual markers (📍🏥👨‍⚕️📅✅)
- Short paragraphs (mobile readability)

## Default

If not specified, defaults to `MARKDOWN`.
