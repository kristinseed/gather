# GetGathr — Contact Import Spec
**Item CB | Beta demo moment**
Version 1.1 — May 2026

---

## What this is

The hero demo for beta. An org admin pastes their existing contact list (or uploads a CSV) and within 60 seconds sees their people in the member list and can send them an invitation. This is the "I want this" moment that converts a skeptical organizer.

The flow must be fast, forgiving, and feel magical — not like a data import tool.

---

## Scope for beta

**In scope:**
- Full-page flow (laptop-optimized)
- Paste a plain-text list (name + email, one per line or comma-separated)
- Upload a CSV
- Preview with match confidence before committing
- Confirm → creates unclaimed person + membership(invited) + invitation(token) rows
- Invitations send immediately on confirm — no queue, no second step
- Member list reflects imported contacts immediately

**Deferred (pre-launch or roadmap):**
- Excel / .xlsx upload
- Duplicate merge UI (flagged rows shown, resolution deferred)
- Re-import / update existing records
- Column mapping UI for non-standard CSVs
- Invitation send queue / scheduling (backlog)
- Mobile-optimized modal variant (item CH)

---

## Invitation sender (resolved)

All invitations send from the shared platform sender:

```
From: [Tenant name] via GetGathr <invitations@mail.getgathr.co>
```

Example for Class of 1990:
```
From: Class of 1990 via GetGathr <invitations@mail.getgathr.co>
```

This is hardcoded for beta. Per-org-group sender subdomains are roadmap item CG. Blocked on item A (Resend account + `mail.getgathr.co` DNS verification at Porkbun).

---

## User flow

### Step 1 — Entry point
Admin is on the Member Management screen. Empty state or existing list. Prominent button: **"Add members"**. Clicking opens a full-page import flow (not a modal — the preview table needs room).

### Step 2 — Input
Two tabs: **Paste a list** | **Upload CSV**

**Paste tab:**
- Large textarea with placeholder text:
  ```
  Sarah Johnson, sarah@email.com
  Mike Chen, mike.chen@gmail.com
  Tom Williams
  ```
- Helper text: "One person per line. Email optional — you can invite them later."
- Accept any of these formats per line:
  - `First Last, email@example.com`
  - `First Last <email@example.com>`
  - `email@example.com` (email only — name left blank)
  - `First Last` (name only — no email, still importable)

**CSV tab:**
- File picker, accepts .csv only for beta
- Auto-detect columns: first_name, last_name, full_name, email, graduation_year, phone
- If column detection is ambiguous, show a simple column mapper (three dropdowns max)
- For beta: if CSV structure is too complex, show error and ask them to use paste instead

### Step 3 — Preview
Before any writes happen, show a preview table. This is where trust gets built.

**Preview table columns:**
| Name | Email | Status | Action |
|------|-------|--------|--------|
| Sarah Johnson | sarah@email.com | ✅ Ready to add | — |
| Mike Chen | mike.chen@gmail.com | ⚠️ Possible duplicate | Review |
| Tom Williams | *(none)* | 📋 No email — invite later | — |
| | not-an-email | ❌ Invalid email | Fix |

**Status logic:**
- `Ready to add` — clean row, no existing person record with this email
- `Possible duplicate` — email matches an existing person in this tenant. Show side-by-side. Admin can: Keep both / Use existing / Skip.
- `No email` — name only. Still importable. Creates unclaimed person record. Invitation can be sent manually later from member list.
- `Invalid email` — failed format validation. Inline fix field.

**Summary line above table:**
> "42 ready to add · 2 possible duplicates · 1 missing email · 1 invalid"

**Actions:**
- "Fix issues" — jumps to flagged rows
- "Skip issues and import X" — imports only clean rows, leaves flagged for later
- "Import all X" — primary CTA, imports everything including no-email rows

### Step 4 — Confirm
One-sentence confirmation prompt before writing:
> "Add 42 members to Class of 1990? They'll receive an invitation email at invitations@mail.gathr.co."

Two buttons: **Cancel** | **Add members**

If the tenant has no active event yet, confirmation copy changes to:
> "Add 42 members to Class of 1990? No event is published yet — you can send invitations from the member list when you're ready."

> Note: if no event exists, invitation rows are still created (with event_id = null) but the send step is skipped. Admin sends manually from member list once an event is published.

### Step 5 — Processing
Progress indicator. For beta this will be near-instant (< 1 second for 50 rows). Show row count ticking up. On completion:

> "✓ 42 members added. Invitations sent."  
> [View member list]

Or if no event exists:
> "✓ 42 members added. Send invitations from the member list when your event is ready."  
> [View member list]

---

## Data contract — what gets written on confirm

For each clean row, in a single transaction:

