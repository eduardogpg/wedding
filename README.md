# Boda — wedding planner studio

A local Rails application for one planner managing multiple weddings. You manage
weddings in a private dashboard; couples and guests visit a public subdomain.

## Start with Docker

You only need Docker Desktop with Docker Compose. Ruby, Rails, PostgreSQL, and
image processing run inside containers.

```sh
docker compose up --build -d
```

Startup creates the database, runs migrations, creates a planner account, and
adds three sample weddings on an empty development database. The first build
can take a few minutes.

- **Planner:** <http://app.localhost:3001>
- **Sample wedding:** <http://eduardo-and-raquel.localhost:3001>
- **Email:** `planner@example.com`
- **Password:** `wedding-planner-2026`

`http://localhost:3001` also opens the planner application. Sign in on the same
host each time: cookies are deliberately not shared across subdomains.

The application binds to `127.0.0.1`, so it is available on this computer only.
The database has no host port. Nothing is published online.

## First things to try

1. Sign in and open Eduardo & Raquel.
2. Choose **Edit wedding** to change names, dates, invitation text, and their story.
3. Add ceremony and reception events, including local times, venues, and maps.
4. Upload a cover and multiple gallery photos, choose carousel or grid display,
   and select one of three palettes.
5. Preview the page, then publish and share its local subdomain.
6. Open the public page and submit an RSVP. View responses and export CSV in the dashboard.

Sofía & Daniel and Valentina & Andrés start as drafts. Draft subdomains return
404; their previews require a signed-in planner. Guests never need accounts.

RSVPs accept a maximum party of 10, one response per email per wedding. The
optional deadline closes responses after that date. All responses close after
the wedding date. Responses are stored locally; no emails are sent.

## Photo carousel and venue maps

In **Edit wedding → Photos & style**, choose **Photo carousel** under **Gallery
display** and select multiple images in **Gallery / carousel photos**. Guests
can use previous/next arrows, photo dots, keyboard arrows, or swipe. There is no
automatic rotation. A single photo displays without navigation; the **Photo
grid** option retains the original gallery layout.

Each schedule event has a **Show Google Maps on the wedding page** checkbox.
The default map searches using its venue name and address. To select an exact
pin, open the venue in Google Maps, choose **Share → Embed a map → Copy HTML**,
and paste it into **Google Maps embed code or URL**. This follows [Google’s map
sharing instructions](https://support.google.com/maps/answer/7101463?hl=en).
Only a Google Maps embed source URL is retained from pasted HTML. Maps load
when guests scroll to them, and the external **Open in Google Maps** link remains
available when an embedded map is hidden. Map display requires internet access.

## Phone layout and reminder ideas

The guest page has a phone navigation bar with shortcuts to the invitation,
schedule/maps, photos (when available), and RSVP. Form inputs use 16 px text,
and the navigation bar hides while a guest is editing their RSVP. Safe-area
spacing keeps the navigation clear of the phone’s home indicator.

Responsive browser checks on October 27, 2026 covered widths of 320, 375, 390,
and 430 px, with long partner names and 20 carousel photos. Each page stayed
within its viewport width. RSVP navigation and form focus were also checked.
These are browser viewport checks, rather than tests on physical phones.

Guest reminders are planned in [IDEAS.md](IDEAS.md), including RSVP reminders,
wedding-day directions, and photo upload prompts. That backlog records push
permission, iPhone Home Screen setup, email alternatives, and server scheduling.

## Configuration

Copy `.env.example` to `.env` if you want to customize the defaults. The current
checkout already has a local `.env`, using port 3001 because port 3000 is occupied.

| Variable | Default | Purpose |
| --- | --- | --- |
| `APP_PORT` | `3001` | Browser port; change it if another app uses this port. |
| `APP_DOMAIN` | `localhost` | Root domain for the planner and wedding subdomains. |
| `PLANNER_EMAIL` | `planner@example.com` | Email used when creating the initial planner. |
| `PLANNER_PASSWORD` | `wedding-planner-2026` | Initial password, at least 12 characters. |
| `POSTGRES_PASSWORD` | `boda_local_password` | Local database password; set before initial startup. |
| `SEED_DEMO` | `true` | Create demo weddings when the development wedding table is empty. |

After changing configuration, run `docker compose up -d` to recreate the web
container. Existing planner passwords and edited weddings are preserved by
seeding. Changing `PLANNER_PASSWORD` does not reset an existing account. Set
`SEED_DEMO=false` if you want an empty planner workspace.

Modern Chromium browsers resolve `*.localhost` to the local computer. If your
browser or resolver does not, add the exact local names you need to your hosts
file, for example `127.0.0.1 app.localhost eduardo-and-raquel.localhost`.
Wildcard subdomains are handled by the application, and require no production
DNS setup for this local version.

## Useful commands

```sh
# See service health
docker compose ps

# Follow Rails logs
docker compose logs -f web

# Stop the app; database and uploads remain in Docker volumes
docker compose down

# Start again
docker compose up -d

# Run tests (uses the separate boda_test database)
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec web bin/rails test

# Check Rails autoloading
docker compose exec web bin/rails zeitwerk:check

# Open the Rails console
docker compose exec web bin/rails console
```

Source files are mounted into the web container, so ordinary application edits
reload automatically. Rebuild with `docker compose up --build -d` after changing
gems or the Dockerfile.

## Stack and structure

- Ruby 3.4, Rails 8.1, PostgreSQL 17, Puma, Hotwire, and Propshaft.
- `User`: planner sign-in, bcrypt password hashing, host-specific sessions.
- `Wedding`: unique subdomain, date, text, palette, and publication state.
- `Event`: a wedding's schedule, venues, and safe HTTPS map links.
- `Rsvp`: guest responses scoped to the wedding's subdomain.
- Active Storage: persistent local uploads, with libvips-generated image sizes.
- `postgres_data`: persistent database volume.
- `uploads`: persistent original photos and image variants.

JPEG, PNG, and WebP uploads are accepted up to 10 MB each, with a maximum of
20 gallery photos per wedding. The built-in botanical illustrations work without
network access or stock photo services.

The tests cover host isolation, draft privacy, sign-in, wedding editing and
publishing, event time zones, photo uploads and removal, RSVP deadlines and
duplicates, and CSV formula escaping.

This Docker setup is for local development. A later production deployment will
need a real domain, wildcard DNS and HTTPS, private credentials, storage backups,
and production web/worker configuration.

See [first-version scope](docs/first-version.md) for the initial product boundaries.
