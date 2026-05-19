# 00 — Foundation
*Run this prompt first, before any screen, before any feature. This establishes the complete app scaffold. Do not skip any section.*

---

## PART 1 — Project setup and constraints

You are building **Gather** — a multi-tenant reunion and gathering platform.

Tech stack:
- React (Lovable-generated)
- Supabase (Postgres + Row Level Security) at `https://gemqyweikfcwwdvwrguh.supabase.co`
- Supabase Auth with Google and Facebook OAuth
- Tailwind CSS with CSS custom properties for theming
- Vercel for deployment
- GitHub for version control

**Standing rules that apply to every file you generate:**
- One Supabase client instance only, in `src/lib/supabase.ts`
- Never call `createClient()` inside a component
- Never hardcode colors — always use CSS custom properties
- Never hardcode tenant IDs, person IDs, or org IDs in component code
- Never bypass RLS — let Supabase enforce data access
- Always filter `deleted_at IS NULL` on every query unless building an admin recovery view
- All type/status/role values come from Supabase lookup tables — never hardcode enum options in the UI
- Sentence case everywhere in UI copy — never ALL CAPS or Title Case labels
- No logic in JSX — move conditionals and transforms into hooks or utils
- Named exports on all components except page-level route components

---

## PART 2 — Supabase client

Create `src/lib/supabase.ts`:

```ts
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
```

All environment variables in `.env.local`. Never inline credentials anywhere else.

---

## PART 3 — CSS design tokens

Create `src/styles/tokens.css`. This is the single source of truth for every color, font, spacing, and shadow value in the app. Import it in `src/main.tsx` or `src/index.css` before anything else.

```css
/* ─── Gather default tokens ─── */
:root {
  /* Brand colors */
  --gather-primary: #1E3A5F;
  --gather-accent: #D4A853;
  --gather-accent-hover: #C49843;

  /* Surfaces */
  --gather-surface: #FAFAF8;
  --gather-surface-raised: #F0EFEC;
  --gather-surface-overlay: #FFFFFF;
  --gather-border: #E2E0DB;

  /* Text */
  --gather-text: #1A1A1A;
  --gather-text-muted: #6B6B6B;
  --gather-text-inverse: #FFFFFF;

  /* Feedback */
  --gather-success: #2D7A4F;
  --gather-warning: #B45309;
  --gather-error: #B91C1C;
  --gather-info: #1D4ED8;

  /* Tenant override slots — injected at runtime by useTenantBranding() */
  --tenant-primary: #1E3A5F;
  --tenant-secondary: #D4A853;
  --tenant-primary-dark: #152B47;

  /* Typography */
  --gather-heading-font: Georgia, 'Times New Roman', serif;
  --gather-body-font: Inter, system-ui, sans-serif;

  /* Type scale */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  /* Spacing scale (matches Tailwind) */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  /* Border radius */
  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.07), 0 2px 4px -2px rgb(0 0 0 / 0.05);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.08), 0 4px 6px -4px rgb(0 0 0 / 0.05);

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-base: 200ms ease;
  --transition-slow: 300ms ease;
}

/* ─── Dark mode tokens ─── */
[data-theme="dark"] {
  --gather-surface: #0F1923;
  --gather-surface-raised: #1A2733;
  --gather-surface-overlay: #243040;
  --gather-border: #2E3D4D;

  --gather-text: #F0EFEC;
  --gather-text-muted: #8A9BB0;
  --gather-text-inverse: #0F1923;

  --gather-primary: #4A7FB5;
  --gather-accent: #D4A853;

  --gather-success: #4ADE80;
  --gather-warning: #FBBF24;
  --gather-error: #F87171;
  --gather-info: #60A5FA;
}

/* ─── Typography base ─── */
body {
  font-family: var(--gather-body-font);
  color: var(--gather-text);
  background-color: var(--gather-surface);
  font-size: var(--text-base);
  line-height: 1.625;
  -webkit-font-smoothing: antialiased;
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--gather-heading-font);
  font-weight: 500;
  line-height: 1.25;
  color: var(--gather-text);
}

/* ─── Focus styles ─── */
:focus-visible {
  outline: 2px solid var(--tenant-primary);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}
```

---

## PART 4 — Context providers

### 4a — AuthContext

Create `src/context/AuthContext.tsx`:

