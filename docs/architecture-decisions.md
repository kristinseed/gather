# gather. — Architecture Decision Record (ADR)

Version 1.0 | Created at project inception

This document captures the key architectural decisions made for Gather and the reasoning behind them. When someone asks "why did you build it this way?" — this is the answer.

---

## ADR-001: Multi-tenant architecture with shared schema

**Decision:** All reunion orgs (tenants) live in the same database schema, isolated by tenant_id foreign keys and Row Level Security policies.

**Why:** Single-schema multi-tenancy is the right choice at this stage. It means one codebase, one deployment, one database to manage. Adding a new org is a row insert, not a new database. Supabase RLS enforces data isolation at the database level — no application code can accidentally leak data across tenants.

**Trade-off accepted:** At very high scale (thousands of large orgs), per-tenant schemas or databases perform better. That is not today's problem. The schema supports migration to that model if needed.

**Alternatives rejected:** Per-tenant databases (operational overhead too high for a v1), separate schemas per tenant (middle ground with few advantages at this scale).

---

## ADR-002: Person is a platform-level identity, not a tenant-level one

**Decision:** A single Person record represents a human across all orgs. Membership is the org-level relationship. Identity is the auth-credential relationship.

**Why:** People belong to multiple orgs (a family reunion AND a class reunion). They should have one login, one profile, one place to manage their data. Merging duplicate records is a known hard problem — the Merge Log table and claimed field exist because we know this will happen with imported member lists.

**Trade-off accepted:** More complex auth flow (identity resolution sequence with 4 steps). Worth it because the alternative — per-tenant accounts — means one person has 3 logins and 3 profiles and the admin can't tell they're the same person.

---

## ADR-003: Soft deletes everywhere

**Decision:** Every major entity has a deleted_at timestamp field. Nothing is hard deleted.

**Why:** Reunion orgs deal with real people and real money. Accidental deletes happen. Admins need recovery options. The audit trail matters. Soft deletes cost almost nothing (a filtered query) and give back enormous value when something goes wrong.

**Implementation rule:** Every query in the application must include `WHERE deleted_at IS NULL`. Lovable prompts should specify this explicitly.

---

## ADR-004: Branding is versioned

**Decision:** Each branding change creates a new Branding record. The previous record gets active_to set to now(). Only one record per tenant has active_to = null (the current one).

**Why:** Events happened in the past with branding that existed at that time. A 10-year reunion should render with the logo and colors that were active when it happened, not whatever the org uploaded last week. Versioning makes this possible without storing branding snapshots on every event record.

---

## ADR-005: Activity Event as the central nervous system

**Decision:** Every meaningful action in the system writes an Activity Event record. The admin dashboard nudge, the audit log, and future notification triggers all read from this table.

**Why:** A single event stream is far easier to reason about than scattered notification logic, audit tables, and dashboard queries. The Activity Event table is designed now even though most consumers of it (engagement scoring, notification triggers) are roadmap features. Building it now costs nothing; retrofitting it later costs weeks.

---

## ADR-006: Invitation is a first-class object

**Decision:** Invitations are stored as records with tokens, status tracking, and expiry — not just emails sent and forgotten.

**Why:** "Did they get my invitation?" is the number one question reunion admins ask. Tracking invitation status (pending / opened / accepted / expired / declined) turns a black hole into a managed workflow. The token-based approach also enables secure invitation acceptance without requiring the recipient to already have an account.

---

## ADR-007: Roadmap features are modeled in the schema now

**Decision:** Fields like engagement_score, involvement_rung, giving_interest, and verification_config exist in v1 schema even though no UI touches them.

**Why:** Schema migrations on a live production database with real user data are painful and risky. Adding a nullable column to an existing table is trivial now. Adding it after 10,000 members are in the system requires a migration plan, downtime consideration, and backfill logic. The cost of modeling these fields now is zero.

---

## ADR-008: Supabase Auth with Google and Facebook OAuth

**Decision:** Use Supabase's built-in auth with Google and Facebook as primary providers, email magic link as fallback.

**Why:** Reunion members are not developers. They will not remember a password they created for a site they visit once a year. OAuth with Google or Facebook means they log in with something they use every day. Magic link is the fallback for people who don't use those providers. No password storage, no password reset flows to build.

**Trade-off accepted:** Dependency on Google and Facebook OAuth availability. Acceptable — if either goes down, magic link still works.

---

## Stack summary

| Layer | Choice | Reason |
|---|---|---|
| Frontend | React via Lovable | Fastest path to production UI with AI assistance |
| Backend/DB | Supabase (Postgres + RLS) | Auth, database, storage, and API in one platform |
| Auth | Supabase Auth | Native integration, OAuth support, no password management |
| File storage | Supabase Storage | Same platform, RLS applies to files too |
| Deployment | Vercel | Git-connected, automatic deploys, generous free tier |
| Version control | GitHub | Industry standard, integrates with Lovable and Vercel |
| Styling | Tailwind CSS + CSS custom properties | Tenant theming via CSS variables without runtime overhead |

## ADR-009: Four-level hierarchy — org_group → tenant → event → event_session

**Decision:** The data model has four levels: org_group (parent organization), tenant (reunion class or chapter), event (the gathering), and event_session (discrete sub-event within a gathering).

**Why:** Real reunions are not single events. A 40th reunion weekend has a Friday night reception, a Saturday dinner, a Sunday brunch, and a golf outing. Each has its own headcount, venue, capacity, and optional RSVP. Flattening these into one event record forces ugly workarounds. A session layer makes the data match reality.

The org_group level exists because some organizations span multiple tenants — a high school has a Class of 1986 and a Class of 1990, both under the same school. Org_group gives the school-level admin an aggregate view without collapsing the tenant boundaries that keep member data isolated.

**Trade-off accepted:** More joins in queries. Worth it — the alternative is JSONB blobs or denormalized event records that become unmaintainable as soon as a real multi-session reunion tries to use the system.

**Implementation rules:**
- event_session is always a child of event — never render sessions without parent event context
- session_attendee only exists when requires_separate_rsvp = true on the session
- org_group membership rows use org_group_id with tenant_id null; tenant membership rows use tenant_id with org_group_id null — never both
