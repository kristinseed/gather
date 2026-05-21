-- ============================================================
-- Migration: Succession Policy Schema
-- Date: 2026-05-20
-- Session: Admin Succession Policy (Item D)
-- Run in: Supabase SQL editor
-- Safe to re-run: No — use IF NOT EXISTS / IF EXISTS guards
-- ============================================================


-- ------------------------------------------------------------
-- 1. LOOKUP TABLE: succession_policy
--    Text PK pattern (matches join_policy, discoverability, etc.)
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.succession_policy (
  id          text        NOT NULL,
  label       text        NOT NULL,
  description text,
  is_active   boolean     NOT NULL DEFAULT true,
  CONSTRAINT succession_policy_pkey PRIMARY KEY (id)
);

INSERT INTO public.succession_policy (id, label, description) VALUES
  ('activity_based',       'Activity Based',       'Temporary co-admin assigned from most active members. Used for informal orgs (family, military).'),
  ('institutional_email',  'Institutional Email',  'Platform contacts org via captured institutional email. Human resolution required. Used for schools, fraternities, civic orgs.'),
  ('platform_managed',     'Platform Managed',     'Routes directly to platform admin work queue. No automated reassignment. Fallback for org types with no clear succession path.')
ON CONFLICT (id) DO NOTHING;


-- ------------------------------------------------------------
-- 2. LOOKUP TABLE: succession_trigger
--    Records what caused a succession event — used by succession_event table
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.succession_trigger (
  id          text        NOT NULL,
  label       text        NOT NULL,
  description text,
  is_active   boolean     NOT NULL DEFAULT true,
  CONSTRAINT succession_trigger_pkey PRIMARY KEY (id)
);

INSERT INTO public.succession_trigger (id, label, description) VALUES
  ('inactivity',              'Inactivity',               'Admin crossed the inactivity threshold for their org_type.'),
  ('manual_transfer',         'Manual Transfer',          'Current admin initiated a voluntary transfer of ownership.'),
  ('death_report',            'Death Report',             'Platform received a report that the admin has passed away or is incapacitated.'),
  ('platform_reassignment',   'Platform Reassignment',    'Platform super admin manually reassigned admin rights.')
ON CONFLICT (id) DO NOTHING;


-- ------------------------------------------------------------
-- 3. NEW TABLE: succession_event
--    Audit log for every admin status change due to succession
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.succession_event (
  id                  uuid        NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id           uuid        NOT NULL REFERENCES public.tenant(id),
  triggered_by        text        NOT NULL REFERENCES public.succession_trigger(id),
  previous_admin_id   uuid        REFERENCES public.person(id),
  new_admin_id        uuid        REFERENCES public.person(id),  -- nullable: may not be resolved yet
  triggered_at        timestamptz NOT NULL DEFAULT now(),
  resolved_at         timestamptz,                               -- null = still open
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT succession_event_pkey PRIMARY KEY (id)
);

-- Index for platform admin work queue queries
CREATE INDEX IF NOT EXISTS succession_event_tenant_id_idx       ON public.succession_event (tenant_id);
CREATE INDEX IF NOT EXISTS succession_event_resolved_at_idx     ON public.succession_event (resolved_at) WHERE resolved_at IS NULL;


-- ------------------------------------------------------------
-- 4. ALTER TABLE: org_type
--    Add succession business rule columns to the lookup table
-- ------------------------------------------------------------

ALTER TABLE public.org_type
  ADD COLUMN IF NOT EXISTS succession_inactivity_days  integer,
  ADD COLUMN IF NOT EXISTS co_admin_required           boolean NOT NULL DEFAULT false;

-- Populate defaults for existing org_type rows
UPDATE public.org_type SET
  succession_inactivity_days = 540,   -- 18 months
  co_admin_required          = false
WHERE id = 'family';

UPDATE public.org_type SET
  succession_inactivity_days = 730,   -- 24 months
  co_admin_required          = true
WHERE id IN ('high_school', 'middle_school', 'college');

UPDATE public.org_type SET
  succession_inactivity_days = 300,   -- 10 months
  co_admin_required          = true
WHERE id IN ('fraternity', 'sorority', 'civic');

UPDATE public.org_type SET
  succession_inactivity_days = 300,   -- 10 months
  co_admin_required          = false
WHERE id = 'military';

UPDATE public.org_type SET
  succession_inactivity_days = 540,   -- 18 months
  co_admin_required          = false
WHERE id = 'other';


-- ------------------------------------------------------------
-- 5. ALTER TABLE: tenant
--    Add succession + org contact columns
-- ------------------------------------------------------------

ALTER TABLE public.tenant
  ADD COLUMN IF NOT EXISTS org_contact_email          text,
  ADD COLUMN IF NOT EXISTS org_contact_email_verified boolean     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS org_contact_website        text,
  ADD COLUMN IF NOT EXISTS last_event_at              timestamptz,
  ADD COLUMN IF NOT EXISTS succession_policy          text        REFERENCES public.succession_policy(id),
  ADD COLUMN IF NOT EXISTS co_admin_required_by       date;       -- set when first co-admin warning fires


-- ------------------------------------------------------------
-- 6. ALTER TABLE: org_group
--    Add institutional contact + succession policy columns
-- ------------------------------------------------------------

ALTER TABLE public.org_group
  ADD COLUMN IF NOT EXISTS institutional_contact_email  text,
  ADD COLUMN IF NOT EXISTS org_contact_website          text,
  ADD COLUMN IF NOT EXISTS succession_policy            text      REFERENCES public.succession_policy(id);


-- ------------------------------------------------------------
-- 7. ALTER TABLE: membership
--    Add last_activity_at for activity-based succession ranking
-- ------------------------------------------------------------

ALTER TABLE public.membership
  ADD COLUMN IF NOT EXISTS last_activity_at  timestamptz;


-- ------------------------------------------------------------
-- 8. RLS: succession_event
--    Mirrors the pattern used on other audit/admin tables.
--    Platform admins: full access.
--    Org admins: read their own tenant's succession events.
--    No client writes — service role only.
-- ------------------------------------------------------------

ALTER TABLE public.succession_event ENABLE ROW LEVEL SECURITY;

-- Super admin: full access
CREATE POLICY "Super admin full access on succession_event"
  ON public.succession_event
  FOR ALL
  TO authenticated
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- Org admin: read only, own tenant
CREATE POLICY "Org admin read own tenant succession_event"
  ON public.succession_event
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.membership m
      WHERE m.tenant_id    = succession_event.tenant_id
        AND m.person_id    = my_person_id()
        AND m.org_role     = 'org_admin'
        AND m.status       = 'active'
        AND m.deleted_at   IS NULL
    )
  );

-- No INSERT/UPDATE/DELETE for authenticated users — service role only


-- ------------------------------------------------------------
-- 9. VERIFY
--    Run these SELECTs after migration to confirm everything landed.
-- ------------------------------------------------------------

-- SELECT id, label FROM public.succession_policy ORDER BY id;
-- SELECT id, label FROM public.succession_trigger ORDER BY id;
-- SELECT id, succession_inactivity_days, co_admin_required FROM public.org_type ORDER BY id;
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'tenant'      AND column_name LIKE '%succession%' OR column_name LIKE '%org_contact%';
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'org_group'   AND column_name IN ('institutional_contact_email', 'org_contact_website', 'succession_policy');
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'membership'  AND column_name = 'last_activity_at';
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'succession_event';
