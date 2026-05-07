#!/bin/bash
# Run on the production server (root@45.32.102.242) after deploy-local.sh:
#   - Snapshot prod DB to /root/db-backups/ (auto-prune > 7 days)
#   - Verify GitHub Actions auto-deploy completed (HEAD == origin/main)
#   - Confirm new migration ran (promptpay enum)
#   - Smoke-test backend + frontend HTTP
#
# Post-flight verification only. Deploy itself is already done by:
#   - GitHub Actions workflow (backend: composer install + migrate --force)
#   - deploy-frontend-to-production.sh (frontend tarball + nginx restart)

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAILED=1; }

FAILED=0
DEPLOY_DIR="$HOME/deployment"
BACKEND_DIR="$DEPLOY_DIR/clinic-backend"

echo "=== Production post-deploy check ==="
date
echo ""

# ---------- 1. Backup DB ----------
echo "[1/5] Backing up clinic_db..."
mkdir -p /root/db-backups
TS=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="/root/db-backups/clinic_db_${TS}.sql.gz"

if mysqldump --single-transaction --quick --no-tablespaces clinic_db 2>/dev/null | gzip > "$BACKUP_FILE"; then
  if [ -s "$BACKUP_FILE" ]; then
    ok "DB backup: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
  else
    fail "DB backup file is empty: $BACKUP_FILE"
  fi
else
  fail "mysqldump failed (check ~/.my.cnf or run manually)"
fi

# Prune backups older than 7 days
find /root/db-backups -name "clinic_db_*.sql.gz" -mtime +7 -delete 2>/dev/null || true

# ---------- 2. Verify GitHub Actions deploy completed ----------
echo ""
echo "[2/5] Verifying ~/deployment is up-to-date with origin/main..."

if [ ! -d "$DEPLOY_DIR/.git" ]; then
  fail "$DEPLOY_DIR is not a git repo"
else
  cd "$DEPLOY_DIR"
  git fetch origin main --quiet 2>/dev/null || warn "git fetch failed (network?)"

  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse origin/main 2>/dev/null || echo "unknown")

  if [ "$LOCAL" = "$REMOTE" ]; then
    ok "HEAD matches origin/main: ${LOCAL:0:8}"
  else
    fail "HEAD ($LOCAL) != origin/main ($REMOTE) — GitHub Actions may still be running"
    warn "  Wait for the action to finish, or run manually:"
    warn "    cd ~/deployment && git fetch origin main && git reset --hard origin/main"
    warn "    cd clinic-backend && composer install --no-dev --optimize-autoloader && php artisan migrate --force"
  fi
fi

# ---------- 3. Verify new migration applied ----------
echo ""
echo "[3/5] Verifying promptpay migration applied..."

if [ -d "$BACKEND_DIR" ]; then
  cd "$BACKEND_DIR"
  STATUS=$(php artisan migrate:status 2>/dev/null | grep -i promptpay || true)
  if echo "$STATUS" | grep -qiE "ran|\[1\]|y "; then
    ok "Migration applied: $(echo "$STATUS" | head -1 | tr -s ' ')"
  elif [ -n "$STATUS" ]; then
    fail "Migration found but not ran: $STATUS"
    warn "  Run: cd $BACKEND_DIR && php artisan migrate --force"
  else
    fail "promptpay migration not found in migrate:status output"
  fi

  # Verify enum actually contains promptpay
  ENUM_CHECK=$(php artisan tinker --execute="echo \DB::selectOne(\"SHOW COLUMNS FROM orders LIKE 'payment_method'\")->Type;" 2>/dev/null | tail -1 || true)
  if echo "$ENUM_CHECK" | grep -q "promptpay"; then
    ok "orders.payment_method enum includes 'promptpay'"
  else
    fail "orders.payment_method enum does NOT include 'promptpay': $ENUM_CHECK"
  fi
else
  fail "$BACKEND_DIR not found"
fi

# ---------- 4. Smoke test backend ----------
echo ""
echo "[4/5] Smoke testing backend..."

API_BASE="https://api.exquillermember.com/api"

HTTP_PRODUCTS=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/products" || echo "000")
if [ "$HTTP_PRODUCTS" = "200" ]; then
  ok "GET $API_BASE/products → 200"
else
  fail "GET $API_BASE/products → $HTTP_PRODUCTS (expected 200)"
fi

HTTP_LOGIN=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"smoke-test-nonexistent@example.invalid","password":"wrong"}' || echo "000")
if [ "$HTTP_LOGIN" = "401" ]; then
  ok "POST $API_BASE/auth/login (bad creds) → 401"
elif [ "$HTTP_LOGIN" = "422" ]; then
  ok "POST $API_BASE/auth/login (bad creds) → 422 (validation)"
else
  fail "POST $API_BASE/auth/login → $HTTP_LOGIN (expected 401 or 422)"
fi

# ---------- 5. Smoke test frontend ----------
echo ""
echo "[5/5] Smoke testing frontend..."

FE_BASE="https://exquillermember.com"
HTTP_FE=$(curl -s -o /dev/null -w "%{http_code}" "$FE_BASE/" || echo "000")
if [ "$HTTP_FE" = "200" ]; then
  ok "GET $FE_BASE/ → 200"
else
  fail "GET $FE_BASE/ → $HTTP_FE (expected 200)"
fi

INDEX_HEAD=$(curl -s "$FE_BASE/" | head -c 4096)
if echo "$INDEX_HEAD" | grep -qi "exquiller"; then
  ok "Frontend HTML contains expected app marker"
else
  warn "Frontend HTML did not contain 'exquiller' in first 4KB — may still be valid"
fi

# ---------- Summary ----------
echo ""
if [ "$FAILED" = "0" ]; then
  echo -e "${GREEN}=== ALL CHECKS PASSED ===${NC}"
  exit 0
else
  echo -e "${RED}=== ONE OR MORE CHECKS FAILED — investigate above ===${NC}"
  exit 1
fi
