-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.accommodation (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid xNOT NULL,
  hotel_name text NOT NULL,
  block_size integer,
  rooms_remaining integer,
  cutoff_date timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT accommodation_pkey PRIMARY KEY (id),
  CONSTRAINT accommodation_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id)
);
CREATE TABLE public.activity_event (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  actor_id uuid,
  action_type text NOT NULL,
  object_type text,
  object_id uuid,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT activity_event_pkey PRIMARY KEY (id),
  CONSTRAINT activity_event_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.person(id)
);
CREATE TABLE public.attendee_record (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  person_id uuid NOT NULL,
  event_role text DEFAULT 'member'::text CHECK (event_role = ANY (ARRAY['event_admin'::text, 'committee'::text, 'member'::text, 'guest'::text])),
  rsvp_status text DEFAULT 'no_response'::text CHECK (rsvp_status = ANY (ARRAY['attending'::text, 'not_attending'::text, 'maybe'::text, 'no_response'::text])),
  rsvp_at timestamp with time zone,
  meal_preference text,
  dietary_restrictions text,
  tshirt_size text,
  table_assignment text,
  payment_status text DEFAULT 'unpaid'::text CHECK (payment_status = ANY (ARRAY['unpaid'::text, 'paid'::text, 'waived'::text, 'refunded'::text])),
  plus_one_count integer DEFAULT 0,
  waitlist_position integer,
  CONSTRAINT attendee_record_pkey PRIMARY KEY (id),
  CONSTRAINT attendee_record_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT attendee_record_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id),
  CONSTRAINT attendee_rsvp_status_fkey FOREIGN KEY (rsvp_status) REFERENCES public.rsvp_status(id),
  CONSTRAINT attendee_payment_status_fkey FOREIGN KEY (payment_status) REFERENCES public.payment_status(id),
  CONSTRAINT attendee_event_role_fkey FOREIGN KEY (event_role) REFERENCES public.event_role(id),
  CONSTRAINT attendee_tshirt_size_fkey FOREIGN KEY (tshirt_size) REFERENCES public.tshirt_size(id)
);
CREATE TABLE public.branding (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid,
  logo_url text,
  mascot_url text,
  hero_image_url text,
  primary_color text,
  secondary_color text,
  primary_color_dark text,
  font_choice text DEFAULT 'system'::text CHECK (font_choice = ANY (ARRAY['system'::text, 'serif'::text, 'rounded'::text, 'classic'::text])),
  active_from timestamp with time zone DEFAULT now(),
  active_to timestamp with time zone,
  org_group_id uuid,
  CONSTRAINT branding_pkey PRIMARY KEY (id),
  CONSTRAINT branding_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT branding_org_group_id_fkey FOREIGN KEY (org_group_id) REFERENCES public.org_group(id)
);
CREATE TABLE public.communication (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid,
  event_id uuid,
  sender_id uuid,
  channel text DEFAULT 'email'::text CHECK (channel = ANY (ARRAY['email'::text, 'sms'::text])),
  audience text,
  subject text,
  body text,
  sent_at timestamp with time zone,
  status text DEFAULT 'draft'::text CHECK (status = ANY (ARRAY['draft'::text, 'sent'::text, 'failed'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT communication_pkey PRIMARY KEY (id),
  CONSTRAINT communication_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT communication_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT communication_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.person(id),
  CONSTRAINT communication_channel_fkey FOREIGN KEY (channel) REFERENCES public.communication_channel(id),
  CONSTRAINT communication_status_fkey FOREIGN KEY (status) REFERENCES public.communication_status(id),
  CONSTRAINT communication_audience_fkey FOREIGN KEY (audience) REFERENCES public.communication_audience(id)
);
CREATE TABLE public.communication_audience (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT communication_audience_pkey PRIMARY KEY (id)
);
CREATE TABLE public.communication_channel (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT communication_channel_pkey PRIMARY KEY (id)
);
CREATE TABLE public.communication_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT communication_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.discoverability (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT discoverability_pkey PRIMARY KEY (id)
);
CREATE TABLE public.event (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL,
  name text NOT NULL,
  date timestamp with time zone,
  timezone text DEFAULT 'America/New_York'::text,
  venue text,
  type text DEFAULT 'other'::text CHECK (type = ANY (ARRAY['dinner'::text, 'golf'::text, 'picnic'::text, 'multi_day'::text, 'other'::text])),
  headcount_target integer,
  status text DEFAULT 'draft'::text CHECK (status = ANY (ARRAY['draft'::text, 'published'::text, 'closed'::text, 'completed'::text])),
  discoverability text CHECK (discoverability = ANY (ARRAY['open'::text, 'gated'::text, 'link_only'::text, 'invite_only'::text])),
  join_policy text CHECK (join_policy = ANY (ARRAY['auto_approve'::text, 'admin_approve'::text, 'invite_only'::text])),
  deleted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT event_pkey PRIMARY KEY (id),
  CONSTRAINT event_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT event_type_fkey FOREIGN KEY (type) REFERENCES public.event_type(id),
  CONSTRAINT event_status_fkey FOREIGN KEY (status) REFERENCES public.event_status(id),
  CONSTRAINT event_discoverability_fkey FOREIGN KEY (discoverability) REFERENCES public.discoverability(id),
  CONSTRAINT event_join_policy_fkey FOREIGN KEY (join_policy) REFERENCES public.join_policy(id)
);
CREATE TABLE public.event_role (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT event_role_pkey PRIMARY KEY (id)
);
CREATE TABLE public.event_session (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  name text NOT NULL,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  timezone text,
  venue text,
  type text,
  headcount_target integer,
  capacity integer,
  is_optional boolean NOT NULL DEFAULT false,
  requires_separate_rsvp boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'Draft'::text,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT event_session_pkey PRIMARY KEY (id),
  CONSTRAINT event_session_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id)
);
CREATE TABLE public.event_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT event_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.event_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT event_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.identity (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  person_id uuid,
  provider text NOT NULL CHECK (provider = ANY (ARRAY['google'::text, 'facebook'::text, 'email'::text])),
  provider_user_id text NOT NULL,
  email text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT identity_pkey PRIMARY KEY (id),
  CONSTRAINT identity_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id)
);
CREATE TABLE public.invitation (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid,
  tenant_id uuid,
  sender_id uuid,
  recipient_email text NOT NULL,
  token text NOT NULL UNIQUE,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'opened'::text, 'accepted'::text, 'expired'::text, 'declined'::text])),
  expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT invitation_pkey PRIMARY KEY (id),
  CONSTRAINT invitation_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT invitation_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT invitation_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.person(id),
  CONSTRAINT invitation_status_fkey FOREIGN KEY (status) REFERENCES public.invitation_status(id)
);
CREATE TABLE public.invitation_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT invitation_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.join_policy (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT join_policy_pkey PRIMARY KEY (id)
);
CREATE TABLE public.join_request (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL,
  person_id uuid NOT NULL,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'declined'::text])),
  trust_score double precision,
  reviewed_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT join_request_pkey PRIMARY KEY (id),
  CONSTRAINT join_request_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT join_request_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id),
  CONSTRAINT join_request_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.person(id),
  CONSTRAINT join_request_status_fkey FOREIGN KEY (status) REFERENCES public.join_request_status(id)
);
CREATE TABLE public.join_request_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT join_request_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.media (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL,
  event_id uuid,
  uploader_id uuid,
  url text NOT NULL,
  type text DEFAULT 'photo'::text CHECK (type = ANY (ARRAY['photo'::text, 'video'::text])),
  moderation_flag boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT media_pkey PRIMARY KEY (id),
  CONSTRAINT media_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT media_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT media_uploader_id_fkey FOREIGN KEY (uploader_id) REFERENCES public.person(id),
  CONSTRAINT media_type_fkey FOREIGN KEY (type) REFERENCES public.media_type(id)
);
CREATE TABLE public.media_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT media_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.membership (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  person_id uuid NOT NULL,
  tenant_id uuid,
  org_role text DEFAULT 'member'::text CHECK (org_role = ANY (ARRAY['org_admin'::text, 'committee'::text, 'member'::text, 'guest_linked'::text])),
  linked_member_id uuid,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['active'::text, 'pending'::text, 'declined'::text, 'removed'::text])),
  engagement_score double precision,
  involvement_rung integer,
  joined_at timestamp with time zone DEFAULT now(),
  deleted_at timestamp with time zone,
  org_group_id uuid,
  CONSTRAINT membership_pkey PRIMARY KEY (id),
  CONSTRAINT membership_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id),
  CONSTRAINT membership_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT membership_linked_member_id_fkey FOREIGN KEY (linked_member_id) REFERENCES public.membership(id),
  CONSTRAINT membership_org_role_fkey FOREIGN KEY (org_role) REFERENCES public.membership_role(id),
  CONSTRAINT membership_org_group_id_fkey FOREIGN KEY (org_group_id) REFERENCES public.org_group(id),
  CONSTRAINT membership_status_fkey FOREIGN KEY (status) REFERENCES public.membership_status(id)
);
CREATE TABLE public.membership_role (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT membership_role_pkey PRIMARY KEY (id)
);
CREATE TABLE public.membership_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT membership_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.memory (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid,
  author_id uuid,
  media_id uuid,
  caption text,
  year integer,
  visibility text DEFAULT 'members_only'::text CHECK (visibility = ANY (ARRAY['public'::text, 'members_only'::text, 'subgroup_only'::text])),
  tags ARRAY,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT memory_pkey PRIMARY KEY (id),
  CONSTRAINT memory_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT memory_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.person(id),
  CONSTRAINT memory_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media(id)
);
CREATE TABLE public.merge_log (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  person_id_a uuid NOT NULL,
  person_id_b uuid NOT NULL,
  merged_at timestamp with time zone DEFAULT now(),
  merged_by uuid,
  evidence jsonb,
  CONSTRAINT merge_log_pkey PRIMARY KEY (id),
  CONSTRAINT merge_log_person_id_a_fkey FOREIGN KEY (person_id_a) REFERENCES public.person(id),
  CONSTRAINT merge_log_person_id_b_fkey FOREIGN KEY (person_id_b) REFERENCES public.person(id),
  CONSTRAINT merge_log_merged_by_fkey FOREIGN KEY (merged_by) REFERENCES public.person(id)
);
CREATE TABLE public.notification_recipient_role (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT notification_recipient_role_pkey PRIMARY KEY (id)
);
CREATE TABLE public.notification_rule_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT notification_rule_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.notification_trigger (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  rule_type text NOT NULL,
  threshold double precision,
  channel text DEFAULT 'in_app'::text CHECK (channel = ANY (ARRAY['email'::text, 'sms'::text, 'in_app'::text])),
  recipient_role text,
  cooldown interval,
  last_fired_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notification_trigger_pkey PRIMARY KEY (id),
  CONSTRAINT notification_rule_type_fkey FOREIGN KEY (rule_type) REFERENCES public.notification_rule_type(id),
  CONSTRAINT notification_recipient_role_fkey FOREIGN KEY (recipient_role) REFERENCES public.notification_recipient_role(id),
  CONSTRAINT notification_channel_fkey FOREIGN KEY (channel) REFERENCES public.communication_channel(id)
);
CREATE TABLE public.org_group (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  group_admin_id uuid,
  type text,
  aggregate_view_only boolean DEFAULT true,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  slug text NOT NULL UNIQUE,
  CONSTRAINT org_group_pkey PRIMARY KEY (id),
  CONSTRAINT org_group_group_admin_id_fkey FOREIGN KEY (group_admin_id) REFERENCES public.person(id),
  CONSTRAINT org_group_type_fkey FOREIGN KEY (type) REFERENCES public.org_type(id)
);
CREATE TABLE public.org_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT org_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.payment (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  attendee_record_id uuid NOT NULL,
  amount numeric NOT NULL,
  method text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text, 'refunded'::text])),
  processor_ref text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payment_pkey PRIMARY KEY (id),
  CONSTRAINT payment_attendee_record_id_fkey FOREIGN KEY (attendee_record_id) REFERENCES public.attendee_record(id),
  CONSTRAINT payment_status_fkey FOREIGN KEY (status) REFERENCES public.payment_status_type(id),
  CONSTRAINT payment_method_fkey FOREIGN KEY (method) REFERENCES public.payment_method(id)
);
CREATE TABLE public.payment_method (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT payment_method_pkey PRIMARY KEY (id)
);
CREATE TABLE public.payment_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT payment_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.payment_status_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT payment_status_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.person (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  photo_url text,
  dark_mode_pref text DEFAULT 'system'::text CHECK (dark_mode_pref = ANY (ARRAY['light'::text, 'dark'::text, 'system'::text])),
  giving_interest boolean DEFAULT false,
  claimed boolean DEFAULT true,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  social_profiles jsonb DEFAULT '{}'::jsonb,
  first_name text,
  last_name text,
  maiden_name text,
  preferred_name text,
  auth_user_id uuid,
  CONSTRAINT person_pkey PRIMARY KEY (id),
  CONSTRAINT person_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.plan_tier (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT plan_tier_pkey PRIMARY KEY (id)
);
CREATE TABLE public.platform_user (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  role text NOT NULL DEFAULT 'super_admin'::text,
  granted_by uuid,
  granted_at timestamp with time zone DEFAULT now(),
  revoked_at timestamp with time zone,
  auth_user_id uuid,
  CONSTRAINT platform_user_pkey PRIMARY KEY (id),
  CONSTRAINT platform_user_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id),
  CONSTRAINT platform_user_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.person(id),
  CONSTRAINT platform_user_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.rsvp_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT rsvp_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.session_attendee (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  person_id uuid NOT NULL,
  rsvp_status text,
  rsvp_at timestamp with time zone,
  waitlist_position integer,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT session_attendee_pkey PRIMARY KEY (id),
  CONSTRAINT session_attendee_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.event_session(id),
  CONSTRAINT session_attendee_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id)
);
CREATE TABLE public.session_status (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT session_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.session_type (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT session_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.sponsor (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  business_name text NOT NULL,
  contact_person_id uuid,
  tier text,
  amount numeric,
  fulfillment_status text DEFAULT 'pending'::text CHECK (fulfillment_status = ANY (ARRAY['pending'::text, 'fulfilled'::text, 'cancelled'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT sponsor_pkey PRIMARY KEY (id),
  CONSTRAINT sponsor_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT sponsor_contact_person_id_fkey FOREIGN KEY (contact_person_id) REFERENCES public.person(id),
  CONSTRAINT sponsor_tier_fkey FOREIGN KEY (tier) REFERENCES public.sponsor_tier(id),
  CONSTRAINT sponsor_fulfillment_status_fkey FOREIGN KEY (fulfillment_status) REFERENCES public.sponsor_fulfillment_status(id)
);
CREATE TABLE public.sponsor_fulfillment_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT sponsor_fulfillment_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.sponsor_tier (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT sponsor_tier_pkey PRIMARY KEY (id)
);
CREATE TABLE public.subgroup (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL,
  name text NOT NULL,
  type text,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subgroup_pkey PRIMARY KEY (id),
  CONSTRAINT subgroup_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id),
  CONSTRAINT subgroup_type_fkey FOREIGN KEY (type) REFERENCES public.subgroup_type(id)
);
CREATE TABLE public.subgroup_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT subgroup_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.survey (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  questions jsonb,
  responses jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT survey_pkey PRIMARY KEY (id),
  CONSTRAINT survey_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id)
);
CREATE TABLE public.tenant (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  org_group_id uuid,
  name text NOT NULL,
  slug text NOT NULL,
  type text DEFAULT 'other'::text,
  discoverability text DEFAULT 'gated'::text CHECK (discoverability = ANY (ARRAY['open'::text, 'gated'::text, 'link_only'::text, 'invite_only'::text])),
  join_policy text DEFAULT 'admin_approve'::text CHECK (join_policy = ANY (ARRAY['auto_approve'::text, 'admin_approve'::text, 'invite_only'::text])),
  domain_restriction text,
  verification_config jsonb,
  plan_tier text DEFAULT 'free'::text,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tenant_pkey PRIMARY KEY (id),
  CONSTRAINT tenant_org_group_id_fkey FOREIGN KEY (org_group_id) REFERENCES public.org_group(id),
  CONSTRAINT tenant_type_fkey FOREIGN KEY (type) REFERENCES public.tenant_type(id),
  CONSTRAINT tenant_plan_tier_fkey FOREIGN KEY (plan_tier) REFERENCES public.plan_tier(id),
  CONSTRAINT tenant_discoverability_fkey FOREIGN KEY (discoverability) REFERENCES public.discoverability(id),
  CONSTRAINT tenant_join_policy_fkey FOREIGN KEY (join_policy) REFERENCES public.join_policy(id)
);
CREATE TABLE public.tenant_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT tenant_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tshirt_size (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT tshirt_size_pkey PRIMARY KEY (id)
);
CREATE TABLE public.vendor_booking (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  vendor_profile_id uuid NOT NULL,
  headcount integer,
  cost numeric,
  contract_url text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text])),
  rating double precision,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vendor_booking_pkey PRIMARY KEY (id),
  CONSTRAINT vendor_booking_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT vendor_booking_vendor_profile_id_fkey FOREIGN KEY (vendor_profile_id) REFERENCES public.vendor_profile(id),
  CONSTRAINT vendor_booking_status_fkey FOREIGN KEY (status) REFERENCES public.vendor_booking_status(id)
);
CREATE TABLE public.vendor_booking_status (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT vendor_booking_status_pkey PRIMARY KEY (id)
);
CREATE TABLE public.vendor_profile (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  contact_person_id uuid,
  type text,
  region text,
  capacity integer,
  pricing jsonb,
  avg_rating double precision,
  verified boolean DEFAULT false,
  discoverable boolean DEFAULT false,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vendor_profile_pkey PRIMARY KEY (id),
  CONSTRAINT vendor_profile_contact_person_id_fkey FOREIGN KEY (contact_person_id) REFERENCES public.person(id),
  CONSTRAINT vendor_type_fkey FOREIGN KEY (type) REFERENCES public.vendor_type(id)
);
CREATE TABLE public.vendor_type (
  id text NOT NULL,
  label text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT vendor_type_pkey PRIMARY KEY (id)
);

