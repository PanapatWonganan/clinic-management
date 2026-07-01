# Points-Based Reward Redemption — Design Spec

**Date:** 2026-07-01
**Status:** Approved (brainstorming complete, pending final spec review)

## Problem

The app's 5th bottom-nav tab ("รีวอร์ด" → `RewardsScreen`) presents a points-based
reward catalog, but the redemption half of the feature is unfinished:

- **Frontend:** catalog list is wired to `GET /products/rewards`, but the points balance
  is hard-coded (`availablePoints = 1000000` in `reward_detail_screen.dart`), the
  "แลกรีวอร์ด" button is a stub dialog with no API call, and `reward_history_screen.dart`
  is entirely mock data.
- **Backend:** no standalone points-based redemption exists. `current_points` is a
  display-only derived stat (`floor(total_spent / 10000)`), never stored or deducted.
  There is no redemption endpoint and no history table for this flow.

This feature is **separate** from the existing bundle-deal free-item flow
(`UserClaimedReward` / `FreeItemRedemption` / `MembershipProgressService`, reached from
the 2nd nav tab). The two systems must not be conflated.

## Goal

Make the 5th tab redeem real rewards with **real points that are actually deducted**,
end-to-end: user spends points → redemption request created (status pending) → admin
approves and ships → user sees status in history.

## Non-Goals

- Do NOT touch the membership/bundle-deal flow, payment flow, or the existing
  `current_points` derivation.
- Do NOT build a full points ledger (earn events are still derived live from spend).
- Do NOT build a new admin product-management screen (reuse `category=reward` + `points`).

## Key Decisions (from brainstorming)

| Topic | Decision |
|---|---|
| Points source | Derived live from spend: `floor(total_spent / 10000)`. Not stored as earned events. |
| Deduction mechanism | **Approach A**: single `users.points_spent` counter. Balance = earned − spent. No payment/membership changes. |
| Fulfillment | Admin approve + ship (mirrors bundle-deal `FreeItemRedemption` lifecycle). |
| Reward products | Reuse existing `products.category='reward'` + `products.points`. Admin manages via existing product screen. |
| Shipping address | Chosen at redemption time via bottom sheet in the existing detail screen. |
| Catalog seeding | 10 fixed reward items seeded into `products` as `category='reward'` (see below). |
| Reward images | Temporary Material Icons per item type (real images arriving from the team later). |
| Price integrity | Snapshot `points_per_item` on the redemption row so later price edits don't corrupt history. |
| Cancel behavior | Admin cancel refunds points (`points_spent -= points_total`) and restores stock. |

## Points Formula (no changes to existing derivation)

```
points_earned  = floor(users.total_spent / 10000)   # existing derived logic, untouched
points_balance = points_earned - users.points_spent  # new: subtract cumulative spent
```

`total_spent` / `current_points` continue to be computed as they are today
(`ProfileController` / `MembershipProgressService`). We only subtract a new
`points_spent` counter — ground truth (real purchase total) stays authoritative.

## Data Model (Backend — Laravel)

### Migration 1 — `users.points_spent`
```
points_spent  INT  NOT NULL  DEFAULT 0
```
Cumulative points redeemed across all reward redemptions.

### Migration 2 + Model — `reward_redemptions`
Parallel to `free_item_redemptions`, but points-bound (no `claimed_reward_id`):

| Column | Type | Notes |
|---|---|---|
| `id` | PK | |
| `user_id` | FK users | |
| `product_id` | FK products | must be `category='reward'` |
| `quantity` | INT | items redeemed |
| `points_per_item` | INT | **snapshot** of `products.points` at redemption time |
| `points_total` | INT | `= quantity * points_per_item`, actual amount deducted |
| `status` | ENUM | `pending, approved, preparing, shipped, delivered, cancelled` (default `pending`) — same set as `free_item_redemptions` |
| `shipping_address_id` | FK customer_addresses | |
| `tracking_number` | nullable | |
| `notes` | nullable | user note |
| `admin_notes` | nullable | |
| `approved_at` / `shipped_at` / `delivered_at` | nullable timestamps | |
| `created_at` / `updated_at` | timestamps | |

**Model `RewardRedemption`** — relationships `user()`, `product()`, `shippingAddress()`;
scopes `pending()`, `active()` (mirror `FreeItemRedemption`).

## Reward Catalog Seed

Seed these 10 fixed items into `products` as `category='reward'`, `is_active=true`,
with the points cost below. A dedicated seeder (idempotent — upsert by name or a stable
`sku`/slug so re-running does not duplicate). Stock is set to a sensible default per item
(team can adjust later via the existing admin product screen).

| # | Name (TH/EN) | Points | Temp icon (Material) |
|---|---|---|---|
| 1 | หมวก | 50 | `Icons.sports_baseball` (cap) → `checkroom` fallback |
| 2 | กระเป๋า | 60 | `Icons.shopping_bag` |
| 3 | เสื้อ Babytee | 80 | `Icons.checkroom` |
| 4 | เสื้อ Oversize | 120 | `Icons.checkroom` |
| 5 | VDO Marketing | 750 | `Icons.videocam` |
| 6 | Insurance | 3700 | `Icons.shield` (or `health_and_safety`) |
| 7 | Hand-Ons 1:1 | 4000 | `Icons.handshake` (or `person`) |
| 8 | Lecture + Training | 6000 | `Icons.school` |
| 9 | Travel Ticket | 10000 | `Icons.airplane_ticket` (or `confirmation_number`) |
| 10 | Travel Trip | 32000 | `Icons.flight_takeoff` (or `luggage`) |

