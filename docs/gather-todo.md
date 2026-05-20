# Gather — Master To-Do List
*Last updated: May 2026 — Session 11*

---

## FOUNDATIONAL BLOCKERS
Do these before onboarding any real users. These are not features — they are preconditions.

- [ ] **A. Email deliverability** — SPF/DKIM/DMARC on sending domain. Decide tenant email strategy: does each tenant send from `noreply@gather.app` or `noreply@{slug}.gather.app`? Affects deliverability, branding, and trust.
- [ ] **B. Stripe Connect architecture** — Platform fee model vs. payment facilitator. Money cannot move through the app until this is decided. Affects compliance, tax reporting, and integration design.
- [ ] **C. File storage governance** — Define per-tenant upload limits by plan tier, NSFW/moderation policy for memory wall, and GDPR deletion policy for shared uploads when a person deletes their account.
- [ ] **D. No-admin succession flow** — What triggers the alert when an org has no active admin? What does outreach look like? Who can self-nominate? What is the verification step?
- [ ] **E. Accessibility (WCAG AA)** — Especially critical for institutional buyers (national fraternities, alumni associations). Color contrast checker in branding tool is a start. Audit Lovable-generated forms and inputs.
- [ ] **F. Terms of Service + Privacy Policy** — Must cover unclaimed/imported PII (CCPA + GDPR). Real documents, not boilerplate. Required before first real user.
- [ ] **G. Secret management** — Move all API keys from Google Sheet to Vercel environment variables. Establish `.env` pattern for local dev. Do before any external users.
- [ ] **H. E2E auth chain tests** — Playwright or Cypress covering the 4-step identity resolution sequence. This is the most complex logic in the app and hardest to manually QA after every Lovable regeneration.
- [ ] **I. Mobile PWA decision** — Affects notification architecture. Member-facing flows must be genuinely excellent on mobile. Decide before building more member screens.

---

## BACKEND / SCHEMA
- [ ] Fix Lovable routes
- [ ] Write `01-auth-chain.md` content
- [ ] Complete OAuth setup (Google + Facebook)
- [ ] Commit `02-member-first-visit.md` to GitHub
- [ ] Update `schema.sql` to reflect all current tables
- [ ] Rename legacy RLS policies to new naming convention
- [ ] RLS on remaining tables (all tables should have policies)
- [ ] Add cols to `org_group`: status, nces_id, city, state, zip, website, last_verified_at, source
- [ ] Download NCES CCD (high schools) + IPEDS (colleges) CSVs for seeding
- [ ] Add `subscription` table (org-level, Stripe fields)
- [ ] Add `feature_flag` table or JSONB on tenant
- [ ] Add financial visibility role to membership
- [ ] Add `data_source_import` table for platform hygiene tracking

---

## PRODUCT / GTM
- [ ] Pricing tier matrix — what's in each tier, where features gate
- [ ] Consent model — architect now, not retrofit. Especially for long-play data strategy.
- [ ] Finalize one-sentence pitch for each ICP (Grassroots Initiator, Institutional buyer)
- [ ] Institutional sales motion — who calls who, what's the deck, what proof point is needed
- [ ] Research: confirm Salesforce/Blackbaud do not have a reunion execution module
- [ ] GTM Session 10 — success scenarios, consumer/prosumer path, enterprise path, GEO/AEO marketing

---

## PROJECT HYGIENE
- [ ] Upload key docs to Claude Project (replaces memory entries): schema, foundation doc, decisions log, this file
- [ ] Decide on Claude background task setup (API + cron via GitHub Actions or Google Apps Script)
- [ ] Wire Trent's auth_user_id to his person record

---

## DECISIONS ALREADY MADE (do not relitigate)
- Lookup tables for all type/status/role/policy columns — super admin manages via UI, no raw SQL
- Soft delete everywhere — `deleted_at` on all entities, never hard delete
- RLS pattern: service role for admin client, auth.uid() checks for all client queries
- Tenant slug unique per org_group, not globally
- org_group = platform owned; tenant = first creator; event = creator
- Hierarchy: org_group → tenant → event
- URL structure: `/{org-group-slug}/{tenant-slug}/` prefix on all tenant routes
- Stripe Connect (not facilitator) — decided, not yet implemented
- Gather is execution layer on top of Salesforce/Blackbaud for institutional buyers — integration story, not replacement story
- Revenue model: institutional SaaS + event license + payment processing % + future vendor/data layer
