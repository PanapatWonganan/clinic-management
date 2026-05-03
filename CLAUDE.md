# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

Two-part monorepo for the "Exquiller Member" clinic membership system:

- **`lib/`** — Flutter client (mobile + web). Entry point `lib/main.dart`, boots to `LoginScreen` or `HomeScreen` based on stored token. Target SDK `>=3.0.0`. Thai locale (`th_TH`) is initialized at startup.
- **`clinic-backend/`** — Laravel 12 / PHP 8.2+ API at `api.exquillermember.com`. Sanctum bearer tokens for the Flutter app, web session + `IsAdmin` middleware for the Blade admin dashboard, MySQL (`clinic_db`), Telegram bot for notifications, PaySolutions for payments.

Frontend build artifacts (`frontend-build.tar.gz`, `product-images.tar.gz`, `build/`, `.dart_tool/`) are `.gitignore`'d. Build locally before deploying the frontend — they are never committed.

## Common Commands

### Flutter frontend
```bash
flutter pub get
flutter run                                                     # connected device / emulator
flutter run -d chrome --web-port=3000                           # web — hits local API at 127.0.0.1:8000
flutter build web --release --base-href="/" --dart-define=PRODUCTION=true   # production build → build/web/
flutter test test/path/to/file_test.dart                        # single test
flutter analyze                                                 # lint (flutter_lints)
```

For production, repackage `build/web/` as `frontend-build.tar.gz` at the repo root before running `./deploy-frontend-to-production.sh`.

### Laravel backend (run from `clinic-backend/`)
```bash
composer install
php artisan serve                     # :8000 — Flutter dev config points here
php artisan migrate                   # migrate locally; use --force on prod
php artisan db:seed
php artisan storage:link              # required so /storage/products/* resolves
php artisan queue:work                # Telegram + stock-alert jobs
php artisan test                      # PHPUnit (also: composer test)
php artisan test --filter=SomeTest    # single test
./vendor/bin/pint                     # formatter
composer dev                          # concurrent: serve + queue + pail + vite
```

### Deployment
```bash
./deploy-frontend-to-production.sh    # scp tarball → extract on server → restart nginx
./deploy-backend.sh                   # placeholder — real flow is .github/workflows/deploy.yml
```

GitHub Actions deploys the backend on every push to `main` by SSHing into the server and running `git fetch origin main && git reset --hard origin/main && composer install && php artisan migrate --force`. The frontend is NOT auto-deployed — always build locally and ship the tarball.

Note: the workflow uses `git reset --hard` (not `git pull`) because the history was rewritten in April 2026 to purge previously-committed secrets; `git pull` would have diverged.

## Environment / API URLs

`lib/constants/app_config.dart` centralizes URLs and switches by build flag and platform:

