---
inclusion: always
---

# Git Conventions

## Commit Message

Format: **Conventional Commits**

```
<type>(<scope>): <subject>
```

### Types

| Type | Kapan |
|------|-------|
| `feat` | Fitur baru |
| `fix` | Bug fix |
| `refactor` | Refactor tanpa ubah behavior |
| `chore` | Maintenance (deps, config, tooling) |
| `docs` | Dokumentasi only |
| `style` | Formatting, whitespace (bukan CSS) |
| `test` | Tambah/ubah test |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |

### Rules

- Subject lowercase, tanpa titik di akhir, max 70 char
- Scope opsional, tapi direkomendasikan: `feat(auth):`, `fix(invoice):`
- Body opsional — jelaskan "why", bukan "what" (what sudah terlihat di diff)
- Breaking change: tambah `!` → `feat(api)!: remove deprecated endpoint`

### Contoh

```
feat(payment): add bulk payment processing endpoint
fix(auth): handle expired refresh token gracefully
refactor(invoice): extract PDF generation to separate service
chore(deps): bump echo to v5.1.0
```

## Branch Naming

Format: `<type>/<short-description>`

| Type | Kapan |
|------|-------|
| `feature/` | Fitur baru |
| `bugfix/` | Bug fix |
| `hotfix/` | Fix urgent di production |
| `chore/` | Maintenance, tooling |
| `release/` | Release preparation |

### Rules

- Lowercase, dash-separated: `feature/bulk-payment-export`
- Singkat tapi deskriptif — max 4-5 kata
- Kalau ada ticket/issue number, prefix: `feature/PROJ-123-bulk-payment`
- JANGAN push langsung ke `main`/`master` kecuali fix trivial (typo, config) yang sudah dikonfirmasi user

## Pull Request

### Title

- Ikuti format commit message: `feat(scope): subject`
- Max 70 karakter

### Description

Struktur minimal:

```markdown
## Summary
[1-2 kalimat apa yang berubah]

## Changes
- [bullet point perubahan utama]

## Testing
- [apa yang sudah di-test]
```

### Rules

- 1 PR = 1 concern (jangan campur fitur + refactor + fix)
- Kalau PR besar, pecah jadi smaller PRs yang bisa di-review independen
- Draft PR boleh untuk visibility — tapi jangan minta review sampai ready
- Reviewer assignment: minimal 1, idealnya yang punya context di area itu

## Merge Strategy

- **Default: Squash merge** — 1 commit per PR di main, history bersih
- **Rebase merge** — untuk PR yang commit history-nya sudah rapi dan bermakna
- **Merge commit** — hindari kecuali ada alasan spesifik (long-lived branch)

## Tagging & Release

- Semantic versioning: `v1.2.3` (major.minor.patch)
- Tag di main/master setelah deploy ke production
- Changelog otomatis dari conventional commits

