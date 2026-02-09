# USCIS Case Tracker: CSS Theme Migration Plan

**Version:** 1.0.0  
**Date:** February 8, 2026  
**Author:** Front-End Architecture Team  
**Status:** Planning  

---

## Executive Summary

Migrate the USCIS Case Tracker from a monolithic 3,400-line `app-styles.css` to a modular, token-driven theme system ("Maine Pine v5") that follows Apple Human Interface Guidelines principles: clarity, deference, and depth. The new system uses CSS custom properties as design tokens, a layered specificity model (no `!important` outside print/a11y), and component-scoped modules for maintainability.

### Current State Problems

| Problem | Impact | Severity |
|---------|--------|----------|
| Single 3,394-line `app-styles.css` | Impossible to maintain; changes risk regressions | Critical |
| Overuse of `body` prefix selectors | Specificity inflation; forces `!important` elsewhere | High |
| Hard-coded hex colors throughout | Color changes require find-and-replace across file | High |
| Glassmorphism `backdrop-filter` on everything | Performance regression on older hardware; 60fps failures | Medium |
| No responsive breakpoint system | Ad-hoc `@media` queries scattered; inconsistent behavior | Medium |
| `!important` on floating-label overrides (30+ uses) | Breaks Theme Roller customization; specificity deadlock | High |
| No CSS linting or formatting standards | Inconsistent spacing, selectors, vendor prefixes | Low |
| Forms with no layout rhythm | Full-width sprawl; no max-width constraints | Medium |
| Login page falls back to Oracle defaults | Inconsistent brand experience | Medium |
| Notifications nearly invisible | Low contrast alert colors from Redwood defaults | Medium |
| Footer unstyled | Plain text; no brand integration | Low |
| Region headers overlap content | Zero padding/margin between title and body | Medium |

### Target State

- **Modular architecture:** 1 token file + 7 component modules (< 300 lines each)
- **Zero `!important`:** Specificity managed via cascade layers or constrained selectors
- **Full WCAG 2.1 AA compliance:** All color combinations ≥ 4.5:1 contrast ratio
- **Responsive-first:** 3-breakpoint system (mobile/tablet/desktop)
- **Theme Roller compatible:** All overrides via `--ut-*` / `--a-*` custom properties
- **Performance budget:** < 50KB total CSS (currently ~85KB)

---

## Architecture: New Theme System

### File Structure

```
shared_components/
  files/
    css/
      maine-pine-v5/
        00-tokens.css            # Design tokens (colors, spacing, typography, shadows)
        01-foundations.css        # Reset, body, typography, responsive grid
        02-layout.css            # Page layout, containers, max-width, regions
        03-navigation.css        # Header, sidebar nav, user icon, menu
        04-forms.css             # Inputs, labels, selects, search, IG controls
        05-components.css        # Cards, badges, timeline, buttons, alerts
        06-pages.css             # Page-specific overrides (login, dashboard, etc.)
        07-utilities.css         # Print, a11y, animations, status dots
        maine-pine-v5.css        # Built file — concatenates all modules (make css-build)
    template_components.css      # Unchanged — TC-specific styles
    template_components.js       # Unchanged
```

### APEX Integration

**Reference in Shared Components → User Interface Attributes → CSS File URLs:**
```
#APP_FILES#css/maine-pine-v5/maine-pine-v5.css
#APP_FILES#template_components.css
```

**Replaces:** `#APP_FILES#app-styles.css` (archived, not deleted during migration)

### Cascade Strategy

```
Layer 0: APEX Universal Theme defaults (theme42.min.css)
Layer 1: 00-tokens.css         — :root custom properties only
Layer 2: 01-foundations.css     — element selectors, body
Layer 3: 02-layout.css         — .t-Body, .t-Region (single class)
Layer 4: 03-navigation.css     — .t-Header *, .t-TreeNav *
Layer 5: 04-forms.css          — .t-Form *, .a-IG *, inputs
Layer 6: 05-components.css     — .t-Card, .t-Alert, .t-Button
Layer 7: 06-pages.css          — body.page-X scoping (login, dashboard)
Layer 8: 07-utilities.css      — Animation keyframes, print, sr-only
```

No `!important` needed — specificity increases naturally through each layer.