- **Production** (build with `--dart-define=PRODUCTION=true`): `https://api.exquillermember.com/api`
- **Dev on web / iOS / desktop**: `http://127.0.0.1:8000/api`
- **Dev on Android emulator**: `http://10.0.2.2:8000/api` (special host mapping to the host machine's localhost)

Three getters — `apiBaseUrl`, `thaiAddressApiUrl`, `storageBaseUrl` — are all platform-switched the same way. Mirror the pattern when adding a new backend host.

## Architecture Notes

### Frontend (Flutter)

- **`lib/services/`** — thin HTTP wrappers around the Laravel API. `ApiService` (`api_service.dart`) handles bearer-token injection from `AuthService`, 20s request timeout, and auto-logout on 401 via `AuthService.clearSessionDueToUnauthorized()` — every other service (auth, product, profile, address, delivery, thai_address) goes through it.
- **`AuthService`** is a singleton that persists the token in `SharedPreferences` under key `auth_token`.
- **`lib/screens/`** — each user-facing page. Navigation is stack-based (no router package); screens `Navigator.push` each other directly.
- **`lib/models/`** — plain Dart data classes, manually serialized from JSON in service methods.
- **`lib/constants/`** — colors, text styles (Prompt font, weights 400/500/600), and the `AppConfig` env switcher.

Startup flow (`main.dart`): bind Flutter → init Thai date formatting → load token from `SharedPreferences` → dev-only delivery API probe (fire-and-forget; skipped on production) → show `HomeScreen` vs `LoginScreen` based on `AuthService.instance.isLoggedIn`.

Bottom nav has 5 tabs: home, "ของแถมของฉัน" (`MyFreeItemsScreen`), ชำระเงิน (checkout), ประวัติการซื้อ (order history), รีวอร์ด. Indices are shifted from the original 4-tab layout — update `home_screen.dart:_onBottomNavTap` when adding new tabs.

### Backend (Laravel)

- **`app/Http/Controllers/`** — public/customer API (`routes/api.php`). Everything non-trivial is behind `auth:sanctum`; admin-only endpoints (products CRUD, customers CRUD, patients, appointments, admin customer addresses) are behind `auth:sanctum + admin` — both are required and `admin` is an alias for `IsAdmin` middleware.
- **`app/Http/Controllers/Admin/`** — admin web UI controllers rendering Blade views in `resources/views/admin/`. Admin is a server-rendered dashboard, not part of the Flutter app.
- **`app/Http/Middleware/IsAdmin`** — resolves the user via `$request->user()` so it works under both the web session guard (admin pages) and the `sanctum` guard (API). It returns JSON 401/403 for `api/*` paths and redirects to `admin.login` for web paths.
- **`bootstrap/app.php`** — sets `redirectGuestsTo(null)` for `api/*` paths so the default `Authenticate` middleware emits a JSON 401 instead of trying to redirect to a non-existent `login` route (the project only defines `admin.login`).
- **`app/Services/`** — `MembershipProgressService` (level/bundle-deal math), `PaySolutionsService` (gateway wrapper), `TelegramService` (bot messages).
- **`app/Jobs/`** — `SendTelegramNotification`, `SendLowStockNotification`, `SendDailySalesReport`. Requires a running `queue:work` (supervisor in production).
- **Routes**: `routes/api.php` (Flutter-facing JSON), `routes/web.php` (admin Blade UI).
- Rate limits: `/auth/login` and `/auth/register` at `throttle:10,1`; `/payment/create|status|verify` at `throttle:20,1`; public Thai-address lookup at `throttle:60,1`.
- `/api/payment/simulate` is only registered outside production (`!app()->environment('production')`) and `PaymentController::simulatePayment()` hard-aborts 404 on production as a defense-in-depth.
- `PAYSOLUTIONS_TEST_MODE` defaults to `APP_ENV !== 'production'` — omitting it on prod does NOT silently route real transactions through the sandbox.

### Payments

PaySolutions is the gateway. The backend creates a payment via `PaymentController::createPayment` (returns `payment_url`), the Flutter app opens it in `PaymentWebviewScreen`, and the gateway `POST`s to `/api/payment/callback`. `handleCallback` verifies the callback amount matches the recorded order (within 1 THB rounding), looks up the payment by `transaction_id` first and falls back to the most-recent pending payment for that `order_number` — never a blind `orWhere` that could hit a stale row. Frontend also polls `/api/payment/status/{id}` via `Timer.periodic` (cancelled on dispose). Result URLs are matched by path segment (`/payment/success`, `/payment/cancel`, etc.), not by `contains('success')`, to avoid false-matching unrelated pages. Config lives in `.env` (`PAYSOLUTIONS_*`).

### Free-item redemption flow (cart-side)

When a user's cart quantity crosses a bundle-deal threshold, `home_screen.dart:_recomputePendingReward()` snapshots the best available level into `_pendingReward`. Ticking the "แลกของแถม" checkbox on `RewardCard` invokes `onRedeemCheckboxChanged`, which opens a bottom sheet where the user picks free items against that reward's `free_quantity`. Selections live entirely in the `HomeScreen` state (`_pendingFreeItems`) — nothing is persisted until `CheckoutScreen` POSTs the order with payload field `new_order_free_items`. Backend `OrderController::store` then creates the `UserClaimedReward` and `FreeItemRedemption` rows inside the same transaction. If the user reduces the cart below the level again, selections are cleared; if they cross to a higher level, selections are kept but truncated to the new quota.

`selected_free_items` (existing saved rewards from `user_claimed_rewards`) is a separate payload field with its own validation path — do not merge the two.

## Production Environment

Do NOT hardcode or guess production hostnames — the correct ones are:

- Frontend: `https://exquillermember.com` → `/var/www/exquillermember.com`
- Backend: `https://api.exquillermember.com` → `/var/www/api.exquillermember.com`
- Server: `root@45.32.102.242` (SSH key `~/.ssh/github_actions_deploy`)
- PHP-FPM socket: `/var/run/php/php8.3-fpm.sock` (PHP 8.3)
- Repo clone on server: `~/deployment` (GitHub Action resets into this)

Older docs reference `exquiller.com` / `api.exquiller.com` — those domains are **not** used. `PROJECT_CONFIG.md` is authoritative; `DEPLOYMENT_GUIDE.md` has stale domain names. `DEPLOY_SECURITY_CHECKLIST.md` has the current secret-rotation runbook; `clinic-backend/.env.production.example` is the starting template for the prod `.env`.

### Post-deploy permission fix (frequently needed)

Files uploaded from macOS land with owner `501:staff`, which Nginx (running as `www-data`) cannot read. After extracting any tar on the server (images or frontend), run:

```bash
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/storage/
sudo chmod -R 775 /var/www/api.exquillermember.com/storage/
sudo chown -R www-data:www-data /var/www/exquillermember.com
sudo chmod -R 755 /var/www/exquillermember.com
```

If product images 404 on production, that permission mismatch is the usual cause — see `DEPLOYMENT_NOTES.md` for the full checklist.
