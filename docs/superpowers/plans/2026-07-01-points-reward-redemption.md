# Points-Based Reward Redemption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 5th-tab reward flow redeem real rewards with real, deducted points end-to-end (user spends points → pending redemption → admin approve/ship → history).

**Architecture:** Points balance is derived live (`floor(total_spent / 10000)`) minus a new `users.points_spent` counter — no payment/membership changes. A new `reward_redemptions` table and `RewardRedemptionController` mirror the existing bundle-deal `FreeItemRedemption` pattern but are points-bound (no `claimed_reward_id`). Three existing Flutter screens are wired to the new API; reward products are seeded as `category='reward'` products with temporary Material Icons.

**Tech Stack:** Laravel 12 / PHP 8.2 / MySQL (backend), Flutter / Dart / `http` (frontend). Backend tests via PHPUnit (`php artisan test`). Formatter: `./vendor/bin/pint` (backend), `flutter analyze` (frontend).

## Global Constraints

- Backend runs from `clinic-backend/`. Frontend from repo root `/Users/janejiramalai/Downloads/project 2`.
- Do NOT touch payment flow, membership/bundle-deal flow, or the existing `current_points` derivation in `ProfileController`.
- Points formula: `points_earned = floor(total_spent / 10000)`; `points_balance = points_earned - users.points_spent`. `total_spent` is computed exactly as `ProfileController@getMembershipProgress` does today (completed orders excluding free-item orders).
- Reward products = existing `products` rows with `category='reward'`, `is_active=true`. Cost per item = `products.points`.
- Redemption lifecycle status enum = `pending, approved, preparing, shipped, delivered, cancelled` (same set as `free_item_redemptions`), default `pending`.
- Snapshot `points_per_item` on the redemption row; never re-read `products.points` for historical rows.
- Admin cancel refunds points (`points_spent -= points_total`) and restores stock.
- All new API routes under `auth:sanctum`. All user-facing strings in Thai.
- Money/points deduction happens inside a DB transaction with `lockForUpdate` on the user row.
- Frontend HTTP goes through `ApiService.get(endpoint)` / `ApiService.post(endpoint, data)` and `ApiService.parseResponse(response)`. Bearer token is injected automatically.
- Reward catalog seed (10 fixed items) — names/points are fixed:
  หมวก=50, กระเป๋า=60, เสื้อ Babytee=80, เสื้อ Oversize=120, VDO Marketing=750, Insurance=3700, Hand-Ons 1:1=4000, Lecture + Training=6000, Travel Ticket=10000, Travel Trip=32000.

---

## File Structure

**Backend (`clinic-backend/`)**
- `database/migrations/2026_07_01_000001_add_points_spent_to_users_table.php` (new) — `users.points_spent`.
- `database/migrations/2026_07_01_000002_create_reward_redemptions_table.php` (new) — redemption table.
- `app/Models/RewardRedemption.php` (new) — model + relations + scopes + status labels.
- `app/Services/RewardPointsService.php` (new) — single source of truth for balance math (earned/spent/balance), reused by controller and tests.
- `app/Http/Controllers/RewardRedemptionController.php` (new) — catalog, balance, redeem, history, detail.
- `database/seeders/RewardCatalogSeeder.php` (new) — 10 fixed reward products (idempotent upsert by name).
- `routes/api.php` (modify) — 5 new routes.
- `tests/Feature/RewardRedemptionTest.php` (new) — feature tests.

**Frontend (`lib/`)**
- `models/reward_product.dart` (new) — typed catalog item + `fallbackIcon`.
- `models/reward_redemption.dart` (new) — typed redemption + Thai status label.
- `services/reward_service.dart` (new) — 4 API calls.
- `screens/rewards_screen.dart` (modify) — real catalog + balance.
- `screens/reward_detail_screen.dart` (modify) — real balance + redeem bottom sheet.
- `screens/reward_history_screen.dart` (modify) — real history.

---

## Task 1: `users.points_spent` migration

**Files:**
- Create: `clinic-backend/database/migrations/2026_07_01_000001_add_points_spent_to_users_table.php`

**Interfaces:**
- Produces: column `users.points_spent` (unsigned int, default 0).

- [ ] **Step 1: Write the migration**

`clinic-backend/database/migrations/2026_07_01_000001_add_points_spent_to_users_table.php`:
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Cumulative reward points already redeemed. Balance is derived as
            // floor(total_spent / 10000) - points_spent, so we only track spend.
            $table->unsignedInteger('points_spent')->default(0)->after('id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('points_spent');
        });
    }
};
```

- [ ] **Step 2: Run the migration**

Run: `cd clinic-backend && php artisan migrate`
Expected: migration runs, no error; `users` table now has `points_spent`.

- [ ] **Step 3: Add `points_spent` to the User model fillable/casts**

In `clinic-backend/app/Models/User.php`, add `'points_spent'` to `$fillable` (if a `$fillable` array exists) and `'points_spent' => 'integer'` to `$casts`. (Read the file first to match its existing arrays; do not duplicate keys.)

- [ ] **Step 4: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add clinic-backend/database/migrations/2026_07_01_000001_add_points_spent_to_users_table.php clinic-backend/app/Models/User.php
git commit -m "feat(reward): add users.points_spent for reward point deduction"
```

---

## Task 2: `reward_redemptions` table + model

**Files:**
- Create: `clinic-backend/database/migrations/2026_07_01_000002_create_reward_redemptions_table.php`
- Create: `clinic-backend/app/Models/RewardRedemption.php`