---

## Phase 1: Audit & Foundation (4 hours)

### Task 1.1 — Audit Current CSS

**Goal:** Document every rule in `app-styles.css` by component category.

| Step | Action | Tool | Output |
|------|--------|------|--------|
| 1.1.1 | Extract all unique selectors from `app-styles.css` | `grep -E '^\s*[.#a-z]' app-styles.css \| sort -u` | Selector inventory |
| 1.1.2 | Identify all `!important` usages | `grep -c '!important' app-styles.css` | Count + line numbers |
| 1.1.3 | Map selectors to APEX components | Manual: Page Designer + DevTools | Component map spreadsheet |
| 1.1.4 | Identify dead CSS (unused selectors) | Chrome DevTools Coverage tab | Removal candidates list |
| 1.1.5 | Screenshot all pages for regression comparison | Manual or Percy/Playwright | Baseline gallery |

**Deliverable:** `docs/CSS_AUDIT_RESULTS.md` with full inventory.

### Task 1.2 — Create Design Token File

**Goal:** Extract all colors, spacing, typography, and shadows into `00-tokens.css`.

**Action:**
- Move all `:root` variables from current `app-styles.css` into dedicated tokens file
- Normalize naming to semantic convention: `--mp-{category}-{variant}`
- Add responsive spacing scale
- Define breakpoint custom properties

**Naming Convention:**

| Prefix | Category | Example |
|--------|----------|---------|
| `--mp-color-` | Colors | `--mp-color-primary`, `--mp-color-neutral-300` |
| `--mp-space-` | Spacing | `--mp-space-xs`, `--mp-space-sm`, `--mp-space-md` |
| `--mp-font-` | Typography | `--mp-font-family-sans`, `--mp-font-size-base` |
| `--mp-shadow-` | Shadows | `--mp-shadow-sm`, `--mp-shadow-lg` |
| `--mp-radius-` | Border radius | `--mp-radius-sm`, `--mp-radius-md` |
| `--mp-transition-` | Transitions | `--mp-transition-fast`, `--mp-transition-normal` |
| `--mp-gradient-` | Gradients | `--mp-gradient-primary`, `--mp-gradient-hero` |
| `--mp-status-` | Case status | `--mp-status-approved-bg`, `--mp-status-denied-fg` |

### Task 1.3 — Configure Theme Roller Baseline

**Goal:** Set Theme Roller to align with Maine Pine v5 tokens.

| Theme Roller Setting | Value | Maps To |
|---------------------|-------|---------|
| Primary Color | `#082E58` | `--mp-color-primary` |
| Body Background | `#F4F7F6` | `--mp-color-bg-page` |
| Header Background | `#082E58` | `--mp-color-primary` |
| Navigation Background | `#082E58` | `--mp-color-primary` |
| Component Background | `#FFFFFF` | `--mp-color-bg-card` |
| Border Color | `#CCD3D1` | `--mp-color-neutral-300` |
| Font Family | `Inter, system-ui, -apple-system, sans-serif` | `--mp-font-family-sans` |
| Spacing Unit | `1.25rem` | `--mp-space-unit` |

### Task 1.4 — Backend: Archive Old CSS

```sh
# In project root
cp shared_components/files/app-styles.css shared_components/files/app-styles.v4-archive.css
```

**Deliverables:**
- [x] `00-tokens.css` created with full token system
- [x] Theme Roller configuration documented
- [x] Old CSS archived

---

## Phase 2: Global Foundations (6 hours)

### Task 2.1 — Foundations Module (`01-foundations.css`)

**What moves here:**
- `body` styling (font-family, background, min-height)
- `body::before` background mesh (simplified; remove performance-heavy radial gradients)
- Global typography scale
- Link colors
- Selection highlight
- Focus outline defaults

**Key changes from current:**
- Remove `body::before` pseudo-element radial gradient mesh (perf hit; replace with solid `background-color`)
- Consolidate font declarations into single `body` rule
- Add responsive typography via `clamp()`

### Task 2.2 — Layout Module (`02-layout.css`)

**Handles Issue #1: Forms with No Pattern/Styling, Full-Width Sprawl**

