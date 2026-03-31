# Gastitos

A family expense tracker built with Rails 8.1. All UI is in Spanish.

## Quick Start

```
bin/rails test          # Run full test suite (minitest)
bin/rails db:migrate    # Run pending migrations
bin/rails server        # Start dev server
```

## Architecture

### Stack

- Rails 8.1 with SQLite, Propshaft, Importmap, Hotwire (Turbo + Stimulus)
- Authentication: `has_secure_password` (bcrypt), session-based
- No CSS framework — empty `application.css`, semantic HTML only
- I18n: default locale is `:es`, all strings in `config/locales/es.yml`
- Timezone: `America/Mexico_City`

### Models

- **User** — name, email, password_digest, admin, approved. First user is auto-admin + auto-approved. Subsequent users need admin approval.
- **Category** — name (unique), category_type ("expense" or "income"). Shared across all users.
- **Transaction** — amount (signed decimal: negative=expense, positive=income), date, description (optional, max 140 chars), belongs_to category + created_by (User). Amount sign is auto-applied from category type via `before_validation`. Callbacks manage MonthlyPeriod lifecycle.
- **MonthlyPeriod** — month, year, starting_balance. Auto-created on first transaction for a month, auto-deleted when last transaction is removed. No FK from transactions — relationship is derived from date range. Starting balance defaults to previous period's ending balance.

### Controllers & Routes

- `root` → `transactions#index` (create form + last 10 transactions)
- `resource :session` — login/logout
- `resources :users` — signup (new, create only)
- `resources :transactions` — create, edit, update, destroy
- `resources :categories` — create only (JSON endpoint for Stimulus inline creation)
- `resources :monthly_periods, path: "meses"` — index, show (P&L), edit/update (starting balance)

### Key Patterns

- **Transaction form** (`_form.html.erb`) is shared between create (index) and edit views
- **return_to parameter** on transaction edit/update — validated against `/meses/\d+` to prevent open redirects. Passed as hidden field to survive validation re-renders.
- **Category inline creation** — Stimulus `category-select` controller POSTs JSON to `/categories`, adds option to select dynamically
- **Last date button** — Stimulus `last-date` controller fills date selects from the most recent transaction's date

## Testing

- Framework: Minitest with fixtures
- Test dirs: `test/models/` (unit), `test/integration/` (controller+view)
- Run: `bin/rails test` or `script/test`
- Fixtures in `test/fixtures/` — users (jaime/admin, sofia/approved, unapproved), categories (food, rideshare, salary), transactions (lunch, uber, paycheck), monthly_periods (march_2026)
- Model tests check validations, callbacks, scopes
- Integration tests check full request/response cycles including redirects, flash messages, and HTML assertions
- Error messages are in Spanish — model tests assert `errors[:field].any?` rather than matching specific message strings

## Conventions

- All user-facing text uses `t()` helper with keys in `config/locales/es.yml`
- Views are semantic HTML with no styling — no classes, no CSS framework
- Forms use Rails helpers (`form_with`, `date_select`, etc.)
- Delete actions use `button_to` with `data-turbo-confirm` for browser confirmation
- Amounts are always entered as positive by users; sign is inferred from category type
