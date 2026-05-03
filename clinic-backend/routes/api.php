<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CustomerAddressController;
use App\Http\Controllers\DeliveryPriceController;
use App\Http\Controllers\FreeItemRedemptionController;
use App\Http\Controllers\MembershipPricingController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

// Authentication routes (rate-limited to deter brute force)
Route::middleware('throttle:10,1')->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/register', [AuthController::class, 'register']);
});
// Same throttle as login/register so a leaked token cannot be used to
// hammer the endpoint and revoke the user's other sessions in bulk.
Route::post('/auth/logout', [AuthController::class, 'logout'])
    ->middleware(['auth:sanctum', 'throttle:30,1']);

// Profile routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::get('/membership/progress', [ProfileController::class, 'getMembershipProgress']);
    Route::post('/membership/claim-reward', [ProfileController::class, 'claimReward']);

    // Free item redemption routes
    Route::get('/my-rewards', [FreeItemRedemptionController::class, 'myRewards']);
    Route::get('/my-rewards/{id}', [FreeItemRedemptionController::class, 'showReward']);
    Route::post('/redeem-free-items', [FreeItemRedemptionController::class, 'redeem']);
    Route::get('/redemption-history', [FreeItemRedemptionController::class, 'redemptionHistory']);
    Route::get('/redeemable-products', [FreeItemRedemptionController::class, 'availableProducts']);
});

// Custom Product endpoints (must come before apiResource)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/products/main', [\App\Http\Controllers\ProductController::class, 'getMainProducts']);
    Route::get('/products/rewards', [\App\Http\Controllers\ProductController::class, 'getRewardProducts']);
});

// Product routes
Route::get('/products', [ProductController::class, 'index']); // public list (membership pricing when authed)
Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::put('/products/{id}/stock', [\App\Http\Controllers\ProductController::class, 'updateStock']);
    Route::apiResource('products', ProductController::class)->except(['index']);
});

// Order routes (protected by authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::put('/orders/{id}/cancel', [OrderController::class, 'cancel']);

    // Payment slip routes
    Route::post('/payment-slips/upload', [\App\Http\Controllers\PaymentSlipController::class, 'uploadSlips']);
    Route::get('/orders/{orderId}/payment-slips', [\App\Http\Controllers\PaymentSlipController::class, 'getSlips']);
    Route::delete('/payment-slips/{slipId}', [\App\Http\Controllers\PaymentSlipController::class, 'deleteSlip']);

    // Customer address routes
    Route::apiResource('addresses', CustomerAddressController::class);
    Route::put('/addresses/{id}/set-default', [CustomerAddressController::class, 'setDefault']);

    // PaySolutions payment routes (rate-limited to prevent abuse / duplicate charges)
    Route::middleware('throttle:20,1')->group(function () {
        Route::post('/payment/create', [PaymentController::class, 'createPayment']);
        Route::get('/payment/status/{paymentId}', [PaymentController::class, 'checkStatus']);
        Route::post('/payment/verify/{paymentId}', [PaymentController::class, 'verifyAndUpdatePayment']);
    });
});

// Customer routes (admin only)
Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::apiResource('customers', \App\Http\Controllers\Admin\CustomerController::class);
    Route::get('/customers-stats', [\App\Http\Controllers\Admin\CustomerController::class, 'stats']);
    Route::get('/admin/customers/{id}/addresses', [\App\Http\Controllers\Admin\CustomerController::class, 'getAddresses']);
});

// Delivery price routes
Route::prefix('delivery')->group(function () {
    // Bangkok districts (แขวง)
    Route::get('/districts', [DeliveryPriceController::class, 'getAvailableDistricts']);
    Route::get('/options/{districtName}', [DeliveryPriceController::class, 'getDeliveryOptions']);
    Route::post('/price', [DeliveryPriceController::class, 'getDeliveryPrice']);

    // Suburban provinces (ปริมณฑล)
    Route::get('/provinces', [DeliveryPriceController::class, 'getAvailableProvinces']);
    Route::get('/provinces/{provinceName}/districts', [DeliveryPriceController::class, 'getDistrictsByProvince']);
    Route::get('/provinces/{provinceName}/districts/{districtName}/options', [DeliveryPriceController::class, 'getDeliveryOptionsByProvince']);

    // Unified search (ค้นหารวม)
    Route::post('/unified-options', [DeliveryPriceController::class, 'getUnifiedDeliveryOptions']);
});

// Membership pricing routes
Route::prefix('membership')->group(function () {
    Route::get('/roles', [MembershipPricingController::class, 'getRoles']);
    Route::get('/roles/{roleId}/bundle-deals', [MembershipPricingController::class, 'getRoleBundleDeals']);
    Route::get('/roles/{roleId}/pricing-tiers', [MembershipPricingController::class, 'getPricingTiers']);
    Route::post('/calculate-pricing', [MembershipPricingController::class, 'calculatePricing']);
});

// Serve storage files with CORS headers (workaround for Laravel serve)
Route::get('/storage/{path}', function (string $path) {
    $publicDir = realpath(storage_path('app/public'));
    $filePath = realpath(storage_path('app/public/'.$path));

    // Reject if resolution failed or path escapes the public storage dir
    if (! $publicDir || ! $filePath || ! str_starts_with($filePath, $publicDir.DIRECTORY_SEPARATOR)) {
        abort(404);
    }

    if (is_dir($filePath)) {
        abort(404);
    }

    return response()->file($filePath, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
    ]);
})->where('path', '.*');

// Payment callback (webhook) - no auth required
Route::post('/payment/callback', [PaymentController::class, 'handleCallback']);

// Test payment simulation — only exposed outside production
if (! app()->environment('production')) {
    Route::post('/payment/simulate', [PaymentController::class, 'simulatePayment']);
    Route::get('/test', function () {
        return response()->json(['message' => 'API is working!', 'timestamp' => now()]);
    });
}
