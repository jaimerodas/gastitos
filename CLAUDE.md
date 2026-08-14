# Gastitos

A family expense tracker built with Rails 8.1. All UI and routes are in Spanish.

## Quick Start

```
bin/rails test          # Full test suite (minitest)
script/test_fast        # RuboCop + tests
script/test             # RuboCop + Brakeman + tests
bin/rails db:migrate    # Run pending migrations
bin/rails server        # Start dev server
```

## Architecture

### Stack

- Rails 8.1 with SQLite, Propshaft, Importmap, Hotwire (Turbo + Stimulus)
- Authentication: `has_secure_password` (bcrypt), session-based. Password resets email via Resend (`RESEND_API_KEY`).
- No background jobs. There is no queue backend — the reset email is the app's only outbound mail and is sent inline with `deliver_now`, wrapped in a rescue so a Resend outage can't turn the response into an account-enumeration oracle. Anything added later that needs `deliver_later`/`perform_later` needs a queue backend first; the default `:async` adapter loses jobs on restart.
- CSS: per-component stylesheets in `app/assets/stylesheets/`, no framework. `application.css` is empty because `stylesheet_link_tag :app` bundles every file in that directory — new files load automatically. Light/dark mode via oklch in `colors.css`.
- I18n: default locale is `:es`, all strings in `config/locales/es.yml`
- Timezone: `America/Mexico_City`
- Deployed as a Docker container with Kamal (`config/deploy.yml`)

### Models

- **User** — name, email, password_digest, role (enum: viewer/editor/admin), approved. First user is auto-admin + auto-approved. Subsequent users need admin approval and default to viewer. `can_edit?` gates writes. Reset tokens via `generates_token_for :password_reset, expires_in: 2.hours`.
- **Category** — name (unique), category_type ("expense" or "income"). Shared across all users.
- **Transaction** — amount (signed decimal: negative=expense, positive=income), date, description (optional, max 140 chars), belongs_to category + created_by (User). Amount sign is auto-applied from category type via `before_validation`. Callbacks manage MonthlyPeriod lifecycle.
- **MonthlyPeriod** — month, year, starting_balance. Auto-created on first transaction for a month, auto-deleted when the last one is removed. No FK from transactions — the relationship is derived from date range. Starting balance defaults to the previous period's ending balance. `to_param` is a `YYYY-MM` slug.

Plain objects keep controllers thin — query and presentation logic belongs here:

- **TransactionsDashboard** — home page: recent transactions + stats
- **TransactionStats** — spending aggregates
- **MonthlyPeriodReport** — P&L for a single period

### Activity log

`ActivityLogger.log(user, :event, *args)` appends a line to `storage/activity_logs/user_<id>.log`. One class per event in `app/models/activity_events/`, registered in `ActivityLogger::EVENTS`; each owns its own message via I18n (`activity.*`). `ActivityLogger::FileStore` handles I/O and rotation (1MB × 5 files). Admins view with `recent(user)` and download with `download_for(user)`.

### Controllers & Routes

All paths are Spanish — `config/routes.rb` wraps everything in a `scope path_names:` block.

- `root` → `transactions#index` (create form, stats, last 10 transactions)
- `resource :session`, path `sesion` — login/logout
- `resources :password_resets`, path `restablecer` — token-based, `param: :token`
- `resources :users`, path `usuarios` — new/create (signup), plus admin-only index/show/destroy and `activity_log` (`/usuarios/:id/actividad`)
  - `resource :approval`, path `aprobacion` — admin approve/revoke
  - `resource :role`, path `rol` — admin role changes
- `resources :transactions`, path `transacciones` — create, edit, update, destroy
- `resources :categories`, path `categorias` — create only (JSON endpoint for Stimulus inline creation)
- `resources :monthly_periods`, path `meses` — index, show (P&L), edit/update (starting balance)

`ApplicationController` provides `require_login`, `require_admin`, and `require_editor`.

## Key Patterns

- **Transaction form** (`_form.html.erb`) is shared between create (index) and edit views
- **return_to parameter** on transaction create/edit/update — validated against `/meses/YYYY-MM` to prevent open redirects. Passed as a hidden field to survive validation re-renders.
- **Category inline creation** — the `category-select` Stimulus controller POSTs JSON to `/categorias` and adds the option to the select dynamically
- All user-facing text uses `t()`; amounts are always entered positive, with the sign inferred from the category

## Testing

- Minitest with fixtures. `test/models/` (unit), `test/integration/` (full request/response cycles including redirects, flash messages, and HTML assertions), `test/mailers/`.
- Fixtures in `test/fixtures/` — users (jaime/admin, sofia/editor, viewer, unapproved), categories (food, rideshare, salary), transactions (lunch, uber, paycheck), monthly_periods (march_2026)
- Error messages are in Spanish — model tests assert `errors[:field].any?` rather than matching specific message strings
