# Gathr — Docs Folder Convention
Last updated: May 2026

---

## The rule

Every document in this repo has exactly one correct home. When in doubt, use the decision tree at the bottom of this file.

---

## Folder map

### `docs/auth/`
Specs for the login and identity flow. Anything that touches Supabase Auth, magic links, OAuth, tokens, session handling, or identity resolution.

Current files:
- `01-auth-chain.md` — end-to-end magic link auth flow (item CA)

Future files here: OAuth spec, identity resolution steps 2/3/4, multi-org picker.

---

### `docs/features/`
Specs for user-facing features built in Lovable. One file per feature. These are the documents you hand to Lovable when building a specific screen or flow.

Current files:
- `CB-contact-import-spec.md` — contact import and invitation send (item CB)

Future files here: RSVP flow, memory wall, communications composer, branding settings, member directory, event creation, etc.

---

### `docs/lovable/`
Foundational prompts and structural orientation for Lovable. Paste these at the start of a Lovable session before generating any screens. Not feature specs — these set the context every feature spec builds on.

Current files:
- `00-foundation.md` — app overview, tech stack, product principles
- `01-auth-chain.md` ← **do not duplicate here; lives in `docs/auth/`**
- `02-member-first-visit.md` — first visit onboarding flow

---

### `docs/architecture/`
System-wide patterns and rules that govern how the whole platform behaves. Referenced by both specs and migrations.

Current files:
- `activity-event-vocabulary.md` — canonical action type registry, metadata contracts, nudge engine rules
- `org-type-playbook.md` — org type definitions and UI language rules
- `platform-settings.md` — platform-level configuration reference

---

### `docs/decisions/`
Architecture Decision Records (ADRs). One file per significant decision. Captures what was decided, why, and what was ruled out. Written after the decision is made, not before.

Current files:
- `D-admin-succession-policy.md` — org admin succession and transfer rules

Naming convention: `D-{short-slug}.md`

---

### `docs/schema/`
Database migrations and schema reference SQL. One file per migration, named by date.

Naming convention: `YYYYMMDD_{description}.sql`

Current files:
- `20260520_succession_schema.sql`
- `20260521_activity_event_schema.sql`

---

## Decision tree

**"Is this a spec for building a specific user-facing feature in Lovable?"**
→ `docs/features/`

**"Is this about how login, auth sessions, or identity resolution works?"**
→ `docs/auth/`

**"Is this a foundational prompt I paste into Lovable before any session?"**
→ `docs/lovable/`

**"Is this a system-wide pattern, vocabulary, or rule the whole platform follows?"**
→ `docs/architecture/`

**"Is this a specific decision made with rationale — what we chose and why?"**
→ `docs/decisions/`

**"Is this a SQL migration or schema reference?"**
→ `docs/schema/`

---

## Naming conventions

| Folder | Convention | Example |
|--------|------------|---------|
| `features/` | Item ID + slug | `CB-contact-import-spec.md` |
| `auth/` | Two-digit sequence + slug | `01-auth-chain.md` |
| `lovable/` | Two-digit sequence + slug | `00-foundation.md` |
| `architecture/` | Descriptive slug | `activity-event-vocabulary.md` |
| `decisions/` | D- prefix + slug | `D-admin-succession-policy.md` |
| `schema/` | Date + description | `20260521_activity_event_schema.sql` |

---

## What does NOT live in docs/

- Source code → `src/`
- Environment config → `.env` (never committed) or Vercel dashboard
- Lovable-generated components → stay in Lovable / `src/`
- Anything auto-generated → keep out of docs entirely
