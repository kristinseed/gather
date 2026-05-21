# Gather — Activity Event Vocabulary
**Canonical action type registry and metadata schema**
Version 1.0 — May 2026

---

## Purpose

This document is the authoritative reference for the `activity_event` table. It defines every valid `action_type`, the `object_type` vocabulary, the `metadata` JSONB contract per action, and the rules the nudge engine and audit log rely on.

Every action type registered here must also exist as a row in the `activity_event_action_type` lookup table. Super admin manages that table via UI. The front end and back end never hardcode action type strings — they reference the lookup table.

---

## Table structure (reference)

```sql
activity_event (
  id              uuid PK,
  actor_id        uuid FK → person.id (null if actor_type = 'system'),
  actor_type      text FK → actor_type lookup,
  action_type     text FK → activity_event_action_type lookup,
  object_type     text FK → activity_event_object_type lookup,
  object_id       uuid,
  tenant_id       uuid FK → tenant.id (null for platform-level events),
  org_group_id    uuid FK → org_group.id (null for tenant-level events),
  metadata        jsonb,
  created_at      timestamptz default now(),
  effective_at    timestamptz,   -- when the action took effect; may differ from created_at
  deleted_at      timestamptz    -- soft delete, audit rows are never hard deleted
)
```

---

## Lookup tables required

All of the following must be created following the standard Gather lookup table pattern:
- uuid PK
- `value` text unique (the slug used in code)
- `label` text (human-readable, shown in audit log UI)
- `description` text
- `is_active` boolean default true
- `created_at` timestamptz
- `deleted_at` timestamptz

Super admin manages all values via the lookup table manager UI. No value is ever hard deleted — only deactivated via `is_active`.

### `actor_type` lookup

| value | label | description |
|---|---|---|
| `person` | Person | A human user acting through the UI or API |
| `system` | System | Automated platform action (scheduled job, trigger, expiry) |
| `platform_admin` | Platform admin | Super admin acting via the platform admin UI |

### `activity_event_object_type` lookup

| value | label |
|---|---|
| `person` | Person |
| `identity` | Identity |
| `membership` | Membership |
| `invitation` | Invitation |
| `join_request` | Join request |
| `tenant` | Tenant |
| `org_group` | Org group |
| `event` | Event |
| `event_session` | Event session |
| `attendee_record` | Attendee record |
| `session_attendee` | Session attendee |
| `communication` | Communication |
| `media` | Media |
| `memory` | Memory |
| `payment` | Payment |
| `branding` | Branding |
| `subgroup` | Subgroup |
| `vendor_booking` | Vendor booking |
| `sponsor` | Sponsor |
| `survey` | Survey |
| `survey_response` | Survey response |
| `platform_user` | Platform user |
| `lookup_table_value` | Lookup table value |
| `import_batch` | Import batch |

### `person_deletion_reason` lookup

FK referenced when `person.deleted_at` is set. Determines downstream data retention behavior.

| value | label | description |
|---|---|---|
| `self_requested` | Self-requested | Person requested deletion via profile settings |
| `admin_removed` | Admin removed | Org admin or platform admin removed the record |
| `duplicate_merged` | Duplicate merged | Record was the deprecated side of a person merge |
| `platform_suspended` | Platform suspended | Account suspended for policy violation |
| `inactivity_purge` | Inactivity purge | Automated purge after inactivity threshold (future) |

---

## Metadata contract

### Universal fields — present on every activity_event row

```jsonb
{
  "ip_address": "string | null",         -- for auth events only; null on all others
  "user_agent": "string | null",         -- for auth events only; null on all others
  "source": "web | mobile | api | system"
}
```

### Merge tombstone rule

When `auth.person.merged` fires, the deprecated person's `actor_id` and `object_id` references in all prior activity_event rows are repointed to the surviving `person_id`. The merge event records both IDs in metadata. This is the only mechanism that keeps the audit log coherent after a merge.

```jsonb
// auth.person.merged metadata
{
  "surviving_person_id": "uuid",
  "deprecated_person_id": "uuid",
  "merged_by": "person_id | 'system'",
  "evidence": "string",
  "rows_repointed": "integer"
}
```

---

## Action type registry

