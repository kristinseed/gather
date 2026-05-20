# Org Group Architecture + Seeding Plan

## Hierarchy
org_group = parent org (platform owned)
tenant = class/chapter (first creator = org_admin)
event = gathering (creator = event_admin)

## Org Group Columns
id, name, slug, type FK org_type, status, nces_id, city, state, zip, website, last_verified_at, source

## Org Group Rows (seed data)
- Lawrenceville HS: id=f149a853-21a5-4580-a602-d44ad644ac23, slug=lawrenceville-hs
- Raymond Lincolnwood HS: id=d6d19699-ce7e-49b0-ba6a-d9fbc45d6270, slug=raymond-lincolnwood-hs

## Status Values
- seeded = searchable in onboarding, not live, no tenant yet
- active = tenant exists
- archived = deprecated

## Onboarding Flow
type → state → city → dropdown → select → creates tenant + flips org_group to active
Seeded orgs never appear on public browse — onboarding search only.

## Data Sources
- NCES CCD — high schools
- IPEDS — colleges
- NIC / NPC / NPHC — fraternities/sororities

## Fraternity Hierarchy
national → chapter → pledge class

## UI Rule
Never hardcode school/class language. All labels driven by org_type.

## Ownership + Succession
org_group = platform owned
tenant = first creator (org_admin)
event = creator (event_admin)
Succession mechanism for org_admin needed — not yet built.

## First-Time Flow Rule
Show value before asking for effort. Every role sees something meaningful before doing anything.
Blank states and confusion are #1 drop-off cause.

## Platform Admin Dashboard Needs
1. Action queue: pending join requests, new org creation requests, flagged content, orgs with no admin 12+ months
2. System hygiene: data freshness alerts
3. data_source_import table: source, import_date, records_added, records_updated, records_deprecated
4. org_group needs last_verified_at + source fields
5. Platform nudge example: "NCES CCD file is 14 months old — new version available."
