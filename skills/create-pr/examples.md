# Create PR examples

## Good — single PR

**Title:** `feat(payment): persist review session client secret (EG-2401)`

**Body:**

```markdown
## Summary
- Keep Stripe client secret across Review & Pay remounts so customers are not charged twice
- Scope storage to haul + amount fingerprint

## Jira
- Key: EG-2401
- Link: https://your-domain.atlassian.net/browse/EG-2401

## Test plan
- [ ] Open Review & Pay, leave, return — same PaymentIntent
- [ ] Change haul total — new session created
- [ ] Unit tests for session read/write pass

## Size
- Changed lines vs main: 142 (budget 200)
```

## Good — stacked tip (full stack work report)

**Title:** `feat(payment): wire review panel to session storage (EG-2401)`

**Body (on the tip PR only):**

```markdown
## Summary
- End-to-end Review & Pay session continuity so remounts do not create duplicate PaymentIntents

## Jira
- Key: EG-2401
- Link: https://your-domain.atlassian.net/browse/EG-2401

## Stack work report
Full report for the entire stack. Reviewers should not need to open lower PRs.

### Layer 1 — feat(payment): add reviewPaymentSession util (#101)
- Pure session read/write + fingerprint helpers
- Review notes: no Stripe calls in util; unit-tested
- Risks: none

### Layer 2 (tip) — feat(payment): wire review panel to session storage (#102)
- ReviewPaymentPanel + PaymentForm use session; remount reuse
- Review notes: clear session on amount change
- Risks: ensure fingerprint includes haul id + amount

## Test plan
- [ ] Layer 1 unit tests pass
- [ ] Remount Review & Pay — same client secret
- [ ] Change amount — new session
- [ ] Pay succeeds once

## Size
- This PR vs its base: 95 (budget 200)
```

When Layer 3 is added later: put the **rewritten** full report (Layers 1–3) on the new tip; on #102 leave only a short note that the stack report moved to the new tip.

## Bad

**Title:** `Update payment stuff` — not Conventional Commits, no Jira key

**Title:** `feat(payment): persist review session client secret and also refactor checkout provider and update docs (EG-2401)` — too long / multi-concern (likely over size budget)

**Body missing Jira / Size** — breaks traceability and DORA preflight visibility

**Opening at 340 lines** — violates hard gate; split before `gh pr create`

**Stack report only on a middle PR after a new tip exists** — reviewers miss the tip; rewrite the full report on the new tip