### Authentication & identity

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `auth.login.success` | Login succeeded | person | person | v1 |
| `auth.login.failed` | Login failed | system | person | v1 |
| `auth.logout` | Logged out | person | person | v1 |
| `auth.password.reset.requested` | Password reset requested | person | person | v1 |
| `auth.identity.linked` | OAuth identity linked | person | identity | v1 |
| `auth.identity.claim.submitted` | Record claim submitted | person | person | v1 |
| `auth.identity.claim.approved` | Record claim approved | person / platform_admin | person | v1 |
| `auth.identity.claim.rejected` | Record claim rejected | person / platform_admin | person | v1 |
| `auth.person.merged` | Person records merged | person / platform_admin | person | v1 |

```jsonb
// auth.login.failed metadata
{
  "reason": "invalid_credentials | account_not_found | provider_error",
  "provider": "google | email"
}

// auth.identity.claim.submitted metadata
{
  "claimed_person_id": "uuid",
  "match_confidence": "exact | fuzzy | manual"
}

// auth.person.merged — see merge tombstone rule above
```

---

### Membership

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `membership.created` | Membership created | person / system / platform_admin | membership | v1 |
| `membership.status.changed` | Membership status changed | person / platform_admin | membership | v1 |
| `membership.role.changed` | Membership role changed | person / platform_admin | membership | v1 |
| `membership.join_request.submitted` | Join request submitted | person | join_request | v1 |
| `membership.join_request.approved` | Join request approved | person / platform_admin | join_request | v1 |
| `membership.join_request.declined` | Join request declined | person / platform_admin | join_request | v1 |
| `membership.deleted` | Membership removed | person / platform_admin | membership | v1 |

```jsonb
// membership.status.changed metadata
{
  "previous_status": "string",
  "new_status": "string",
  "reason": "string | null"
}

// membership.role.changed metadata
{
  "previous_role": "string",
  "new_role": "string"
}
```

---

### Invitation

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `invitation.created` | Invitation created | person / platform_admin | invitation | v1 |
| `invitation.sent` | Invitation sent | person / system | invitation | v1 |
| `invitation.opened` | Invitation opened | person | invitation | v1 |
| `invitation.accepted` | Invitation accepted | person | invitation | v1 |
| `invitation.declined` | Invitation declined | person | invitation | v1 |
| `invitation.expired` | Invitation expired | system | invitation | v1 |
| `invitation.resent` | Invitation resent | person / platform_admin | invitation | v1 |
| `invitation.revoked` | Invitation revoked | person / platform_admin | invitation | v1 |

```jsonb
// invitation.created metadata
{
  "recipient_email": "string",
  "scope": "tenant | event",
  "scope_id": "uuid",
  "expires_at": "timestamptz",
  "has_personal_note": "boolean"
}

// invitation.opened / accepted / declined metadata
{
  "token_age_hours": "integer"
}
```

---

### Member import

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `import.started` | Import started | person | import_batch | v1 |
| `import.completed` | Import completed | person / system | import_batch | v1 |
| `import.failed` | Import failed | system | import_batch | v1 |
| `import.row.created` | Import row — new record created | system | person | v1 |
| `import.row.updated` | Import row — existing record updated | system | person | v1 |
| `import.row.skipped` | Import row — duplicate, no change | system | person | v1 |
| `import.row.flagged` | Import row — ambiguous match, needs review | system | person | v1 |

```jsonb
// import.started metadata
{
  "source": "csv | excel | paste",
  "row_count": "integer",
  "tenant_id": "uuid"
}

// import.completed metadata
{
  "rows_created": "integer",
  "rows_updated": "integer",
  "rows_skipped": "integer",
  "rows_flagged": "integer",
  "duration_ms": "integer"
}

// import.row.flagged metadata
{
  "reason": "ambiguous_name | missing_email | possible_duplicate",
  "candidate_person_ids": ["uuid"]
}
```

---

### RSVP & attendance

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `rsvp.created` | RSVP submitted | person | attendee_record | v1 |
| `rsvp.updated` | RSVP updated | person / platform_admin | attendee_record | v1 |
| `rsvp.withdrawn` | RSVP withdrawn | person / platform_admin | attendee_record | v1 |
| `rsvp.waitlisted` | Added to waitlist | system | attendee_record | v1 |
| `rsvp.promoted` | Promoted from waitlist | system | attendee_record | v1 |
| `attendance.checked_in` | Checked in day-of | person / platform_admin | attendee_record | future |

