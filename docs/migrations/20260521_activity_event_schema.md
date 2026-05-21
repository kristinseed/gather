-- =============================================================================
-- Gather Migration: Activity Event Schema
-- Version: 1.0
-- Date: 2026-05-21
-- Description: Creates activity_event table and all required lookup tables.
--   Lookup tables follow standard Gather pattern (uuid PK, value, label,
--   description, is_active, created_at, deleted_at).
--   All v1 action types seeded active. All future action types seeded inactive.
-- =============================================================================

begin;

-- =============================================================================
-- 1. actor_type lookup table
-- =============================================================================

create table if not exists actor_type (
  id          uuid primary key default gen_random_uuid(),
  value       text not null unique,
  label       text not null,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on table actor_type is
  'Who or what generated an activity_event row. Super admin managed via UI.';

insert into actor_type (value, label, description) values
  ('person',         'Person',         'A human user acting through the UI or API'),
  ('system',         'System',         'Automated platform action (scheduled job, trigger, expiry)'),
  ('platform_admin', 'Platform admin', 'Super admin acting via the platform admin UI')
on conflict (value) do nothing;


-- =============================================================================
-- 2. activity_event_object_type lookup table
-- =============================================================================

create table if not exists activity_event_object_type (
  id          uuid primary key default gen_random_uuid(),
  value       text not null unique,
  label       text not null,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on table activity_event_object_type is
  'The type of entity an activity_event acted upon. Super admin managed via UI.';

insert into activity_event_object_type (value, label) values
  ('person',            'Person'),
  ('identity',          'Identity'),
  ('membership',        'Membership'),
  ('invitation',        'Invitation'),
  ('join_request',      'Join request'),
  ('tenant',            'Tenant'),
  ('org_group',         'Org group'),
  ('event',             'Event'),
  ('event_session',     'Event session'),
  ('attendee_record',   'Attendee record'),
  ('session_attendee',  'Session attendee'),
  ('communication',     'Communication'),
  ('media',             'Media'),
  ('memory',            'Memory'),
  ('payment',           'Payment'),
  ('branding',          'Branding'),
  ('subgroup',          'Subgroup'),
  ('vendor_booking',    'Vendor booking'),
  ('sponsor',           'Sponsor'),
  ('survey',            'Survey'),
  ('survey_response',   'Survey response'),
  ('platform_user',     'Platform user'),
  ('lookup_table_value','Lookup table value'),
  ('import_batch',      'Import batch')
on conflict (value) do nothing;


-- =============================================================================
-- 3. person_deletion_reason lookup table
-- =============================================================================

create table if not exists person_deletion_reason (
  id          uuid primary key default gen_random_uuid(),
  value       text not null unique,
  label       text not null,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on table person_deletion_reason is
  'Reason a person record was soft-deleted. Drives downstream data retention behavior.';

insert into person_deletion_reason (value, label, description) values
  ('self_requested',    'Self-requested',    'Person requested deletion via profile settings'),
  ('admin_removed',     'Admin removed',     'Org admin or platform admin removed the record'),
  ('duplicate_merged',  'Duplicate merged',  'Record was the deprecated side of a person merge'),
  ('platform_suspended','Platform suspended','Account suspended for policy violation'),
  ('inactivity_purge',  'Inactivity purge',  'Automated purge after inactivity threshold (future)')
on conflict (value) do nothing;


-- =============================================================================
-- 4. activity_event_action_type lookup table
-- =============================================================================

create table if not exists activity_event_action_type (
  id          uuid primary key default gen_random_uuid(),
  value       text not null unique,
  label       text not null,
  description text,
  domain      text,           -- grouping for audit log UI (auth, membership, event, etc.)
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on table activity_event_action_type is
  'Every valid action type for activity_event. Super admin managed via UI.
   v1 types are is_active = true. Future types are is_active = false.
   Never hardcode action type strings in application code — read from this table.';

-- ----------------------------------------------------------------------------
-- Authentication & identity (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('auth.login.success',              'Login succeeded',          'auth', true),
  ('auth.login.failed',               'Login failed',             'auth', true),
  ('auth.logout',                     'Logged out',               'auth', true),
  ('auth.password.reset.requested',   'Password reset requested', 'auth', true),
  ('auth.identity.linked',            'OAuth identity linked',    'auth', true),
  ('auth.identity.claim.submitted',   'Record claim submitted',   'auth', true),
  ('auth.identity.claim.approved',    'Record claim approved',    'auth', true),
  ('auth.identity.claim.rejected',    'Record claim rejected',    'auth', true),
  ('auth.person.merged',              'Person records merged',    'auth', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Membership (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('membership.created',                  'Membership created',        'membership', true),
  ('membership.status.changed',           'Membership status changed', 'membership', true),
  ('membership.role.changed',             'Membership role changed',   'membership', true),
  ('membership.join_request.submitted',   'Join request submitted',    'membership', true),
  ('membership.join_request.approved',    'Join request approved',     'membership', true),
  ('membership.join_request.declined',    'Join request declined',     'membership', true),
  ('membership.deleted',                  'Membership removed',        'membership', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Invitation (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('invitation.created',  'Invitation created',  'invitation', true),
  ('invitation.sent',     'Invitation sent',     'invitation', true),
  ('invitation.opened',   'Invitation opened',   'invitation', true),
  ('invitation.accepted', 'Invitation accepted', 'invitation', true),
  ('invitation.declined', 'Invitation declined', 'invitation', true),
  ('invitation.expired',  'Invitation expired',  'invitation', true),
  ('invitation.resent',   'Invitation resent',   'invitation', true),
  ('invitation.revoked',  'Invitation revoked',  'invitation', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Member import (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('import.started',       'Import started',                          'import', true),
  ('import.completed',     'Import completed',                        'import', true),
  ('import.failed',        'Import failed',                           'import', true),
  ('import.row.created',   'Import row — new record created',         'import', true),
  ('import.row.updated',   'Import row — existing record updated',    'import', true),
  ('import.row.skipped',   'Import row — duplicate, no change',       'import', true),
  ('import.row.flagged',   'Import row — ambiguous match, needs review', 'import', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- RSVP & attendance (v1 + future)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('rsvp.created',          'RSVP submitted',          'rsvp', true),
  ('rsvp.updated',          'RSVP updated',            'rsvp', true),
  ('rsvp.withdrawn',        'RSVP withdrawn',          'rsvp', true),
  ('rsvp.waitlisted',       'Added to waitlist',       'rsvp', true),
  ('rsvp.promoted',         'Promoted from waitlist',  'rsvp', true),
  ('attendance.checked_in', 'Checked in day-of',       'rsvp', false)  -- future
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Event (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('event.created',     'Event created',          'event', true),
  ('event.updated',     'Event updated',           'event', true),
  ('event.published',   'Event published',         'event', true),
  ('event.unpublished', 'Event unpublished',       'event', true),
  ('event.closed',      'Event closed',            'event', true),
  ('event.completed',   'Event marked completed',  'event', true),
  ('event.deleted',     'Event deleted',           'event', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Event session (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('event.session.created',     'Session created',             'event_session', true),
  ('event.session.updated',     'Session updated',             'event_session', true),
  ('event.session.published',   'Session published',           'event_session', true),
  ('event.session.unpublished', 'Session unpublished',         'event_session', true),
  ('event.session.closed',      'Session closed',              'event_session', true),
  ('event.session.completed',   'Session marked completed',    'event_session', true),
  ('event.session.cancelled',   'Session cancelled',           'event_session', true),
  ('event.session.deleted',     'Session deleted',             'event_session', true),
  ('session.attendee.added',    'Attendee added to session',   'event_session', true),
  ('session.attendee.removed',  'Attendee removed from session','event_session', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Communications (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('communication.drafted',       'Communication drafted',          'communication', true),
  ('communication.sent',          'Communication sent',             'communication', true),
  ('communication.delivery.failed','Delivery failed',               'communication', true),
  ('communication.opened',        'Communication opened',           'communication', true),
  ('communication.clicked',       'Link clicked',                   'communication', true),
  ('communication.bounced',       'Communication bounced',          'communication', true),
  ('communication.subscribed',    'Subscribed to communications',   'communication', true),
  ('communication.resubscribed',  'Resubscribed to communications', 'communication', true),
  ('communication.unsubscribed',  'Unsubscribed from communications','communication', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Payments (future — seeded inactive)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('payment.initiated', 'Payment initiated', 'payment', false),
  ('payment.succeeded', 'Payment succeeded', 'payment', false),
  ('payment.failed',    'Payment failed',    'payment', false),
  ('payment.refunded',  'Payment refunded',  'payment', false),
  ('payment.waived',    'Payment waived',    'payment', false)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Person profile (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('person.profile.updated',   'Profile updated',        'person', true),
  ('person.photo.uploaded',    'Profile photo uploaded', 'person', true),
  ('person.preference.changed','Preference changed',     'person', true),
  ('person.deleted',           'Person soft deleted',    'person', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Branding & settings (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('branding.updated',          'Branding updated',           'settings', true),
  ('tenant.settings.updated',   'Tenant settings updated',    'settings', true),
  ('org_group.settings.updated','Org group settings updated', 'settings', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Media & memory wall (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('media.uploaded',              'Media uploaded',              'media', true),
  ('media.deleted',               'Media deleted',               'media', true),
  ('media.flagged',               'Media flagged for review',    'media', true),
  ('media.moderation.approved',   'Media approved after review', 'media', true),
  ('media.moderation.rejected',   'Media rejected after review', 'media', true),
  ('memory.created',              'Memory created',              'media', true),
  ('memory.updated',              'Memory updated',              'media', true),
  ('memory.deleted',              'Memory deleted',              'media', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Subgroups (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('subgroup.created',        'Subgroup created',            'subgroup', true),
  ('subgroup.updated',        'Subgroup updated',            'subgroup', true),
  ('subgroup.deleted',        'Subgroup deleted',            'subgroup', true),
  ('subgroup.member.added',   'Member added to subgroup',    'subgroup', true),
  ('subgroup.member.removed', 'Member removed from subgroup','subgroup', true)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Vendors (future — seeded inactive)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('vendor.booking.created',   'Vendor booking created',   'vendor', false),
  ('vendor.booking.confirmed', 'Vendor booking confirmed', 'vendor', false),
  ('vendor.booking.updated',   'Vendor booking updated',   'vendor', false),
  ('vendor.booking.cancelled', 'Vendor booking cancelled', 'vendor', false)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Sponsors (future — seeded inactive)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('sponsor.created',              'Sponsor created',              'sponsor', false),
  ('sponsor.updated',              'Sponsor updated',              'sponsor', false),
  ('sponsor.deleted',              'Sponsor deleted',              'sponsor', false),
  ('sponsor.fulfillment.updated',  'Sponsor fulfillment updated',  'sponsor', false)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Surveys (future — seeded inactive)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('survey.created',            'Survey created',            'survey', false),
  ('survey.sent',               'Survey sent',               'survey', false),
  ('survey.closed',             'Survey closed',             'survey', false),
  ('survey.response.submitted', 'Survey response submitted', 'survey', false)
on conflict (value) do nothing;

-- ----------------------------------------------------------------------------
-- Platform / super admin (v1)
-- ----------------------------------------------------------------------------
insert into activity_event_action_type (value, label, domain, is_active) values
  ('platform.tenant.created',                 'Tenant created',                  'platform', true),
  ('platform.tenant.updated',                 'Tenant updated',                  'platform', true),
  ('platform.tenant.disabled',                'Tenant disabled',                 'platform', true),
  ('platform.tenant.reactivated',             'Tenant reactivated',              'platform', true),
  ('platform.tenant.deleted',                 'Tenant deleted',                  'platform', true),
  ('platform.org_group.created',              'Org group created',               'platform', true),
  ('platform.org_group.updated',              'Org group updated',               'platform', true),
  ('platform.org_group.deleted',              'Org group deleted',               'platform', true),
  ('platform.user.role.changed',              'Platform user role changed',      'platform', true),
  ('platform.lookup_table.value.added',       'Lookup table value added',        'platform', true),
  ('platform.lookup_table.value.deactivated', 'Lookup table value deactivated',  'platform', true)
on conflict (value) do nothing;


-- =============================================================================
-- 5. activity_event table
-- =============================================================================

create table if not exists activity_event (
  id            uuid primary key default gen_random_uuid(),
  actor_id      uuid references person(id) on delete set null,
  actor_type    text not null references actor_type(value),
  action_type   text not null references activity_event_action_type(value),
  object_type   text not null references activity_event_object_type(value),
  object_id     uuid,
  tenant_id     uuid references tenant(id) on delete set null,
  org_group_id  uuid references org_group(id) on delete set null,
  metadata      jsonb not null default '{}',
  created_at    timestamptz not null default now(),
  effective_at  timestamptz,
  deleted_at    timestamptz
);

comment on table activity_event is
  'Immutable event stream. Every meaningful action in the platform writes a row here.
   Used for: organizer dashboard nudge engine, audit log, future AI analytics.
   Rows are never hard deleted — only soft deleted via deleted_at.
   No PII in metadata — use person_id references only.';

comment on column activity_event.actor_id is
  'person.id of the human who took the action. Null when actor_type = system.';

comment on column activity_event.effective_at is
  'When the action took effect. May differ from created_at for scheduled actions
   (e.g. a scheduled communication send). Never null when timing matters to the nudge engine.';

comment on column activity_event.metadata is
  'Action-specific payload per the activity-event-vocabulary.md contract.
   Universal fields always present: source (web|mobile|api|system).
   Auth events also include ip_address and user_agent.
   Never store PII, email addresses, phone numbers, or payment card data here.';


-- =============================================================================
-- 6. Indexes
-- =============================================================================

-- Dashboard queries: filter by tenant, order by recency
create index if not exists activity_event_tenant_created
  on activity_event (tenant_id, created_at desc)
  where deleted_at is null;

-- Per-person audit queries
create index if not exists activity_event_actor_created
  on activity_event (actor_id, created_at desc)
  where deleted_at is null;

-- Nudge engine pattern matching: filter by action type within a tenant
create index if not exists activity_event_action_tenant
  on activity_event (action_type, tenant_id)
  where deleted_at is null;

-- Object lookup: find all events for a specific record (e.g. all events on a membership)
create index if not exists activity_event_object
  on activity_event (object_type, object_id)
  where deleted_at is null;

-- Effective time queries for nudge engine scheduling
create index if not exists activity_event_effective_at
  on activity_event (effective_at desc)
  where deleted_at is null and effective_at is not null;


-- =============================================================================
-- 7. Row Level Security
-- =============================================================================

alter table activity_event enable row level security;

-- Tenant admins: read events scoped to their tenant
create policy "tenant_admin_read_own_events"
  on activity_event
  for select
  using (
    tenant_id in (
      select m.tenant_id
      from membership m
      join person p on p.id = m.person_id
      where p.auth_user_id = auth.uid()
        and m.org_role in ('org_admin', 'committee')
        and m.deleted_at is null
        and m.tenant_id is not null
    )
  );

-- Org group admins: read events scoped to their org group
create policy "org_admin_read_own_org_events"
  on activity_event
  for select
  using (
    org_group_id in (
      select m.org_group_id
      from membership m
      join person p on p.id = m.person_id
      where p.auth_user_id = auth.uid()
        and m.org_role = 'org_admin'
        and m.deleted_at is null
        and m.org_group_id is not null
    )
  );

-- Platform admins: read all events
create policy "platform_admin_read_all_events"
  on activity_event
  for select
  using (
    exists (
      select 1
      from platform_user pu
      where pu.auth_user_id = auth.uid()
        and pu.is_active = true
        and pu.deleted_at is null
    )
  );

-- Insert: authenticated service role only (app writes events via service role client)
-- Members never write to activity_event directly
-- No direct insert policy for anon or authenticated role —
-- all writes go through the service role client in Supabase edge functions or server actions

-- Note: if writing activity_event rows from the Lovable front end directly via
-- the anon/authenticated client, add a restricted insert policy here scoped to
-- the actor's own person_id. Recommended: route all event writes through a
-- Supabase edge function to enforce the metadata contract server-side.


-- =============================================================================
-- 8. RLS on lookup tables
--    All lookup tables: public read (needed by front end to load action type lists),
--    platform admin write only.
-- =============================================================================

alter table actor_type enable row level security;
alter table activity_event_action_type enable row level security;
alter table activity_event_object_type enable row level security;
alter table person_deletion_reason enable row level security;

-- Public read on all four lookup tables
create policy "public_read_actor_type"
  on actor_type for select using (true);

create policy "public_read_action_type"
  on activity_event_action_type for select using (true);

create policy "public_read_object_type"
  on activity_event_object_type for select using (true);

create policy "public_read_deletion_reason"
  on person_deletion_reason for select using (true);

-- Platform admin write on all four lookup tables
create policy "platform_admin_manage_actor_type"
  on actor_type for all
  using (
    exists (
      select 1 from platform_user pu
      where pu.auth_user_id = auth.uid()
        and pu.is_active = true
        and pu.deleted_at is null
    )
  );

create policy "platform_admin_manage_action_type"
  on activity_event_action_type for all
  using (
    exists (
      select 1 from platform_user pu
      where pu.auth_user_id = auth.uid()
        and pu.is_active = true
        and pu.deleted_at is null
    )
  );

create policy "platform_admin_manage_object_type"
  on activity_event_object_type for all
  using (
    exists (
      select 1 from platform_user pu
      where pu.auth_user_id = auth.uid()
        and pu.is_active = true
        and pu.deleted_at is null
    )
  );

create policy "platform_admin_manage_deletion_reason"
  on person_deletion_reason for all
  using (
    exists (
      select 1 from platform_user pu
      where pu.auth_user_id = auth.uid()
        and pu.is_active = true
        and pu.deleted_at is null
    )
  );


-- =============================================================================
-- 9. Grant usage to authenticated role
-- =============================================================================

grant select on activity_event to authenticated;
grant select on actor_type to authenticated;
grant select on activity_event_action_type to authenticated;
grant select on activity_event_object_type to authenticated;
grant select on person_deletion_reason to authenticated;


commit;

-- =============================================================================
-- Post-migration verification queries
-- Run these in Supabase SQL editor after applying the migration to confirm
-- everything landed correctly.
-- =============================================================================

-- 1. Confirm lookup table row counts
-- select 'actor_type' as tbl, count(*) from actor_type
-- union all select 'action_type', count(*) from activity_event_action_type
-- union all select 'object_type', count(*) from activity_event_object_type
-- union all select 'deletion_reason', count(*) from person_deletion_reason;
-- Expected: 3 / ~85 / 24 / 5

-- 2. Confirm v1 vs future split
-- select is_active, count(*) from activity_event_action_type group by is_active;
-- Expected: true ~68, false ~17

-- 3. Confirm indexes exist
-- select indexname from pg_indexes where tablename = 'activity_event';

-- 4. Confirm RLS is enabled
-- select tablename, rowsecurity from pg_tables
-- where tablename in ('activity_event','actor_type','activity_event_action_type',
--                     'activity_event_object_type','person_deletion_reason');
-- All rows should show rowsecurity = true

-- 5. Spot-check a domain grouping
-- select domain, count(*), bool_or(is_active) as has_active
-- from activity_event_action_type
-- group by domain order by domain;
