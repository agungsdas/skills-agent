# Testing Strategy

## Template

```markdown
## Testing Strategy

### Test Pyramid

```
        /  E2E  \          ← Few, slow, expensive
       / Integration \      ← Moderate amount
      /    Unit Tests   \   ← Many, fast, cheap
```

### Test Types & Coverage

| Test Type | Scope | Coverage Target | Tools | Run When |
|-----------|-------|-----------------|-------|----------|
| Unit Tests | Functions, utils, helpers | > [X]% | [Jest/Vitest/Go test] | Every commit |
| Integration Tests | API endpoints, DB queries | > [X]% | [Supertest/httptest] | Every PR |
| E2E Tests | Critical user flows | Top [N] flows | [Playwright/Cypress] | Pre-release |
| Performance Tests | API response time, load | Key endpoints | [k6/Artillery] | Pre-release |
| Security Tests | Auth, injection, XSS | All endpoints | [OWASP ZAP] | Weekly |

### Unit Test Plan

| Module | What to Test | Priority |
|--------|-------------|----------|
| [Utils/Helpers] | Pure functions, edge cases | High |
| [Validators] | Input validation rules | High |
| [Business Logic] | Usecase/service methods | High |
| [Data Transformers] | Entity ↔ Model conversion | Medium |

### Integration Test Plan

| Endpoint | Test Cases | Priority |
|----------|-----------|----------|
| POST /api/[resource] | Create success, validation error, auth error, duplicate | High |
| GET /api/[resource] | List with pagination, filter, empty result | High |
| GET /api/[resource]/[id] | Found, not found, no permission | High |
| PUT /api/[resource]/[id] | Update success, partial update, not found, no permission | Medium |
| DELETE /api/[resource]/[id] | Delete success, not found, no permission, cascade check | Medium |

### E2E Test Plan — Critical Flows

| Flow | Steps | Priority |
|------|-------|----------|
| User Login | Open login → Enter credentials → Redirect to dashboard | P0 |
| Create Document | Navigate to workspace → New doc → Edit → Save | P0 |
| Share Document | Open doc → Share → Select user → Set permission | P1 |
| Search | Ctrl+K → Type query → Click result → Navigate | P1 |

### Test Data Strategy

| Environment | Data Source | Reset Frequency |
|-------------|------------|-----------------|
| Unit Tests | Mocked/fixtures | Every test run |
| Integration Tests | Test database (seeded) | Every test suite |
| E2E Tests | Staging database (seeded) | Daily |
| Performance Tests | Production-like dataset | Per test run |

### Test Environment

| Environment | Database | External Services | Purpose |
|-------------|----------|-------------------|---------|
| Local | MongoDB (Docker) | Mocked | Development |
| CI | MongoDB (Docker) | Mocked | Automated tests |
| Staging | MongoDB (dedicated) | Real (sandbox) | Pre-release validation |
```

## Rules

1. Unit test coverage target HARUS didefinisikan — minimal 70% untuk business logic
2. Integration tests WAJIB untuk setiap API endpoint — happy path + error cases
3. E2E tests fokus pada critical user flows — jangan test everything E2E
4. Test data harus reproducible — gunakan seed scripts atau fixtures
5. Performance tests harus run dengan production-like data volume
6. Security tests minimal quarterly — lebih sering untuk fitur auth-related
7. CI/CD harus block merge jika tests fail
8. Test environment harus terisolasi — jangan share database antar test suites