```jsonb
// rsvp.created metadata
{
  "rsvp_status": "string",
  "plus_one_count": "integer",
  "has_meal_preference": "boolean",
  "has_dietary_restrictions": "boolean"
}

// rsvp.updated metadata
{
  "previous_status": "string",
  "new_status": "string",
  "fields_changed": ["string"]
}

// rsvp.waitlisted / rsvp.promoted metadata
{
  "waitlist_position": "integer",
  "headcount_target": "integer",
  "confirmed_count": "integer"
}
```

---

### Event

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `event.created` | Event created | person | event | v1 |
| `event.updated` | Event updated | person | event | v1 |
| `event.published` | Event published | person | event | v1 |
| `event.unpublished` | Event unpublished | person | event | v1 |
| `event.closed` | Event closed | person / system | event | v1 |
| `event.completed` | Event marked completed | person | event | v1 |
| `event.deleted` | Event deleted | person / platform_admin | event | v1 |

```jsonb
// event.updated metadata
{
  "fields_changed": ["string"],
  "previous_values": { "field": "value" },
  "new_values": { "field": "value" }
}

// event.published metadata
{
  "headcount_target": "integer",
  "discoverability": "string",
  "join_policy": "string"
}
```

---

### Event session

Mirrors event lifecycle exactly.

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `event.session.created` | Session created | person | event_session | v1 |
| `event.session.updated` | Session updated | person | event_session | v1 |
| `event.session.published` | Session published | person | event_session | v1 |
| `event.session.unpublished` | Session unpublished | person | event_session | v1 |
| `event.session.closed` | Session closed | person / system | event_session | v1 |
| `event.session.completed` | Session marked completed | person | event_session | v1 |
| `event.session.cancelled` | Session cancelled | person / platform_admin | event_session | v1 |
| `event.session.deleted` | Session deleted | person / platform_admin | event_session | v1 |
| `session.attendee.added` | Attendee added to session | person / system | session_attendee | v1 |
| `session.attendee.removed` | Attendee removed from session | person / system | session_attendee | v1 |

```jsonb
// event.session.updated metadata
{
  "fields_changed": ["string"],
  "previous_values": { "field": "value" },
  "new_values": { "field": "value" }
}

// event.session.cancelled metadata
{
  "reason": "string | null",
  "attendees_notified": "boolean"
}
```

---

### Communications

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `communication.drafted` | Communication drafted | person | communication | v1 |
| `communication.sent` | Communication sent | person / system | communication | v1 |
| `communication.delivery.failed` | Delivery failed | system | communication | v1 |
| `communication.opened` | Communication opened | system | communication | v1 |
| `communication.clicked` | Link clicked | system | communication | v1 |
| `communication.bounced` | Communication bounced | system | communication | v1 |
| `communication.subscribed` | Subscribed to communications | person / system | membership | v1 |
| `communication.resubscribed` | Resubscribed to communications | person | membership | v1 |
| `communication.unsubscribed` | Unsubscribed from communications | person / system | membership | v1 |

```jsonb
// communication.sent metadata
{
  "channel": "email | sms",
  "audience": "string",
  "recipient_count": "integer",
  "subject": "string | null",
  "template_used": "string | null"
}

// communication.delivery.failed metadata
{
  "reason": "string",
  "recipient_person_id": "uuid",
  "provider_error_code": "string | null"
}

// communication.subscribed / resubscribed / unsubscribed metadata
{
  "channel": "email | sms",
  "trigger": "membership_created | explicit_opt_in | explicit_opt_out | bounce | complaint"
}
```

---

### Payments

Schema hooks only. No UI in v1.

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `payment.initiated` | Payment initiated | person | payment | future |
| `payment.succeeded` | Payment succeeded | system | payment | future |
| `payment.failed` | Payment failed | system | payment | future |
| `payment.refunded` | Payment refunded | person / platform_admin | payment | future |
| `payment.waived` | Payment waived | person / platform_admin | payment | future |