### 1. `person` row (if no existing match)
```sql
INSERT INTO person (
  id,               -- gen_random_uuid()
  first_name,       -- parsed from input
  last_name,        -- parsed from input
  email,            -- from input (null if none provided)
  claimed,          -- false
  created_at        -- now()
)
```

### 2. `membership` row
```sql
INSERT INTO membership (
  id,               -- gen_random_uuid()
  person_id,        -- from step 1
  tenant_id,        -- current tenant context
  org_role,         -- 'member' (lookup FK)
  status,           -- 'invited' (lookup FK)
  joined_at         -- now()
)
```

### 3. `invitation` row (only if email present)
```sql
INSERT INTO invitation (
  id,               -- gen_random_uuid()
  tenant_id,        -- current tenant context
  event_id,         -- null if no active event; active event id if one exists
  sender_id,        -- current admin's person_id
  recipient_email,  -- from input (lowercased, trimmed)
  token,            -- crypto.randomUUID() — unique per invitation
  status,           -- 'pending'
  expires_at,       -- now() + 30 days
  created_at        -- now()
)
```

### 4. Invitation send (if email present AND active event exists)
Immediately after the transaction commits:
- Call Resend to send invitation email for each row with a valid email
- From: `Class of 1990 via Gathr <invitations@mail.gathr.co>`
- Embed magic link: `https://gathr.co/invite/{token}`
- On send success: UPDATE invitation SET status = 'sent', sent_at = now()
- On send failure: log to activity_event with action_type = `communication.delivery.failed`; invitation status stays 'pending'; admin can retry from member list

### 5. `activity_event` rows
One `import.started` row when import begins. One `import.completed` row on success. One `import.row.created` row per person created (actor_type = 'system', object_type = 'person'). One `invitation.sent` row per invitation dispatched.

```jsonb
// import.completed metadata
{
  "rows_created": 42,
  "rows_updated": 0,
  "rows_skipped": 2,
  "rows_flagged": 1,
  "duration_ms": 847,
  "source": "paste"   // or "csv"
}
```

---

## Parsing rules

### Name parsing (paste input)
- Split on first space: everything before = first_name, everything after = last_name
- "Sarah" alone → first_name = "Sarah", last_name = null
- "Sarah Jane Johnson" → first_name = "Sarah", last_name = "Jane Johnson"
- Do not attempt middle name splitting for beta

### Email parsing
- Standard RFC 5322 format check
- Trim whitespace
- Lowercase before storing
- Reject obvious junk (no TLD, local-only addresses)

### Duplicate detection (beta — simple)
- Check `person.email` against all existing person records in this tenant (via membership join)
- Exact email match = possible duplicate
- No fuzzy name matching for beta (deferred to item AO)

### CSV column detection
Look for these header variants (case-insensitive):
- first_name / firstname / first / fname → `first_name`
- last_name / lastname / last / lname / surname → `last_name`
- name / full_name / fullname → split into first/last
- email / email_address / e-mail → `email`
- graduation_year / grad_year / year / class_year → `graduation_year` (parse but don't block on missing — not imported in beta)

---

## Edge cases to handle

| Scenario | Behavior |
|---|---|
| Empty paste | Disable import button, show helper text |
| All rows flagged | Show "nothing to import clean — resolve issues first" |
| 0 emails in entire import | Warning: "None of these contacts have emails — you can still add them but can't send invitations yet." Confirm still available. |
| > 500 rows | Warn "Large import — this may take a moment." No hard cap but no async queue for beta. |
| Admin imports same list twice | Second run hits duplicate detection — all rows show "Possible duplicate." Admin can skip all. |
| No active event | Invitation rows created with event_id = null, send step skipped. Admin sends from member list after publishing event. |
| Resend API failure | Log delivery failure to activity_event. Show error count on completion screen. Admin can retry failed sends from member list. |

---

## What the member list looks like after import

Each imported contact appears as a row in member management with:
- Name (or "Unknown" if name-only and no name parsed)
- Email (or "No email on file")
- Status badge: **Invited** (grey) — invitation sent, not yet claimed
- RSVP: **—** (no response yet)

The admin can: Resend invitation / View profile / Remove

---

## What this spec does NOT cover
- The invitation email template design (separate comms spec — blocked on item A)
- The magic link landing page the invitee hits (that's CA — auth chain spec)
- Re-import / update flow (post-beta)
- Bulk actions on member list after import (post-beta)
- Invitation send queue / scheduling (backlog)
- Mobile modal variant (roadmap item CH)
- Per-org-group sender subdomains (roadmap item CG)

---

*Commit to `docs/features/CB-contact-import-spec.md`. Reference alongside `docs/auth/01-auth-chain.md` when building import screens in Lovable. The invitation token created here is the entry point for Entry A in the auth chain.*