```tsx
// Exports: AuthProvider, useAuth()
// useAuth() returns: { session, person, membership, tenantId, orgGroupId, role, loading, error }
//
// On mount:
// 1. Get Supabase session
// 2. If session exists: fetch person where auth_user_id = session.user.id
// 3. Fetch active membership(s) for this person
// 4. Expose the resolved values via context
//
// On session expiry: clear context, show toast "Your session expired. Please sign in again.", redirect to /login
// On auth state change: re-run the resolution chain
```

Build `AuthProvider` to wrap the entire app. It must resolve `person` and `membership` before any protected screen renders. Show a full-screen loading skeleton (not a spinner) while resolving.

### 4b — TenantContext

Create `src/context/TenantContext.tsx`:

```tsx
// Exports: TenantProvider, useTenant()
// useTenant() returns: { tenant, orgGroup, branding, loading, error }
//
// Reads org-group-slug and tenant-slug from the URL
// Fetches tenant record from Supabase matching slug + org_group_id
// Fetches active branding record (active_to IS NULL or active_to > now())
// Injects tenant branding as CSS custom properties on :root:
//   --tenant-primary, --tenant-secondary, --tenant-primary-dark
// Falls back to Gather default tokens if no branding record exists
```

TenantProvider wraps all tenant-scoped routes. It does not wrap `/platform/*` or `/login` or `/onboarding`.

### 4c — useTenantBranding hook

Create `src/hooks/useTenantBranding.ts`:

Fetches branding record for the current tenant or org_group. Injects values into CSS custom properties on `:root`. Called once when TenantContext mounts. Cleans up overrides when the component unmounts (user navigates away from tenant space).

---

## PART 5 — Core hooks

Create these hooks in `src/hooks/`. Each hook encapsulates all Supabase interaction for its domain. Pages and components never call Supabase directly — they call hooks.

```
useAuth()          → from AuthContext — session, person, membership, role
useTenant()        → from TenantContext — tenant, orgGroup, branding
useMembers()       → membership list for current tenant, with person join
useEvent(id)       → single event record with sessions
useEvents()        → all events for current tenant
useAttendees(eventId)  → attendee_records with person join for an event
useInvitation(token)   → invitation lookup by token
useLookup(tableName)   → fetch all active rows from any lookup table
```

Every hook returns `{ data, loading, error }` plus a `refetch` function. Every hook filters `deleted_at IS NULL` automatically. Every hook that fetches a list supports an optional `filter` param.

---

## PART 6 — Component library scaffold

Create these components. Build each one completely — not as a placeholder. Every component uses only CSS custom property tokens, never hardcoded values.

### 6a — UI primitives (`src/components/ui/`)

**Button**
```
Props: variant ('primary' | 'secondary' | 'ghost' | 'destructive'), size ('sm' | 'md' | 'lg'), loading (bool), disabled (bool), fullWidth (bool), onClick, children
- primary: bg var(--tenant-primary), text white
- secondary: border var(--gather-border), bg transparent
- ghost: no border, no bg, text var(--gather-text-muted)
- destructive: bg var(--gather-error), text white
- loading state: show spinner, disable click, show "Saving…" text
- fullWidth: width 100%, used on mobile CTAs
- min touch target: 44px height always
```

**InputField**
```
Props: label, name, type, value, onChange, error, helperText, required, disabled, placeholder
- Label above field, sentence case
- Error text below field in var(--gather-error), appears on blur
- Helper text below field in var(--gather-text-muted)
- Focus ring: var(--tenant-primary)
- Full width by default
```

**SelectField**
```
Same pattern as InputField but renders a <select>
Options always loaded from a useLookup() hook — never hardcoded
```

**TextArea**
```
Same pattern as InputField, multi-line, resizable vertically only
```

**Badge**
```
Props: label, variant ('default' | 'success' | 'warning' | 'error' | 'info' | 'muted')
Pill shape, small text, color maps to feedback tokens
Used for: RSVP status, membership status, event status, payment status
```

**Avatar**
```
Props: src, firstName, lastName, size ('sm' | 'md' | 'lg')
Shows photo if src exists
Falls back to initials (first + last initial) on colored background
Background color derived deterministically from name (not random)
```