**Interfaces:**
- Consumes: `users`, `products`, `customer_addresses` tables.
- Produces: `RewardRedemption` model with fillable `user_id, product_id, quantity, points_per_item, points_total, status, shipping_address_id, tracking_number, notes, admin_notes, approved_at, shipped_at, delivered_at`; relations `user()`, `product()`, `shippingAddress()`; scopes `pending()`, `active()`; status constants `STATUS_PENDING` … `STATUS_CANCELLED`; accessor `status_label`.

- [ ] **Step 1: Write the migration**

`clinic-backend/database/migrations/2026_07_01_000002_create_reward_redemptions_table.php`:
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Points-based reward redemptions. Parallel to free_item_redemptions but
     * bound to reward points (no claimed_reward_id). points_per_item is a
     * snapshot of products.points at redemption time so later price edits do
     * not corrupt historical rows.
     */
    public function up(): void
    {
        Schema::create('reward_redemptions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('product_id');
            $table->integer('quantity');
            $table->unsignedInteger('points_per_item'); // snapshot of products.points
            $table->unsignedInteger('points_total');     // quantity * points_per_item
            $table->enum('status', ['pending', 'approved', 'preparing', 'shipped', 'delivered', 'cancelled'])
                ->default('pending');
            $table->unsignedBigInteger('shipping_address_id')->nullable();
            $table->string('tracking_number')->nullable();
            $table->text('notes')->nullable();
            $table->text('admin_notes')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('product_id')->references('id')->on('products')->onDelete('cascade');
            $table->foreign('shipping_address_id')->references('id')->on('customer_addresses')->onDelete('set null');

            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reward_redemptions');
    }
};
```

- [ ] **Step 2: Run the migration**

Run: `cd clinic-backend && php artisan migrate`
Expected: creates `reward_redemptions`, no error.

- [ ] **Step 3: Write the model**

`clinic-backend/app/Models/RewardRedemption.php`:
```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RewardRedemption extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'product_id',
        'quantity',
        'points_per_item',
        'points_total',
        'status',
        'shipping_address_id',
        'tracking_number',
        'notes',
        'admin_notes',
        'approved_at',
        'shipped_at',
        'delivered_at',
    ];

    protected $casts = [
        'quantity' => 'integer',
        'points_per_item' => 'integer',
        'points_total' => 'integer',
        'approved_at' => 'datetime',
        'shipped_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    const STATUS_PENDING = 'pending';
    const STATUS_APPROVED = 'approved';
    const STATUS_PREPARING = 'preparing';
    const STATUS_SHIPPED = 'shipped';
    const STATUS_DELIVERED = 'delivered';
    const STATUS_CANCELLED = 'cancelled';

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function shippingAddress()
    {
        return $this->belongsTo(CustomerAddress::class, 'shipping_address_id');
    }

    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeActive($query)
    {
        return $query->whereNotIn('status', [self::STATUS_CANCELLED, self::STATUS_DELIVERED]);
    }

    public function getStatusLabelAttribute()
    {
        return match ($this->status) {
            self::STATUS_PENDING => 'รอดำเนินการ',
            self::STATUS_APPROVED => 'อนุมัติแล้ว',
            self::STATUS_PREPARING => 'กำลังจัดเตรียม',
            self::STATUS_SHIPPED => 'จัดส่งแล้ว',
            self::STATUS_DELIVERED => 'ส่งถึงแล้ว',
            self::STATUS_CANCELLED => 'ยกเลิก',
            default => $this->status,
        };
    }
}
```

- [ ] **Step 4: Verify model loads**

Run: `cd clinic-backend && php artisan tinker --execute="echo App\Models\RewardRedemption::count();"`
Expected: prints `0` (table empty), no class error.

- [ ] **Step 5: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add clinic-backend/database/migrations/2026_07_01_000002_create_reward_redemptions_table.php clinic-backend/app/Models/RewardRedemption.php
git commit -m "feat(reward): add reward_redemptions table and model"
```

---

## Task 3: `RewardPointsService` (balance math)

**Files:**
- Create: `clinic-backend/app/Services/RewardPointsService.php`
- Test: `clinic-backend/tests/Feature/RewardPointsServiceTest.php`

**Interfaces:**
- Consumes: `User` model, `Order`/`OrderItem` (completed orders), `RewardRedemption` (for nothing here — spend is read from `users.points_spent`).
- Produces:
  - `RewardPointsService::earnedPoints(User $user): int` — `floor(total_spent / 10000)` using the same completed-order rule as `ProfileController@getMembershipProgress`.
  - `RewardPointsService::balance(User $user): int` — `earnedPoints($user) - $user->points_spent`, floored at 0 for display.

- [ ] **Step 1: Read the existing total_spent logic**

Read `clinic-backend/app/Http/Controllers/ProfileController.php` lines 120–142 to copy the exact completed-orders query (status filter + exclude free-item orders) so `earnedPoints` matches `current_points`.

- [ ] **Step 2: Write the failing test**

`clinic-backend/tests/Feature/RewardPointsServiceTest.php`:
```php
<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\RewardPointsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RewardPointsServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_balance_is_earned_minus_spent(): void
    {
        $user = User::factory()->create(['points_spent' => 3]);
        // No orders → earned 0. Balance floored at 0 even though spent is 3.
        $service = new RewardPointsService();

        $this->assertSame(0, $service->earnedPoints($user));
        $this->assertSame(0, $service->balance($user));
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd clinic-backend && php artisan test --filter=RewardPointsServiceTest`
Expected: FAIL — `Class "App\Services\RewardPointsService" not found`.

