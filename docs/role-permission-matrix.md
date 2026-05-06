# gather. — Role Permission Matrix

Version 1.0 | Reference for screen-building and RLS policy writing

Use this document when building any screen in Lovable or writing RLS policies in Supabase. Every data access decision should trace back to a row in this matrix.

---

## Role definitions

| Role | Scope | Who they are |
|---|---|---|
| **Super Admin** | Platform | Gather staff. Access to all tenants, billing, system health |
| **Org Group Admin** | Org Group | National fraternity HQ, school district office. Aggregate view only |
| **Org Admin** | Tenant | The reunion committee chair. Full control of their org |
| **Committee Member** | Tenant | Committee volunteers. Can do most things except billing and deletion |
| **Member** | Tenant | Reunion attendees. Self-service only |
| **Guest** | Event | Plus-ones and observers. Event-scoped RSVP only |
| **Vendor Contact** | Event | Caterers, venues. Logistics data only, no member data |

---

## Permission matrix

### Member data

| Action | Super Admin | Org Group Admin | Org Admin | Committee | Member | Guest | Vendor |
|---|---|---|---|---|---|---|---|
| View own profile | ✓ | — | ✓ | ✓ | ✓ | ✓ | — |
| Edit own profile | ✓ | — | ✓ | ✓ | ✓ | — | — |
| View other member full profile | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| View other member (name/photo/year only) | ✓ | — | ✓ | ✓ | ✓ | ✗ | ✗ |
| View engagement_score / involvement_rung | ✓ | — | ✓ read only | ✗ | ✗ | ✗ | ✗ |
| View giving_interest | ✓ | — | ✓ read only | ✗ | ✗ | ✗ | ✗ |
| Export member data | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| Import members | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |
| Delete member | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |

### Event data

| Action | Super Admin | Org Group Admin | Org Admin | Committee | Member | Guest | Vendor |
|---|---|---|---|---|---|---|---|
| Create event | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| Edit event | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| Delete event | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |
| View event details | ✓ | — | ✓ | ✓ | ✓ | ✓ | ✓ own booking only |
| RSVP to event | ✓ | — | ✓ | ✓ | ✓ | ✓ | ✗ |
| View attendee list (full) | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| View headcount + logistics export | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✓ own event only |

### Org management

| Action | Super Admin | Org Group Admin | Org Admin | Committee | Member | Guest | Vendor |
|---|---|---|---|---|---|---|---|
| Edit org settings | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |
| Edit branding | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |
| Manage billing | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |
| Approve join requests | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| Send communications | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |
| View aggregate stats across orgs | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Delete org | ✓ | — | ✓ | ✗ | ✗ | ✗ | ✗ |

### Memory wall

| Action | Super Admin | Org Group Admin | Org Admin | Committee | Member | Guest | Vendor |
|---|---|---|---|---|---|---|---|
| Upload media | ✓ | — | ✓ | ✓ | ✓ | ✗ | ✗ |
| View public memories | ✓ | — | ✓ | ✓ | ✓ | ✓ | ✗ |
| View members_only memories | ✓ | — | ✓ | ✓ | ✓ | ✗ | ✗ |
| Moderate / remove media | ✓ | — | ✓ | ✓ | ✗ | ✗ | ✗ |

---

## Key rules to enforce in code

1. **Event role overrides org role.** Always check event_role first on attendee_record. Fall back to org_role on membership if event_role is null.

2. **Sensitive fields are read-only for Org Admin, invisible to everyone else.** engagement_score, involvement_rung, giving_interest — never in any export, never visible to Committee or below.

3. **Vendor export never contains PII.** Headcount, dietary summary, t-shirt sizes, table count only. No names, no emails, no contact details.

4. **Soft-deleted records are invisible to all roles.** WHERE deleted_at IS NULL on every query, every role.

5. **Discoverability gates the front door.** invite_only orgs are invisible in search to everyone without a valid token. No exceptions.

6. **Directory is limited for members.** Members see name, photo, class year only for other members. Full profile is Org Admin and above.
