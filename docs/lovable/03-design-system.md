# Gathr — Design System for Lovable
**Reference: `docs/lovable/03-design-system.md`**
Version 1.0 — May 2026

---

## How to use this document

Paste this at the start of every Lovable session before building any screens. It defines every visual and structural decision for the Gathr UI. When you need to build something not explicitly covered here, follow the **When in doubt** rule at the bottom of this document.

---

## The aesthetic in one sentence

Warm, minimal, and trustworthy — feels like flipping through a yearbook, not filing a form.

---

## CSS custom properties (design tokens)

These are the only colors, fonts, and spacing values Lovable should ever use. Never hardcode hex values. Never use Tailwind's default color palette (blue-500, gray-300, etc.) — always reference these tokens.

### Light mode tokens

```css
:root {
  /* Brand */
  --gathr-primary: #BA7517;        /* Amber — accent, progress, active states */
  --gathr-primary-hover: #9E6312;  /* Darker amber for hover states */

  /* Surfaces */
  --gathr-surface: #FDFCFA;        /* Warm white — page background */
  --gathr-surface-2: #F5F3EE;      /* Cards, stat backgrounds, input fills */
  --gathr-surface-3: #EDE9E0;      /* Subtle dividers, hover backgrounds */

  /* Text */
  --gathr-text: #2C2C2A;           /* Primary text — near black */
  --gathr-text-muted: #5F5E5A;     /* Secondary text, labels, captions */
  --gathr-text-inverse: #FDFCFA;   /* Text on dark/amber backgrounds */

  /* Borders */
  --gathr-border: #E8E4DC;         /* Standard border — warm gray */
  --gathr-border-strong: #C8C4BC;  /* Emphasized border */

  /* Status */
  --gathr-success: #2D6A4F;        /* Green — confirmed, verified */
  --gathr-warning: #B45309;        /* Amber-brown — pending, needs attention */
  --gathr-error: #991B1B;          /* Red — failed, invalid */
  --gathr-neutral: #5F5E5A;        /* Gray — inactive, deferred */

  /* Typography */
  --gathr-heading-font: Georgia, 'Times New Roman', serif;
  --gathr-body-font: system-ui, -apple-system, sans-serif;

  /* Spacing scale */
  --gathr-radius: 6px;             /* Default border radius */
  --gathr-radius-lg: 12px;         /* Cards, modals */
  --gathr-radius-full: 9999px;     /* Pills, badges */
}
```

### Dark mode tokens

Applied via `.dark` class on the root element. User preference stored on `person.dark_mode_pref`.

```css
.dark {
  --gathr-primary: #EF9F27;        /* Lighter amber for dark mode */
  --gathr-primary-hover: #D4881F;

  --gathr-surface: #1C1B18;
  --gathr-surface-2: #252420;
  --gathr-surface-3: #2E2D28;

  --gathr-text: #F5F3EE;
  --gathr-text-muted: #A8A49C;
  --gathr-text-inverse: #1C1B18;

  --gathr-border: #3A3830;
  --gathr-border-strong: #4A4840;

  --gathr-success: #4ADE80;
  --gathr-warning: #FCD34D;
  --gathr-error: #FCA5A5;
  --gathr-neutral: #A8A49C;
}
```

### Tenant override layer

When a tenant org is loaded, inject their branding on the root element. Tenant colors only ever affect the accent layer — never structural chrome.

```css
:root {
  --tenant-primary: {branding.primary_color};
  --tenant-primary-dark: {branding.primary_color_dark ?? auto-generated};
}
```

Where tenant branding applies: top color bar, eyebrow text, progress fills, active nav indicators, nudge borders, hero background tint, invitation landing page accent. Everything else stays on Gathr default tokens.

---

## Typography rules

### Fonts
- **H1, H2 only**: `var(--gathr-heading-font)` — Georgia serif, font-weight 500
- **Everything else**: `var(--gathr-body-font)` — system sans-serif, font-weight 400 or 500

### Weight rules
- Never use font-weight 600 or 700 — too heavy against the warm palette
- 400 for body text, captions, helper text
- 500 for labels, nav items, buttons, subheadings

### Size scale
- H1: 2rem (32px)
- H2: 1.5rem (24px)
- H3: 1.125rem (18px)
- Body: 1rem (16px)
- Small/caption: 0.875rem (14px)
- Micro/badge: 0.75rem (12px)

### Line height
- Body: 1.7
- Headings: 1.25
- UI labels/buttons: 1.2

### Case rules
- Sentence case everywhere — never ALL CAPS, never Title Case In Every Word
- Exception: badge labels (INVITED, PENDING) may use ALL CAPS at micro size only

---

## Component patterns

### Buttons

**Primary button** — one per screen, the main action
```
Background: var(--gathr-primary)
Text: var(--gathr-text-inverse)
Font-weight: 500
Border-radius: var(--gathr-radius)
Padding: 10px 20px
Hover: var(--gathr-primary-hover)
```

**Secondary button** — supporting actions
```
Background: transparent
Border: 1px solid var(--gathr-border-strong)
Text: var(--gathr-text)
Hover: background var(--gathr-surface-2)
```

**Destructive button** — delete, remove, revoke
```
Background: transparent
Border: 1px solid var(--gathr-error)
Text: var(--gathr-error)
Hover: background #FEF2F2
```

**Ghost/text button** — low-emphasis inline actions
```
Background: transparent
Border: none
Text: var(--gathr-primary)
Hover: text underline
```

Never use more than one primary button per screen. Never use icon-only buttons without a tooltip.

