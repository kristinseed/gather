For the reasoning behind decisions, see architecture-decisions.md. For the current schema and rules for building screens, see ARCHITECTURE.md.

# Gather Schema Reference

## All Tables
accommodation, activity_event, attendee_record, branding, communication, event, identity, invitation, join_request, media, membership, memory, merge_log, notification_trigger, org_group, payment, person, sponsor, subgroup, survey, tenant, vendor_booking, vendor_profile

## Core Table Columns

### person
id, email, first_name, last_name, maiden_name, preferred_name, photo_url, dark_mode_pref, giving_interest, claimed, deleted_at, created_at, social_profiles, auth_user_id

### membership
id, person_id, tenant_id, org_group_id, org_role, linked_member_id, status, engagement_score, involvement_rung
— org_group_id and tenant_id are both nullable; exactly one must be set (check constraint)
— supports both org_group-level admin roles and tenant-level membership

### identity
id, person_id, provider, provider_user_id, email, created_at

### tenant
id, org_group_id, name, slug, type, discoverability, join_policy, domain_restriction, verification_config, plan_tier, deleted_at, created_at
— slug is unique per org_group_id, not globally
— type, discoverability, join_policy, plan_tier all FK to lookup tables

### event
id, tenant_id, name, date, timezone, venue, type, headcount_target, status, discoverability, join_policy, deleted_at, created_at

### event_session
id, event_id FK, name, starts_at, ends_at, timezone, venue, type FK session_type, headcount_target, capacity, is_optional, requires_separate_rsvp, status FK session_status, deleted_at
— event = parent container, session = discrete sub-event

### session_attendee
opt-in RSVPs for individual sessions

### attendee_record
id, event_id, person_id, event_role, rsvp_status, rsvp_at, meal_preference, dietary_restrictions, tshirt_size, table_assignment, payment_status, plus_one_count, waitlist_position

### invitation
id, event_id, tenant_id, sender_id, recipient_email, token, status, expires_at, created_at

### branding
id, tenant_id, org_group_id FK, logo_url, mascot_url, hero_image_url, primary_color, secondary_color, primary_color_dark, font_choice, active_from, active_to

### communication
id, tenant_id, event_id, sender_id, channel, audience, subject, body, sent_at, status, created_at

### media
id, tenant_id, event_id, uploader_id, url, type, moderation_flag, created_at

### activity_event
id, actor_id, action_type, object_type, object_id, metadata, created_at

## Lookup Tables — Rules
- ALL lookup tables have is_active flag
- ALL lookup tables have uuid PK + label + description + is_active
- Super admin manages ALL lookup table values via UI — no raw SQL ever
- This is a hard rule for every lookup table past and future

## Lookup Tables
| Table | Values |
|---|---|
| org_type | high_school, middle_school, college, fraternity, sorority, family, military, civic, other |
| tenant_type | class, chapter, branch, team, club, standalone |
| membership_role | (super admin managed) |
| event_type | (super admin managed) |
| event_status | (super admin managed) |
| session_type | (super admin managed) |
| session_status | (super admin managed) |
| rsvp_status | (super admin managed) |
| payment_status | (super admin managed) |

## Schema Rules
- All status/type/role/policy columns FK to lookup tables — no raw check constraints
- type/status stored as plain text slugs (not uuid FKs) in lookup references
- RLS on all tables; mirrors pattern of nearest parent table
- Lovable uses browser client + service role admin client
