[org-type-playbook.md](https://github.com/user-attachments/files/28082235/org-type-playbook.md)

# Gather — Org Type Playbook

**Repo:** kristinseed/gather  
**Path:** docs/platform/org-type-playbook.md  
**Status:** Living document — update when any org_type is added or modified  
**Last updated:** May 2026

---

## Purpose

Every org_type in the `org_type` lookup table carries a set of business rules that must be explicitly decided before that type goes live. This document is the required checklist. No new org_type row should be activated (`is_active = true`) without all fields in this checklist answered and recorded.

The super admin UI for lookup table management (item AJ) should eventually enforce this inline. Until then, this file is the gate.

---

## Required decisions for every new org_type

When adding a new org_type, answer every question below and record the values in the schema fields listed.

### 1. Succession inactivity threshold
How long can the org admin be inactive before the platform flags the org as unmanaged?

- **Schema field:** `org_type.succession_inactivity_days` (int)
- **Consideration:** Does this org type have regular scheduled activity (annual events, rotating officers)? If yes, use a shorter window. If it's naturally episodic (family reunions every few years), use a longer window.

### 2. Co-admin required?
Does this org type require a second admin before certain actions are allowed?

- **Schema field:** `org_type.co_admin_required` (bool)
- **Consideration:** Institutional orgs (fraternity, civic, military) should require it. Personal/informal orgs (family) should nudge but not require at creation.

### 3. Generic/institutional email required?
Does this org type require a non-personal org contact email (e.g. info@, general@, alumni@) at some point in the lifecycle?

- **Schema field:** `tenant.org_contact_email`, `tenant.org_contact_email_verified`
- **Trigger options:** At creation / after first event / after first payment / never required
- **Consideration:** Orgs with institutional backing (fraternity, military unit, school) should require it. Informal orgs (family) should capture it if available but never block on it.

### 4. Succession policy type
Which succession model applies when the admin goes inactive?

- **Schema field:** `tenant.succession_policy` (enum: `activity_based` / `institutional_email` / `platform_managed`)
- `activity_based` — temporary co-admin assigned from most active members, prompt to assume ownership
- `institutional_email` — platform contacts the org via captured institutional email, human resolution required
- `platform_managed` — routes directly to platform admin work queue, no automated reassignment

### 5. Org website redirect
If the org goes unmanaged, should members be redirected to an external org website with a context packet?

- **Schema field:** `org_group.org_contact_website` or `tenant.org_contact_website`
- **Consideration:** Only meaningful if the org type typically has an external web presence. Family orgs usually don't. Fraternities and civic orgs usually do.
- **Follow-up window:** Platform queues a 30-day check-in after redirect fires to see if org was reactivated.

### 6. Annual anniversary email
Should admins and committee members receive an annual "it's been a year" stewardship email prompting them to review org details and consider ownership transfer?

- **Default:** Yes for all org types
- **Consideration:** Timing matters — for episodic orgs (family, class reunion) the anniversary email should also prompt "are you planning another event?"

### 7. Transfer of ownership prompt triggers
At what moments should the platform proactively prompt ownership transfer?

- **Default triggers for all org types:** Event close + annual anniversary email
- **Additional triggers to consider:** Officer rotation cycle for civic/fraternity orgs, graduation cycle for school class orgs

---

## Current org_type decisions

| org_type | inactivity_days | co_admin_required | generic_email_trigger | succession_policy | website_redirect | anniversary_email |
|---|---|---|---|---|---|---|
| family | 540 | false (nudge only) | never required | activity_based | if available | yes |
| high_school | 730 | true | after first event (10+ RSVPs or first payment) | institutional_email | yes | yes |
| middle_school | 730 | true | after first event | institutional_email | yes | yes |
| college | 730 | true | after first event | institutional_email | yes | yes |
| fraternity | 300 | true | after first event | institutional_email | yes | yes |
| sorority | 300 | true | after first event | institutional_email | yes | yes |
| military | 300 | false (nudge only) | if available | activity_based | if available | yes |
| civic | 300 | true | at creation | institutional_email | yes | yes |
| other | 540 | false (nudge only) | never required | platform_managed | if available | yes |

---

## What goes wrong if you skip this

- A new org_type activates with `succession_inactivity_days = null` — succession logic throws an error or never fires
- Co-admin nudge never shows because `co_admin_required` is null — orgs of this type become single-admin with no safety net
- Members of an unmanaged org of this type get no redirect and no context — dead end experience
- Platform admin inherits an org they have no policy for — work queue item with no resolution path

---

## Process for adding a new org_type

1. Answer all 7 questions above
2. Update the decisions table in this file
3. Add the row to `org_type` with all required fields populated
4. Update `platform-settings.md` if any new configurable defaults are introduced
5. Set `is_active = true` only after steps 1–4 are complete
6. Note the addition in the session log
