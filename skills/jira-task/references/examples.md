# Breakdown examples

Catalog tables are canonical. When these examples and a catalog row disagree, use the catalog.

## Do not over-split

Keep as one subtask:

| Summary | Points |
| --- | ---: |
| Fix login button color | 1 |
| Update environment variable for maps token | 1 |
| Add empty-state copy | 1 |

Incorrect: turning a color fix into UI + functionality + API tickets.
Incorrect: creating extra subtasks only to increase story points.

---

## Frontend

**Story:** User can filter products by category
**Parent points:** 8

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add filter dropdown UI | Subtask | 1 |
| 2 | Add active filter tag UI | Subtask | 1 |
| 3 | Add filter functionality | Subtask | 2 |
| 4 | Connect product filter API | Subtask | 2 |
| 5 | Add product filter unit tests | Subtask | 2 |

Catalog matches: `Add dropdown/select UI` = 1, `Add filter functionality` = 2, `Connect filter API` = 2, `Add unit tests` = 2.

Incorrect: `Add filter UI, validation, and connect filter API`

---

## Backend

**Story:** Admin can create catalog items
**Parent points:** 8

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add create item request validation | Subtask | 2 |
| 2 | Add create item service functionality | Subtask | 2 |
| 3 | Implement create item API | Subtask | 2 |
| 4 | Add create item unit tests | Subtask | 2 |

Catalog matches: `Add request validation` = 2, `Add service functionality` = 2, `Implement create API` = 2, `Add unit tests` = 2. If API integration tests are required, add `Add API integration tests` = 3 as its own subtask.

Incorrect: `Implement create item API with validation and database logic`

---

## Integration — payment (Stripe)

**Story:** Customer can purchase credits using Stripe
**Parent points:** 31

### Frontend

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add payment UI | Subtask | 1 |
| 2 | Add payment validation functionality | Subtask | 2 |
| 3 | Connect Stripe payment | Subtask | 3 |
| 4 | Add payment error handling functionality | Subtask | 2 |
| 5 | Add payment unit tests | Subtask | 2 |

### Backend

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 6 | Add payment request validation | Subtask | 2 |
| 7 | Add Stripe payment functionality | Subtask | 3 |
| 8 | Implement Stripe payment API | Subtask | 3 |
| 9 | Implement Stripe webhook | Subtask | 3 |
| 10 | Add Stripe webhook handling functionality | Subtask | 2 |
| 11 | Add Stripe payment tests | Subtask | 3 |

### Configuration

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 12 | Configure Stripe products/prices | Subtask | 2 |
| 13 | Configure Stripe webhook | Subtask | 1 |
| 14 | Configure Stripe production environment | Subtask | 2 |

Points follow [catalog-vendors.md](catalog-vendors.md) and frontend/backend catalogs (catalog wins over illustrative process examples).

Skip setup (`Add Stripe integration` = 1) if the SDK is already in the project.
Skip webhook tickets if there are no inbound events.

Incorrect: `Implement complete payment integration` as one ticket.

---

## Integration — invoice + notification

**Story:** Create an invoice after successful payment and notify the customer
**Parent points:** 23

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add payment success event handling | Subtask | 2 |
| 2 | Add invoice creation functionality | Subtask | 3 |
| 3 | Implement Zoho Books invoice API | Subtask | 3 |
| 4 | Add invoice synchronization functionality | Subtask | 3 |
| 5 | Add notification workflow functionality | Subtask | 3 |
| 6 | Implement notification API | Subtask | 2 |
| 7 | Add Zoho Books integration tests | Subtask | 3 |
| 8 | Configure invoice settings | Subtask | 2 |
| 9 | Configure Knock notification workflow | Subtask | 2 |

Catalog-aligned naming from [catalog-vendors.md](catalog-vendors.md).

---

## Mobile

**Story:** User can view overdue items
**Parent points:** 6

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add overdue items section UI | Subtask | 1 |
| 2 | Add overdue items list functionality | Subtask | 1 |
| 3 | Connect overdue items API | Subtask | 2 |
| 4 | Add overdue items unit tests | Subtask | 2 |

---

## Mobile native

**Story:** User can enable push notifications
**Parent points:** 7

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add notification permission UI | Subtask | 1 |
| 2 | Add push notification native functionality | Subtask | 2 |
| 3 | Connect notification token API | Subtask | 2 |
| 4 | Add notification permission unit tests | Subtask | 2 |

Native functionality is a non-catalog extension (1–2).

---

## Bug

**Story:** Search results ignore the selected sort order
**Parent points:** 3

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Investigate search sort order | Subtask | 1 |
| 2 | Fix search sort order | Subtask | 2 |

If the cause is already known, skip investigate. Match maintenance rows when possible (`Fix UI bug` = 1, `Fix functional bug` = 2, `Fix backend bug` = 2).

---

## Spike

**Story:** Decide how to store uploaded files
**Parent points:** 1

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Investigate file storage options | Subtask | 1 |

Do not add implementation tickets until the spike is done.

---

## Data + API

**Story:** Add archived flag to products
**Parent points:** 8

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add product archived database migration | Subtask | 2 |
| 2 | Add product archive service functionality | Subtask | 2 |
| 3 | Implement archive product API | Subtask | 2 |
| 4 | Add product archive unit tests | Subtask | 2 |

If a new model is required (not just a column migration), use `Add database model` = 3 instead of or in addition to migration = 2. If API integration tests are required, add that subtask at 3.

---

## DevOps / docs / analytics

**Story:** Track checkout started events
**Parent points:** 2

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Add analytics tracking | Subtask | 1 |
| 2 | Add checkout analytics documentation | Subtask | 1 |

**Story:** Run tests on pull requests
**Parent points:** 2

| # | Summary | Type | Points |
| --- | --- | --- | ---: |
| 1 | Update test pipeline CI | Subtask | 2 |

CI is a non-catalog extension (1–2).

---

## Separation of concerns

### Incorrect

Implement Stripe payment with UI, backend API, webhook, and tests

### Correct

| Summary | Points |
| --- | ---: |
| Add payment UI | 1 |
| Connect Stripe payment | 3 |
| Add Stripe payment functionality | 3 |
| Implement Stripe payment API | 3 |
| Implement Stripe webhook | 3 |
| Add Stripe webhook handling functionality | 2 |
| Add Stripe payment tests | 3 |
| Configure Stripe dashboard | 2 |
| Configure Stripe webhook | 1 |