- [ ] **Step 4: Write the service**

`clinic-backend/app/Services/RewardPointsService.php` — mirror the ProfileController completed-order rule read in Step 1. Use the SAME query. Template (adjust the order query to match what Step 1 showed exactly):
```php
<?php

namespace App\Services;

use App\Models\Order;
use App\Models\User;

class RewardPointsService
{
    /**
     * Points earned = floor(total completed spend / 10000). Mirrors
     * ProfileController@getMembershipProgress so this never diverges from the
     * displayed current_points. Excludes free-item orders.
     */
    public function earnedPoints(User $user): int
    {
        $totalSpent = Order::where('user_id', $user->id)
            ->where('status', 'completed')
            ->where(function ($q) {
                $q->where('is_free_item_order', false)
                    ->orWhereNull('is_free_item_order');
            })
            ->sum('total_amount');

        return (int) floor($totalSpent / 10000);
    }

    /**
     * Spendable balance = earned - already spent, never below 0 for display.
     */
    public function balance(User $user): int
    {
        return max(0, $this->earnedPoints($user) - (int) $user->points_spent);
    }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd clinic-backend && php artisan test --filter=RewardPointsServiceTest`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add clinic-backend/app/Services/RewardPointsService.php clinic-backend/tests/Feature/RewardPointsServiceTest.php
git commit -m "feat(reward): add RewardPointsService for balance math"
```

---

## Task 4: `RewardRedemptionController` + routes

**Files:**
- Create: `clinic-backend/app/Http/Controllers/RewardRedemptionController.php`
- Modify: `clinic-backend/routes/api.php` (after the existing reward routes, ~line 42)
- Test: `clinic-backend/tests/Feature/RewardRedemptionTest.php`

**Interfaces:**
- Consumes: `RewardPointsService::balance()`/`earnedPoints()`, `RewardRedemption`, `Product`, `CustomerAddress`.
- Produces API:
  - `GET /reward-catalog` → `{ success, data: [{id,name,description,points,image,stock}] }`
  - `GET /reward-points/balance` → `{ success, data: { points_balance, points_earned, points_spent } }`
  - `POST /reward-redemptions` body `{ product_id, quantity, shipping_address_id, notes? }` → `201 { success, data: {redemption}, points_balance }` or `422 { success:false, message }`
  - `GET /reward-redemptions` → `{ success, data: [redemption...] }`
  - `GET /reward-redemptions/{id}` → `{ success, data: redemption }` (owner only)

- [ ] **Step 1: Write the failing feature tests**

`clinic-backend/tests/Feature/RewardRedemptionTest.php`:
```php
<?php

namespace Tests\Feature;

use App\Models\CustomerAddress;
use App\Models\Order;
use App\Models\Product;
use App\Models\RewardRedemption;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RewardRedemptionTest extends TestCase
{
    use RefreshDatabase;

    private function rewardProduct(int $points = 50, int $stock = 10): Product
    {
        return Product::factory()->create([
            'category' => 'reward',
            'is_active' => true,
            'points' => $points,
            'stock' => $stock,
        ]);
    }

    /** A user with 100k spend has 10 points earned. */
    private function userWithPoints(int $earnedBaht = 100000): User
    {
        $user = User::factory()->create(['points_spent' => 0]);
        Order::factory()->create([
            'user_id' => $user->id,
            'status' => 'completed',
            'total_amount' => $earnedBaht,
            'is_free_item_order' => false,
        ]);
        return $user;
    }

    public function test_redeem_deducts_points_and_stock_and_creates_row(): void
    {
        $user = $this->userWithPoints(100000); // 10 points
        $product = $this->rewardProduct(50, 10);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // cost = 1 * 50 = 50 points, but earned is only 10 → should fail first;
        // use a cheaper product to succeed instead.
        $cheap = $this->rewardProduct(5, 10);
        $addr2 = $address;

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $cheap->id,
            'quantity' => 2,
            'shipping_address_id' => $addr2->id,
        ]);

        $res->assertStatus(201);
        $this->assertSame(0, $res->json('points_balance')); // 10 - 2*5 = 0
        $this->assertDatabaseHas('reward_redemptions', [
            'user_id' => $user->id,
            'product_id' => $cheap->id,
            'quantity' => 2,
            'points_per_item' => 5,
            'points_total' => 10,
            'status' => 'pending',
        ]);
        $user->refresh();
        $this->assertSame(10, (int) $user->points_spent);
        $cheap->refresh();
        $this->assertSame(8, (int) $cheap->stock);
    }

    public function test_redeem_fails_when_points_insufficient(): void
    {
        $user = $this->userWithPoints(10000); // 1 point
        $product = $this->rewardProduct(50, 10);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 1,
            'shipping_address_id' => $address->id,
        ]);

        $res->assertStatus(422);
        $this->assertSame(0, RewardRedemption::count());
        $user->refresh();
        $this->assertSame(0, (int) $user->points_spent);
    }

    public function test_redeem_fails_when_out_of_stock(): void
    {
        $user = $this->userWithPoints(100000);
        $product = $this->rewardProduct(5, 1);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 2,
            'shipping_address_id' => $address->id,
        ]);

        $res->assertStatus(422);
        $this->assertSame(0, RewardRedemption::count());
    }

    public function test_redeem_rejects_address_not_owned(): void
    {
        $user = $this->userWithPoints(100000);
        $other = User::factory()->create();
        $product = $this->rewardProduct(5, 10);
        $addr = CustomerAddress::factory()->create(['user_id' => $other->id]);
        Sanctum::actingAs($user);

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 1,
            'shipping_address_id' => $addr->id,
        ]);

        $res->assertStatus(422);
    }

    public function test_balance_endpoint_reports_earned_minus_spent(): void
    {
        $user = $this->userWithPoints(100000); // earned 10
        $user->update(['points_spent' => 4]);
        Sanctum::actingAs($user);

        $res = $this->getJson('/api/reward-points/balance');
        $res->assertOk();
        $this->assertSame(10, $res->json('data.points_earned'));
        $this->assertSame(4, $res->json('data.points_spent'));
        $this->assertSame(6, $res->json('data.points_balance'));
    }
}
```

Note: `Product`, `Order`, `CustomerAddress`, `User` factories are assumed to exist. If a factory is missing, add a minimal one in `database/factories/` matching the model's fillable — check `database/factories/` first.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd clinic-backend && php artisan test --filter=RewardRedemptionTest`
Expected: FAIL — route `/api/reward-redemptions` not defined (404).

