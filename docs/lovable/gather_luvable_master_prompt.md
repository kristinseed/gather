# Gathr — Lovable Master Prompt
**Full product specification for front-end scaffolding**
Version 3.2 — May 2026 — Added Section 12: Accessibility, inclusive design, and device strategy (complete)

---

> **How to use this document:** drop each section into Lovable as a structured prompt. Start with Section 1 (app overview) and Section 2 (data model) before generating any screens. Sections 3–7 map to screen groups — prompt one at a time. Sections 8–12 are global standards — paste Sections 9, 11, and 12 at the top of every new Lovable session.

> ⚑ **v3.2 changes from v3.1:** Section 12 added (WCAG AA, font size preference, age-appropriate components, tablet-first layout rules, landscape orientation, large screen behavior, touch interaction model, type scale, PWA manifest readiness, admin mobile lite stub). Section 11a device table updated to reflect tablet as first-class. Rem-based sizing mandate added throughout.

---

## Section 1 — App Overview
> ⚑ Paste this section first in Lovable before generating any screens or components.

### The one-sentence brief

```
PROMPT — App Overview
Build a multi-tenant web application called Gathr — a reunion and gathring platform where every organization looks and feels like itself, the organizer is guided rather than overwhelmed, and members feel like they belong rather than like they're being managed.
```

### Tech stack

| Layer | Choice |
|---|---|
| Front end | React (Lovable-generated) |
| Backend / database | Supabase (Postgres + Row Level Security) |
| Auth | Supabase Auth with Google OAuth |
| File storage | Supabase Storage |
| Deployment | Vercel |
| Version control | GitHub |
| Styling | Tailwind CSS with CSS custom properties for tenant theming |

### App structure

- Multi-tenant SaaS — each org is an isolated tenant with its own data, branding, and members
- Single codebase — tenant context loaded at runtime from Supabase based on org slug in the URL
- URL structure: `gathr.app/{org-group-slug}/{tenant-slug}` for tenant spaces, `gathr.app/admin` for super admin
- Responsive web app — must work well on mobile (members) and desktop (admins); tablet is a first-class device for both
- Dark mode: user-controlled toggle, preference stored on Person record, respect system preference on first visit
- Font size preference: user-controlled, stored on Person record as `font_size_pref` (values: `default` / `large` / `larger`), silently saved on change, applied via rem scaling on `<html>`

### Core product principles

- **Guide, don't dump** — the organizer dashboard shows one hero number and one suggested action, not a wall of data
- **Warm and nostalgic** — serif headings, generous whitespace, amber accent, feels like flipping through a yearbook
- **Trust by default** — members never feel marketed to, no dark patterns, no aggressive prompts
- **Branded but structured** — tenant colors and logo overlay on a consistent layout system, never break the layout
- **Progressive disclosure** — simple defaults, advanced settings revealed as admins get comfortable
- **Generic language** — never hardcode 'school', 'class', or 'reunion' in UI copy; use 'organization', 'group', 'gathring' or drive labels from `org_group.type`
- **Built for all ages** — primary users are 45–70 years old. Generous sizing, clear labels, forgiving touch targets, no interaction that requires precision or speed

---

## Section 2 — Data Model
> ⚑ Paste this before generating any screens so Lovable understands the relationships.

### Entity hierarchy

```
PROMPT — Hierarchy
Platform → Org Group (optional parent org) → Tenant (class / chapter / branch) → Event → Attendee Record
Person is a platform-level identity. Membership links a Person to either a Tenant or an Org Group. One person can belong to many tenants.
```

### Key relationships

- `org_group` = the school, fraternity, family, military unit — the parent organization
- `tenant` = the class of 1990, the Beta chapter, the Midwest branch — scoped under an org_group
- `membership.tenant_id` OR `membership.org_group_id` — exactly one must be set (never both)
- All type/status/role columns are FK references to lookup tables — never free text
- Lookup table values are managed by super admin via UI — never hardcode enum values in the front end

### Supabase connection

```
PROMPT — Supabase Config
Connect to Supabase project: https://gemqyweikfcwwdvwrguh.supabase.co
All data access must go through Supabase client with the anon key. Never bypass RLS. The auth chain is: auth.uid() → person.auth_user_id → membership → tenant_id or org_group_id.
```

### Auth chain

Every authenticated screen must resolve the user's context via this chain:

