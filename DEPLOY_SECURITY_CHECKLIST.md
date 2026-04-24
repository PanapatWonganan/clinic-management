# Pre-deploy security checklist

Run these in order. Nothing here is optional — every item on this list addresses a specific hole that could leak customer data or let an attacker transact on your gateway.

---

## 1. Prepare the production `.env`

On the production server, `ssh root@45.32.102.242`, then:

```bash
cd /var/www/api.exquillermember.com
cp /root/deployment/clinic-backend/.env.production.example .env
nano .env   # fill every <FILL_ME> marker
php artisan key:generate --force   # writes a fresh APP_KEY into .env
```

Things to double-check after editing:
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://api.exquillermember.com`
- `PAYSOLUTIONS_TEST_MODE=false`
- `SESSION_SECURE_COOKIE=true`
- `DB_PASSWORD` is not the same as the old one (rotate — see step 3)

---

## 2. Invalidate every existing session and API token

All tokens that were issued while the old `APP_KEY` was leakable need to die. Run **on the production server**, inside `/var/www/api.exquillermember.com`:

```bash
# Kill every Sanctum bearer token issued by the Flutter app
php artisan tinker --execute="DB::table('personal_access_tokens')->delete();"

# Kill every admin web session
php artisan tinker --execute="DB::table('sessions')->delete();"

# Rebuild caches now that the new key is in place
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan queue:restart
```

After this, every user has to log in again. That is the point.

---

## 3. Rotate the database password

The old `DB_PASSWORD` is in `.env` files and backups, so treat it as compromised.

```bash
# On the DB host:
mysql -u root -p
> SET PASSWORD FOR 'clinic_user'@'localhost' = PASSWORD('<new_strong_password>');
> FLUSH PRIVILEGES;
```

Then update `DB_PASSWORD` in the new `.env` and re-run `php artisan config:cache`.

---

## 4. Rotate the GitHub Actions SSH key

`ssh_key_base64.txt` was committed — assume the private key in it is public. Replace it:

```bash
# On your laptop:
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_new -N ""

# On the server: authorise the new key, remove the old one
ssh root@45.32.102.242 "cat >> ~/.ssh/authorized_keys" < ~/.ssh/github_actions_new.pub
ssh root@45.32.102.242   # log in, then edit ~/.ssh/authorized_keys and DELETE the old line

# In GitHub → Settings → Secrets and variables → Actions:
#   Replace SSH_PRIVATE_KEY with:
cat ~/.ssh/github_actions_new | base64 | pbcopy
```

Confirm the next deploy works before you delete the old key from `authorized_keys`.

---

## 5. Rotate PaySolutions credentials

Log into the PaySolutions merchant portal and rotate:
- `PAYSOLUTIONS_API_KEY`
- `PAYSOLUTIONS_SECRET_KEY`

Update `.env` on the server. Sandbox and production credentials are separate — rotate both.

---

## 6. Rotate the Telegram bot token

1. Talk to `@BotFather` → `/revoke` → select the bot → receive new token.
2. Update `TELEGRAM_BOT_TOKEN` in `.env`.
3. `php artisan config:cache && php artisan queue:restart`.

---

## 7. (Optional, recommended) Purge secrets from Git history

The `.git/` folder still contains every historical version of `cookies.txt`, `ssh_key_base64.txt`, etc. `git rm` alone does not scrub history. If you want a clean repo, do this on your laptop:

```bash
# Back up the repo first
cp -a "project 2" "project 2.bak"

# Install the tool
brew install git-filter-repo

# Scrub every known-bad path from every commit
cd "project 2"
git filter-repo \
  --path-glob '*cookies*.txt' \
  --path-glob '*_test.txt' \
  --path-glob 'ssh_key*.txt' \
  --path-glob 'github_actions_pubkey.txt' \
  --path-glob 'admin_response.html' \
  --path-glob 'response.html' \
  --path-glob '.dart_tool/**' \
  --path-glob 'frontend-build.tar.gz' \
  --path-glob 'frontend-production.tar.gz' \
  --path-glob 'product-images.tar.gz' \
  --invert-paths

# git-filter-repo resets the remote — re-add it
git remote add origin https://github.com/PanapatWonganan/clinic-management.git

# Force-push the rewritten history
git push --force origin main
```

**Warnings:**
- This rewrites every commit SHA. Anyone else with a clone must re-clone; their old clone cannot be merged back.
- Any fork or cached copy on GitHub may still hold the old history for a while. After force-push, also open a support request with GitHub to purge cached views if the repo was ever public.
- If the repo has open PRs, close them first and recreate after the rewrite.

If you skip this step, steps 2–6 still protect you — the compromised secrets are rotated, so old copies of the repo are worthless.

---

## 8. Deploy

```bash
# Backend: push triggers GitHub Action
git push origin main

# Frontend: build locally, ship tarball
cd "project 2"
flutter build web --release --base-href="/" --dart-define=PRODUCTION=true
cd build/web && tar -czf ../../frontend-build.tar.gz . && cd ../..
./deploy-frontend-to-production.sh
```

After deploy, on the server:

```bash
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/storage
sudo chmod -R 775 /var/www/api.exquillermember.com/storage
sudo chown -R www-data:www-data /var/www/exquillermember.com
sudo chmod -R 755 /var/www/exquillermember.com
sudo systemctl reload nginx
```

---

## 9. Smoke-test production

```bash
# Should 401 (Unauthenticated JSON, not an HTML 500)
curl -i https://api.exquillermember.com/api/customers

# Should 401
curl -i -X POST https://api.exquillermember.com/api/products \
  -H 'Content-Type: application/json' -d '{}'

# Should 200 with a products array
curl -i https://api.exquillermember.com/api/products

# Should 404 — simulate route must not exist on production
curl -i -X POST https://api.exquillermember.com/api/payment/simulate \
  -H 'Content-Type: application/json' -d '{"order_id":"1","status":"success"}'

# Rate limiter test — the 11th request should come back 429
for i in $(seq 1 12); do
  curl -s -o /dev/null -w "$i: %{http_code}\n" \
    -X POST https://api.exquillermember.com/api/auth/login \
    -H 'Content-Type: application/json' -d '{"email":"x@x","password":"x"}'
done

# Frontend loads and logs in
open https://exquillermember.com
```

If any check fails, roll back and fix before users hit it.