- [ ] **Step 3: Write the controller**

`clinic-backend/app/Http/Controllers/RewardRedemptionController.php`:
```php
<?php

namespace App\Http\Controllers;

use App\Models\CustomerAddress;
use App\Models\Product;
use App\Models\RewardRedemption;
use App\Models\User;
use App\Services\RewardPointsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class RewardRedemptionController extends Controller
{
    public function __construct(private RewardPointsService $points)
    {
    }

    /** GET /reward-catalog — reward products available to redeem. */
    public function catalog()
    {
        $products = Product::where('category', 'reward')
            ->where('is_active', true)
            ->where('stock', '>', 0)
            ->get()
            ->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'description' => $p->description,
                'points' => (int) $p->points,
                'image' => $p->image_url ?: null, // products column is image_url
                'stock' => (int) $p->stock,
            ]);

        return response()->json(['success' => true, 'data' => $products]);
    }
    // Note: products stores the image path in `image_url` (not `image`).
    // ProductController@getRewardProducts runs rewriteStoredImageUrls() to
    // resolve it to a full URL; reuse that helper if you need resolved URLs.
    // Seeded reward items have image_url = null → frontend uses an icon fallback.

    /** GET /reward-points/balance */
    public function balance()
    {
        $user = Auth::user();

        return response()->json([
            'success' => true,
            'data' => [
                'points_balance' => $this->points->balance($user),
                'points_earned' => $this->points->earnedPoints($user),
                'points_spent' => (int) $user->points_spent,
            ],
        ]);
    }

    /** POST /reward-redemptions */
    public function redeem(Request $request)
    {
        $data = $request->validate([
            'product_id' => 'required|integer|exists:products,id',
            'quantity' => 'required|integer|min:1',
            'shipping_address_id' => 'required|integer',
            'notes' => 'nullable|string|max:1000',
        ]);

        try {
            $result = DB::transaction(function () use ($data) {
                /** @var User $user */
                $user = User::where('id', Auth::id())->lockForUpdate()->first();

                $product = Product::where('id', $data['product_id'])
                    ->lockForUpdate()
                    ->first();

                if (! $product || $product->category !== 'reward' || ! $product->is_active) {
                    abort(422, 'สินค้านี้ไม่สามารถแลกได้');
                }

                $address = CustomerAddress::where('id', $data['shipping_address_id'])
                    ->where('user_id', $user->id)
                    ->first();
                if (! $address) {
                    abort(422, 'ไม่พบที่อยู่จัดส่ง');
                }

                $quantity = (int) $data['quantity'];
                if ($product->stock < $quantity) {
                    abort(422, 'สินค้าหมด');
                }

                $pointsPerItem = (int) $product->points;
                $pointsTotal = $pointsPerItem * $quantity;

                $balance = $this->points->balance($user);
                if ($balance < $pointsTotal) {
                    abort(422, 'คะแนนไม่เพียงพอ');
                }

                $user->points_spent = (int) $user->points_spent + $pointsTotal;
                $user->save();

                $product->stock -= $quantity;
                $product->save();

                $redemption = RewardRedemption::create([
                    'user_id' => $user->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'points_per_item' => $pointsPerItem,
                    'points_total' => $pointsTotal,
                    'status' => RewardRedemption::STATUS_PENDING,
                    'shipping_address_id' => $address->id,
                    'notes' => $data['notes'] ?? null,
                ]);

                return [
                    'redemption' => $redemption,
                    'points_balance' => $this->points->balance($user->refresh()),
                ];
            });
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getStatusCode());
        }

        // TODO(reward): enqueue SendTelegramNotification to admin (match the
        // dispatch pattern used by FreeItemRedemptionController@redeem).

        return response()->json([
            'success' => true,
            'data' => $result['redemption'],
            'points_balance' => $result['points_balance'],
        ], 201);
    }

    /** GET /reward-redemptions — current user's history. */
    public function history()
    {
        $rows = RewardRedemption::where('user_id', Auth::id())
            ->with('product')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($r) => $this->presentRedemption($r));

        return response()->json(['success' => true, 'data' => $rows]);
    }

    /** GET /reward-redemptions/{id} */
    public function show($id)
    {
        $r = RewardRedemption::where('id', $id)
            ->where('user_id', Auth::id())
            ->with('product')
            ->first();

        if (! $r) {
            return response()->json(['success' => false, 'message' => 'ไม่พบรายการ'], 404);
        }

        return response()->json(['success' => true, 'data' => $this->presentRedemption($r)]);
    }

    private function presentRedemption(RewardRedemption $r): array
    {
        return [
            'id' => $r->id,
            'product_id' => $r->product_id,
            'product_name' => $r->product?->name,
            'quantity' => $r->quantity,
            'points_per_item' => $r->points_per_item,
            'points_total' => $r->points_total,
            'status' => $r->status,
            'status_label' => $r->status_label,
            'tracking_number' => $r->tracking_number,
            'created_at' => $r->created_at->format('Y-m-d H:i:s'),
        ];
    }
}
```

