# Boda — wedding planner studio

A local Rails application for one planner managing multiple weddings. You manage
weddings in a private dashboard; couples and guests visit a public subdomain.

## Start with Docker

You need Docker Desktop with Docker Compose v2 and `make`. Start Docker Desktop,
then run the following command from the project directory. Ruby, Rails,
PostgreSQL, and image processing run inside containers.

```sh
make setup
```

This creates `.env` from `.env.example` if needed, builds the Rails image, and
starts both services. Startup creates the database, runs migrations, creates a
planner account, and adds three sample weddings on an empty development
database. The command waits for the services to be healthy. The first build can
take a few minutes. Existing `.env` settings, database records, and uploaded
photos are preserved.

For later starts, use `make run` (or `make up`). Run `make help` (or just `make`)
for all commands.

`make run` starts Docker services in the background, waits for them to be
healthy, and prints the browser URLs. Returning to your terminal prompt is
expected; the app continues running. Open the printed planner URL to sign in.
Use `make logs` if you want to follow server output in your terminal.

The default browser address uses **port 3001**, including
<http://localhost:3001>. Port 3000 is Rails' internal container port; Docker maps
it to the `APP_PORT` setting on your computer. The printed URLs use your current
configuration.

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
3. Add a ceremony, a reception, or both, including local times, venues, and maps.
   One complete event is enough; unused schedule rows are ignored.
4. Upload a cover and multiple gallery photos, choose carousel or grid display,
   select a page template (Botanical, Editorial, or Classic), and choose a palette.
5. Choose **Save and preview**, then publish and share its local subdomain.
6. Open the public page and submit an RSVP. View responses and export CSV in the dashboard.

Sofía & Daniel and Valentina & Andrés start as drafts. Draft subdomains return
404; their previews require a signed-in planner. Guests never need accounts.

RSVPs accept a maximum party of 10, one response per email per wedding. The
optional deadline closes responses after that date. All responses close after
the wedding date. Responses are stored locally; no emails are sent.

## Live event mock

On branch `codex/live-wedding-mock`, try the Spanish live-wedding experience at
<http://eduardo-and-raquel.localhost:3001/fiesta>. The planner also has a
**Preview live event** button; signed-in planners can preview drafts.

The mock presents two main actions: **Subir fotos** and **Dejar buenos deseos**.
You can choose photos to see local thumbnails, remove selections, write a wish,
and try the confirmation screens. All interactions use temporary browser memory.
The mock makes no uploads or submissions and stores no photos or messages.
It does not change wedding dates or automatically switch the invitation’s phase.

The normal invitation remains at `/`; `/fiesta` is an explicit mock route.

## Templates and photo uploads

In **Edit wedding → Photos & style**, choose a **Page template**:

- **Botanical**: the illustrated garden layout with an arched portrait.
- **Editorial**: a full-width photo cover and a magazine-style layout.
- **Classic**: a framed, centered invitation with a landscape portrait.

Each template works with every color palette and both gallery displays. Existing
weddings keep the Botanical template until you choose another. Use **Save and
preview** to save the selection and open the private preview.

Selected photos show thumbnails before saving. On save, signed-in planners
upload photos directly to the local Docker storage volume. If another wedding
field fails validation, the form retains those uploaded photos so you can fix
the field and save again. Without a separate cover photo, the first gallery
photo is also used as the cover. Uploads lost before this fix need to be
selected again; no original file was stored for those failed submissions.

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

On November 12, 2026, all three invitation templates were also checked at 320,
390, and 430 px. Direct upload, validation-error retention, photo rendering,
and switching templates and palettes were checked in the local browser.

Guest reminders are planned in [IDEAS.md](IDEAS.md), including RSVP reminders,
wedding-day directions, and photo upload prompts. That backlog records push
permission, iPhone Home Screen setup, email alternatives, and server scheduling.

## Configuration

Run `make env` to create `.env` before your first setup if you want to customize
the defaults. This command preserves an existing `.env`. Edit that file, then
run `make setup`. The default browser port is 3001.

| Variable | Default | Purpose |
| --- | --- | --- |
| `APP_PORT` | `3001` | Browser port; change it if another app uses this port. |
| `APP_DOMAIN` | `localhost` | Root domain for the planner and wedding subdomains. |
| `PLANNER_EMAIL` | `planner@example.com` | Email used when creating the initial planner. |
| `PLANNER_PASSWORD` | `wedding-planner-2026` | Initial password, at least 12 characters. |
| `POSTGRES_PASSWORD` | `boda_local_password` | Local database password; set before initial startup. |
| `SEED_DEMO` | `true` | Create demo weddings when the development wedding table is empty. |

After changing configuration, run `make up` to recreate the web
container. Existing planner passwords and edited weddings are preserved by
seeding. Changing `PLANNER_PASSWORD` does not reset an existing account. Set
`SEED_DEMO=false` if you want an empty planner workspace.

