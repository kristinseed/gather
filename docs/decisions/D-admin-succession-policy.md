[D-admin-succession-policy.md](https://github.com/user-attachments/files/28082226/D-admin-succession-policy.md)

# Decision Record: Admin Succession Policy

**ID:** D-admin-succession-policy  
**Repo:** kristinseed/gather  
**Path:** docs/decisions/D-admin-succession-policy.md  
**Status:** Decided  
**Session:** May 2026  

---

## Decision

Admin succession is triggered by **admin inactivity**, not org inactivity. The clock resets on admin login only. Member activity does not reset the clock.

---

## Core model

When an admin crosses the inactivity threshold for their org_type, the org enters an **unmanaged state**:

- Temporary reassignment routes to the platform admin work queue — never silently absorbed by the platform
- The unmanaged state is clearly labeled in the UI with a member-facing banner
- All pending join requests are held with a member-facing message
- Draft events are frozen and cannot be published
- Outbound communications are blocked
- If `org_contact_website` exists, members receive a redirect with a context packet (member record summary, event history, plain-language Gather explanation) and a 30-day follow-up to check if the org reactivated

---

## Inactivity thresholds by org_type

Stored in `org_type.succession_inactivity_days`. Editable by super admin without a code deploy.

| org_type | days |
|---|---|
| family | 540 (18 months) |
| high_school / middle_school / college | 730 (24 months) |
| fraternity / sorority / civic | 300 (10 months) |
| military | 300 (10 months) |
| other | 540 (18 months) |

**Rationale:** Institutional orgs with regular leadership cycles (fraternity, civic) warrant a shorter window. School class orgs operate on 5-year reunion cycles but 24 months catches true abandonment before the next cycle. Family orgs are episodic but two admins provides a safety net at 18 months.

---

## Co-admin requirement

**Minimum two admins** for family orgs before the org is considered stable. All other org types: co-admin is required to publish an event (not to create one).

Progressive nudge escalation — `co_admin_required_by` date is set on tenant when the first warning fires:

- **Day 1:** Persistent dashboard warning, dismissible
- **Day 30:** Modal on login, must actively dismiss
- **Day 60:** Blocks event publish until second admin confirmed and accepted

Second admin receives a confirmation email and must actively accept — passive addition does not count. This prevents admins from adding a fake account to clear the block.

---

## Succession paths by org_type

| org_type | path |
|---|---|
| family | Activity-based: temporary co-admin from 2–3 most active members, prompt to assume ownership |
| high_school / middle_school / college | Institutional email: platform contacts org via `org_contact_email`, human resolution |
| fraternity / sorority / civic | Institutional email: same as above |
| military | Activity-based: same as family |
| other | Platform managed: routes to platform admin work queue, no automated reassignment |

---

## Generic/institutional email requirement

Required for institutional org types. Trigger: after first real event, defined as first event with 10+ RSVPs or first payment processed.

Not required at creation — gates adoption for individual organizers who don't have access to an institutional email yet.

---

## Transfer of ownership (proactive path)

Transfer of admin is a first-class flow in org settings — not just a succession fallback.

- Current admin selects recipient
- Recipient receives notification and must actively accept
- All transfers logged to `succession_event`

**Proactive prompt triggers:**
- On event close: "Who's leading the next one?"
- On annual creation anniversary: email to all admins and committee members — "It's been a year — is everything still accurate?"

---

## Death / incapacitation path

No fields needed on tenant or org_group. This is a person-level event, not an org-level one.

Resolution path:
- "Report an issue with this org" contact link on every org page when unmanaged
- Routes to platform admin work queue as a support form submission
- Work queue item references `tenant_id` and `person_id` of reported admin
- Logged to `succession_event` with `triggered_by = death_report` and free-text `notes`

---

## Schema additions required

**On `tenant`:**
- `org_contact_email` string
- `org_contact_email_verified` boolean
- `org_contact_website` string
- `last_event_at` timestamp
- `succession_policy` enum: `activity_based / institutional_email / platform_managed`
- `co_admin_required_by` date

**On `org_group`:**
- `institutional_contact_email` string
- `org_contact_website` string
- `succession_policy` enum

**On `membership`:**
- `last_activity_at` timestamp

**On `org_type` lookup table:**
- `succession_inactivity_days` int
- `co_admin_required` boolean

**New table: `succession_event`:**
```
id                  uuid PK
tenant_id           uuid FK → tenant
triggered_by        enum: inactivity / manual_transfer / death_report / platform_reassignment
previous_admin_id   uuid FK → person
new_admin_id        uuid FK → person (nullable — may not be resolved yet)
triggered_at        timestamp
resolved_at         timestamp (nullable)
notes               text
```

---

## Related documents

- `docs/platform/org-type-playbook.md` — required checklist when adding any new org_type
- `docs/platform/platform-settings.md` — all configurable values and their current defaults
