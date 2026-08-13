# UX/UI Guidelines

## Template

```markdown
## UX/UI Guidelines

### Design Principles

1. **Clarity over cleverness** — User harus langsung paham tanpa perlu tutorial
2. **Consistency** — Pattern yang sama untuk aksi yang sama di seluruh aplikasi
3. **Feedback** — Setiap aksi user harus ada feedback (loading, success, error)
4. **Progressive disclosure** — Tampilkan yang penting dulu, detail di-expand

### Wireframe References

| Screen | Wireframe Link | Status |
|--------|----------------|--------|
| [Screen 1] | [Figma/link] | Draft / Approved |
| [Screen 2] | [Figma/link] | Draft / Approved |

### User Flow Diagram

```
[Start] → [Screen A] → [Action] → [Screen B]
                ↓ (error)
           [Error State] → [Retry] → [Screen A]
```

### Interaction Patterns

| Interaction | Pattern | Detail |
|-------------|---------|--------|
| Create | Modal / Full page | [Kapan pakai modal vs full page] |
| Edit | Inline / Modal | [Kapan pakai inline vs modal] |
| Delete | Confirmation dialog | [Selalu confirm sebelum delete] |
| Loading | Skeleton / Spinner | [Skeleton untuk content, spinner untuk action] |
| Empty State | Illustration + CTA | [Selalu ada call-to-action di empty state] |
| Error | Inline message / Toast | [Inline untuk form, toast untuk action] |
| Success | Toast notification | [Auto-dismiss setelah 3 detik] |

### Responsive Behavior

| Breakpoint | Layout | Navigation |
|------------|--------|------------|
| Desktop (≥992px) | Sidebar fixed + content | Full sidebar |
| Tablet (576-991px) | Sidebar collapsible | Hamburger menu |
| Mobile (<576px) | Single column | Bottom nav / drawer |

### Accessibility Notes

- Tab order harus logical (top-to-bottom, left-to-right)
- Focus trap di modal/dialog
- Escape key untuk close modal
- Loading states announced ke screen reader
- Color bukan satu-satunya indicator (tambah icon/text)
```

## Rules

1. Wireframe link HARUS ada — jika belum ada, status "Pending Design"
2. User flow diagram minimal untuk happy path + 1 error path
3. Interaction patterns harus konsisten di seluruh aplikasi
4. Responsive behavior WAJIB didefinisikan untuk 3 breakpoint minimum
5. Accessibility notes bukan opsional — minimal keyboard nav + screen reader
6. Section ini BUKAN design spec detail — cukup guidelines dan principles