```css
/* Dashboard / form container constraint */
.t-Body-contentInner {
    max-width: 1400px;
    margin: 0 auto;
    padding: var(--mp-space-lg);
}

/* Region card styling */
.t-Region {
    --ut-region-background-color: var(--mp-color-bg-card);
    --ut-component-border-color: var(--mp-color-neutral-300);
    --ut-component-border-radius: var(--mp-radius-md);
    --ut-component-shadow: var(--mp-shadow-sm);
}

/* Form regions get consistent card treatment */
.t-Region--scrollBody,
.t-Form--stretchInputs {
    max-width: 1200px;
    margin: 0 auto;
    padding: var(--mp-space-lg);
}
```

**Key changes:**
- Add `max-width: 1400px` to main content area (prevents full-width sprawl)
- Center all regions with `margin: 0 auto`
- Consistent padding rhythm using spacing tokens
- Region borders and shadows via UT custom properties (not hard-coded)

### Task 2.3 — Responsive Breakpoint System

> **⚠ Note:** CSS custom properties (`var(--mp-bp-mobile)` etc.) **cannot** be used
> inside `@media` rules. Media queries are evaluated before the cascade, so the
> browser does not resolve custom properties at that point. The tokens below are
> defined as a documentation reference; the actual `@media` rules must use literal
> values. If you need single-source breakpoint values, use a build-time tool such
> as Sass variables (`$bp-mobile: 640px`) or PostCSS Custom Media
> (`@custom-media --mobile (max-width: 640px)`).

```css
/* In 00-tokens.css — these tokens document the breakpoints but cannot be
   referenced inside @media queries (CSS limitation). */
:root {
    --mp-bp-mobile: 640px;
    --mp-bp-tablet: 1024px;
    --mp-bp-desktop: 1400px;
}

/* In 01-foundations.css — literal values required */
@media (max-width: 640px)  { /* mobile rules */ }
@media (max-width: 1024px) { /* tablet rules */ }
@media (min-width: 1025px) { /* desktop rules */ }

/* PostCSS alternative (requires postcss-custom-media plugin):
   @custom-media --mobile (max-width: 640px);
   @custom-media --tablet (max-width: 1024px);
   @custom-media --desktop (min-width: 1025px);
   @media (--mobile) { ... }
*/
```

**Deliverables:**
- [x] `01-foundations.css` — body, typography, links, focus
- [x] `02-layout.css` — page layout, region cards, responsive grid

---

## Phase 3: Navigation & Chrome (4 hours)

### Task 3.1 — Navigation Module (`03-navigation.css`)

**Handles Issue #2: Menu/User Icon with Simple Styling**

**What moves here:**
- All `.t-Header` rules
- All `.t-TreeNav` / sidebar nav rules
- Logo styling
- User avatar/icon button
- Navigation bar menu items

**Key changes from current:**

| Current Problem | Fix |
|----------------|-----|
| 30+ selectors for sidebar nav with `body` prefix | Flatten to 10 essential selectors |
| Hard-coded `#0A3D73` / `#082E58` in nav | Use `--mp-color-primary` / `--mp-color-primary-light` tokens |
| `!important` on `.a-TreeView-label` color | Increase selector specificity naturally instead |
| No hover transition on nav bar items | Add `transition: background var(--mp-transition-fast)` |
| User icon is invisible/bland | Add border + border-radius + hover shadow |

**New: User Avatar Styling:**

```css
/* User icon in header */
.t-Header .t-Button--headerUser {
    --a-button-background-color: transparent;
    border: 1px solid var(--mp-color-neutral-300);
    border-radius: 50%;
    padding: var(--mp-space-xs);
    transition: box-shadow var(--mp-transition-fast);
}

.t-Header .t-Button--headerUser:hover {
    box-shadow: var(--mp-shadow-md);
}
```

**New: Nav Bar Menu Enhancement:**

```css
.t-NavigationBar-item a {
    padding: 0.75rem 1.25rem;
    transition: background var(--mp-transition-fast);
}

.t-NavigationBar-item a:hover {
    background-color: rgba(255, 255, 255, 0.08);
    border-radius: var(--mp-radius-sm);
}
```

**Deliverable:** `03-navigation.css` — header + sidebar + user icon

---

## Phase 4: Forms & Interactive Grid (6 hours)