Modern Chromium browsers resolve `*.localhost` to the local computer. If your
browser or resolver does not, add the exact local names you need to your hosts
file, for example `127.0.0.1 app.localhost eduardo-and-raquel.localhost`.
Wildcard subdomains are handled by the application, and require no production
DNS setup for this local version.

## Useful commands

| Command | Purpose |
| --- | --- |
| `make` or `make help` | List available commands. |
| `make setup` | Create local configuration, build, prepare, and start the project. |
| `make run` | Start the project locally (alias for `make up`). |
| `make up` | Start services and wait for them to be healthy. |
| `make stop` | Stop services without removing containers. |
| `make down` | Remove containers while keeping database and photo volumes. |
| `make restart` | Restart Rails. |
| `make build` | Rebuild the Rails image. Run `make up` afterward to use it. |
| `make status` | Show service health and published ports. |
| `make logs` | Follow the Rails logs; exit with Ctrl-C. |
| `make db-prepare` | Create the development database if needed and apply migrations. |
| `make db-migrate` | Apply development migrations explicitly. |
| `make db-seed` | Rerun the safe, repeatable seeds. |
| `make test` | Prepare `boda_test` and run the Rails tests. |
| `make check` | Prepare the test database, check autoloading, and run tests. |
| `make console` | Open the interactive Rails console. |
| `make shell` | Open an interactive shell in the web container. |

Database commands, checks, the console, and the shell start PostgreSQL if
needed and use temporary Rails containers. They also work when the web server
is stopped or needs database migrations. `make test` and `make check` use the
separate test database. The regular stop/down commands keep persistent data in
Docker volumes.

Source files are mounted into the web container, so ordinary application edits
reload automatically. Run `make setup` again after changing gems or the
Dockerfile to rebuild and start the updated image.

The Makefile wraps Docker Compose, so direct `docker compose` commands still
work. If a command reports that Docker is unavailable, start Docker Desktop and
retry it.

## Stack and structure

- Ruby 3.4, Rails 8.1, PostgreSQL 17, Puma, Hotwire, and Propshaft.
- `User`: planner sign-in, bcrypt password hashing, host-specific sessions.
- `Wedding`: unique subdomain, date, text, template, palette, and publication state.
- `Event`: a wedding's schedule, venues, and safe HTTPS map links.
- `Rsvp`: guest responses scoped to the wedding's subdomain.
- Active Storage: persistent local uploads, with libvips-generated image sizes.
- `postgres_data`: persistent database volume.
- `uploads`: persistent original photos and image variants.

JPEG, PNG, and WebP uploads are accepted up to 10 MB each, with a maximum of
20 gallery photos per wedding. The built-in botanical illustrations work without
network access or stock photo services.

The tests cover host isolation, draft privacy, sign-in, wedding editing and
publishing, single-event schedules, event time zones, template selection, photo upload
retention and removal, RSVP deadlines and
duplicates, and CSV formula escaping.

This Docker setup is for local development. A later production deployment will
need a real domain, wildcard DNS and HTTPS, private credentials, storage backups,
and production web/worker configuration.

See [first-version scope](docs/first-version.md) for the initial product boundaries.

## Preguntas frecuentes opcionales

En **Editar boda → Para los invitados**, usa **Agregar pregunta** para escribir
una pregunta y su respuesta. Guarda los cambios con **Guardar boda** o
**Guardar y ver**. Puedes agregar las que necesites, editar y quitar preguntas.

La casilla **Mostrar esta pregunta en la invitación** permite ocultarla sin
borrarla. Sin preguntas visibles, no se muestra la sección ni sus enlaces. Las
filas nuevas completamente vacías se ignoran; una pregunta empezada necesita
también su respuesta. Todas las bodas existentes comienzan sin preguntas.

Las respuestas aparecen en un acordeón accesible en las tres plantillas, con
un acceso **Dudas** en teléfonos. También están disponibles en la invitación
original cuando la boda ya muestra la página de la fiesta.

## Atributos de los modelos

Usamos [AnnotateRb](https://github.com/drwl/annotaterb) solo en desarrollo para
mostrar las columnas, tipos, valores predeterminados, índices y claves foráneas
al inicio de cada modelo de Active Record. Los comentarios se actualizan
automáticamente después de las migraciones de desarrollo.

Para regenerarlos manualmente con Docker:

```sh
make annotate
```

La configuración está en `.annotaterb.yml`. Solo se anotan los modelos; las
pruebas, fixtures y rutas quedan fuera de la generación. Las anotaciones se
generan desde el esquema de la base de datos, sin modificar sus registros.

## Despliegue en DigitalOcean

Consulta la [guía en español para Ubuntu, un Droplet, PostgreSQL y Amazon S3](docs/despliegue-digitalocean.md). Incluye la preparación pendiente de producción, Docker Compose, HTTPS wildcard, respaldos y actualizaciones. Los archivos de producción se presentan como ejemplos para crear; el entorno local conserva sus comandos actuales.
