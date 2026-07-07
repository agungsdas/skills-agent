# Adding New Knowledge Source

## Two Types

### 1. Static Knowledge (Markdown)

For rarely-changing content (FAQ, policies, troubleshooting guides).

```bash
# Create category directory
mkdir -p knowledge/new_category/

# Write content (chunked by ## headers)
cat > knowledge/new_category/topic.md << 'EOF'
# Topic Title

## Section 1
Content that will become a searchable chunk.

## Section 2
Another chunk. Keep sections 200-500 chars for best retrieval.
EOF

# Ingest to Qdrant
make ingest
```

RAG retriever auto-searches `knowledge` collection.

### 2. API Sync Knowledge (Dynamic)

For data that changes regularly and comes from external APIs.

#### Step 1: Add sync method

Edit `engine/app/services/knowledge_sync.py` (or create new file):

```python
COLLECTION_NAME = "new_collection"

def sync_new_source(self) -> dict:
    """Sync from external API to Qdrant."""
    print("🔄 Starting new source sync...")
    
    client = QdrantClient(url=self.qdrant_url)
    embeddings = get_embeddings()
    
    # Recreate collection
    collections = [c.name for c in client.get_collections().collections]
    if COLLECTION_NAME not in collections:
        client.create_collection(...)
    else:
        client.delete_collection(COLLECTION_NAME)
        client.create_collection(...)
    
    # Fetch data from API
    data = self._fetch_from_api()
    
    # Format + embed + store
    points = []
    for item in data:
        chunk = self._format_item(item)  # Plain text
        vector = embeddings.embed_query(chunk)
        points.append(PointStruct(
            id=point_id,
            vector=vector,
            payload={"content": chunk, "type": "xxx", "source": "api_sync"},
        ))
    
    client.upsert(collection_name=COLLECTION_NAME, points=points)
    self._update_sync_status(COLLECTION_NAME, True, len(points), duration)
```

#### Step 2: Add to retriever

Edit `engine/app/rag/retriever.py`:

```python
# Add search for new collection
try:
    new_results = client.query_points(
        collection_name="new_collection",
        query=query_vector,
        limit=top_k,
        score_threshold=score_threshold,
    ).points
    all_results.extend(new_results)
except Exception:
    pass
```

#### Step 3: Add API endpoint + cron

```python
# engine/app/main.py
@app.post("/sync/new-source")
async def sync_new_source():
    result = knowledge_sync_service.sync_new_source()
    return result
```

Add to `sync_all()` and daily cron (05:00 WIB).

#### Step 4: Update sync status

Status auto-tracked in MongoDB `sync_status` collection via `_update_sync_status()`.

## Chunk Best Practices

- Keep chunks 200-500 characters for best embedding relevance
- Include enough context in each chunk to be self-contained
- Use ## headers as natural chunk boundaries (for markdown)
- For API data: format as structured plain text, not markdown
- Include metadata in payload (type, source, city, category, etc.)

## Score Threshold

Default: 0.40 (in `specialist.py`). Lower = more results but possibly less relevant.
Adjust per specialist if needed.