**Card**
```
Props: children, padding ('sm' | 'md' | 'lg'), onClick (optional — makes card clickable)
bg var(--gather-surface-overlay), border var(--gather-border), shadow var(--shadow-sm)
border-radius var(--radius-lg)
Hover state if onClick provided: shadow var(--shadow-md), slight lift
```

**StatCard**
```
Props: label, value, trend (optional: { direction: 'up'|'down', label: string })
Large number in heading font, label in muted text below
Used on dashboards — not for general use
```

**Modal**
```
Props: open, onClose, title, children, footer (optional)
Overlay: black 50% opacity
Panel: centered, max-width 480px on desktop, full-width bottom sheet on mobile
Close button top-right (×)
Trap focus when open
Close on Escape key and overlay click
```

**Toast (via useToast hook)**
```
Variants: success, error, warning, info
Position: top-right desktop, top-center mobile
Auto-dismiss: 4 seconds (success/info/warning), persist until dismissed (error)
Max 2 visible at once — queue additional toasts
Never use browser alert()
```

**EmptyState**
```
Props: message, action (optional: { label, onClick })
Centered, warm illustration placeholder (SVG), message text, optional CTA button
Used whenever a list or table has zero rows
```

**LoadingSpinner**
```
Small inline spinner for button loading states only
Never use as a full-page loader — use skeletons instead
```

**AlertBanner**
```
Props: variant ('info' | 'warning' | 'error' | 'success'), message, dismissible (bool)
Full-width banner, appears above content area
Used for form-level errors and system messages
```

### 6b — Layout components (`src/components/layout/`)

**AppShell (mobile — member-facing)**
```
Structure:
- TenantHeader fixed top (48px): org logo left, org name center, dark mode toggle right
- Scrollable content area: padding-bottom 80px to clear BottomNav
- BottomNav fixed bottom (64px): 4 tabs — Home, Events, Directory, Profile
  - Active tab: icon + label in var(--tenant-primary)
  - Inactive: icon + label in var(--gather-text-muted)
  - Touch targets: full tab width, 64px height
```

**AdminShell (desktop — admin-facing)**
```
Structure:
- Sidebar fixed left (240px): Gather logo top, nav links grouped by section, collapses to 56px icon-only at 1024px
- TopBar fixed top, left offset by sidebar width (56px): page context left, user avatar + name right
- Main content: margin-left 240px (or 56px collapsed), padding 32px, max-width 1200px, centered
- Responsive: sidebar icon-only at 1024px, full sidebar at 1280px+
```

**AuthShell (unauthenticated screens)**
```
Centered card layout, max-width 440px
Gather logo top-center
Card: white, shadow-lg, border-radius-xl, padding 40px
Used for: /login, invitation acceptance, join request confirmation
```

**TenantGuard**
```
Props: requiredRole ('member' | 'admin' | 'org_admin' | 'super_admin'), children
Runs auth + membership check sequence on mount:
1. No session → redirect /login
2. No person record → redirect /onboarding
3. Tenant slug not found → render <NotFound />
4. No membership + open/gated tenant → redirect to join flow
5. No membership + invite_only tenant → render <InviteOnly />
6. Pending membership → render <PendingApproval />
7. Active membership, insufficient role → redirect to member home
8. Active membership, role satisfied → render children
Show full-screen loading skeleton while checking — never flash unauthorized content
```

**AppErrorBoundary**
```
Catches unhandled React errors
Shows: Gather logo centered, "Something went wrong. We're looking into it.", Reload button
Never shows stack trace to user
Wraps entire app at root level
```

**NotFound**
```
Clean 404 page: "We couldn't find that page.", link back to home
```

**PageHeader (admin)**
```
Props: title, subtitle (optional), action (optional: { label, onClick })
Title left in heading font, primary action Button top-right
Used at the top of every admin page below TopBar
```

---

## PART 7 — Route structure

Set up React Router with the following routes. Every route is listed with its guard level.

