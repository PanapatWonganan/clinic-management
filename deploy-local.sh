#!/bin/bash
# Deploy session changes to production:
#  1. Stage + commit session changes (5 files), push to main
#  2. GitHub Actions auto-deploys backend (composer install + migrate --force)
#  3. flutter clean + pub get + build web --release --dart-define=PRODUCTION=true
#  4. Pack frontend-build.tar.gz
#  5. Invoke deploy-frontend-to-production.sh (scp + extract + chown + nginx)
#  6. Print reminder to run server post-check (deploy-server-postcheck.sh)
#
# This script is for PRODUCTION ONLY. It pushes to origin/main which triggers
# the live deploy workflow at .github/workflows/deploy.yml.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[deploy]${NC} $*"; }
warn() { echo -e "${YELLOW}[deploy]${NC} $*"; }
fail() { echo -e "${RED}[deploy]${NC} $*"; exit 1; }

# ---------- 1. Pre-flight ----------
log "Pre-flight checks..."

[ -f "pubspec.yaml" ]   || fail "Not at project root (pubspec.yaml missing)"
[ -d "clinic-backend" ] || fail "Not at project root (clinic-backend missing)"
command -v flutter >/dev/null || fail "flutter not in PATH"
command -v git >/dev/null     || fail "git not in PATH"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  fail "Must be on 'main' branch (currently on '$CURRENT_BRANCH'). Switch first."
fi

# Confirm production deploy
if [ "${SKIP_CONFIRM:-0}" != "1" ]; then
  echo ""
  warn "This will deploy to PRODUCTION:"
  warn "  Frontend → https://exquillermember.com"
  warn "  Backend  → https://api.exquillermember.com (via GitHub Actions on push)"
  echo ""
  read -r -p "Type 'deploy' to continue: " ans
  [ "$ans" = "deploy" ] || fail "Aborted."
fi

# ---------- 2. Stage + commit session changes ----------
log "Staging session changes..."

SESSION_FILES=(
  "lib/screens/home_screen.dart"
  "lib/screens/checkout_screen.dart"
  "lib/screens/my_free_items_screen.dart"
  "clinic-backend/app/Http/Controllers/FreeItemRedemptionController.php"
  "clinic-backend/database/migrations/2026_05_07_000001_add_promptpay_to_orders_payment_method_enum.php"
)

for f in "${SESSION_FILES[@]}"; do
  [ -e "$f" ] || fail "Missing expected file: $f"
done

git add "${SESSION_FILES[@]}"

if git diff --cached --quiet; then
  warn "No staged changes — skipping commit (assuming already pushed)."
  SKIP_COMMIT=1
else
  SKIP_COMMIT=0
fi

if [ "$SKIP_COMMIT" = "0" ]; then
  COMMIT_MSG="Fix reward checkout flow, add promptpay enum, merge MyFreeItems screen

- Frontend: home_screen sends earned_free_items in _pendingReward so checkout
  shows the correct number of free items instead of 0
- Frontend: home_screen gates appliedReward on _pendingFreeItems.isNotEmpty
  in both bottom-nav and inline checkout buttons (don't preselect a reward
  when the user didn't tick redeem)
- Frontend: checkout_screen sends payment_method=promptpay (was qr_code)
  to match backend validation
- Frontend: my_free_items_screen merges approved + pending + available
  rewards into one screen with per-level claim button
- Backend: FreeItemRedemptionController::myRewards accepts ?include_pending=1
  to surface pending claims for the merged UI
- Backend: migration adds 'promptpay' to orders.payment_method enum"

  log "Committing..."
  git commit -m "$COMMIT_MSG"
fi

# ---------- 3. Push to main (triggers backend deploy via GitHub Actions) ----------
log "Pushing to origin/main..."
git push origin main
log "Backend deploy triggered (GitHub Actions: .github/workflows/deploy.yml)"

# ---------- 4. Build Flutter web for production ----------
log "Cleaning Flutter build cache..."
flutter clean

log "Fetching pub dependencies..."
flutter pub get

log "Building Flutter web (release, PRODUCTION=true)..."
flutter build web \
  --release \
  --base-href="/" \
  --dart-define=PRODUCTION=true

[ -f "build/web/index.html" ] || fail "Build failed — build/web/index.html not found"
[ -d "build/web/assets" ]    || fail "Build failed — build/web/assets not found"
log "Build OK."

# ---------- 5. Pack tarball ----------
log "Packing frontend-build.tar.gz..."
rm -f frontend-build.tar.gz
( cd build/web && tar czf "../../frontend-build.tar.gz" . )

SIZE=$(du -h frontend-build.tar.gz | cut -f1)
log "Tarball ready: $SIZE"

# ---------- 6. Run existing deploy script (scp + extract + chown + nginx) ----------
log "Invoking deploy-frontend-to-production.sh..."
[ -x "deploy-frontend-to-production.sh" ] || chmod +x deploy-frontend-to-production.sh
./deploy-frontend-to-production.sh

# ---------- 7. Done ----------
echo ""
log "Deploy completed."
echo ""
warn "Recommended post-deploy verification (run on server):"
warn "  scp deploy-server-postcheck.sh root@45.32.102.242:/tmp/"
warn "  ssh root@45.32.102.242 'bash /tmp/deploy-server-postcheck.sh'"
echo ""
warn "Or manually browser-test:"
warn "  https://exquillermember.com   (hard reload: Cmd+Shift+R / Ctrl+Shift+R)"
warn "  https://api.exquillermember.com/api/products  (smoke test)"
