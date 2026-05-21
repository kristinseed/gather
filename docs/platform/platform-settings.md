[platform-settings.md](https://github.com/user-attachments/files/28082240/platform-settings.md)

# Gather — Platform Settings Reference

**Repo:** kristinseed/gather  
**Path:** docs/platform/platform-settings.md  
**Status:** Living document — update whenever a new configurable value is introduced  
**Last updated:** May 2026

---

## Purpose

Every configurable platform value lives here — what it controls, where it's stored in the schema, who can change it, and what the current default is. This file feeds the super admin settings UI (item AJ) when it's built. Until then it's the authoritative reference so defaults don't live only in someone's memory.

---

## Succession + Admin Continuity

| Setting | Current default | Schema location | Who can edit | Notes |
|---|---|---|---|---|
| Succession inactivity threshold | Per org_type (see org-type-playbook.md) | `org_type.succession_inactivity_days` | Super admin | Editable per org_type without code deploy |
| Co-admin required | Per org_type (see org-type-playbook.md) | `org_type.co_admin_required` | Super admin | Drives nudge vs. hard requirement |
| Co-admin nudge — first escalation | 30 days after warning first fires | Hardcoded business rule | Platform dev | Move to settings table in v1.5 |
| Co-admin nudge — event publish block | 60 days after warning first fires | Hardcoded business rule | Platform dev | Move to settings table in v1.5 |
| Generic email trigger | After first event (10+ RSVPs or first payment) | Hardcoded business rule | Platform dev | Applies to org types where generic email is required |
| Org website redirect follow-up window | 30 days | Hardcoded business rule | Platform dev | Check-in after unmanaged redirect fires |
| Annual anniversary email | On for all org types | Hardcoded business rule | Platform dev | Fires on tenant creation anniversary |
| Transfer of ownership prompt — event close | On | Hardcoded business rule | Platform dev | Prompt fires when event status → completed |
| Transfer of ownership prompt — anniversary | On | Hardcoded business rule | Platform dev | Included in anniversary email |
| Succession clock reset trigger | Admin login only | Hardcoded business rule | Platform dev | Member activity does not reset the clock |

---

## Invitations + Join Flow

| Setting | Current default | Schema location | Who can edit | Notes |
|---|---|---|---|---|
| Invitation expiry | 30 days | `invitation.expires_at` | Org admin (per invitation) | Default applied at creation |
| Join request auto-approval | Per tenant `join_policy` | `tenant.join_policy` | Org admin | Values: auto_approve / admin_approve / invite_only |

---

## Unmanaged Org State

| Setting | Current default | Schema location | Who can edit | Notes |
|---|---|---|---|---|
| Pending join requests during unmanaged window | Hold with member-facing message | Hardcoded business rule | Platform dev | No auto-approval while unmanaged |
| Draft events during unmanaged window | Frozen | Hardcoded business rule | Platform dev | Cannot be published |
| Outbound communications during unmanaged window | Blocked | Hardcoded business rule | Platform dev | No blast emails while unmanaged |
| Member redirect context packet | Included when org_contact_website exists | Hardcoded business rule | Platform dev | Includes member record summary + event history |

---

## Branding

| Setting | Current default | Schema location | Who can edit | Notes |
|---|---|---|---|---|
| Branding versioning | New record on every change, active_to set on previous | `branding.active_from / active_to` | Org admin | Historical events render with branding active at their date |
| Dark mode auto-generated color | Lighter stop of primary_color if no dark override | `branding.primary_color_dark` | Org admin | Auto-generated if null |

---

## Platform Defaults (Gather unbranded theme)

| Token | Value | Notes |
|---|---|---|
| `--gather-primary` | #BA7517 | Amber accent |
| `--gather-primary-dark` | #EF9F27 | Dark mode amber |
| `--gather-surface` | #FDFCFA | Warm white |
| `--gather-surface-2` | #F5F3EE | Cards, stat backgrounds |
| `--gather-text` | #2C2C2A | Primary text |
| `--gather-text-muted` | #5F5E5A | Secondary text |
| `--gather-border` | #E8E4DC | Warm gray border |
| Dark mode surface | #1C1B18 | |
| Dark mode text | #F5F3EE | |

---

## Settings Hardcoded Today → Move to Admin UI in v1.5

These are currently hardcoded business rules that should become super-admin-editable without a code deploy. Track here until they're migrated.

- Co-admin nudge escalation days (30 / 60)
- Generic email trigger threshold (10 RSVPs or first payment)
- Org website redirect follow-up window (30 days)
- Succession clock reset trigger definition

---

## How to use this file

When you introduce any new configurable value:
1. Add it to the relevant section above
2. Note whether it's hardcoded or schema-stored
3. Note who can edit it and at what UI layer
4. If it's hardcoded, add it to the "Move to Admin UI in v1.5" section if it should eventually be editable
