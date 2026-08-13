# Adding New Specialist

## Step 1: Add Intent to Router

Edit `configs/agent.yaml`:

```yaml
routing:
  intents:
    - booking
    - doctor_info
    - facility
    - coe
    - billing
    - technical
    - general
    - complaint
    - new_intent    # ← tambah di sini
  router_prompt_override: |
    Klasifikasi pesan pelanggan ke salah satu intent:
    - booking: mau booking, buat janji...
    - new_intent: keywords yang trigger intent ini
    
    Respond JSON: {"intent": "...", "confidence": 0.0-1.0}
```

## Step 2: Create Specialist Config

```yaml
specialists:
  - name: new_intent
    model_override: gpt-4o-mini    # atau gpt-4o untuk complex tasks
    system_prompt: |
      Kamu adalah specialist untuk X di Mitra Keluarga.
      
      Yang bisa kamu bantu:
      - ...
      
      Rules:
      - Jawab berdasarkan CONTEXT (dari knowledge base)
      - Gunakan tools jika butuh data real-time
      - Format sesuai output_format instruction
    knowledge_categories:
      - general                    # RAG categories to search
    tools:
      - tool_name_1               # Tools dari tool_registry
      - tool_name_2
```

## Step 3: Add Knowledge (optional)

Kalau specialist butuh knowledge base:

### Static (markdown):
```bash
mkdir -p knowledge/new_category/
echo "# Topic" > knowledge/new_category/info.md
make ingest
```

### API sync:
Tambah sync method di `engine/app/services/knowledge_sync.py` dan collection baru di retriever.

## Step 4: Add Tools (optional)

Lihat `references/adding-tool.md`.

## Step 5: Test

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test-01","message":"pesan yang trigger intent baru"}'
```

Verify:
- `intent` = "new_intent"
- `confidence` >= 0.7
- Response sesuai specialist prompt

## Tips

- Start dengan `gpt-4o-mini` (murah, fast) — upgrade ke `gpt-4o` kalau kurang akurat
- Knowledge categories filter RAG results — pakai category yang relevan
- System prompt harus JELAS dan SPECIFIC — LLM ikut instruksi literal
- Gunakan `tools: []` kalau specialist cuma butuh RAG (no API calls)
