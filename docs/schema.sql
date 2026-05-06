-- ============================================================
-- gather. — Database Schema
-- Version 1.0 | Supabase (Postgres + RLS)
-- ============================================================

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ============================================================
-- CORE ENTITIES
-- ============================================================

-- Person (platform-level identity)
create table person (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  name text,
  photo_url text,
  dark_mode_pref text check (dark_mode_pref in ('light', 'dark', 'system')) default 'system',
  giving_interest boolean default false,
  claimed boolean default true,
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Identity (auth credentials — one Person, many Identities)
create table identity (
  id uuid primary key default uuid_generate_v4(),
  person_id uuid references person(id),
  provider text check (provider in ('google', 'facebook', 'email')) not null,
  provider_user_id text not null,
  email text,
  created_at timestamptz default now(),
  unique (provider, provider_user_id)
);

-- Org Group (optional parent of tenants)
create table org_group (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  group_admin_id uuid references person(id),
  type text,
  aggregate_view_only boolean default true,
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Tenant (Reunion Org)
create table tenant (
  id uuid primary key default uuid_generate_v4(),
  org_group_id uuid references org_group(id),
  name text not null,
  slug text unique not null,
  type text check (type in ('class_reunion', 'family', 'fraternity', 'other')) default 'other',
  discoverability text check (discoverability in ('open', 'gated', 'link_only', 'invite_only')) default 'gated',
  join_policy text check (join_policy in ('auto_approve', 'admin_approve', 'invite_only')) default 'admin_approve',
  domain_restriction text,
  verification_config jsonb,
  plan_tier text default 'free',
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Branding (versioned per tenant)
create table branding (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenant(id) not null,
  logo_url text,
  mascot_url text,
  hero_image_url text,
  primary_color text,
  secondary_color text,
  primary_color_dark text,
  font_choice text check (font_choice in ('system', 'serif', 'rounded', 'classic')) default 'system',
  active_from timestamptz default now(),
  active_to timestamptz
);

-- Membership (person's relationship to a tenant)
create table membership (
  id uuid primary key default uuid_generate_v4(),
  person_id uuid references person(id) not null,
  tenant_id uuid references tenant(id) not null,
  org_role text check (org_role in ('org_admin', 'committee', 'member', 'guest_linked')) default 'member',
  linked_member_id uuid references membership(id),
  status text check (status in ('active', 'pending', 'declined', 'removed')) default 'pending',
  engagement_score float,
  involvement_rung int,
  joined_at timestamptz default now(),
  deleted_at timestamptz,
  unique (person_id, tenant_id)
);

-- Event
create table event (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenant(id) not null,
  name text not null,
  date timestamptz,
  timezone text default 'America/New_York',
  venue text,
  type text check (type in ('dinner', 'golf', 'picnic', 'multi_day', 'other')) default 'other',
  headcount_target int,
  status text check (status in ('draft', 'published', 'closed', 'completed')) default 'draft',
  discoverability text check (discoverability in ('open', 'gated', 'link_only', 'invite_only')),
  join_policy text check (join_policy in ('auto_approve', 'admin_approve', 'invite_only')),
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Attendee Record (person's relationship to a specific event)
create table attendee_record (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id) not null,
  person_id uuid references person(id) not null,
  event_role text check (event_role in ('event_admin', 'committee', 'member', 'guest')) default 'member',
  rsvp_status text check (rsvp_status in ('attending', 'not_attending', 'maybe', 'no_response')) default 'no_response',
  rsvp_at timestamptz,
  meal_preference text,
  dietary_restrictions text,
  tshirt_size text,
  table_assignment text,
  payment_status text check (payment_status in ('unpaid', 'paid', 'waived', 'refunded')) default 'unpaid',
  plus_one_count int default 0,
  waitlist_position int,
  unique (event_id, person_id)
);

-- ============================================================
-- SUPPORTING ENTITIES
-- ============================================================

-- Invitation
create table invitation (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id),
  tenant_id uuid references tenant(id),
  sender_id uuid references person(id),
  recipient_email text not null,
  token text unique not null,
  status text check (status in ('pending', 'opened', 'accepted', 'expired', 'declined')) default 'pending',
  expires_at timestamptz,
  created_at timestamptz default now()
);

-- Join Request
create table join_request (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenant(id) not null,
  person_id uuid references person(id) not null,
  status text check (status in ('pending', 'approved', 'declined')) default 'pending',
  trust_score float,
  reviewed_by uuid references person(id),
  created_at timestamptz default now()
);

-- Subgroup
create table subgroup (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenant(id) not null,
  name text not null,
  type text,
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Media
create table media (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenant(id) not null,
  event_id uuid references event(id),
  uploader_id uuid references person(id),
  url text not null,
  type text check (type in ('photo', 'video')) default 'photo',
  moderation_flag boolean default false,
  created_at timestamptz default now()
);

-- Memory
create table memory (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id),
  author_id uuid references person(id),
  media_id uuid references media(id),
  caption text,
  year int,
  visibility text check (visibility in ('public', 'members_only', 'subgroup_only')) default 'members_only',
  tags text[],
  created_at timestamptz default now()
);

-- Survey
create table survey (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id) not null,
  questions jsonb,
  responses jsonb,
  created_at timestamptz default now()
);

-- Communication
create table communication (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenant(id),
  event_id uuid references event(id),
  sender_id uuid references person(id),
  channel text check (channel in ('email', 'sms')) default 'email',
  audience text,
  subject text,
  body text,
  sent_at timestamptz,
  status text check (status in ('draft', 'sent', 'failed')) default 'draft',
  created_at timestamptz default now()
);

-- ============================================================
-- ACTIVITY, NOTIFICATIONS, VENDORS, FINANCIALS
-- ============================================================

-- Activity Event
create table activity_event (
  id uuid primary key default uuid_generate_v4(),
  actor_id uuid references person(id),
  action_type text not null,
  object_type text,
  object_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

-- Notification Trigger
create table notification_trigger (
  id uuid primary key default uuid_generate_v4(),
  rule_type text not null,
  threshold float,
  channel text check (channel in ('email', 'sms', 'in_app')) default 'in_app',
  recipient_role text,
  cooldown interval,
  last_fired_at timestamptz,
  created_at timestamptz default now()
);

-- Vendor Profile
create table vendor_profile (
  id uuid primary key default uuid_generate_v4(),
  contact_person_id uuid references person(id),
  type text,
  region text,
  capacity int,
  pricing jsonb,
  avg_rating float,
  verified boolean default false,
  discoverable boolean default false,
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Vendor Booking
create table vendor_booking (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id) not null,
  vendor_profile_id uuid references vendor_profile(id) not null,
  headcount int,
  cost numeric,
  contract_url text,
  status text check (status in ('pending', 'confirmed', 'cancelled')) default 'pending',
  rating float,
  created_at timestamptz default now()
);

-- Sponsor
create table sponsor (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id) not null,
  business_name text not null,
  contact_person_id uuid references person(id),
  tier text,
  amount numeric,
  fulfillment_status text check (fulfillment_status in ('pending', 'fulfilled', 'cancelled')) default 'pending',
  created_at timestamptz default now()
);

-- Accommodation
create table accommodation (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references event(id) not null,
  hotel_name text not null,
  block_size int,
  rooms_remaining int,
  cutoff_date timestamptz,
  created_at timestamptz default now()
);

-- Payment
create table payment (
  id uuid primary key default uuid_generate_v4(),
  attendee_record_id uuid references attendee_record(id) not null,
  amount numeric not null,
  method text,
  status text check (status in ('pending', 'completed', 'failed', 'refunded')) default 'pending',
  processor_ref text,
  created_at timestamptz default now()
);

-- Merge Log
create table merge_log (
  id uuid primary key default uuid_generate_v4(),
  person_id_a uuid references person(id) not null,
  person_id_b uuid references person(id) not null,
  merged_at timestamptz default now(),
  merged_by uuid references person(id),
  evidence jsonb
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table person enable row level security;
alter table identity enable row level security;
alter table org_group enable row level security;
alter table tenant enable row level security;
alter table branding enable row level security;
alter table membership enable row level security;
alter table event enable row level security;
alter table attendee_record enable row level security;
alter table invitation enable row level security;
alter table join_request enable row level security;
alter table subgroup enable row level security;
alter table media enable row level security;
alter table memory enable row level security;
alter table survey enable row level security;
alter table communication enable row level security;
alter table activity_event enable row level security;
alter table notification_trigger enable row level security;
alter table vendor_profile enable row level security;
alter table vendor_booking enable row level security;
alter table sponsor enable row level security;
alter table accommodation enable row level security;
alter table payment enable row level security;
alter table merge_log enable row level security;