- `auth.uid()` from Supabase Auth
- → `person` where `auth_user_id = auth.uid()`
- → `membership` where `person_id = person.id`
- → `tenant_id` (for class/chapter admin) OR `org_group_id` (for org-level admin)

> ⚑ Never hardcode tenant IDs or person IDs in component code. Always resolve from auth context.

---

## Section 3 — Super Admin Screens
> ⚑ `gathr.app/admin` — only accessible to `platform_user` records with `super_admin` role.

### Super admin dashboard

```
PROMPT — Super Admin Dashboard
Build the super admin dashboard at /admin. Show: total org_groups, total tenants, total persons, total events (active). Sidebar navigation: Dashboard, Org Groups, Tenants, People, Lookup Tables, Platform Settings. All data from Supabase. Super admin only — redirect any non-super_admin to /unauthorized.
```

### Lookup table manager

```
PROMPT — Lookup Table Manager
Build a lookup table manager under /admin/lookup-tables. Show a list of all lookup tables (org_type, tenant_type, membership_role, event_type, event_status, rsvp_status, payment_status, etc.). For each table, allow super admin to: view all values, add new values, edit label/description, toggle is_active. Never allow deleting a value — only deactivating via is_active. All changes write directly to Supabase.
```

---

## Section 4 — Org Group Admin Screens
> ⚑ Accessible to membership rows scoped to `org_group_id` with `org_role = org_admin`.

### Org group dashboard

```
PROMPT — Org Group Admin Dashboard
Build the org group admin dashboard. Show: all tenants under this org_group, total members across all tenants, upcoming events across all tenants. The admin sees the whole organization, not just one class. Navigation: Dashboard, Groups (tenants), Members, Settings. Resolve org_group context from auth chain: auth.uid() → person → membership where org_group_id is set.
```

---

## Section 5 — Tenant Admin Screens
> ⚑ Accessible to membership rows scoped to `tenant_id` with `org_role = org_admin` or `class_admin`.

### Tenant admin dashboard

```
PROMPT — Tenant Admin Dashboard
Build the tenant (class/chapter) admin dashboard. Hero metric: confirmed RSVPs for the next upcoming event. Suggested next action (e.g. 'You have 12 members who haven't been invited yet'). Sections: Events, Members, Communications, Settings. All data scoped to the authenticated user's tenant_id — never show cross-tenant data. Resolve tenant context from auth chain.
```

### Member management

```
PROMPT — Member Management
Build the member management screen under the tenant admin. Show all membership records for this tenant with columns: name, email, status (from membership_status lookup), org_role (from membership_role lookup), engagement_score. Filter by status. Actions: invite new member, change role, change status. Status and role values must be loaded from the lookup tables — never hardcode the options.
```

---

## Section 6 — Event Screens

### Event management

```
PROMPT — Event Management
Build event management screens for tenant admins. List view shows all events for this tenant with status badge (from event_status lookup table — values: draft, published, closed, completed, archived). Create/edit form fields: name, date, timezone, venue, type (from event_type lookup), headcount_target, discoverability (from discoverability lookup), join_policy (from join_policy lookup). Status transitions: draft → published → closed → completed → archived.
```

### Attendee management

```
PROMPT — Attendee Management
Build the attendee management screen for a specific event. Show all attendee_records with: person name, rsvp_status (from rsvp_status lookup), payment_status (from payment_status lookup), meal_preference, tshirt_size (from tshirt_size lookup), table_assignment. Allow bulk RSVP status updates. Show summary counts: accepted / declined / waitlisted / invited.
```

---

## Section 7 — Member-Facing Screens

### Member profile and dashboard

```
PROMPT — Member Dashboard
Build the member-facing dashboard. Show: upcoming events for their tenant, their RSVP status for each, profile completeness prompt if missing photo or preferred_name. Navigation is minimal — members don't manage anything. Dark mode toggle in header, preference saved to person.dark_mode_pref in Supabase. Font size control in header, preference saved to person.font_size_pref in Supabase.
```

### Magic link join flow

```
PROMPT — Join Flow
Build the magic link join flow at /join/[token]. On load: look up invitation by token in Supabase, validate it is pending and not expired. If valid: show the org name, event name (if applicable), and a form to claim the account (confirm name, set password or use Google OAuth). On completion: update invitation.status to accepted, update membership.status to active, redirect to member dashboard.
```

---

## Section 8 — Theming System
> ⚑ Apply this globally before styling any individual screens.