### Cards
```
Background: var(--gathr-surface-2)
Border: 1px solid var(--gathr-border)
Border-radius: var(--gathr-radius-lg)
Padding: 24px
Box-shadow: none (flat design — no drop shadows)
```

### Form inputs
```
Background: var(--gathr-surface-2)
Border: 1px solid var(--gathr-border)
Border-radius: var(--gathr-radius)
Padding: 10px 14px
Font: var(--gathr-body-font), 1rem
Focus ring: 2px solid var(--gathr-primary), offset 2px
Error state: border var(--gathr-error)
```

### Status badges
```
Border-radius: var(--gathr-radius-full)
Padding: 2px 10px
Font-size: 0.75rem
Font-weight: 500
ALL CAPS text
```

Badge color pairs (background / text):
- Active / Confirmed: #D1FAE5 / #065F46
- Invited / Pending: #F3F4F6 / #374151
- Declined / Failed: #FEE2E2 / #991B1B
- Waitlisted: #FEF3C7 / #92400E

### Tables
```
Header row: background var(--gathr-surface-3), text var(--gathr-text-muted), font-weight 500, font-size 0.875rem
Body rows: background var(--gathr-surface), border-bottom 1px solid var(--gathr-border)
Row hover: background var(--gathr-surface-2)
Cell padding: 12px 16px
```

Never zebra-stripe tables. Hover state is sufficient.

### Empty states
```
Center-aligned in container
Icon or illustration: optional, simple, monochrome
Heading: H3, var(--gathr-text)
Body: var(--gathr-text-muted), max-width 320px
CTA button: primary button if there's an action, absent if there isn't
```

Empty states should be minimal and plain. Do not add decorative illustrations unless explicitly specified in the feature spec.

---

## Layout rules

### Page structure
```
Max content width: 1200px, centered
Page padding: 24px (desktop), 16px (mobile)
Nav height: 56px, fixed top
Main content: padding-top 56px to clear nav
```

### Spacing
Use multiples of 4px only: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Never use arbitrary values like 13px or 22px.

### Responsive
- Beta is laptop-optimized (min-width 1024px)
- Do not build mobile layouts unless explicitly specified in the feature spec
- Use `min-width: 1024px` as the baseline — do not add responsive breakpoints below this for beta

---

## Component library rules

### Use Tailwind CSS for:
All layout, spacing, color, typography, borders, backgrounds — everything visual.

### Use shadcn/ui only for:
Complex interactive behavior where accessibility matters:
- Dialog / Modal
- Dropdown Menu
- Combobox / Select
- Date Picker
- Toast / Notification

For everything else — tables, cards, buttons, badges, forms, nav — build with Tailwind only. Do not reach for shadcn components for simple visual elements.

### Never use:
- Tailwind's default color palette (blue-500, gray-300, red-400, etc.) — use CSS variables only
- Font-weight 600 or 700
- Drop shadows (`shadow-md`, `shadow-lg`) — flat design only
- Rounded-full on non-pill elements
- Gradient backgrounds
- Animations or transitions beyond 150ms ease
- Third-party UI libraries other than shadcn (no MUI, no Chakra, no Ant Design)

---

## Navigation structure

### Org admin nav (left sidebar, desktop)
```
Dashboard
Members
Events
Communications
Settings
```

### Member nav (top bar, desktop)
```
[Tenant logo] — Home — Directory — Memory Wall — My Profile
```

### Platform admin nav
```
Tenants — Org Groups — Users — Lookup Tables — Settings
```

Nav active state: left border 3px solid var(--gathr-primary), background var(--gathr-surface-2).

---

## Tenant branding application

When a tenant is loaded, apply branding in these specific places only:

1. Nav top border or accent strip (4px, tenant primary color)
2. Primary button background (tenant primary replaces --gathr-primary)
3. Progress bar fill
4. Active nav indicator
5. Invitation landing page — full hero background tint at 10% opacity
6. Org logo in nav top-left

Never apply tenant colors to: body text, card backgrounds, borders, form inputs, error states, or structural chrome. The layout stays neutral — only the accent layer changes.

---

## When in doubt

This is the most important rule in this document. When Lovable needs to build something not explicitly covered by this spec or the feature spec for the current session:

**Default to minimal and plain.**

Specifically:
- Use `var(--gathr-surface-2)` as the background, `var(--gathr-border)` as the border, `var(--gathr-text)` as the text
- No decorative elements, no illustrations, no icons unless specified
- No animations beyond a simple 150ms opacity fade
- Body font, font-weight 400, sentence case
- Leave a comment in the code: `// TODO: style per spec`

Do not attempt to infer the "Gathr aesthetic" for unspecified components. A plain unstyled component is always preferable to a confidently wrong one. Styling gaps are fixed in a targeted follow-up prompt — they are not an invitation to improvise.

**The one exception:** error states and empty states always get helper text in `var(--gathr-text-muted)` explaining what happened and what to do next. Never leave a blank screen or a raw error code visible to the user.

---

## What Lovable should never do unprompted

- Add a loading spinner to every async action — only add where explicitly specified
- Add a confirmation modal to every destructive action — only where the feature spec says so
- Add pagination to every list — only where specified
- Add search to every list — only where specified
- Add a "last updated" timestamp to every record — only where specified
- Create new routes or pages not in the feature spec
- Add placeholder/dummy data beyond what's needed to render the component
- Use `console.log` in production code
- Hardcode any tenant name, email address, or ID — always read from context

---

*Reference this document at the start of every Lovable session. Pair with the relevant feature spec (docs/features/) and auth spec (docs/auth/) for the screens being built that session.*