### Task 4.1 — Forms Module (`04-forms.css`)

**Handles Issues #1 and #4: Form Layout + Title Overlap**

**What moves here:**
- All `.t-Form-*` rules
- Floating-label overrides (rewritten without `!important`)
- Input/select/textarea styling
- Filter bar / search region
- Interactive Grid controls
- Receipt number input
- Checkbox/radio styling

**Key changes:**

| Current Problem | Fix |
|----------------|-----|
| Floating-label fix uses 30+ `!important` rules | Use `:where()` pseudo-class to lower UT specificity, allowing override without `!important` |
| Form labels and content overlap | Add consistent `padding-bottom: var(--mp-space-lg)` to `.t-Region-header` |
| No label alignment | Add flex layout to `.t-Form-labelContainer` with right-align option |
| IG cell padding too tight | Override `--a-ig-cell-padding: 1rem` |

**Form Title Fix (Issue #4):**

```css
/* Region header spacing — prevents title/content overlap */
.t-Region-header {
    padding-bottom: var(--mp-space-lg);
    margin-bottom: var(--mp-space-md);
    border-bottom: 1px solid var(--mp-color-neutral-300);
}

.t-Region-titleText {
    margin: 0;  /* reset any overlapping margins */
}
```

**Interactive Grid Polish:**

```css
.a-IG {
    --a-ig-grid-border-color: var(--mp-color-neutral-300);
    --a-ig-cell-padding: 1rem;
    --a-ig-header-background-color: var(--mp-color-bg-page);
    border-radius: var(--mp-radius-md);
    overflow: hidden;
}
```

**Deliverable:** `04-forms.css` — all form + IG styling (< 300 lines)

---

## Phase 5: Components (8 hours)

### Task 5.1 — Components Module (`05-components.css`)

**Handles Issues #4, #5, #6: Titles, Footer, Notifications**

**What moves here:**
- Cards (`.t-Card`, `.summary-card`)
- Buttons (all variants: hot, danger, success, warning, simple)
- Alerts/Notifications
- Badges
- Timeline
- Footer
- Status dots
- API status indicator
- Toggle switches

**Notification Visibility Fix (Issue #6):**

```css
/* High-contrast alerts */
.t-Alert--success {
    --ut-alert-background-color: #dcfce7;
    --ut-alert-text-color: #166534;
    border-left: 4px solid #22c55e;
}

.t-Alert--info {
    --ut-alert-background-color: #dbeafe;
    --ut-alert-text-color: #1e40af;
    border-left: 4px solid #3b82f6;
}

.t-Alert--warning {
    --ut-alert-background-color: #fef3c7;
    --ut-alert-text-color: #92400e;
    border-left: 4px solid #f59e0b;
}

.t-Alert--danger {
    --ut-alert-background-color: #fce8e8;
    --ut-alert-text-color: #6e1111;
    border-left: 4px solid #ef4444;
}

/* Badge urgency */
.t-BadgeList-value {
    --a-badge-background-color: var(--mp-color-danger);
    --a-badge-text-color: #fff;
    font-weight: 700;
}
```

**Footer Styling (Issue #5):**

```css
.t-Footer {
    background-color: var(--mp-color-bg-page);
    border-top: 1px solid var(--mp-color-neutral-300);
    padding: var(--mp-space-md);
    font-size: var(--mp-font-size-sm);
    color: var(--mp-color-neutral-500);
    text-align: center;
}

.t-Footer a {
    color: var(--mp-color-secondary);
    text-decoration: underline;
    text-underline-offset: 2px;
}

.t-Footer a:hover {
    color: var(--mp-color-primary);
}
```

**Button Simplification:**

Current CSS has 150+ lines of button rules with `body` prefix inflation. New approach:

```css
/* Hot buttons via UT variables — no specificity war */
.t-Button--hot {
    --a-button-background-color: var(--mp-color-primary);
    --a-button-text-color: #fff;
    --a-button-hover-background-color: var(--mp-color-primary-light);
    border-radius: var(--mp-radius-md);
    font-weight: 600;
}
```

**Deliverable:** `05-components.css` — all UI components

---

## Phase 6: Page-Specific & Login (4 hours)

### Task 6.1 — Pages Module (`06-pages.css`)

**Handles Issue #3: Login Page Weird**

**Login Page Fix:**

```css
/* Login page — force brand consistency */
body.t-PageBody--login {
    background: var(--mp-gradient-hero);
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
}

.t-Login-container {
    max-width: 420px;
    padding: var(--mp-space-xl);
    background: var(--mp-color-bg-card);
    border: 1px solid var(--mp-color-neutral-300);
    border-radius: var(--mp-radius-lg);
    box-shadow: var(--mp-shadow-xl);
}

.t-Login-title {
    font-size: var(--mp-font-size-xl);
    color: var(--mp-color-primary);
    font-weight: 700;
    margin-bottom: var(--mp-space-lg);
}

.t-Login-logo {
    text-align: center;
    margin-bottom: var(--mp-space-lg);
}
```

**Also include:**
- Dashboard page (Page 1) — summary card grid
- Import/Export page (Page 6) — transfer cards, drag-drop overlay
- Settings page (Page 7) — credential indicators
- Admin page (Page 8) — health cards, audit badges

**Deliverable:** `06-pages.css` — page-scoped overrides

### Task 6.2 — Utilities Module (`07-utilities.css`)

**What moves here:**
- `@keyframes` (all animations: `dotPulse`, `statusPulse`, `pulseRing`, `timelineSlideIn`, `spin`)
- Print styles
- Screen-reader-only utility (`.sr-only`)
- Status dot classes (`.status-dot.approved`, etc.)
- Hero region empty-icon fix

**Deliverable:** `07-utilities.css` — animations, print, a11y

---

## Phase 7: Assembly & Integration (2 hours)

### Task 7.1 — Create Concatenated Theme File

Create `maine-pine-v5.css` that imports all modules in order:

```css
/* Maine Pine v5 — USCIS Case Tracker Theme
   Version: 5.0.0
   Assembled: auto-concatenated from modules */

/* @import url("maine-pine-v5/00-tokens.css"); */
/* @import url("maine-pine-v5/01-foundations.css"); */
/* ... etc ... */

/* Note: APEX static files don't support @import.
   This file is a build artifact — concatenate modules
   during the upload step via the Makefile. */
```

### Task 7.2 — Update Makefile

Add new targets:

```makefile
# Concatenate CSS modules into single theme file
css-build:
	cat shared_components/files/css/maine-pine-v5/00-tokens.css \
	    shared_components/files/css/maine-pine-v5/01-foundations.css \
	    shared_components/files/css/maine-pine-v5/02-layout.css \
	    shared_components/files/css/maine-pine-v5/03-navigation.css \
	    shared_components/files/css/maine-pine-v5/04-forms.css \
	    shared_components/files/css/maine-pine-v5/05-components.css \
	    shared_components/files/css/maine-pine-v5/06-pages.css \
	    shared_components/files/css/maine-pine-v5/07-utilities.css \
	    > shared_components/files/css/maine-pine-v5.css

# Minify for production
css-minify: css-build
	# Requires: npm install -g clean-css-cli
	cleancss -o shared_components/files/css/maine-pine-v5.min.css \
	         shared_components/files/css/maine-pine-v5.css

# Full CSS pipeline
css: css-build css-minify
```

### Task 7.3 — Update APEX Static File Reference

In Shared Components → User Interface Attributes → CSS File URLs:

**Before:**
```
#APP_FILES#app-styles.css
```

**After:**
```
#APP_FILES#css/maine-pine-v5/maine-pine-v5.css
#APP_FILES#template_components.css
```

---

## Phase 8: Testing & Validation (4 hours)

### Task 8.1 — Visual Regression Testing

| Page | Test Criteria | Tool |
|------|--------------|------|
| Login (101) | Centered card, branded colors, no Oracle defaults | Manual + screenshot |
| Dashboard (1) | Summary cards constrained, no full-width sprawl | Manual |
| Case List (2) | IG borders consistent, row hover works | Manual |
| Case Detail (3) | Timeline animates, badges visible, title no overlap | Manual |
| Add Case (4) | Form labels stacked, inputs aligned, focus ring visible | Manual |
| Check Status (5) | Modal styled, loading states work | Manual |
| Import/Export (6) | Drag-drop overlay, progress bar styled | Manual |
| Settings (7) | Credential indicators visible | Manual |
| Admin (8) | Health cards equal height, badges styled | Manual |

### Task 8.2 — Responsive Testing

| Breakpoint | Width | Verify |
|-----------|-------|--------|
| Mobile | 375px | Single-column layout, stacked cards, readable text |
| Tablet | 768px | 2-column grid, sidebar collapsed, touch targets ≥ 44px |
| Desktop | 1440px | Full layout, sidebar visible, max-width respected |

### Task 8.3 — Accessibility Audit

- [ ] All color combinations ≥ 4.5:1 contrast (use axe DevTools)
- [ ] Focus indicators visible on all interactive elements
- [ ] No content hidden by CSS that should be accessible
- [ ] Print stylesheet hides non-essential UI
- [ ] Reduced motion: `@media (prefers-reduced-motion)` disables animations

### Task 8.4 — Performance Audit

- [ ] Total CSS < 50KB (gzipped < 10KB)
- [ ] No unused selectors > 5% (Chrome Coverage tab)
- [ ] Largest Contentful Paint < 2.5s
- [ ] No layout shifts from CSS loading

---

## Phase 9: Deployment & Cleanup (2 hours)

### Task 9.1 — Deploy New Theme

```sh
make css-build         # Concatenate modules
make upload            # Upload to APEX static files
make deploy            # Import app + upload files
```

### Task 9.2 — Remove Old Page-Level CSS

After confirming new theme works on all pages:

1. Go through each page in APEX Builder
2. Remove any inline CSS from Page → CSS → Inline
3. Remove page-specific CSS file references
4. Verify no regressions

### Task 9.3 — Archive and Document

- Archive `app-styles.css` → `app-styles.v4-archive.css`
- Update `docs/APEX_FRONTEND_DESIGN.md` Section 3 with new theme system
- Update `docs/APEX_CONTEXTUAL_ANCHOR.md` P2 section with new file references
- Add CSS linting rules to project (stylelint config)

### Task 9.4 — Team Guidelines

Add to `README.md` or create `docs/CSS_GUIDELINES.md`:

```markdown
## CSS Development Rules

1. **Never edit `maine-pine-v5.css` directly** — it's a build artifact
2. **All changes go in module files** (`00-tokens.css` through `07-utilities.css`)
3. **Run `make css-build` after changes** to regenerate the concatenated file
4. **No `!important`** — increase selector specificity or use UT variables instead
5. **Use design tokens** — never hard-code colors, spacing, or shadows
6. **New components** go in `05-components.css`; page-specific in `06-pages.css`
7. **Test at 3 breakpoints** before committing: 375px, 768px, 1440px
```

---

## Timeline & Effort Summary

| Phase | Description | Hours | Dependencies |
|-------|------------|-------|-------------|
| 1 | Audit & Foundation | 4 | None |
| 2 | Global Foundations | 6 | Phase 1 |
| 3 | Navigation & Chrome | 4 | Phase 2 |
| 4 | Forms & Interactive Grid | 6 | Phase 2 |
| 5 | Components | 8 | Phase 2 |
| 6 | Page-Specific & Login | 4 | Phases 3-5 |
| 7 | Assembly & Integration | 2 | Phase 6 |
| 8 | Testing & Validation | 4 | Phase 7 |
| 9 | Deployment & Cleanup | 2 | Phase 8 |
| **Total** | | **40 hours** | |

**Recommended cadence:** 2 phases per week → **5 weeks elapsed**

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Visual regressions on obscure pages | High | Medium | Baseline screenshots before starting; test every page |
| Theme Roller overrides conflict with CSS | Medium | Medium | Set Theme Roller first, then write CSS to complement |
| APEX 24.2 update changes UT variables | Low | High | Pin to documented `--ut-*` / `--a-*` variables only |
| `!important` removal breaks floating labels | High | High | Prototype floating-label fix in isolation first |
| Team adds page-level CSS again | Medium | Medium | Lint rules + code review checklist + documentation |

---

## Appendix A: Design Token Migration Map

Maps old variable names to new `--mp-*` token names:

| Old Variable | New Token | Value |
|-------------|-----------|-------|
| `--uscis-primary` | `--mp-color-primary` | `#082E58` |
| `--uscis-primary-light` | `--mp-color-primary-light` | `#0A3D73` |
| `--uscis-secondary` | `--mp-color-secondary` | `#004832` |
| `--uscis-secondary-dark` | `--mp-color-secondary-dark` | `#002E20` |
| `--uscis-accent` | `--mp-color-accent` | `#FFE84F` |
| `--status-approved` | `--mp-status-approved` | `#004832` |
| `--status-denied` | `--mp-status-denied` | `#8B1A1A` |
| `--status-pending` | `--mp-status-pending` | `#6F513E` |
| `--status-rfe` | `--mp-status-rfe` | `#082E58` |
| `--status-received` | `--mp-status-received` | `#4A2D73` |
| `--status-transferred` | `--mp-status-transferred` | `#006064` |
| `--status-unknown` | `--mp-status-unknown` | `#5A5A5A` |
| `--neutral-100` | `--mp-color-neutral-100` | `#FFFFFF` |
| `--neutral-300` | `--mp-color-neutral-300` | `#CCD3D1` |
| `--neutral-500` | `--mp-color-neutral-500` | `#6F513E` |
| `--neutral-700` | `--mp-color-neutral-700` | `#3D3028` |
| `--neutral-900` | `--mp-color-neutral-900` | `#0F1B2A` |
| `--bg-page` | `--mp-color-bg-page` | `#F4F7F6` |
| `--bg-card` | `--mp-color-bg-card` | `#FFFFFF` |
| `--shadow-sm` | `--mp-shadow-sm` | `0 1px 3px rgba(0,0,0,0.08)` |
| `--shadow-md` | `--mp-shadow-md` | `0 4px 6px rgba(0,0,0,0.1)` |
| `--shadow-lg` | `--mp-shadow-lg` | `0 10px 25px rgba(0,0,0,0.15)` |
| `--radius-sm` | `--mp-radius-sm` | `6px` |
| `--radius-md` | `--mp-radius-md` | `10px` |
| `--radius-lg` | `--mp-radius-lg` | `16px` |
| `--transition-fast` | `--mp-transition-fast` | `0.15s cubic-bezier(0.4, 0, 0.2, 1)` |
| `--transition-normal` | `--mp-transition-normal` | `0.25s cubic-bezier(0.4, 0, 0.2, 1)` |

## Appendix B: `!important` Removal Strategy

The current floating-label fix uses 30+ `!important` declarations. Strategy to remove:

1. **Use `:where()` to lower APEX's specificity:**
   ```css
   /* APEX generates: .t-Form-fieldContainer--floatingLabel .t-Form-labelContainer
      which has specificity (0,2,0). Wrap the APEX qualifier in :where() to reduce
      it to (0,1,0) so our single-class overrides win without !important: */
   :where(.t-Form-fieldContainer--floatingLabel) .t-Form-labelContainer {
       position: relative;
       transform: none;
   }
   ```

2. **Double-class trick** for stubborn overrides:
   ```css
   .t-Form-label.t-Form-label {
       font-size: 13px;
       font-weight: 600;
   }
   ```

3. **Remaining `!important` allowed only in:**
   - `@media print` rules
   - `.sr-only` accessibility utility
   - APEX JavaScript inline style overrides (documented exceptions)

## Appendix C: Page-by-Page CSS Removal Checklist

After deploying the new theme, verify and remove old page-specific CSS:

| Page | Page ID | Has Inline CSS? | Action Required |
|------|---------|----------------|-----------------|
| Dashboard | 1 | Check | Remove; covered by `06-pages.css` |
| Case List | 2 | Check | Remove; covered by `04-forms.css` + `05-components.css` |
| Case Detail | 3 | Check | Remove; covered by `05-components.css` |
| Add Case | 4 | Check | Remove; covered by `04-forms.css` |
| Check Status | 5 | Check | Remove; covered by `04-forms.css` |
| Import/Export | 6 | Check | Remove; covered by `06-pages.css` |
| Settings | 7 | Check | Remove; covered by `06-pages.css` |
| Admin | 8 | Check | Remove; covered by `06-pages.css` |
| Login | 101 | Check | Remove; covered by `06-pages.css` |
| Bulk Refresh | 22 | Check | Remove; covered by `04-forms.css` |
