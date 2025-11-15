<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\PatientController;
use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\CustomerAddressController;
use App\Http\Controllers\DeliveryPriceController;
use App\Http\Controllers\MembershipPricingController;
use App\Http\Controllers\PaymentController;

// Authentication routes
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

// Profile routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::get('/membership/progress', [ProfileController::class, 'getMembershipProgress']);
    Route::post('/membership/claim-reward', [ProfileController::class, 'claimReward']);
});

// Patient routes
Route::apiResource('patients', PatientController::class);

// Appointment routes  
Route::apiResource('appointments', AppointmentController::class);

// Custom Product endpoints (must come before apiResource)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/products/main', [\App\Http\Controllers\ProductController::class, 'getMainProducts']);
    Route::get('/products/rewards', [\App\Http\Controllers\ProductController::class, 'getRewardProducts']);
});
Route::put('/products/{id}/stock', [\App\Http\Controllers\ProductController::class, 'updateStock']);

// Product routes (auth is optional for membership pricing)
Route::get('/products', [ProductController::class, 'index']);
Route::apiResource('products', ProductController::class)->except(['index']);

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

    // PaySolutions payment routes
    Route::post('/payment/create', [PaymentController::class, 'createPayment']);
    Route::get('/payment/status/{paymentId}', [PaymentController::class, 'checkStatus']);
});

// Cart routes
Route::prefix('cart')->group(function () {
    Route::get('/', [CartController::class, 'index']);
    Route::post('/add', [CartController::class, 'addItem']);
    Route::put('/update/{item}', [CartController::class, 'updateItem']);
    Route::delete('/remove/{item}', [CartController::class, 'removeItem']);
    Route::delete('/clear', [CartController::class, 'clear']);
});

// Customer routes
Route::apiResource('customers', \App\Http\Controllers\Admin\CustomerController::class);
Route::get('/customers-stats', [\App\Http\Controllers\Admin\CustomerController::class, 'stats']);

// Admin customer addresses route
Route::get('/admin/customers/{id}/addresses', [\App\Http\Controllers\Admin\CustomerController::class, 'getAddresses']);

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
Route::get('/storage/{path}', function (Illuminate\Http\Request $request) {
    // Get the full path after /api/storage/
    $fullPath = $request->path();
    $path = str_replace('api/storage/', '', $fullPath);

    $filePath = storage_path('app/public/' . $path);

    if (!file_exists($filePath)) {
        abort(404, 'File not found: ' . $path);
    }

    if (is_dir($filePath)) {
        abort(404, 'Path is a directory: ' . $path);
    }

    $file = file_get_contents($filePath);
    $mimeType = mime_content_type($filePath);

    return response($file)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
})->where('path', '.*');

// Payment callback (webhook) - no auth required
Route::post('/payment/callback', [PaymentController::class, 'handleCallback']);

// Test payment simulation routes (only available in test mode)
Route::post('/payment/simulate', [PaymentController::class, 'simulatePayment']);

// Test route
Route::get('/test', function () {
    return response()->json(['message' => 'API is working!', 'timestamp' => now()]);
});
