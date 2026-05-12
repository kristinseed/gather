-- ============================================================
-- gather. — RLS Policies
-- Version 1.0
-- Run after schema.sql
-- ============================================================

-- Person
create policy "Users can view own person record"
  on person for select
  using (id = auth.uid());

create policy "Users can update own person record"
  on person for update
  using (id = auth.uid());

-- Membership
create policy "Users can view own memberships"
  on membership for select
  using (person_id = auth.uid());

-- Tenant
create policy "Users can view tenants they belong to"
  on tenant for select
  using (
    id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and status = 'active'
      and deleted_at is null
    )
  );

-- Event
create policy "Users can view events for their tenants"
  on event for select
  using (
    tenant_id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and status = 'active'
      and deleted_at is null
    )
  );

-- Attendee Record
create policy "Users can view own attendee records"
  on attendee_record for select
  using (person_id = auth.uid());

create policy "Users can update own attendee records"
  on attendee_record for update
  using (person_id = auth.uid());

-- Org admin policies
create policy "Org admins can manage memberships"
  on membership for all
  using (
    tenant_id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and org_role in ('org_admin', 'committee')
      and status = 'active'
      and deleted_at is null
    )
  );

create policy "Org admins can manage events"
  on event for all
  using (
    tenant_id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and org_role in ('org_admin', 'committee')
      and status = 'active'
      and deleted_at is null
    )
  );

create policy "Org admins can view all attendee records"
  on attendee_record for select
  using (
    event_id in (
      select e.id from event e
      join membership m on m.tenant_id = e.tenant_id
      where m.person_id = auth.uid()
      and m.org_role in ('org_admin', 'committee')
      and m.status = 'active'
      and m.deleted_at is null
    )
  );

create policy "Org admins can manage branding"
  on branding for all
  using (
    tenant_id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and org_role = 'org_admin'
      and status = 'active'
      and deleted_at is null
    )
  );

-- Invitations
create policy "Users can view own invitations"
  on invitation for select
  using (
    recipient_email = (
      select email from person where id = auth.uid()
    )
  );

create policy "Org admins can manage invitations"
  on invitation for all
  using (
    tenant_id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and org_role in ('org_admin', 'committee')
      and status = 'active'
      and deleted_at is null
    )
  );

-- Join Requests
create policy "Users can view own join requests"
  on join_request for select
  using (person_id = auth.uid());

create policy "Org admins can manage join requests"
  on join_request for all
  using (
    tenant_id in (
      select tenant_id from membership
      where person_id = auth.uid()
      and org_role = 'org_admin'
      and status = 'active'
      and deleted_at is null
    )
  );

-- Super Admin
create policy "Super admin full access to person"
  on person for all
  using (
    (select email from person where id = auth.uid())
    = 'kristinseed@gmail.com'
  );

create policy "Super admin full access to tenant"
  on tenant for all
  using (
    (select email from person where id = auth.uid())
    = 'kristinseed@gmail.com'
  );

create policy "Super admin full access to membership"
  on membership for all
  using (
    (select email from person where id = auth.uid())
    = 'kristinseed@gmail.com'
  );