- [ ] **Step 4: Add the routes**

In `clinic-backend/routes/api.php`, inside the same `auth:sanctum` group as the existing reward routes (right after the `/products/rewards` route, ~line 42), add:
```php
    // Points-based reward catalog + redemption (5th-tab flow)
    Route::get('/reward-catalog', [\App\Http\Controllers\RewardRedemptionController::class, 'catalog']);
    Route::get('/reward-points/balance', [\App\Http\Controllers\RewardRedemptionController::class, 'balance']);
    Route::post('/reward-redemptions', [\App\Http\Controllers\RewardRedemptionController::class, 'redeem']);
    Route::get('/reward-redemptions', [\App\Http\Controllers\RewardRedemptionController::class, 'history']);
    Route::get('/reward-redemptions/{id}', [\App\Http\Controllers\RewardRedemptionController::class, 'show']);
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd clinic-backend && php artisan test --filter=RewardRedemptionTest`
Expected: all pass. If a factory is missing, add it (see note in Step 1) and re-run.

- [ ] **Step 6: Format + commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2/clinic-backend" && ./vendor/bin/pint app/Http/Controllers/RewardRedemptionController.php
cd "/Users/janejiramalai/Downloads/project 2"
git add clinic-backend/app/Http/Controllers/RewardRedemptionController.php clinic-backend/routes/api.php clinic-backend/tests/Feature/RewardRedemptionTest.php clinic-backend/database/factories/
git commit -m "feat(reward): add reward redemption API (catalog, balance, redeem, history)"
```

---

## Task 5: Admin cancel refunds points + stock

**Files:**
- Modify: `clinic-backend/app/Http/Controllers/Admin/RewardController.php` (add a reward-redemption status/cancel action; read the file first to match its pattern)
- Modify: `clinic-backend/routes/web.php` (add admin route under the existing `admin/rewards` group)
- Test: append to `clinic-backend/tests/Feature/RewardRedemptionTest.php`

**Interfaces:**
- Consumes: `RewardRedemption`, `User`, `Product`.
- Produces: admin action that sets a `RewardRedemption` status; when transitioning to `cancelled` from a non-cancelled state, refunds `user.points_spent -= points_total` and restores `product.stock += quantity`, inside a transaction. Idempotent: cancelling an already-cancelled row is a no-op refund.

- [ ] **Step 1: Write the failing test (append)**

Append to `RewardRedemptionTest.php`:
```php
    public function test_admin_cancel_refunds_points_and_stock(): void
    {
        $user = $this->userWithPoints(100000); // earned 10
        $product = $this->rewardProduct(5, 10);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);
        $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 2,
            'shipping_address_id' => $address->id,
        ])->assertStatus(201);

        $user->refresh();
        $this->assertSame(10, (int) $user->points_spent);
        $product->refresh();
        $this->assertSame(8, (int) $product->stock);

        $redemption = RewardRedemption::first();

        // Admin cancel (call the service/controller method directly).
        $admin = new \App\Http\Controllers\Admin\RewardController();
        $admin->cancelRewardRedemption($redemption->id);

        $user->refresh();
        $product->refresh();
        $redemption->refresh();
        $this->assertSame(0, (int) $user->points_spent);   // refunded
        $this->assertSame(10, (int) $product->stock);       // restored
        $this->assertSame('cancelled', $redemption->status);

        // Idempotent: second cancel does not double-refund.
        $admin->cancelRewardRedemption($redemption->id);
        $user->refresh();
        $this->assertSame(0, (int) $user->points_spent);
    }
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd clinic-backend && php artisan test --filter=test_admin_cancel_refunds_points_and_stock`
Expected: FAIL — `cancelRewardRedemption` not defined.

- [ ] **Step 3: Implement the cancel method**

Read `clinic-backend/app/Http/Controllers/Admin/RewardController.php` first. Add this method (adapt the response to match whether the controller returns JSON or redirects for web; the test calls the method directly so return value is not asserted):
```php
    /**
     * Cancel a points-based reward redemption: refund points to the user and
     * restore product stock. Idempotent — a row already cancelled is skipped.
     */
    public function cancelRewardRedemption($id)
    {
        \Illuminate\Support\Facades\DB::transaction(function () use ($id) {
            $redemption = \App\Models\RewardRedemption::where('id', $id)->lockForUpdate()->first();
            if (! $redemption || $redemption->status === \App\Models\RewardRedemption::STATUS_CANCELLED) {
                return;
            }

            $user = \App\Models\User::where('id', $redemption->user_id)->lockForUpdate()->first();
            if ($user) {
                $user->points_spent = max(0, (int) $user->points_spent - (int) $redemption->points_total);
                $user->save();
            }

            $product = \App\Models\Product::where('id', $redemption->product_id)->lockForUpdate()->first();
            if ($product) {
                $product->stock = (int) $product->stock + (int) $redemption->quantity;
                $product->save();
            }

            $redemption->status = \App\Models\RewardRedemption::STATUS_CANCELLED;
            $redemption->save();
        });

        return back()->with('success', 'ยกเลิกและคืนคะแนนเรียบร้อย');
    }
