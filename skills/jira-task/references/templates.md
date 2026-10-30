# Subtask templates

Use these patterns. Skip any type the story does not need.

Every subtask uses Type `Subtask` and **1, 2, or 3** points. Look up the fixed value in the catalogs:

- [catalog-frontend.md](catalog-frontend.md)
- [catalog-backend.md](catalog-backend.md)
- [catalog-integrations.md](catalog-integrations.md)
- [catalog-vendors.md](catalog-vendors.md)

## Description (every subtask)

```markdown
## Scope
- What to build
- Where (module/screen/endpoint)

## Out of scope
- What this subtask must not include

## Acceptance criteria
- [ ] Testable criterion 1
- [ ] Testable criterion 2

## Notes
- Design / API / dependency if applicable
```

---

## Frontend

Order: UI → Functionality → API → Tests

### UI

**Summary:** `Add [Component/Screen] UI`

Look up fixed points in the frontend UI catalog. Common values:

| Pattern | Points |
| --- | ---: |
| Add component / modal / dropdown / empty / loading / error / responsive UI | 1 |
| Add page / form / table/list / navigation / detail page UI | 2 |
| Add dashboard UI | 3 |

Scope: layout, components, styling, responsive behavior, visual states, design implementation.

Out of scope: business logic, API calls, state management, form submission.

If the UI is larger than the matching catalog row (max 3), split by screen or section.

### Functionality

**Summary:** `Add [feature] functionality`

Look up fixed points in the frontend functionality catalog (1–3). Examples: form validation = 2, sorting = 1, state management / permissions / file upload / auth / optimistic update = 3.

Scope: client-side logic, state, events, validation, calculations, conditional behavior.

Out of scope: API integration.

### API connection

**Summary:** `Connect [resource] API`

Look up fixed points in the frontend API connection catalog (1–3). Examples: delete/details = 1, list/create/update/search/filter/upload = 2, authentication/payment/messaging = 3.

Scope: request/response, loading/success/error, wiring to existing UI/state.

Out of scope: backend implementation.

### Tests

**Summary:** `Add [feature] tests` / `Add [feature] unit tests` / `Add [feature] component tests` / `Add [feature] integration tests` / `Add [feature] E2E tests`

| Type | Points |
| --- | ---: |
| Unit tests | 2 |
| Component tests | 2 |
| Integration tests | 3 |
| E2E tests | 3 |

---

## Backend

Order: Database / DTO (if needed) → Functionality → API → Tests

### Database

**Summary:** `Add [entity] database model` / `Add [entity] database migration` / related DB rows

Look up [catalog-backend.md](catalog-backend.md) Database Tasks (model = 3, migration = 2, etc.).

### DTO & validation

**Summary:** `Add [resource] DTO` / `Add [resource] DTO validation` / `Add [resource] request validation` / etc.

Look up DTO & Validation Tasks (DTO = 1; validation/transformation = 2).

### Functionality

**Summary:** `Add [feature] functionality`

Look up Service & Business Logic (service = 2; business logic / permission / auth / authz / caching / background job / queue = 3; logging = 1).

Scope: service/business logic, models, repositories, error handling as matched by the catalog row.

Out of scope: controller/route implementation in the same subtask when you are also creating an API subtask.

### API implementation

**Summary:** `Implement [resource] API`

Look up API Tasks (most CRUD = 2; search / upload / authentication / webhook = 3).

Scope: route, HTTP method, request/response wiring, calling the service, controller error handling.

Out of scope: underlying business logic (that belongs in functionality).

Never use `Connect [X] API` for backend work.

### Tests

**Summary:** `Add [feature] unit tests` / `Add [feature] service unit tests` / `Add [feature] validation tests` / `Add [feature] API integration tests` / `Add [feature] database tests`

| Type | Points |
| --- | ---: |
| Unit tests / service unit tests / validation tests | 2 |
| API integration tests / database tests | 3 |

---

## Integrations