```
PUBLIC (no auth required):
/                                    → <LandingPage />
/login                               → <LoginPage />  [AuthShell]
/invite/:token                       → <InvitationAcceptPage />  [AuthShell]
/unauthorized                        → <UnauthorizedPage />

AUTHENTICATED (session required, no membership check):
/onboarding/*                        → <OnboardingFlow />

TENANT MEMBER (TenantGuard requiredRole="member"):
/:orgGroupSlug/:tenantSlug/          → <MemberHome />         [AppShell mobile]
/:orgGroupSlug/:tenantSlug/events/:eventId  → <EventDetail />
/:orgGroupSlug/:tenantSlug/events/:eventId/sessions/:sessionId → <SessionDetail />
/:orgGroupSlug/:tenantSlug/rsvp      → <RSVPFlow />
/:orgGroupSlug/:tenantSlug/pay/:attendeeRecordId → <PaymentFlow />
/:orgGroupSlug/:tenantSlug/directory → <MemberDirectory />
/:orgGroupSlug/:tenantSlug/memories  → <MemoryWall />
/:orgGroupSlug/:tenantSlug/profile   → <MemberProfile />

TENANT ADMIN (TenantGuard requiredRole="admin"):
/:orgGroupSlug/:tenantSlug/admin/              → <AdminDashboard />        [AdminShell]
/:orgGroupSlug/:tenantSlug/admin/members       → <MemberManagement />
/:orgGroupSlug/:tenantSlug/admin/members/join-requests → <JoinRequestQueue />
/:orgGroupSlug/:tenantSlug/admin/events        → <EventManagement />
/:orgGroupSlug/:tenantSlug/admin/events/:eventId → <EventEdit />
/:orgGroupSlug/:tenantSlug/admin/comms         → <Communications />
/:orgGroupSlug/:tenantSlug/admin/payments      → <PaymentOverview />
/:orgGroupSlug/:tenantSlug/admin/sponsors      → <SponsorManagement />
/:orgGroupSlug/:tenantSlug/admin/vendors       → <VendorManagement />
/:orgGroupSlug/:tenantSlug/admin/subgroups     → <SubgroupManagement />
/:orgGroupSlug/:tenantSlug/admin/branding      → <BrandingSettings />
/:orgGroupSlug/:tenantSlug/admin/settings      → <OrgSettings />

ORG GROUP ADMIN (TenantGuard requiredRole="org_admin"):
/:orgGroupSlug/admin/                → <OrgGroupDashboard />   [AdminShell]
/:orgGroupSlug/admin/groups          → <TenantList />
/:orgGroupSlug/admin/members         → <OrgMemberList />
/:orgGroupSlug/admin/settings        → <OrgGroupSettings />

VENDOR (authenticated, booking-scoped):
/vendor/                             → <VendorHome />
/vendor/:bookingId/                  → <VendorBookingDetail />
/vendor/:bookingId/profile           → <VendorProfileEdit />

SUPER ADMIN (TenantGuard requiredRole="super_admin"):
/platform/                           → <PlatformDashboard />   [AdminShell]
/platform/org-groups                 → <OrgGroupManagement />
/platform/tenants                    → <TenantManagement />
/platform/people                     → <PeopleManagement />
/platform/lookup-tables              → <LookupTableManager />
/platform/settings                   → <PlatformSettings />
```

Wrap the router in `AuthProvider` at the root. Wrap tenant-scoped routes in `TenantProvider`. Wrap the entire app in `AppErrorBoundary`.

---

## PART 8 — Dark mode wiring

Dark mode is controlled by `data-theme="dark"` on the `<html>` element. It is never driven by a media query.

On app load:
1. Read `person.dark_mode_pref` from AuthContext
2. If `dark` → set `document.documentElement.setAttribute('data-theme', 'dark')`
3. If `light` → remove attribute
4. If `system` → read `window.matchMedia('(prefers-color-scheme: dark)')` and apply accordingly
5. If no person record yet (unauthenticated) → follow system preference

When user toggles dark mode:
1. Update local state immediately (instant visual feedback)
2. Write new value to `person.dark_mode_pref` in Supabase (confirmed write, no optimistic needed here)

---

## PART 9 — What NOT to build in this prompt

Do not generate any screen content beyond the scaffold. This prompt produces:
- Token file
- Context providers
- Core hooks (stubs with correct signatures are fine)
- Component library (fully built)
- Route structure (configured but pages can be placeholder `<div>` for now)
- Dark mode wiring

Do not build yet:
- Any actual page content
- Any data tables with real data
- Any forms
- Any auth flow screens (those come in 01-auth-chain.md)

When complete, confirm: "Foundation scaffold complete. Tokens, contexts, hooks, components, and routes are in place. Ready for 01-auth-chain."

---

*Gather — docs/lovable/00-foundation.md*
*Last updated: May 2026*
