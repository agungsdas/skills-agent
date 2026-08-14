---
inclusion: always
---

# Diagram Rules

## Rules

1. **DILARANG pakai ASCII art untuk diagram** — tidak boleh pakai box-drawing characters (`┌─┐│└┘`), ASCII arrows (`│▼├└→`), atau text-based diagram apapun.
2. **WAJIB pakai Mermaid** untuk semua diagram: architecture, flow, sequence, ERD, state, dll.
3. Format Mermaid yang tersedia:
   - `graph TB` / `graph LR` — architecture, component, flow
   - `sequenceDiagram` — interaction antar service/component
   - `erDiagram` — data model / entity relationship
   - `stateDiagram-v2` — state machine / workflow status
   - `flowchart TD` — decision tree, process flow
4. **File tree structure tetap boleh pakai `├──` format** — ini bukan diagram, ini listing.
5. **Inline flow satu baris tetap boleh** (contoh: `A → B → C`) — ini bukan diagram, ini shorthand.
6. Rule ini berlaku untuk semua output: ERD, PRD, SKILL.md, references, dan dokumentasi apapun.
