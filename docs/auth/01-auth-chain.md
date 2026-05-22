# Gathr — Auth Chain Spec
**Item CA | Magic link auth — beta**
Version 1.1 — May 2026

---

## What this document is

The authoritative spec for every step between "user receives an invitation email" and "user sees their tenant dashboard." Lovable builds every auth-related screen from this document. Nothing in this flow is left to Lovable's defaults.

Beta scope: magic link only. Google OAuth, Facebook OAuth, and identity resolution steps 2/3/4 are deferred to pre-launch.

---

## URL structure (canonical)

All tenant-scoped URLs follow this pattern:

```
/o/{org-group-slug}/{tenant-slug}/
```

Examples:
```
/o/raymond-lincolnwood-hs/class-of-1990/
/o/raymond-lincolnwood-hs/class-of-1990/dashboard
/o/raymond-lincolnwood-hs/class-of-1990/members
/o/lawrenceville-hs/class-of-1986/dashboard
```

The org-group slug and tenant slug are both present in every tenant-scoped URL. There are no shortcuts. This enables org-group level pages (`/o/raymond-lincolnwood-hs/`) as a future destination.

Platform-level routes:
```
/                          → marketing / landing (future)
/login                     → magic link request form
/auth/callback             → Supabase OAuth callback handler (internal)
/admin                     → super admin (platform_user only)
```

---

## The invitation magic link

When an admin imports contacts and confirms, Gathr:
1. Creates an `invitation` row with a unique `token` (UUID)
2. Sends an email via Resend from `invitations@mail.gathr.co`
3. From name: `[Tenant name] via Gathr` (e.g. "Class of 1990 via Gathr")

The magic link URL embedded in the email:
```
https://gathr.co/invite/{token}
```

This is NOT a Supabase magic link. It is Gathr's own token. Supabase auth is triggered after token validation, not before.

Token validity: 30 days default. Configurable per invitation (future).

---

## Full auth flow — step by step

### Entry point A: Invitation link (`/invite/{token}`)

The most common beta path. Invitee clicks link in email.

```
Step 1 — Token lookup
  - Query invitation table WHERE token = {token} AND deleted_at IS NULL
  - If not found → route to /invite/invalid (see error states)
  - If found AND status = 'accepted' → route to tenant dashboard (already a member)
  - If found AND expires_at < now() → route to /invite/expired (see error states)
  - If valid → continue

Step 2 — Check for existing Supabase session
  - Call supabase.auth.getSession()
  - If session exists AND session email matches invitation.recipient_email:
      → skip to Step 5 (post-auth routing)
  - If session exists but email does NOT match:
      → sign out existing session, continue to Step 3
  - If no session → continue to Step 3

Step 3 — Show invitation landing page (tenant-branded)
  - Load branding for invitation.tenant_id
  - Render: tenant logo, tenant primary color, warm welcome message
  - Heading: "You're invited to [Tenant name]"
  - Body: "We'll send a sign-in link to [recipient_email]. One click and you're in."
  - Single button: "Send my sign-in link"
  - No password field. No form. One tap.
  - If invitation has a personal note from the admin, show it above the button.

Step 4 — Send Supabase magic link
  - Call supabase.auth.signInWithOtp({ email: invitation.recipient_email })
  - Supabase sends its own magic link email to recipient_email
  - Show confirmation screen: "Check your email — we sent a link to [email]"
  - Do not auto-redirect. Wait for the user to click the Supabase link.
  - Supabase redirectTo must be set to: https://gathr.co/auth/callback?invite={token}

Step 5 — Auth callback handler (/auth/callback)
  - Supabase exchanges the OTP and creates/confirms the auth session
  - Read invite token from query param
  - Look up invitation row again to get tenant_id
  - Look up person WHERE email = session.user.email
    - If person found AND person.auth_user_id IS NULL:
        → SET person.auth_user_id = session.user.id
    - If person found AND person.auth_user_id = session.user.id:
        → no change needed
    - If person NOT found:
        → CREATE person row (first_name/last_name from invitation if available,
           email from session, claimed = true, auth_user_id = session.user.id)
        → CREATE membership row (tenant_id from invitation, org_role = 'member',
           status = 'active')
  - UPDATE invitation SET status = 'accepted', accepted_at = now()
  - Write activity_event: invitation.accepted (actor_id = person.id,
    object_id = invitation.id, tenant_id = invitation.tenant_id)

Step 6 — Route to dashboard
  - Look up tenant slug and org_group slug for invitation.tenant_id
  - Redirect to: /o/{org-group-slug}/{tenant-slug}/dashboard
  - Dashboard shows: welcome banner (first visit only, dismissible),
    event hero if event exists, member list CTA
  - No profile completion gate. Profile nudge appears as a dismissible
    banner on the dashboard: "Add a photo so classmates recognize you →"
```