### CSS custom properties

```
PROMPT — Theming
Implement a tenant theming system using CSS custom properties. On app load, fetch the active branding record for the current tenant from Supabase (where active_to IS NULL or active_to > now()). Apply these CSS variables: --color-primary (primary_color), --color-secondary (secondary_color), --color-primary-dark (primary_color_dark for dark mode). All buttons, links, and accent elements must use var(--color-primary) not hardcoded colors. Logo: use branding.logo_url in the header. If no branding record exists, fall back to default Gathr brand colors (#1E3A5F primary, #D4A853 accent).
```

### Default brand tokens

| Token | Value | Usage |
|---|---|---|
| `--color-primary` | `#1E3A5F` | Nav, buttons, headings |
| `--color-accent` | `#D4A853` | CTAs, highlights, amber warmth |
| `--color-surface` | `#FAFAF8` | Page backgrounds |
| `--color-text` | `#1A1A1A` | Body text |
| `--font-heading` | `Georgia, serif` | All headings — nostalgic feel |
| `--font-body` | `Inter, sans-serif` | Body and UI elements |

---

## Section 9 — Coding Standards and Architecture Guardrails
> ⚑ Paste this section when starting any new Lovable session or before generating any screen group. These are standing instructions — they apply to every component, every page, every feature.

### 1. Supabase client — one instance, always

Create a single Supabase client in `src/lib/supabase.ts` and import it everywhere. Never call `createClient()` inside a component. Never inline credentials. Never create a second client instance.

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
```

All environment variables go in `.env.local`. Never hardcode a URL or key in a component file.

### 2. Auth context — one provider, always

Wrap the app in a single `AuthProvider` at the root. Every component that needs the current user reads from `useAuth()` — never calls `supabase.auth.getUser()` directly inside a component.

```typescript
// src/context/AuthContext.tsx
// Exports: AuthProvider, useAuth()
// useAuth() returns: { session, person, membership, loading }
```

`person` is the Gathr Person record joined from Supabase, not the raw Supabase auth user. `membership` is the active tenant membership for the current org slug. Both are resolved before any protected screen renders.

### 3. Theming — CSS custom properties only

Never hardcode a color value anywhere in the codebase. All colors reference CSS custom properties defined in `src/styles/tokens.css`.

gathr default tokens are always present. When a tenant org loads, inject their branding values on `:root` via a `useTenantBranding()` hook. Tenant colors only override the accent layer — never backgrounds, body text, or borders.

```css
/* Always reference tokens, never raw values */
color: var(--gathr-text);           /* ✓ */
color: #2C2C2A;                      /* ✗ never */

background: var(--tenant-primary);  /* ✓ for accent */
background: var(--gathr-surface);  /* ✓ for structure */
```

Dark mode is controlled by a `data-theme="dark"` attribute on `<html>`, toggled by the user preference stored on `Person.dark_mode_pref`. All tokens have dark variants. Never use a media query to drive dark mode — always follow the stored preference.

### 4. Component structure — extract, don't repeat

Every piece of UI that appears in more than one place is a component. Name components by what they are, not where they live.

```
src/
  components/
    ui/           ← generic: Button, Card, Badge, Modal, Avatar
    layout/       ← structural: AppShell, Sidebar, TopNav, PageHeader
    org/          ← tenant-aware: OrgHeader, BrandedHero, MemberCard
    event/        ← event-scoped: RSVPButton, AttendeeTable, EventCountdown
  context/        ← AuthContext, TenantContext
  lib/            ← supabase.ts, utils.ts
  hooks/          ← useAuth, useTenant, useMembers, useEvent
  pages/          ← route-level components only, thin wrappers