```

- [ ] **Step 4: Add the admin route**

In `clinic-backend/routes/web.php`, inside the existing `admin/rewards` group (~lines 153–159), add:
```php
    Route::post('/reward-redemptions/{id}/cancel', [\App\Http\Controllers\Admin\RewardController::class, 'cancelRewardRedemption'])->name('admin.reward-redemptions.cancel');
```

- [ ] **Step 5: Run to verify it passes**

Run: `cd clinic-backend && php artisan test --filter=RewardRedemptionTest`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2/clinic-backend" && ./vendor/bin/pint app/Http/Controllers/Admin/RewardController.php
cd "/Users/janejiramalai/Downloads/project 2"
git add clinic-backend/app/Http/Controllers/Admin/RewardController.php clinic-backend/routes/web.php clinic-backend/tests/Feature/RewardRedemptionTest.php
git commit -m "feat(reward): admin cancel refunds reward points and restores stock"
```

---

## Task 6: Seed the 10 reward products

**Files:**
- Create: `clinic-backend/database/seeders/RewardCatalogSeeder.php`

**Interfaces:**
- Consumes: `Product` model (`category`, `points`, `name`, `is_active`, `stock`).
- Produces: 10 `products` rows with `category='reward'`. Idempotent via `updateOrCreate` keyed on `name`.

- [ ] **Step 1: Write the seeder**

`clinic-backend/database/seeders/RewardCatalogSeeder.php`:
```php
<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class RewardCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            ['name' => 'หมวก', 'points' => 50],
            ['name' => 'กระเป๋า', 'points' => 60],
            ['name' => 'เสื้อ Babytee', 'points' => 80],
            ['name' => 'เสื้อ Oversize', 'points' => 120],
            ['name' => 'VDO Marketing', 'points' => 750],
            ['name' => 'Insurance', 'points' => 3700],
            ['name' => 'Hand-Ons 1:1', 'points' => 4000],
            ['name' => 'Lecture + Training', 'points' => 6000],
            ['name' => 'Travel Ticket', 'points' => 10000],
            ['name' => 'Travel Trip', 'points' => 32000],
        ];

        foreach ($items as $item) {
            Product::updateOrCreate(
                ['name' => $item['name'], 'category' => 'reward'],
                [
                    'points' => $item['points'],
                    'is_active' => true,
                    'stock' => 100,       // team can adjust in admin later
                    'description' => $item['name'],
                    // image_url left null on purpose — frontend renders a
                    // Material Icon fallback until the team supplies real images.
                    // price defaults to 0 at the DB level; no need to set it.
                ]
            );
        }
    }
}
```

Note: if `Product` has other NOT NULL columns without defaults (e.g. `price`), read `products` migration and add sensible defaults (e.g. `'price' => 0`) to the update array so the insert succeeds.

- [ ] **Step 2: Register + run the seeder**

Run: `cd clinic-backend && php artisan db:seed --class=RewardCatalogSeeder`
Expected: no error. Re-run once more to confirm idempotency (still 10, no duplicates):
Run: `php artisan db:seed --class=RewardCatalogSeeder && php artisan tinker --execute="echo App\Models\Product::where('category','reward')->count();"`
Expected: prints `10`.

- [ ] **Step 3: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add clinic-backend/database/seeders/RewardCatalogSeeder.php
git commit -m "feat(reward): seed 10 fixed reward catalog products"
```

---

## Task 7: Flutter models (`RewardProduct`, `RewardRedemption`)

**Files:**
- Create: `lib/models/reward_product.dart`
- Create: `lib/models/reward_redemption.dart`

**Interfaces:**
- Produces:
  - `RewardProduct` — fields `int id, String name, String? description, int points, String? image, int stock`; `factory RewardProduct.fromJson(Map<String,dynamic>)`; getter `IconData fallbackIcon`.
  - `RewardRedemption` — fields `int id, int productId, String? productName, int quantity, int pointsTotal, String status, String statusLabel, String? trackingNumber, String createdAt`; `factory RewardRedemption.fromJson(Map<String,dynamic>)`.

- [ ] **Step 1: Write `reward_product.dart`**

`lib/models/reward_product.dart`:
```dart
import 'package:flutter/material.dart';

class RewardProduct {
  final int id;
  final String name;
  final String? description;
  final int points;
  final String? image;
  final int stock;

  const RewardProduct({
    required this.id,
    required this.name,
    this.description,
    required this.points,
    this.image,
    required this.stock,
  });

  factory RewardProduct.fromJson(Map<String, dynamic> json) {
    return RewardProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      image: (json['image'] as String?)?.isNotEmpty == true
          ? json['image'] as String
          : null,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  /// Temporary icon shown until the team supplies a real image. Keyed by name.
  IconData get fallbackIcon {
    final n = name.toLowerCase();
    if (n.contains('หมวก')) return Icons.sports_baseball;
    if (n.contains('กระเป๋า')) return Icons.shopping_bag;
    if (n.contains('babytee') || n.contains('oversize') || n.contains('เสื้อ')) {
      return Icons.checkroom;
    }
    if (n.contains('vdo') || n.contains('marketing')) return Icons.videocam;
    if (n.contains('insurance')) return Icons.shield;
    if (n.contains('hand-ons') || n.contains('1:1')) return Icons.handshake;
    if (n.contains('lecture') || n.contains('training')) return Icons.school;
    if (n.contains('ticket')) return Icons.airplane_ticket;
    if (n.contains('trip') || n.contains('travel')) return Icons.flight_takeoff;
    return Icons.card_giftcard;
  }
}
```

- [ ] **Step 2: Write `reward_redemption.dart`**

`lib/models/reward_redemption.dart`:
```dart
class RewardRedemption {
  final int id;
  final int productId;
  final String? productName;
  final int quantity;
  final int pointsTotal;
  final String status;
  final String statusLabel;
  final String? trackingNumber;
  final String createdAt;

