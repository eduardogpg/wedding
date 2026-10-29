# Boda: first local version

Boda is a Rails application for one wedding planner managing multiple weddings.
Couples and guests use public wedding subdomains and do not have accounts.

## Local addresses

- Planner dashboard: `http://app.localhost:3001`
- Sample wedding: `http://eduardo-and-raquel.localhost:3001`
- `http://localhost:3001` also opens the planner application.

## Included

- Planner sign-in and sign-out.
- Wedding dashboard with search, upcoming dates, and publication filters.
- Wedding creation and editing, unique subdomains, invitation text, colors,
  dress code, and an RSVP deadline.
- Ceremony, reception, and other schedule events, each with venue details,
  optional embedded Google Maps, and an external map link.
- Cover and gallery photo uploads, with removal controls and a carousel/grid
  display option. Carousels support arrows, dots, keyboard navigation, and swipe.
- Private preview, draft/published states, and public wedding pages.
- Guest RSVP collection and a planner response list with CSV export.
- Phone layouts with quick navigation, larger form fields, and safe-area spacing.
- Docker Compose with PostgreSQL and persistent database and upload volumes.

## Boundaries

- Only the configured root domain and `app` subdomain expose planner routes.
- A wedding subdomain only exposes a published wedding and its RSVP form.
- Draft previews require a planner session on the planner host.
- Session cookies belong to the host that issued them; they are not shared with
  wedding subdomains.
- Subdomain lookup uses an exact normalized match. Reserved names cannot be used.

## Later

Custom domains, multiple planner accounts, guest lists and invitation codes,
additional page templates, vendors, budgets, reminders, and production hosting.
Further concepts, including optional guest notifications, are recorded in
[`IDEAS.md`](../IDEAS.md).