```

Pages import components. Pages do not contain business logic. Data fetching lives in hooks, not in page files.

### 5. Loading and empty states — always required

Every component that fetches data must handle three states: loading, empty, and error.

- **Loading:** skeleton placeholder matching the shape of loaded content. Never a spinner in the middle of a content area.
- **Empty:** warm, on-brand message with a clear action. Never a blank card or empty table.
- **Error:** plain message with a retry option. Never silent failure.

```typescript
if (loading) return <MemberListSkeleton />
if (error) return <ErrorMessage message={error} onRetry={refetch} />
if (!members.length) return <EmptyState message="No members yet." action="Import members" />
return <MemberList members={members} />
```

### 6. RLS-aware data fetching

All Supabase queries run through the authenticated client and rely on Row Level Security to scope data. Never add client-side role checks as a substitute for RLS. Client-side role checks are for UI visibility only — showing or hiding a button — never for data access control.

Always check for null returns — RLS returning no rows is not an error, it is correct behavior.

### 7. Soft deletes — never query without the filter

Every table uses `deleted_at` for soft deletes. Every query must filter `deleted_at IS NULL` unless explicitly building an admin recovery view.

```typescript
.is('deleted_at', null)
```

### 8. Typography and spacing — token-based only

- Headings (H1, H2): serif font via `var(--gathr-heading-font)`, weight 500 only
- Body and UI labels: `var(--gathr-body-font)`, weight 400 or 500 only
- Never use font-weight 600 or 700
- Never use ALL CAPS or Title Case in UI labels — sentence case everywhere
- Spacing follows Tailwind scale — no arbitrary pixel values in `className`
- Line height: `leading-relaxed` (1.625) for body, `leading-tight` (1.25) for headings
- All font sizes use `rem` units — never `px` — so user font size preference scales the entire UI

### 9. What not to build in v1

| Do not build | Why |
|---|---|
| Engagement score display | No data to drive it yet |
| Involvement pathway | Depends on engagement scoring |
| Giving / endowment features | Separate product phase |
| Vendor marketplace | Roadmap — after 20+ bookings |
| AI verification flow | After manual approval is stable |
| Notification trigger rules UI | v1.5 only |
| Org group reporting | When first national org signs up |

### 10. Testing hooks — structure for testability now

- No logic in JSX. Move conditionals, calculations, and transforms into hooks or utils.
- Props over globals. Components receive what they need as props.
- Deterministic renders. Same props = same output. No `Date.now()` inside components.
- Named exports on components. Default exports only for page-level route components.

---

## Section 10 — Reserved
> ⚑ Placeholder for future platform integration standards.

---

## Section 11 — Foundation Patterns
> ⚑ Paste this section into every new Lovable session alongside Sections 9 and 12. These patterns apply to every screen, every role, every feature. They are not optional.

### 11a — Device strategy: who uses what

This is not a "mobile-responsive" app. It is three different layout zones built on one codebase. Tablet is a first-class device, not a fallback.

| Role | Primary device | Secondary device | Layout strategy |
|---|---|---|---|
| Member | Mobile (phone) | Tablet | Mobile-first. Designed at 390px, scales to 768px and 1280px. |
| Organizer / Tenant Admin | Desktop or tablet | Phone (event day only) | Desktop-first at 1280px. Explicit tablet layout at 768–1024px. Phone access for event-day lite mode only. |
| Org Group Admin | Desktop or tablet | None | Desktop-first. Tablet must be fully functional. |
| Vendor | Mobile or desktop | Either | Responsive, no strong preference. |
| Super Admin | Desktop only | None | Desktop only. No mobile or tablet optimization needed. |

The three layout zones:
- **Mobile:** 320–767px — single column, bottom nav, full-width CTAs, touch targets 48px minimum
- **Tablet:** 768–1024px — two-column where useful, touch-first interactions, no hover dependencies, sidebar optional
- **Desktop:** 1025px+ — full sidebar, data tables, multi-column forms, max-width 1200px centered

### 11b — Mobile layout pattern (member-facing screens)

**Shell structure**
```
┌─────────────────────────┐
│   TenantHeader          │  ← Logo, org name, dark mode + font size toggle (48px)
├─────────────────────────┤
│                         │
│   Page content          │  ← Scrollable. Single column. Full width.
│                         │
├─────────────────────────┤
│   BottomNav             │  ← Fixed. 4 tabs max. 64px tall.
└─────────────────────────┘
```

**BottomNav tabs (member):** Home · Events · Directory · Profile

Each tab: icon + label. Active tab uses `var(--tenant-primary)`. Inactive tabs use `var(--gathr-text-muted)`. No badges or notification counts in v1.

**Touch targets:** All tappable elements minimum 48×48px. Buttons full-width on mobile unless two side-by-side actions are needed (e.g. Accept / Decline).

**Cards and lists:** Single-column card stack. No grids on mobile. Cards have 16px horizontal padding, 12px vertical padding. 12px gap between cards minimum.

**CTAs and forms:** Primary CTA always at bottom of screen, full-width, 16px margin each side. Forms are one field per row. No multi-column form layouts on mobile.

**Landscape orientation (phone):** Header shrinks to 36px. Bottom nav stays fixed. Content reflows to use the wider viewport — do not hide content in landscape. Never break the layout in landscape orientation.

**Navigation pattern for flows** (onboarding, RSVP, payment): Step-by-step wizard. One question or action per screen. Progress indicator at top. Back arrow top-left. Forward/Next CTA bottom-right or full-width bottom. Never show the whole form at once on mobile.

### 11c — Tablet layout pattern (768–1024px)

Tablet is a primary device for admin users and a common secondary device for members. It requires its own explicit layout, not just a collapsed desktop.

**Member-facing on tablet:**
- Two-column card layout where content allows (e.g. event cards, directory)
- Bottom nav stays — do not switch to sidebar on tablet for member screens
- Touch targets remain 48px minimum — tablet users are touching, not clicking
- Font size and dark mode controls remain visible in header

**Admin-facing on tablet:**
- Sidebar collapses to icon-only (56px wide) — labels hidden, icons visible, tooltips on long-press
- Main content area goes full width
- Two-column form layouts collapse to single column
- Data tables stay and scroll horizontally if needed — never hide columns, never paginate differently
- Bottom sheet modals instead of dropdown menus for contextual actions — dropdowns are unreliable on touch
- All table row actions accessible via tap on the row or a clearly visible action button — never rely on hover to reveal actions

**The tablet rule:** If an interaction requires a hover state to be discovered or activated, it is broken on tablet. Every action must be reachable by tap alone.

### 11d — Desktop layout pattern (admin-facing screens, 1025px+)

**Shell structure**
```
┌──────────┬──────────────────────────────────┐
│          │  TopBar                           │  ← 56px. Org name, user avatar, dark mode, font size.
│ Sidebar  ├──────────────────────────────────┤
│          │  PageHeader                       │  ← Page title, primary action button (right).
│  240px   ├──────────────────────────────────┤
│          │                                   │
│  Fixed   │  Main content area                │  ← Scrollable. Max-width 1200px. Centered.
│          │                                   │
└──────────┴──────────────────────────────────┘
```

**Large screen behavior (1440px+):** Sidebar stays 240px. Content stays max-width 1200px centered. Extra space is background — never stretch content to fill it. Never add a second panel or auto-expand the sidebar at large viewports unless explicitly prompted.

**Sidebar navigation (admin):** Fixed left, 240px. Vertical nav with icons. Active link: filled background `var(--gathr-surface-raised)`, left border accent `var(--tenant-primary)`. Collapse to icon-only at 1024px. Grouped with muted section labels.

**Tenant admin sidebar sections:**
- Overview → Dashboard
- People → Members, Join Requests
- Events → All Events, [active event name if one exists]
- Comms → Communications
- Money → Payments, Sponsors
- Logistics → Vendors, Subgroups, Accommodation
- Settings → Branding, Org Settings

**Org group admin sidebar sections:**
- Overview → Dashboard
- Groups → All Tenants
- People → All Members
- Settings → Org Settings

**Super admin sidebar:** Dashboard · Org Groups · Tenants · People · Lookup Tables · Platform Settings

**Data tables:** Column headers, sort on click, row hover state, contextual action menu (⋯) per row. Pagination: 25 rows default, 50 and 100 options. Filter bar above: search left, filters right, action button far right.

**Dashboard pattern (organizer):** Two-column at top: one hero stat card left, one NudgeCard right. Below: up to three secondary stat cards. Below that: main content section. Never more than one NudgeCard at a time.

**Forms (admin):** Two-column layout for simple fields. Full-width for text areas and complex inputs. Submit button bottom-right. Cancel link bottom-left. Inline validation on blur.

### 11e — Tenant guard and route protection pattern

Every route falls into one of four protection levels:

| Level | Routes | Requirements |
|---|---|---|
| Public | `/`, `/login`, `/invite/{token}`, org public pages | No auth |
| Authenticated | `/onboarding/*` | Valid session, no role check |
| Tenant member | All `/{org-group-slug}/{tenant-slug}/*` member routes | Valid session + active membership |
| Tenant admin | All `/{org-group-slug}/{tenant-slug}/admin/*` routes | Valid session + `org_role = org_admin` or `committee` |
| Super admin | All `/platform/*` routes | Valid session + `platform_user` with active role |

**TenantGuard component** — wraps every tenant-scoped route. On mount: resolve auth → load person → load tenant from URL slug → check membership → four outcomes: active (render), pending (PendingApproval screen), no membership open tenant (join flow), no membership invite-only (InviteOnly screen). For admin routes: check `org_role` → insufficient → redirect to member home.

```typescript
<TenantGuard requiredRole="member">
  <MemberDashboard />
</TenantGuard>

<TenantGuard requiredRole="admin">
  <AdminDashboard />
</TenantGuard>
```

`TenantGuard` lives in `src/components/layout/TenantGuard.tsx`. It is the only place membership and role checks happen for routing.

**Auth failure mid-session:** Clear auth context → toast "Your session expired. Please sign in again." → redirect to `/login?redirect=[current path]`. Never silent failure. Never blank screen.

### 11f — Global error boundary pattern

- App-level boundary (`AppErrorBoundary.tsx`): gathr logo centered, "Something went wrong. We're looking into it.", one Reload button. No stack trace to user.
- Route-level boundary per shell (member, admin, platform): a broken admin screen does not take down the member shell.
- Every Supabase `{ data, error }` response checked — never swallow silently. Translate errors to plain language.
- Toast system: four variants (success/error/warning/info), top-right desktop, top-center mobile, 4-second auto-dismiss, error toasts persist. Never `alert()`.

### 11g — Form mutation pattern

**Four states every form must handle:** Idle → Submitting (spinner, fields disabled) → Success (toast + redirect or reset) → Error (field-level message, fields re-enabled).

**Validation:** on blur, then again on submit. Required: "[Field name] is required." Format: "[Field name] is not valid." Error text below field in `var(--gathr-error)`, 14px.

**Optimistic updates:** RSVP status, profile edits, dark mode toggle, font size toggle, table assignments.

**Confirmed updates (wait for Supabase response):** payments, membership status changes, invitation sends, event publish/unpublish, any destructive action.

**Destructive actions:** confirmation modal required. Title = plain statement of what happens. Body = one sentence of consequence. Two buttons: Cancel (secondary, left) and destructive label in red (right). Never "Are you sure?"

---

## Section 12 — Accessibility, Inclusive Design, and Device Readiness
> ⚑ Paste this section into every new Lovable session alongside Sections 9 and 11. These rules apply to every component without exception. They are not a post-build checklist — they are build requirements.

### 12a — Who we are building for

gathr's primary users are 45–70 years old. Many are accessing the app on a phone or tablet for the first time in a high-stakes moment — joining a reunion, RSVPing, seeing their friends' names. The UI must be forgiving, readable, and confidence-building on first contact. Younger admins and org staff are secondary users. Accessibility is not a compliance layer — it is the product.

Design every component as if the user:
- Has moderate vision reduction and benefits from larger, higher-contrast text
- Is using their phone with one hand in a noisy room
- Has never used this app before and has no tolerance for confusion
- May be using a screen reader, a keyboard only, or a switch device

If a component is not usable under these conditions, it is not finished.

### 12b — WCAG AA compliance — non-negotiable rules

Every component must meet WCAG 2.1 AA. These are the rules Lovable must follow without exception.

**Color contrast:**
- Normal text (under 18px): minimum contrast ratio 4.5:1 against background
- Large text (18px+ or 14px+ bold): minimum contrast ratio 3:1 against background
- UI components (buttons, inputs, focus rings): minimum contrast ratio 3:1 against adjacent color
- Never convey information by color alone — always pair color with text, icon, or pattern
- Test every tenant branding combination: tenant primary color must meet contrast against `var(--gathr-surface)` and white. If a tenant uploads a color that fails, show a platform warning in the branding editor

**Focus states:**
- Every interactive element (buttons, links, inputs, select menus, checkboxes, toggles) must have a visible focus ring
- Focus ring style: 2px solid `var(--color-accent)` with 2px offset — never remove the outline, never `outline: none` without a custom replacement
- Focus order must follow the visual reading order of the page — never create a tab trap except inside modals
- Modal dialogs: trap focus inside the modal while open, return focus to the trigger element on close

**Keyboard navigation:**
- Every user action reachable by keyboard alone
- `Enter` activates buttons and links. `Space` activates checkboxes and toggles. `Escape` closes modals and dropdowns
- Dropdown menus navigable with arrow keys
- No keyboard-inaccessible interactions — if it works with a mouse, it works with a keyboard

**Screen reader support:**
- All images have `alt` text. Decorative images use `alt=""`
- All form inputs have associated `<label>` elements — never placeholder text as the only label
- Buttons and icon-only controls have `aria-label` describing the action
- Status messages (success toasts, error messages, loading states) use `aria-live` regions so screen readers announce them
- Page titles update on route change — never leave the title stale after navigation
- Semantic HTML: `<button>` for actions, `<a>` for navigation, `<nav>`, `<main>`, `<header>`, `<footer>` landmarks present on every page

**Motion and animation:**
- Respect `prefers-reduced-motion`. All transitions and animations must have a reduced-motion alternative (typically: instant or opacity-only)
- No auto-playing animation that cannot be paused
- No content that flashes more than 3 times per second

### 12c — Font size preference system

Users control their font size. The system saves it silently. No user should ever have to fight with font size.

**Storage:** `person.font_size_pref` column. Values: `default` / `large` / `larger`. Default if null.

**Implementation:** Set `font-size` on `<html>` element based on preference:

```css
/* Default */
html { font-size: 16px; }

