# Story point guide

Story points are relative engineering effort and complexity, not hours, seniority, or deadlines.

## Scale

| Points | Meaning |
| --- | --- |
| **1** | Small and straightforward — single/simple responsibility, few conditions, minimal dependencies |
| **2** | Moderate — multiple implementation steps, moderate business rules, dependencies or integration |
| **3** | Complex — multiple interacting conditions, complex business logic, multiple integration points, significant edge cases, or high testing complexity |

Maximum **3 points per subtask**. If work needs more than 3, split into separate responsibilities. Do not raise the fixed catalog value.

Each generic task in the catalogs has **one standard fixed point value**. Use that value consistently across projects and developers.

Do not increase points because a developer is new to the project.
Do not decrease points because a developer is experienced.
Do not estimate from deadlines or client importance.

## Catalogs (canonical fixed points)

When a subtask matches a named row, use that fixed value — do not re-judge 1 vs 2 vs 3.

| Area | File |
| --- | --- |
| Frontend | [catalog-frontend.md](catalog-frontend.md) |
| Backend | [catalog-backend.md](catalog-backend.md) |
| Third-party setup, workflow, webhooks, generic config | [catalog-integrations.md](catalog-integrations.md) |
| Stripe, Zoho, Knock, messaging, email, and other vendors | [catalog-vendors.md](catalog-vendors.md) |

If a task does not clearly match an existing standard, the Project Coordinator/PM and relevant technical lead should agree on a fixed point value for that task type. Recurring task types should reuse the same fixed value.

Non-catalog skill extensions (mobile native, accessibility, i18n, CI, backfill): default **1**; use **2** only when clearly moderate. Never assign more than 3.

## Quick reference

### 1 Point

- Simple UI (component, modal, empty/loading/error state, responsive)
- Small functionality (sorting, conditional rendering)
- Simple API connect (delete, details)
- Basic configuration, credentials, sandbox env
- Simple bug fix (UI bug)
- Simple docs / analytics / dependency bump

### 2 Points

- Moderate UI (page, form, table/list, navigation, detail page)
- Moderate functionality and API integration
- Moderate business logic / third-party workflow pieces
- Webhook handling / event handling (when catalog says 2)
- Unit and component tests
- Moderate refactoring

### 3 Points

- Complex UI (dashboard)
- Complex functionality (state management, permissions, file upload, auth, optimistic updates)
- Complex API (search, upload, auth, webhook implementation)
- Payment / messaging / complex third-party workflows
- Integration and E2E tests
- Significant performance optimization

## Parent stories

- Parent points = sum of subtask points, or leave parent unestimated.
- Do not inflate the parent independently of the breakdown.

## Estimation hygiene

- **Not hours** — points are relative complexity and effort, not a direct productivity score for individuals.
- **Team capacity** — use historical completed points for team-level sprint capacity; do not assign fixed point targets to individual developers.
- **Spike** — if feasibility, architecture, requirements, or third-party behavior is unknown, create a separate `Investigate [topic]` spike (1) instead of inflating implementation points.
- **Subtask creation** — create a subtask only when it is a distinct responsibility with clear ownership or meaningful tracking value. Do not create artificial subtasks only to increase story points.
- **Calibration** — periodically review completed work for inconsistent estimates. When similar work is repeatedly estimated differently, update the standard and apply it going forward.