```jsonb
// payment.succeeded / failed metadata
{
  "amount_cents": "integer",
  "currency": "string",
  "processor": "stripe",
  "processor_ref": "string",
  "attendee_record_id": "uuid"
  // Never store card numbers, CVV, or full PAN — processor ref only
}
```

---

### Person profile

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `person.profile.updated` | Profile updated | person / platform_admin | person | v1 |
| `person.photo.uploaded` | Profile photo uploaded | person | person | v1 |
| `person.preference.changed` | Preference changed | person | person | v1 |
| `person.deleted` | Person soft deleted | person / platform_admin / system | person | v1 |

```jsonb
// person.profile.updated metadata
{
  "fields_changed": ["string"]
  // Never log previous or new values for profile fields — PII
}

// person.preference.changed metadata
{
  "preference": "dark_mode_pref | font_size_pref",
  "new_value": "string"
  // Previous value not needed — last-write-wins
}

// person.deleted metadata
{
  "deletion_reason": "string FK → person_deletion_reason",
  "initiated_by": "person_id | 'system'",
  "data_retention_applied": "boolean"
}
```

---

### Branding & settings

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `branding.updated` | Branding updated | person / platform_admin | branding | v1 |
| `tenant.settings.updated` | Tenant settings updated | person / platform_admin | tenant | v1 |
| `org_group.settings.updated` | Org group settings updated | person / platform_admin | org_group | v1 |

```jsonb
// branding.updated metadata
{
  "fields_changed": ["string"],
  "previous_branding_id": "uuid",
  "new_branding_id": "uuid"
}

// tenant.settings.updated / org_group.settings.updated metadata
{
  "fields_changed": ["string"]
  // No previous/new values — settings may contain sensitive config
}
```

---

### Media & memory wall

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `media.uploaded` | Media uploaded | person | media | v1 |
| `media.deleted` | Media deleted | person / platform_admin | media | v1 |
| `media.flagged` | Media flagged for review | person / system | media | v1 |
| `media.moderation.approved` | Media approved after review | platform_admin | media | v1 |
| `media.moderation.rejected` | Media rejected after review | platform_admin | media | v1 |
| `memory.created` | Memory created | person | memory | v1 |
| `memory.updated` | Memory updated | person | memory | v1 |
| `memory.deleted` | Memory deleted | person / platform_admin | memory | v1 |

```jsonb
// media.uploaded metadata
{
  "media_type": "photo | video",
  "file_size_bytes": "integer",
  "event_id": "uuid | null",
  "tenant_id": "uuid"
}

// media.flagged metadata
{
  "reason": "string",
  "flagged_by": "person_id | 'system'",
  "auto_moderation": "boolean"
}
```

---

### Subgroups

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `subgroup.created` | Subgroup created | person | subgroup | v1 |
| `subgroup.updated` | Subgroup updated | person | subgroup | v1 |
| `subgroup.deleted` | Subgroup deleted | person / platform_admin | subgroup | v1 |
| `subgroup.member.added` | Member added to subgroup | person / system | membership | v1 |
| `subgroup.member.removed` | Member removed from subgroup | person / system | membership | v1 |

```jsonb
// subgroup.member.added / removed metadata
{
  "subgroup_id": "uuid",
  "subgroup_name": "string",
  "event_id": "uuid | null",
  "session_id": "uuid | null"
}
```

---

### Vendors

Schema hooks. Scoped to event and session where applicable.

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `vendor.booking.created` | Vendor booking created | person | vendor_booking | future |
| `vendor.booking.confirmed` | Vendor booking confirmed | person / system | vendor_booking | future |
| `vendor.booking.updated` | Vendor booking updated | person | vendor_booking | future |
| `vendor.booking.cancelled` | Vendor booking cancelled | person / platform_admin | vendor_booking | future |

```jsonb
// vendor.booking.created metadata
{
  "event_id": "uuid",
  "session_id": "uuid | null",
  "vendor_type": "string",
  "headcount": "integer | null"
}
```

---

### Sponsors