/* Large */
html[data-font-size="large"] { font-size: 18px; }

/* Larger */
html[data-font-size="larger"] { font-size: 20px; }
```

All font sizes throughout the app use `rem` — never `px`. All spacing that relates to text (padding inside buttons, line height, input height) uses `rem` or scales via Tailwind's rem-based scale. This means the entire UI scales correctly when the user changes their font size preference — no component needs special-casing.

**Control placement:**
- Member-facing: font size toggle (A / A+ / A++) in the TenantHeader alongside the dark mode toggle. Three tappable options, minimum 48×48px each, clearly labeled
- Admin-facing: font size control in the TopBar user menu dropdown
- Preference saved to Supabase on change with no confirmation prompt — silent save, instant visual feedback
- On first load: read `person.font_size_pref` from auth context and apply before first paint to avoid flash of wrong size

**The rem rule:** Lovable will sometimes generate `text-[14px]` or inline `style={{ fontSize: '14px' }}`. These are violations. Every font size must use a Tailwind rem-based class (`text-sm`, `text-base`, `text-lg`) or a `rem` CSS value. Arbitrary pixel font sizes are forbidden.

### 12d — Age-appropriate component standards

These rules apply to every UI component in the library. They are not optional overrides — they are the baseline.

**Buttons:**
- Minimum height: 48px on mobile and tablet, 44px on desktop
- Minimum width: 120px for any labeled button
- Label text: always visible, always descriptive — "Save changes" not "Save", "Send invitation" not "Send"
- Never icon-only buttons without an `aria-label` and a visible tooltip or adjacent label
- Primary button: solid fill, high contrast, `var(--tenant-primary)` background with white text (verify contrast)
- Destructive button: red background, white text, never the same style as a primary action
- Disabled state: visually distinct (reduced opacity) but never the only indicator — add `aria-disabled` and a tooltip explaining why

**Form inputs:**
- Minimum height: 48px on mobile, 44px on desktop
- Label always above the input — never inside (placeholder only) or to the side on mobile
- Label font size: `text-base` (1rem) minimum — never smaller than the input text
- Helper text below input: `text-sm` (0.875rem), `var(--gathr-text-muted)` color
- Error text below input: `text-sm`, `var(--gathr-error)` color, preceded by an error icon for non-color indication
- Input border: 1.5px, clearly visible against background. Focus border: 2px `var(--color-accent)`
- No floating labels — they disappear when the user types and confuse older users

**Checkboxes and toggles:**
- Checkbox minimum size: 20×20px with a 48×48px tap target area around it
- Toggle (for settings like dark mode, font size): minimum 44px wide, 28px tall, with a clear on/off label adjacent
- Never rely on the toggle position alone — label must read "Dark mode: on" or show the current state in text

**Modals and bottom sheets:**
- On mobile: use bottom sheet (slides up from bottom) instead of centered modal for contextual actions
- On desktop: centered modal, max-width 560px, with overlay behind
- Modal header: clear title in `text-xl`, close button top-right, minimum 44×44px tap target
- Body text: `text-base` minimum, `leading-relaxed` line height
- Action buttons at bottom, full-width on mobile, right-aligned on desktop

**Tables (admin):**
- Row height minimum 52px — never compact table rows
- Font size: `text-base` for data cells, `text-sm` for secondary metadata only
- Sortable column headers: clearly indicate sort state with an icon + `aria-sort` attribute
- Row actions: visible tap/click target on every row — never hover-only reveal

**Empty states and errors:**
- Empty state illustration: simple, warm, on-brand — never a sad face or broken icon
- Empty state copy: one sentence explaining what goes here, one action button
- Error messages: plain English, never technical. Say what happened and what the user can do. Never show error codes to users.

### 12e — PWA readiness and installability

The app is built as an installable progressive web app from day one, with the service worker deferred until post-beta.

**What to implement now:**

Web app manifest at `/public/manifest.json`:
```json
{
  "name": "gathr",
  "short_name": "gathr",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FAFAF8",
  "theme_color": "#1E3A5F",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

In `index.html`: `<link rel="manifest" href="/manifest.json">` and `<meta name="theme-color" content="#1E3A5F">`.

**What to defer:** service worker registration, offline caching, background sync. Do not implement these until the native app decision is made.

**What this gives you now:** "Add to Home Screen" prompt on iOS and Android with the correct app name and icon. The app opens without browser chrome (address bar hidden) when launched from the home screen. This is the fastest path to an app-like experience for beta users without committing to a full PWA or native build.

**Future native app path:** The member-facing UI is designed as if it will be wrapped in a native shell (React Native via Expo, or Capacitor). This means: no features that require a desktop browser API, all member interactions work via touch, no reliance on browser back button behavior, bottom nav matches native app tab bar conventions. When the native app is built, the web components transfer with minimal rework.

### 12f — Admin event-day mobile lite (stub now, build later)

Admins manage events from desktops before the event. They manage events from phones during the event. These are different jobs and need different interfaces.

**Do not build this for beta.** Stub the route now so navigation doesn't need restructuring later.

The event-day admin lite view lives at `/{org-group-slug}/{tenant-slug}/admin/events/{event-id}/day-of`. It is a mobile-optimized single-purpose screen showing:
- Live headcount (arrived vs. expected)
- Quick RSVP status update (tap a name, mark arrived)
- Quick communication send (pre-written templates only — no composer on mobile)
- No settings, no member management, no financials

For beta: create the route file, add it to the sidebar under Events as "Day-of view (coming soon)", render a placeholder screen. This reserves the navigation slot and sets the expectation with beta users.

### 12g — Touch interaction rules (applies to all devices)

These rules apply everywhere a user might be touching instead of clicking — which includes all phones, all tablets, and any laptop with a touchscreen.

- **No hover-dependent interactions.** If content, actions, or labels only appear on hover, they are invisible on touch. Every action must be reachable without hover.
- **No hover-only tooltips as the only source of information.** Tooltips may supplement but never replace visible labels.
- **Dropdown menus triggered by hover:** forbidden. All dropdowns open on tap/click only.
- **Contextual menus (⋯ actions on table rows):** open on tap, not hover. The tap target for the ⋯ button must be 48×48px minimum.
- **Swipe gestures:** do not implement swipe-to-delete or swipe-to-action in v1. They are not discoverable for this user demographic. Use explicit buttons.
- **Double-tap:** never use double-tap as a primary interaction. It conflicts with browser zoom and confuses older users.
- **Pointer events:** use pointer events (not mouse events) for all interactive elements so they work correctly on both touch and mouse input.

---

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | May 3, 2026 | Initial version. Tenant named by class year, no org_group hierarchy, check constraints on enums, school-specific language. |
| 2.0 | May 14, 2026 | Corrected hierarchy (org_group / tenant). All status/type/role/policy columns now FK to lookup tables. UI language generalized. Auth chain documented. Super admin lookup table manager added. |
| 3.0 | May 15, 2026 | Sections 9 and 10 added. |
| 3.1 | May 18, 2026 | Section 11 added — device strategy, layout patterns, route guards, error handling, form mutations. |
| 3.2 | May 21, 2026 | Section 12 added — WCAG AA compliance, font size preference system, age-appropriate component standards, tablet as first-class device, landscape orientation rules, large screen behavior, touch interaction model, PWA manifest readiness, admin event-day mobile lite stub. Section 11a device table updated. Rem-based sizing mandate added throughout. |

---

> ⚑ Previous versions preserved in Google Drive. Never overwrite old versions. GitHub is the source of truth from v3.2 onward.