Only create the steps the story needs. Prefer vendor rows in [catalog-vendors.md](catalog-vendors.md) when the story names the vendor.

### Setup

**Summary:** `Add [service] integration` / `Add [service] SDK/package`

Typical: SDK/package = 1; integration = 1–2 per catalog.

Scope: SDK/package, env vars, client configuration. Not the full business workflow.

### Configure

**Summary:** `Configure [service] dashboard/settings` / `Configure [service] [setting]`

Look up Integration Setup and Generic Dashboard & Configuration in [catalog-integrations.md](catalog-integrations.md), or vendor-specific configure rows.

Include these when work requires configuration outside the codebase.

### Workflow

**Summary:** `Add [service] [workflow] functionality`

Typical: third-party workflow / business logic = 3; error handling / event handling = 2; data sync = 3.

### API

**Summary:** `Implement [service] [operation] API`

Typical: implement third-party API = 2; vendor payment/messaging APIs often = 3.

### Webhook

**Summary:** `Implement [service] [event] webhook` / `Configure [service] webhook`

| Kind | Typical pts |
| --- | ---: |
| Configure webhook | 1–2 |
| Implement webhook | 3 |
| Signature validation / event handling / error handling | 2 |
| Event parsing | 1 |
| Webhook tests | 3 |

Scope for implement: endpoint, signature verification, parse/validate, hand off to app handling.

Split independent events into separate subtasks.

### Event handling

**Summary:** `Add [service] [event] handling functionality`

Typical: 2. Use when webhook infrastructure already exists.

### Frontend third-party

**Summary:** `Connect [service] [feature]`

Typical: Connect third-party API = 2; Connect Stripe payment / messaging = 3.

Scope: frontend SDK usage, wiring existing UI, loading/error/success. Not backend work.

### Integration tests

**Summary:** `Add [service] integration tests`

Typical: 3 (notification tests = 2 per Knock catalog).

---

## Mobile

Order: UI → Functionality → API → Tests

### UI

**Summary:** `Add [Screen] UI`

Use frontend UI catalog points when the screen type matches (component = 1, page/form = 2, dashboard = 3).

### Functionality

**Summary:** `Add [feature] functionality`

Use frontend functionality catalog when it matches.

### Native (non-catalog)

**Summary:** `Add [feature] native functionality`
**Points:** 1–2 (default 1; 2 if clearly moderate)

Use for permissions, push, deep links, offline, device APIs.

### API / tests

Same as frontend: `Connect [resource] API`, `Add [feature] tests` with catalog points.

---

## Other work types

| Type | Summary | Points | Notes |
| --- | --- | --- | --- |
| Bug | `Fix [issue]` | Catalog: Fix UI bug = 1, Fix functional bug = 2, Fix backend bug = 2 | Investigate first only if cause is unknown |
| Spike | `Investigate [topic]` | 1 | Timeboxed. No implementation in the same ticket |
| QA / regression | `Add [feature] regression tests` / `Add [feature] E2E tests` | 2–3 | Last; E2E = 3 |
| Migration | `Add [entity] migration` / `Add database migration` | 2 | Before API if schema must change first; model = 3 if separate |
| Backfill | `Add [entity] backfill` | 1–2 (non-catalog) | After migration |
| Worker / job | `Add [job] worker functionality` / background job | 3 | After service logic |
| CI | `Update [pipeline] CI` | 1–2 (non-catalog) | Standalone |
| Config | `Add [env] configuration` / `Configure …` | 1–2 | Prefer catalog configure rows |
| Docs | `Add [feature] documentation` | FE docs = 1; API docs = 2 | Last |
| Analytics | `Add analytics tracking` / `Connect [event] analytics` | 1 | After functionality |
| Accessibility | `Add [screen] accessibility` | 1 (non-catalog) | After UI |
| i18n | `Add [feature] translations` | 1 (non-catalog) | After UI |
| Refactor | `Refactor [area]` | Component/service = 2; module = 3 | No behavior change mixed with features |