Stubbed. Schema hooks only.

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `sponsor.created` | Sponsor created | person | sponsor | future |
| `sponsor.updated` | Sponsor updated | person | sponsor | future |
| `sponsor.deleted` | Sponsor deleted | person / platform_admin | sponsor | future |
| `sponsor.fulfillment.updated` | Sponsor fulfillment updated | person | sponsor | future |

---

### Surveys

Stubbed. Schema hooks only.

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `survey.created` | Survey created | person | survey | future |
| `survey.sent` | Survey sent | person / system | survey | future |
| `survey.closed` | Survey closed | person / system | survey | future |
| `survey.response.submitted` | Survey response submitted | person | survey_response | future |

---

### Platform / super admin

| action_type | label | actor_type | object_type | v1 / future |
|---|---|---|---|---|
| `platform.tenant.created` | Tenant created | person / platform_admin | tenant | v1 |
| `platform.tenant.updated` | Tenant updated | platform_admin | tenant | v1 |
| `platform.tenant.disabled` | Tenant disabled | platform_admin | tenant | v1 |
| `platform.tenant.reactivated` | Tenant reactivated | platform_admin | tenant | v1 |
| `platform.tenant.deleted` | Tenant deleted | platform_admin | tenant | v1 |
| `platform.org_group.created` | Org group created | person / platform_admin | org_group | v1 |
| `platform.org_group.updated` | Org group updated | platform_admin | org_group | v1 |
| `platform.org_group.deleted` | Org group deleted | platform_admin | org_group | v1 |
| `platform.user.role.changed` | Platform user role changed | platform_admin | platform_user | v1 |
| `platform.lookup_table.value.added` | Lookup table value added | platform_admin | lookup_table_value | v1 |
| `platform.lookup_table.value.deactivated` | Lookup table value deactivated | platform_admin | lookup_table_value | v1 |

```jsonb
// platform.tenant.disabled metadata
{
  "reason": "string",
  "disabled_by": "platform_user_id"
}

// platform.lookup_table.value.added / deactivated metadata
{
  "table_name": "string",
  "value": "string",
  "label": "string"
}
```

---

## Rules the nudge engine depends on

The rule-based nudge engine reads `activity_event` directly. For it to work cleanly:

1. **`effective_at` must be set accurately.** For scheduled sends, `effective_at` = the send time, not when the row was written. For RSVP changes, `effective_at` = `created_at`. Never null when the timing of the action matters.

2. **`tenant_id` must always be set** for any event scoped below platform level. The nudge engine filters by tenant — a missing `tenant_id` means the event is invisible to that org's dashboard.

3. **`actor_type = 'system'`** must be used consistently for all automated events. The nudge engine distinguishes human-driven vs. system-driven activity — a `communication.sent` by a person means the admin acted; by `system` means a scheduled send fired. Different nudge implications.

4. **`metadata` must be valid JSON.** Never write a null or malformed metadata field. If there is nothing meaningful to record beyond the universal fields, write `{}`.

5. **No PII in metadata.** Email addresses, phone numbers, payment card data, and free-text profile fields must never appear in `metadata`. Use `person_id` references only. The audit log UI resolves names from the person table at display time — it does not store them in the event stream.

---

## Schema migration notes

The following must be created as a single migration following the standard Gather lookup table pattern:

1. `actor_type` lookup table — seed with `person`, `system`, `platform_admin`
2. `activity_event_action_type` lookup table — seed with all v1 action types from this document, `is_active = true`. All future-flagged types seeded with `is_active = false`
3. `activity_event_object_type` lookup table — seed with full object type list
4. `person_deletion_reason` lookup table — seed with all five values
5. `activity_event` table — with FK constraints to all four lookup tables
6. RLS on `activity_event`: tenant admins read their own tenant's events; platform admins read all; members read none directly (dashboard aggregates only)
7. Index on `(tenant_id, created_at DESC)` for dashboard queries
8. Index on `(actor_id, created_at DESC)` for per-person audit queries
9. Index on `(action_type, tenant_id)` for nudge engine pattern matching

---

## Version history

| Version | Date | Changes |
|---|---|---|
| 1.0 | May 2026 | Initial vocabulary. ~85 action types across 15 domains. Lookup table pattern established. Merge tombstone rule defined. PII rules defined. Nudge engine contract defined. |
