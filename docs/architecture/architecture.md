# Gather — Architecture Brief
**Version 2.0 — Post Session 8**
*Paste this at the start of every new Lovable chat. Commit to repo root as ARCHITECTURE.md.*

---

## 1. What Gather is

Multi-tenant reunion planning platform. Every org looks and feels like itself. One codebase, tenant context loaded at runtime from Supabase based on slug in the URL.

**Stack:** React (Lovable) · Supabase Postgres + RLS · Supabase Auth · Supabase Storage · Vercel · GitHub · Tailwind CSS

---

## 2. Supabase connection

- **External Gather project:** `https://gemqyweikfcwwdvwrguh.supabase.co`
- **Always use the Gather external client** for all data queries — never the Lovable Cloud instance
- Browser client: `src/integrations/gather/client.ts`
- Admin client (server-side, bypasses RLS): uses `GATHER_SUPABASE_SERVICE_ROLE_KEY`
- Lovable Cloud (`gnbfyglgywpdhknjmydy`) sits unused in background — ignore it

---

## 3. Data hierarchy

```
org_group → tenant → event → event_session
                   ↓
              person (platform-level identity)
              membership (links person to tenant)
              session_attendee (links person to session)
```

---

## 4. Table reference

### Column naming rules
- All PKs: `uuid`, named `id`
- Soft deletes: `deleted_at timestamptz` — never hard delete, never show deleted records in UI
- Lookup table FKs: stored as **plain text** on the referencing table (e.g. `type text`, `status text`) — not uuid FKs
- Lookup tables: `id uuid PK`, `label text`, `description text`, `is_active boolean`

### Core tables

**org_group** — parent organization (e.g. Lawrenceville HS)
`id, name, slug, type, deleted_at, created_at`

**tenant** — reunion org / class (e.g. Class of 1986)
`id, org_group_id, name, slug, type, discoverability, join_policy, domain_restriction, verification_config, plan_tier, deleted_at, created_at`

**person** — platform-level identity
`id, email, first_name, last_name, maiden_name, preferred_name, photo_url, dark_mode_pref, giving_interest, claimed, deleted_at, created_at, social_profiles, auth_user_id`

**membership** — links person to tenant
`id, person_id, tenant_id, org_group_id, org_role, linked_member_id, status, engagement_score, involvement_rung, joined_at, deleted_at`

**identity** — auth credentials
`id, person_id, provider, provider_user_id, email, created_at`

**event** — parent container for all sessions
`id, tenant_id, name, date, timezone, venue, type, headcount_target, status, discoverability, join_policy, deleted_at, created_at`

**event_session** — discrete sub-event within an event
`id, event_id, name, starts_at, ends_at, timezone, venue, type, headcount_target, capacity, is_optional, requires_separate_rsvp, status, deleted_at, created_at`

**session_attendee** — opt-in RSVP to a specific session
`id, session_id, person_id, rsvp_status, rsvp_at, waitlist_position, created_at`

**attendee_record** — person's relationship to an event
`id, event_id, person_id, event_role, rsvp_status, rsvp_at, meal_preference, dietary_restrictions, tshirt_size, table_assignment, payment_status, plus_one_count, waitlist_position`

**branding** — versioned, one active record per tenant or org_group
`id, tenant_id, org_group_id, logo_url, mascot_url, hero_image_url, primary_color, secondary_color, primary_color_dark, font_choice, active_from, active_to`

**invitation**
`id, event_id, tenant_id, sender_id, recipient_email, token, status, expires_at, created_at`

**communication**
`id, tenant_id, event_id, sender_id, channel, audience, subject, body, sent_at, status, created_at`

**media**
`id, tenant_id, event_id, uploader_id, url, type, moderation_flag, created_at`

**activity_event**
`id, actor_id, action_type, object_type, object_id, metadata, created_at`

### Lookup tables (super admin managed, all have is_active)
`org_type, tenant_type, membership_role, event_type, event_status, rsvp_status, payment_status, session_type, session_status`

---

## 5. Auth chain

Every authenticated screen must resolve in this order:

```
auth.uid()
  → person.auth_user_id
  → membership.person_id
  → membership.tenant_id (+ org_role + status)
  → load tenant context
```

Never hardcode a tenant_id or person_id. Always derive from auth.uid().

---

## 6. Real tenant data

### Tenant 1 — Lawrenceville IL HS Class of 1986
- `tenant_id`: `fe603109-106c-4800-8101-4aac5316053f`
- `slug`: `class-of-1986`
- `org_group_id`: `f149a853-21a5-4580-a602-d44ad644ac23`
- org admin: Trent Seed · `trentmseed@gmail.com` · `person_id: 30c9359a-7fbc-490f-b540-28c1a814d261`

### Tenant 2 — Raymond Lincolnwood HS Class of 1990
- `tenant_id`: `603834bc-0a3d-4f56-a42e-6779b9a418cf`
- `slug`: `class-of-1990`
- `org_group_id`: `d6d19699-ce7e-49b0-ba6a-d9fbc45d6270`
- org admin: Kristin Seed · `kristinseed@gmail.com` · `person_id: da662cb3-1742-43dd-8310-c466e720cb5a`
- also platform super_admin · `platform_user_id: b23a7348-c328-47c8-8a6e-e1873b270cde`

---

## 7. Existing screens in Lovable

| Path | What it is |
|------|------------|
| `/login` | Auth entry point |
| `/` | Landing / home |
| `/org-admin-preview` | Org admin dashboard |
| `/org-admin-preview/branding` | First-time branding wizard (preserve this as first-time flow — settings branding is separate) |
| `/platform-admin-preview` | Super admin dashboard (cross-tenant) |
| `/platform-admin` | Super admin wired version |

---

## 8. Rules for every screen you build

1. **Always use the Gather external Supabase client** — never the Lovable Cloud instance
2. **Never hardcode tenant_id, person_id, or org_group_id** — always derive from auth chain
3. **Never show soft-deleted records** — always filter `WHERE deleted_at IS NULL`
4. **Lookup table values are text** — query by label string, not uuid
5. **event_session is a child of event** — never render sessions without their parent event context
6. **session_attendee only exists when requires_separate_rsvp = true** — check this before rendering a session RSVP flow
7. **Branding is versioned** — always load the record where `active_to IS NULL` for current branding
8. **Role check order**: check `event_role` on attendee_record first, fall back to `org_role` on membership
9. **The branding wizard at `/org-admin-preview/branding` is a first-time flow** — do not overwrite it with a settings page

---

## 9. Theming

Default Gather tokens — always use CSS custom properties, never hardcode:

| Token | Value |
|-------|-------|
| `--gather-primary` | `#BA7517` (amber) |
| `--gather-surface` | `#FDFCFA` (warm white) |
| `--gather-surface-2` | `#F5F3EE` |
| `--gather-text` | `#2C2C2A` |
| `--gather-text-muted` | `#5F5E5A` |
| `--gather-border` | `#E8E4DC` |
| `--gather-heading-font` | `Georgia, serif` |
| `--gather-body-font` | `system-ui, sans-serif` |

Tenant colors override accent layer only (top bar, progress fills, active states). Never override backgrounds, body text, or borders.