**Images are temporary.** Real images will be supplied by the team later. Until then the
Flutter catalog/detail cards render a Material Icon chosen by item type. The image field on
the product may be empty/null; the frontend falls back to the mapped icon when no image URL
is present. Icon mapping lives in the frontend (keyed by product name/slug) so swapping in
real images later is just populating `products.image` — no icon-mapping changes needed once
images arrive; the fallback simply stops triggering.

## API (Backend)

New controller `RewardRedemptionController`, all routes under `auth:sanctum`:

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/reward-catalog` | reward products: `category='reward'`, `is_active`, `stock > 0`, with points cost |
| `GET` | `/reward-points/balance` | `{ points_balance, points_earned, points_spent }` |
| `POST` | `/reward-redemptions` | redeem: `{ product_id, quantity, shipping_address_id, notes? }` |
| `GET` | `/reward-redemptions` | current user's redemption history |
| `GET` | `/reward-redemptions/{id}` | single redemption detail |

### `POST /reward-redemptions` — core transaction

Within a DB transaction:
1. `lockForUpdate` on the user row.
2. Recompute `points_balance` fresh from DB.
3. Validate:
   - product exists, `category='reward'`, `is_active`.
   - `stock >= quantity`.
   - `points_balance >= quantity * product.points`.
   - `shipping_address_id` belongs to the authenticated user.
4. On pass: `users.points_spent += points_total`; insert `reward_redemptions`
   (status `pending`, snapshot `points_per_item`); decrement product stock.
5. Enqueue `SendTelegramNotification` to admin (existing pattern).
6. Commit → return the redemption row + updated balance.

### Admin

Reuse the `Admin/RewardController` pattern (server-rendered Blade). Add index/detail/
status actions for `reward_redemptions`: approve / set tracking / ship / deliver / cancel.
**Cancel refunds points (`points_spent -= points_total`) and restores stock.**

### Error handling (Thai messages)

| Case | Response |
|---|---|
| Insufficient points | `422` "คะแนนไม่เพียงพอ" |
| Out of stock | `422` "สินค้าหมด" |
| Invalid / non-reward product | `422` |
| Address not owned by user | `422` / `403` |
| Concurrent redemption (race) | Prevented by `lockForUpdate`; transaction rolls back if balance would go negative |

## Frontend (Flutter)

Screens already exist — the work is replacing mock data with real API calls.

### New: `lib/services/reward_service.dart` (via existing `ApiService`)
- `getRewardCatalog()` → `GET /reward-catalog`
- `getPointsBalance()` → `GET /reward-points/balance`
- `redeem({productId, quantity, shippingAddressId, notes})` → `POST /reward-redemptions`
- `getRedemptionHistory()` → `GET /reward-redemptions`

### New models
- `lib/models/reward_product.dart` — typed reward catalog item (id, name, description, points, image, stock). Exposes a computed `fallbackIcon` (Material Icon by name/slug) used when `image` is null/empty.
- `lib/models/reward_redemption.dart` — typed redemption (id, product, quantity, points_total, status, tracking, timestamps).

### Modified screens

| Screen | Today (mock) | Change |
|---|---|---|
| `rewards_screen.dart` | catalog via `/products/rewards`; header points via `/membership/progress` | catalog + balance from `reward_service` (real, deducted balance) |
| `reward_detail_screen.dart` | `availablePoints=1000000`; redeem = stub dialog | real balance; redeem via bottom sheet (address picker + confirm) calling `redeem()`; refresh balance on success |
| `reward_history_screen.dart` | fully mock list | real `getRedemptionHistory()` with real statuses |

### Redemption flow (`reward_detail_screen.dart`)
1. Pick quantity → client-side check `balance >= quantity * points` (UX guard only; backend is authoritative).
2. Tap redeem → **bottom sheet** in the same screen: choose shipping address
   (reuse the address-selection pattern from `redeem_free_items_screen.dart`; if no
   address exists, route to add one first).
3. Confirm → call API → on success show result + refresh points; on failure show the
   backend Thai error message (`422`).

## Testing

- Backend: feature test for `POST /reward-redemptions` covering success (points deducted,
  stock decremented, row created), insufficient points (`422`, no mutation), out of stock,
  address-not-owned, and admin cancel (points + stock refunded). Concurrency guarded by
  `lockForUpdate`.
- Frontend: verify the three screens render real data and the redeem flow surfaces backend
  errors rather than a fake success dialog.

## Files Touched (anticipated)

**Backend (`clinic-backend/`)**
- `database/migrations/*_add_points_spent_to_users.php` (new)
- `database/migrations/*_create_reward_redemptions_table.php` (new)
- `database/seeders/RewardCatalogSeeder.php` (new — 10 fixed reward items)
- `app/Models/RewardRedemption.php` (new)
- `app/Http/Controllers/RewardRedemptionController.php` (new)
- `app/Http/Controllers/Admin/RewardController.php` (extend) + Blade views
- `routes/api.php` (new routes) / `routes/web.php` (admin actions)

**Frontend (`lib/`)**
- `services/reward_service.dart` (new)
- `models/reward_product.dart`, `models/reward_redemption.dart` (new)
- `screens/rewards_screen.dart`, `screens/reward_detail_screen.dart`,
  `screens/reward_history_screen.dart` (modify)