  const RewardRedemption({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.pointsTotal,
    required this.status,
    required this.statusLabel,
    this.trackingNumber,
    required this.createdAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['id'] as int,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      pointsTotal: (json['points_total'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? '',
      trackingNumber: json['tracking_number'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
```

- [ ] **Step 3: Analyze**

Run: `cd "/Users/janejiramalai/Downloads/project 2" && flutter analyze lib/models/reward_product.dart lib/models/reward_redemption.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add lib/models/reward_product.dart lib/models/reward_redemption.dart
git commit -m "feat(reward): add typed RewardProduct and RewardRedemption models"
```

---

## Task 8: `reward_service.dart`

**Files:**
- Create: `lib/services/reward_service.dart`

**Interfaces:**
- Consumes: `ApiService.get/post/parseResponse`, `RewardProduct`, `RewardRedemption`.
- Produces `RewardService.instance` with:
  - `Future<List<RewardProduct>> getRewardCatalog()`
  - `Future<int> getPointsBalance()` (returns `points_balance`)
  - `Future<RewardRedemption> redeem({required int productId, required int quantity, required String shippingAddressId, String? notes})`
  - `Future<List<RewardRedemption>> getRedemptionHistory()`
  - Throws `RewardException(String message)` on `422` so the UI can surface the Thai backend message.

- [ ] **Step 1: Write the service**

`lib/services/reward_service.dart`:
```dart
import '../models/reward_product.dart';
import '../models/reward_redemption.dart';
import 'api_service.dart';

class RewardException implements Exception {
  final String message;
  RewardException(this.message);
  @override
  String toString() => message;
}

class RewardService {
  static final RewardService instance = RewardService._internal();
  RewardService._internal();

  Future<List<RewardProduct>> getRewardCatalog() async {
    final response = await ApiService.get('/reward-catalog');
    final data = ApiService.parseResponse(response);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((j) => RewardProduct.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw RewardException(data['message']?.toString() ?? 'โหลดของรางวัลไม่สำเร็จ');
  }

  Future<int> getPointsBalance() async {
    final response = await ApiService.get('/reward-points/balance');
    final data = ApiService.parseResponse(response);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data']['points_balance'] as num?)?.toInt() ?? 0;
    }
    throw RewardException(data['message']?.toString() ?? 'โหลดคะแนนไม่สำเร็จ');
  }

  Future<RewardRedemption> redeem({
    required int productId,
    required int quantity,
    required String shippingAddressId,
    String? notes,
  }) async {
    final response = await ApiService.post('/reward-redemptions', {
      'product_id': productId,
      'quantity': quantity,
      'shipping_address_id': int.tryParse(shippingAddressId) ?? shippingAddressId,
      if (notes != null) 'notes': notes,
    });
    final data = ApiService.parseResponse(response);
    if (response.statusCode == 201 && data['success'] == true) {
      return RewardRedemption.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw RewardException(data['message']?.toString() ?? 'แลกของรางวัลไม่สำเร็จ');
  }

  Future<List<RewardRedemption>> getRedemptionHistory() async {
    final response = await ApiService.get('/reward-redemptions');
    final data = ApiService.parseResponse(response);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((j) => RewardRedemption.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw RewardException(data['message']?.toString() ?? 'โหลดประวัติไม่สำเร็จ');
  }
}
```

- [ ] **Step 2: Analyze**

Run: `cd "/Users/janejiramalai/Downloads/project 2" && flutter analyze lib/services/reward_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add lib/services/reward_service.dart
git commit -m "feat(reward): add RewardService client for catalog/balance/redeem/history"
```

---

## Task 9: Wire `rewards_screen.dart` to real catalog + balance

**Files:**
- Modify: `lib/screens/rewards_screen.dart`

**Interfaces:**
- Consumes: `RewardService.instance.getRewardCatalog()`, `getPointsBalance()`, `RewardProduct`.

- [ ] **Step 1: Read the current screen**

Read `lib/screens/rewards_screen.dart` fully. Note: `_loadRewardProducts()` currently uses `ProductService.instance.getRewardProducts()`; the header points come from `ProfileService.instance.getMembershipProgress()` (`current_points`). The grid passes an item map to `RewardDetailScreen`.

- [ ] **Step 2: Swap the data source**

- Replace the catalog load with `RewardService.instance.getRewardCatalog()` → store `List<RewardProduct>`.
- Replace the header points value with `RewardService.instance.getPointsBalance()` (real, deducted balance). Keep the existing `total_spent`/`total_savings` header bits if desired (still from `getMembershipProgress`), but the "คะแนน" number must come from `getPointsBalance()`.
- In the grid card, when `product.image == null`, render `Icon(product.fallbackIcon, size: 48)` instead of a network image; otherwise render the image as before.
- Pass the `RewardProduct` (or its json) to `RewardDetailScreen` — see Task 10 for the constructor it now expects.

- [ ] **Step 3: Analyze**

Run: `cd "/Users/janejiramalai/Downloads/project 2" && flutter analyze lib/screens/rewards_screen.dart`
Expected: No issues (once Task 10's constructor matches).

- [ ] **Step 4: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add lib/screens/rewards_screen.dart
git commit -m "feat(reward): wire rewards screen to real catalog and points balance"
```

---

## Task 10: Redeem flow in `reward_detail_screen.dart` (bottom sheet)

**Files:**
- Modify: `lib/screens/reward_detail_screen.dart`

**Interfaces:**
- Consumes: `RewardProduct`, `RewardService.instance.redeem(...)`, `RewardService.instance.getPointsBalance()`, `AddressService.fetchAddresses()` → `List<CustomerAddress>`, `CustomerAddress` (`.id` is `String`).

- [ ] **Step 1: Read the current screen**

Read `lib/screens/reward_detail_screen.dart`. Currently: constructor takes `Map<String,dynamic> rewardItem`; `availablePoints = 1000000` (mock); `totalPoints = points * quantity`; `_handleExchange` shows a fake success dialog; renders `rewardItem['image']`.

- [ ] **Step 2: Replace mock balance with real balance**

- Change the field `final int availablePoints = 1000000;` to nullable state `int? availablePoints;` loaded in `initState` via `RewardService.instance.getPointsBalance()` (show a loader until it arrives; treat null as 0 for the `canExchange` guard).
- Render the reward image with the `fallbackIcon` fallback when no image (mirror Task 9).

- [ ] **Step 3: Replace `_handleExchange` with the real redeem bottom sheet**

Replace the stub. On tap, open a `showModalBottomSheet` that:
1. Loads addresses via `AddressService.fetchAddresses()`. If empty → show a message + button routing to the add-address screen (match how checkout routes there; read `checkout_screen.dart` for the exact screen/route), then return.
2. Lets the user pick one `CustomerAddress` (default preselected via the same default-address logic checkout uses: `AddressService.getDefaultAddress(addresses)` if present, else `addresses.first`).
3. Confirm button calls:
```dart
try {
  final redemption = await RewardService.instance.redeem(
    productId: product.id,
    quantity: quantity,
    shippingAddressId: selectedAddress.id,
    notes: null,
  );
  if (!mounted) return;
  Navigator.pop(context); // close sheet
  // refresh balance so the header reflects the deduction
  final newBalance = await RewardService.instance.getPointsBalance();
  setState(() => availablePoints = newBalance);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('แลกของรางวัลสำเร็จ 🎉')),
  );
} on RewardException catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```
(Import `RewardService`, `RewardException`, `AddressService`, `CustomerAddress`, and the `RewardProduct` type. Change the constructor to accept a `RewardProduct product` instead of the raw map, and update the call site in Task 9 accordingly. Keep the quantity selector and `maxQuantity` behavior.)

- [ ] **Step 4: Analyze**

Run: `cd "/Users/janejiramalai/Downloads/project 2" && flutter analyze lib/screens/reward_detail_screen.dart lib/screens/rewards_screen.dart`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add lib/screens/reward_detail_screen.dart lib/screens/rewards_screen.dart
git commit -m "feat(reward): real redeem flow with address bottom sheet and balance refresh"
```

---

## Task 11: Wire `reward_history_screen.dart` to real history

**Files:**
- Modify: `lib/screens/reward_history_screen.dart`

**Interfaces:**
- Consumes: `RewardService.instance.getRedemptionHistory()` → `List<RewardRedemption>`.

- [ ] **Step 1: Read the current screen**

Read `lib/screens/reward_history_screen.dart`. Currently a hard-coded `rewardHistory` list.

- [ ] **Step 2: Replace mock with real data**

- Convert to a `StatefulWidget` (if not already) that loads `RewardService.instance.getRedemptionHistory()` in `initState`.
- Show a loader while loading, an empty state ("ยังไม่มีประวัติการแลกรีวอร์ด") when the list is empty, and one card per `RewardRedemption` showing `productName`, `quantity`, `pointsTotal` ("ใช้ {pointsTotal} คะแนน"), `statusLabel`, and `trackingNumber` if present.
- On load error (`RewardException`), show a retry state.

- [ ] **Step 3: Analyze**

Run: `cd "/Users/janejiramalai/Downloads/project 2" && flutter analyze lib/screens/reward_history_screen.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add lib/screens/reward_history_screen.dart
git commit -m "feat(reward): wire reward history screen to real redemption history"
```

---

## Task 12: Full verification

**Files:** none (verification only).

- [ ] **Step 1: Backend test suite**

Run: `cd clinic-backend && php artisan test --filter=Reward`
Expected: all reward tests pass.

- [ ] **Step 2: Backend lint**

Run: `cd clinic-backend && ./vendor/bin/pint --test`
Expected: no style violations (or run without `--test` to auto-fix, then commit).

- [ ] **Step 3: Frontend analyze (whole reward surface)**

Run: `cd "/Users/janejiramalai/Downloads/project 2" && flutter analyze lib/screens/rewards_screen.dart lib/screens/reward_detail_screen.dart lib/screens/reward_history_screen.dart lib/services/reward_service.dart lib/models/reward_product.dart lib/models/reward_redemption.dart`
Expected: No issues.

- [ ] **Step 4: Manual smoke (optional, if a device/emulator + local API are available)**

`flutter run -d chrome --web-port=3000` with the local API on `:8000`. Log in, open the 5th tab, confirm real catalog + balance render, redeem a cheap item (picks address, deducts points, appears in history as รอดำเนินการ).

- [ ] **Step 5: Final commit if anything was auto-fixed**

```bash
cd "/Users/janejiramalai/Downloads/project 2"
git add -A && git commit -m "chore(reward): lint/format fixes" || echo "nothing to commit"
```