---

### Entry point B: Direct login (`/login`)

For returning users or admins who aren't coming from an invitation link.

```
Step 1 — Magic link request form
  - Single email field
  - Button: "Send my sign-in link"
  - No password. No OAuth buttons (beta).
  - Helper text: "We'll email you a link — no password needed."

Step 2 — Send Supabase magic link
  - Call supabase.auth.signInWithOtp({ email })
  - Supabase redirectTo: https://gathr.co/auth/callback
  - Show: "Check your email — link sent to [email]"

Step 3 — Auth callback (/auth/callback)
  - No invite token in query params this time
  - Look up person WHERE email = session.user.email
    - If found: wire auth_user_id if needed (same as Entry A Step 5)
    - If NOT found: show "We couldn't find an account for this email.
      Check your invitation or contact your organizer." — do not auto-create
      a person record without tenant context.
  - Look up membership for this person
    - If one active membership: route to that tenant's dashboard
    - If multiple memberships (future): route to org picker (deferred — beta
      users have single org)
    - If no membership: show "You don't have access to any orgs yet."
      with a contact-your-organizer message
```

---

## Route protection rules

Every route under `/o/{org-group-slug}/{tenant-slug}/` must:

1. Check for active Supabase session. No session → redirect to `/login`
2. Confirm `person.auth_user_id` matches `session.user.id`
3. Confirm active `membership` row exists for this person + tenant, with `deleted_at IS NULL` and `status = 'active'`
4. Check `org_role` on membership and set role context for the session
5. If any check fails → redirect to `/login` with a `?reason=` param for debugging

Role routing after auth:
- `org_admin` or `committee` → `/dashboard` (admin view)
- `member` or `guest_linked` → `/dashboard` (member view — same route, different UI)
- `platform_user` (super admin) → `/admin` regardless of tenant context

---

## Error states

### `/invite/invalid`
> "This link isn't working."
> "It may have already been used, or it was entered incorrectly. Contact your organizer for a new invitation."

### `/invite/expired`
> "This invitation has expired."
> "Invitations are valid for 30 days. Ask your organizer to resend it."
> CTA: "Request a new link" → opens magic link request form pre-filled with recipient_email if available

### Auth callback failure (Supabase OTP error)
> "Something went wrong signing you in."
> "Try requesting a new link." → back to /login
> Log the error to activity_event with action_type = `auth.login.failed`

### No membership found after auth
> "You don't have access to any groups yet."
> "If you received an invitation, check that you signed in with the same email address it was sent to."
> CTA: "Try a different email" → back to /login

---

## Supabase configuration required

Before this flow works in any environment:

1. **Supabase Auth → Email provider**: confirm magic link emails are enabled
2. **Redirect URLs**: add to Supabase allowed redirect URLs:
   - `https://gathr.co/auth/callback`
   - `https://gather-app-nu.vercel.app/auth/callback` (current staging)
   - `http://localhost:5173/auth/callback` (local dev)
3. **Email templates**: customize the Supabase magic link email template to match Gathr branding (or suppress it in favor of Gathr's own email — see note below)

> **Note on two emails:** The current flow sends TWO emails — Gathr's invitation email, then Supabase's magic link email. For beta this is acceptable. Pre-launch, consolidate to one: Gathr sends a custom email that embeds the Supabase OTP link directly, suppressing Supabase's default email. Tracked as roadmap item CI.

---

## Data contract summary

| Action | Table write | Notes |
|--------|-------------|-------|
| Token validated | — | Read only |
| Magic link sent | — | Supabase handles |
| Auth confirmed | `person.auth_user_id` | Set if null |
| New person | `person` + `membership` | Only if no existing record |
| Invitation consumed | `invitation.status = 'accepted'` | |
| Activity logged | `activity_event` | `invitation.accepted` + `auth.login.success` |

---

## What this spec does NOT cover

- Google OAuth, Facebook OAuth (deferred to pre-launch)
- Identity resolution steps 2/3/4 — email match, fuzzy match, no-match (item CC, deferred)
- Multi-org picker (item CD, deferred)
- Profile completion flow (future — nudge on dashboard is sufficient for beta)
- The invitation email template itself (item A — blocked on Resend/DNS setup)
- Consolidating to single email (roadmap item CI)

---

## Open items before building in Lovable

| Item | Status |
|------|--------|
| A — Resend account + `mail.gathr.co` DNS verified | Not started |
| BY — `gathr.co` pointed at Vercel | Not started |
| Supabase redirect URLs updated for gathr.co | Not started |

The flow can be built and tested on `gather-app-nu.vercel.app` before gathr.co is live. All redirect URLs just need the staging domain in the allowed list.

---

*Reference alongside CB-contact-import-spec.md when building auth and import screens in Lovable. The invitation token created in CB is the entry point for Entry A above.*
