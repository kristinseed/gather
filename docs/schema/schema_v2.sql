-- =============================================================================
-- Gather — Database Schema
-- Version 2.0 — May 2026
-- =============================================================================
-- Hierarchy: org_group → tenant → event → attendee_record
-- Person is platform-level. Membership links person to tenant OR org_group.
-- All type/status/role/policy columns FK to lookup tables.
-- All lookup tables have is_active flag. Super admin manages via UI only.
-- =============================================================================


-- =============================================================================
-- LOOKUP TABLES
-- Pattern: text PK (readable slug), label, description, is_active
-- =============================================================================

CREATE TABLE org_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE tenant_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE membership_role (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE membership_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE event_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE event_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE event_role (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE rsvp_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE payment_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE payment_status_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE payment_method (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE tshirt_size (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE communication_channel (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE communication_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE communication_audience (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE invitation_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE join_request_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE join_policy (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE discoverability (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE plan_tier (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE media_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE sponsor_tier (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE sponsor_fulfillment_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE subgroup_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE vendor_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE vendor_booking_status (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE notification_rule_type (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE notification_recipient_role (
  id text NOT NULL PRIMARY KEY,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true
);


-- =============================================================================
-- CORE TABLES
-- =============================================================================

-- Platform-level identity. One person can belong to many tenants.
CREATE TABLE person (
  id uuid NOT NULL PRIMARY KEY,
  email text NOT NULL,
  first_name text,
  last_name text,
  maiden_name text,
  preferred_name text,
  photo_url text,
  dark_mode_pref text,
  giving_interest boolean,
  claimed boolean,
  social_profiles jsonb,
  deleted_at timestamptz,
  created_at timestamptz
);

-- Auth credentials. One person can have many identities (Google, email, etc.)
CREATE TABLE identity (
  id uuid NOT NULL PRIMARY KEY,
  person_id uuid REFERENCES person(id),
  provider text NOT NULL,
  provider_user_id text NOT NULL,
  email text,
  created_at timestamptz
);

-- Super admin platform users
CREATE TABLE platform_user (
  id uuid NOT NULL PRIMARY KEY,
  person_id uuid NOT NULL REFERENCES person(id),
  role text NOT NULL,
  granted_by uuid REFERENCES person(id),
  granted_at timestamptz,
  revoked_at timestamptz
);

-- Parent organization: the school, fraternity, family, military unit, etc.
CREATE TABLE org_group (
  id uuid NOT NULL PRIMARY KEY,
  name text NOT NULL,
  type text REFERENCES org_type(id),
  group_admin_id uuid REFERENCES person(id),
  aggregate_view_only boolean,
  deleted_at timestamptz,
  created_at timestamptz
);

-- Class, chapter, or branch within an org_group.
-- Slug is unique per org_group, not globally.
CREATE TABLE tenant (
  id uuid NOT NULL PRIMARY KEY,
  org_group_id uuid REFERENCES org_group(id),
  name text NOT NULL,
  slug text NOT NULL,
  type text REFERENCES tenant_type(id),
  discoverability text REFERENCES discoverability(id),
  join_policy text REFERENCES join_policy(id),
  domain_restriction text,
  verification_config jsonb,
  plan_tier text REFERENCES plan_tier(id),
  deleted_at timestamptz,
  created_at timestamptz,
  UNIQUE (org_group_id, slug)
);

-- Links a person to either a tenant OR an org_group (exactly one must be set).
CREATE TABLE membership (
  id uuid NOT NULL PRIMARY KEY,
  person_id uuid NOT NULL REFERENCES person(id),
  tenant_id uuid REFERENCES tenant(id),
  org_group_id uuid REFERENCES org_group(id),
  org_role text REFERENCES membership_role(id),
  status text REFERENCES membership_status(id),
  linked_member_id uuid,
  engagement_score double precision,
  involvement_rung integer,
  joined_at timestamptz,
  deleted_at timestamptz,
  CONSTRAINT membership_scope_check CHECK (
    (tenant_id IS NOT NULL AND org_group_id IS NULL) OR
    (tenant_id IS NULL AND org_group_id IS NOT NULL)
  )
);

-- Versioned branding per tenant. One active record at a time (active_to IS NULL).
CREATE TABLE branding (
  id uuid NOT NULL PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenant(id),
  logo_url text,
  mascot_url text,
  hero_image_url text,
  primary_color text,
  secondary_color text,
  primary_color_dark text,
  font_choice text,
  active_from timestamptz,
  active_to timestamptz
);

-- Events within a tenant
CREATE TABLE event (
  id uuid NOT NULL PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenant(id),
  name text NOT NULL,
  date timestamptz,
  timezone text,
  venue text,
  type text REFERENCES event_type(id),
  headcount_target integer,
  status text REFERENCES event_status(id),
  discoverability text REFERENCES discoverability(id),
  join_policy text REFERENCES join_policy(id),
  deleted_at timestamptz,
  created_at timestamptz
);

-- Per-person record for each event
CREATE TABLE attendee_record (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES event(id),
  person_id uuid NOT NULL REFERENCES person(id),
  event_role text REFERENCES event_role(id),
  rsvp_status text REFERENCES rsvp_status(id),
  rsvp_at timestamptz,
  meal_preference text,
  dietary_restrictions text,
  tshirt_size text REFERENCES tshirt_size(id),
  table_assignment text,
  payment_status text REFERENCES payment_status(id),
  plus_one_count integer,
  waitlist_position integer
);


-- =============================================================================
-- SUPPORTING TABLES
-- =============================================================================

CREATE TABLE invitation (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid REFERENCES event(id),
  tenant_id uuid REFERENCES tenant(id),
  sender_id uuid REFERENCES person(id),
  recipient_email text NOT NULL,
  token text NOT NULL,
  status text REFERENCES invitation_status(id),
  expires_at timestamptz,
  created_at timestamptz
);

CREATE TABLE join_request (
  id uuid NOT NULL PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenant(id),
  person_id uuid NOT NULL REFERENCES person(id),
  status text REFERENCES join_request_status(id),
  trust_score double precision,
  reviewed_by uuid REFERENCES person(id),
  created_at timestamptz
);

CREATE TABLE communication (
  id uuid NOT NULL PRIMARY KEY,
  tenant_id uuid REFERENCES tenant(id),
  event_id uuid REFERENCES event(id),
  sender_id uuid REFERENCES person(id),
  channel text REFERENCES communication_channel(id),
  audience text REFERENCES communication_audience(id),
  subject text,
  body text,
  sent_at timestamptz,
  status text REFERENCES communication_status(id),
  created_at timestamptz
);

CREATE TABLE payment (
  id uuid NOT NULL PRIMARY KEY,
  attendee_record_id uuid NOT NULL REFERENCES attendee_record(id),
  amount numeric NOT NULL,
  method text REFERENCES payment_method(id),
  status text REFERENCES payment_status_type(id),
  processor_ref text,
  created_at timestamptz
);

CREATE TABLE media (
  id uuid NOT NULL PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenant(id),
  event_id uuid REFERENCES event(id),
  uploader_id uuid REFERENCES person(id),
  url text NOT NULL,
  type text REFERENCES media_type(id),
  moderation_flag boolean,
  created_at timestamptz
);

CREATE TABLE memory (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid REFERENCES event(id),
  author_id uuid REFERENCES person(id),
  media_id uuid REFERENCES media(id),
  caption text,
  year integer,
  visibility text,
  tags text[],
  created_at timestamptz
);

CREATE TABLE subgroup (
  id uuid NOT NULL PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenant(id),
  name text NOT NULL,
  type text REFERENCES subgroup_type(id),
  deleted_at timestamptz,
  created_at timestamptz
);

CREATE TABLE sponsor (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES event(id),
  business_name text NOT NULL,
  contact_person_id uuid REFERENCES person(id),
  tier text REFERENCES sponsor_tier(id),
  amount numeric,
  fulfillment_status text REFERENCES sponsor_fulfillment_status(id),
  created_at timestamptz
);

CREATE TABLE vendor_profile (
  id uuid NOT NULL PRIMARY KEY,
  contact_person_id uuid REFERENCES person(id),
  type text REFERENCES vendor_type(id),
  region text,
  capacity integer,
  pricing jsonb,
  avg_rating double precision,
  verified boolean,
  discoverable boolean,
  deleted_at timestamptz,
  created_at timestamptz
);

CREATE TABLE vendor_booking (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES event(id),
  vendor_profile_id uuid NOT NULL REFERENCES vendor_profile(id),
  headcount integer,
  cost numeric,
  contract_url text,
  status text REFERENCES vendor_booking_status(id),
  rating double precision,
  created_at timestamptz
);

CREATE TABLE accommodation (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES event(id),
  hotel_name text NOT NULL,
  block_size integer,
  rooms_remaining integer,
  cutoff_date timestamptz,
  created_at timestamptz
);

CREATE TABLE survey (
  id uuid NOT NULL PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES event(id),
  questions jsonb,
  responses jsonb,
  created_at timestamptz
);

CREATE TABLE notification_trigger (
  id uuid NOT NULL PRIMARY KEY,
  rule_type text NOT NULL REFERENCES notification_rule_type(id),
  threshold double precision,
  channel text REFERENCES communication_channel(id),
  recipient_role text REFERENCES notification_recipient_role(id),
  cooldown interval,
  last_fired_at timestamptz,
  created_at timestamptz
);

CREATE TABLE activity_event (
  id uuid NOT NULL PRIMARY KEY,
  actor_id uuid REFERENCES person(id),
  action_type text NOT NULL,
  object_type text,
  object_id uuid,
  metadata jsonb,
  created_at timestamptz
);

CREATE TABLE merge_log (
  id uuid NOT NULL PRIMARY KEY,
  person_id_a uuid NOT NULL REFERENCES person(id),
  person_id_b uuid NOT NULL REFERENCES person(id),
  merged_at timestamptz,
  merged_by uuid REFERENCES person(id),
  evidence jsonb
);


-- =============================================================================
-- SEED DATA — Lookup Tables
-- =============================================================================

INSERT INTO org_type (id, label) VALUES
  ('high_school', 'High School'), ('middle_school', 'Middle School'),
  ('college', 'College / University'), ('fraternity', 'Fraternity'),
  ('sorority', 'Sorority'), ('family', 'Family'),
  ('military', 'Military Unit'), ('civic', 'Civic Organization'), ('other', 'Other');

INSERT INTO tenant_type (id, label) VALUES
  ('class', 'Class'), ('chapter', 'Chapter'), ('branch', 'Branch'),
  ('team', 'Team'), ('club', 'Club'), ('standalone', 'Standalone');

INSERT INTO membership_role (id, label) VALUES
  ('org_admin', 'Org Admin'), ('class_admin', 'Class Admin'),
  ('committee', 'Committee Member'), ('member', 'Member'), ('guest', 'Guest');

INSERT INTO membership_status (id, label) VALUES
  ('invited', 'Invited'), ('active', 'Active'),
  ('inactive', 'Inactive'), ('removed', 'Removed');

INSERT INTO event_type (id, label) VALUES
  ('reunion', 'Reunion'), ('social', 'Social'), ('fundraiser', 'Fundraiser'),
  ('memorial', 'Memorial'), ('virtual', 'Virtual');

INSERT INTO event_status (id, label) VALUES
  ('draft', 'Draft'), ('published', 'Published'), ('closed', 'Closed'),
  ('completed', 'Completed'), ('archived', 'Archived');

INSERT INTO event_role (id, label) VALUES
  ('attendee', 'Attendee'), ('speaker', 'Speaker'),
  ('organizer', 'Organizer'), ('volunteer', 'Volunteer');

INSERT INTO rsvp_status (id, label) VALUES
  ('invited', 'Invited'), ('viewed', 'Viewed'), ('accepted', 'Accepted'),
  ('declined', 'Declined'), ('waitlisted', 'Waitlisted'), ('cancelled', 'Cancelled');

INSERT INTO payment_status (id, label) VALUES
  ('not_required', 'Not Required'), ('pending', 'Pending'),
  ('paid', 'Paid'), ('refunded', 'Refunded'), ('waived', 'Waived');

INSERT INTO payment_status_type (id, label) VALUES
  ('pending', 'Pending'), ('completed', 'Completed'),
  ('failed', 'Failed'), ('refunded', 'Refunded');

INSERT INTO payment_method (id, label) VALUES
  ('card', 'Card'), ('cash', 'Cash'), ('check', 'Check'), ('waived', 'Waived');

INSERT INTO tshirt_size (id, label) VALUES
  ('xs', 'XS'), ('s', 'S'), ('m', 'M'), ('l', 'L'), ('xl', 'XL'), ('xxl', 'XXL');

INSERT INTO communication_channel (id, label) VALUES
  ('email', 'Email'), ('sms', 'SMS'), ('in_app', 'In-App');

INSERT INTO communication_status (id, label) VALUES
  ('draft', 'Draft'), ('scheduled', 'Scheduled'), ('sent', 'Sent'), ('failed', 'Failed');

INSERT INTO communication_audience (id, label) VALUES
  ('all_members', 'All Members'), ('rsvp_yes', 'RSVP Yes'), ('rsvp_no', 'RSVP No'),
  ('waitlist', 'Waitlist'), ('committee', 'Committee');

INSERT INTO invitation_status (id, label) VALUES
  ('pending', 'Pending'), ('accepted', 'Accepted'),
  ('declined', 'Declined'), ('expired', 'Expired');

INSERT INTO join_request_status (id, label) VALUES
  ('pending', 'Pending'), ('approved', 'Approved'), ('denied', 'Denied');

INSERT INTO join_policy (id, label) VALUES
  ('auto_approve', 'Auto Approve'), ('admin_approve', 'Admin Approve'),
  ('invite_only', 'Invite Only');

INSERT INTO discoverability (id, label) VALUES
  ('open', 'Open'), ('gated', 'Gated'),
  ('link_only', 'Link Only'), ('invite_only', 'Invite Only');

INSERT INTO plan_tier (id, label) VALUES
  ('free', 'Free'), ('starter', 'Starter'), ('pro', 'Pro'), ('enterprise', 'Enterprise');

INSERT INTO media_type (id, label) VALUES
  ('photo', 'Photo'), ('video', 'Video'), ('document', 'Document');

INSERT INTO sponsor_tier (id, label) VALUES
  ('title', 'Title'), ('gold', 'Gold'), ('silver', 'Silver'), ('bronze', 'Bronze');

INSERT INTO sponsor_fulfillment_status (id, label) VALUES
  ('pending', 'Pending'), ('partial', 'Partial'), ('fulfilled', 'Fulfilled');

INSERT INTO subgroup_type (id, label) VALUES
  ('committee', 'Committee'), ('band', 'Band'), ('team', 'Team'), ('club', 'Club');

INSERT INTO vendor_type (id, label) VALUES
  ('venue', 'Venue'), ('catering', 'Catering'), ('photography', 'Photography'),
  ('music', 'Music'), ('other', 'Other');

INSERT INTO vendor_booking_status (id, label) VALUES
  ('inquiry', 'Inquiry'), ('confirmed', 'Confirmed'), ('cancelled', 'Cancelled');

INSERT INTO notification_rule_type (id, label) VALUES
  ('rsvp_reminder', 'RSVP Reminder'), ('payment_due', 'Payment Due'),
  ('event_update', 'Event Update'), ('welcome', 'Welcome');

INSERT INTO notification_recipient_role (id, label) VALUES
  ('all_members', 'All Members'), ('rsvp_yes', 'RSVP Yes'),
  ('rsvp_no', 'RSVP No'), ('org_admin', 'Org Admin');


-- =============================================================================
-- SEED DATA — Org Groups & Tenants
-- =============================================================================

INSERT INTO org_group (id, name, type) VALUES
  ('f149a853-21a5-4580-a602-d44ad644ac23', 'Lawrenceville High School', 'high_school'),
  ('d6d19699-ce7e-49b0-ba6a-d9fbc45d6270', 'Raymond Lincolnwood High School', 'high_school');

INSERT INTO tenant (id, org_group_id, name, slug, type, discoverability, join_policy, plan_tier) VALUES
  ('fe603109-106c-4800-8101-4aac5316053f', 'f149a853-21a5-4580-a602-d44ad644ac23', 'Class of 1986', 'class-of-1986', 'class', 'gated', 'admin_approve', 'free'),
  ('603834bc-0a3d-4f56-a42e-6779b9a418cf', 'd6d19699-ce7e-49b0-ba6a-d9fbc45d6270', 'Class of 1990', 'class-of-1990', 'class', 'gated', 'admin_approve', 'free');
