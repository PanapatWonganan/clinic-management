<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Services\TelegramService;
use App\Http\Controllers\Admin\CustomerController as AdminCustomerController;
use App\Http\Controllers\Admin\ProductController as AdminProductController;
use App\Http\Controllers\Admin\OrderController as AdminOrderController;
use App\Http\Controllers\Admin\AppointmentController as AdminAppointmentController;
use App\Http\Controllers\Admin\ReportController as AdminReportController;
use App\Http\Controllers\Admin\AddressController as AdminAddressController;
use App\Http\Controllers\Admin\RewardController as AdminRewardController;
use App\Http\Controllers\PaymentController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test', function () {
    return '<h1 style="color: red; text-align: center; margin-top: 50px; font-family: Arial;">🎯 TEST WORKS!</h1>';
});

// Serve storage files with CORS headers
Route::get('/storage/{path}', function ($path) {
    $filePath = storage_path('app/public/' . $path);

    if (!file_exists($filePath)) {
        abort(404);
    }

    $file = file_get_contents($filePath);
    $mimeType = mime_content_type($filePath);

    return response($file)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
})->where('path', '.*');

Route::get('/products', function () {
    return response()->json(\App\Models\Product::all());
});

// Admin routes
Route::prefix('admin')->group(function () {
    // Login routes (accessible to all)
    Route::get('/login', function () {
        return view('admin.auth.login');
    })->name('admin.login');
    
    Route::post('/login', [AdminAuthController::class, 'login'])
        ->name('admin.login.post');
    
    // Protected admin routes
    Route::middleware(['auth', 'admin'])->group(function () {
        Route::get('/dashboard', [AdminDashboardController::class, 'index'])
            ->name('admin.dashboard');
        
        Route::get('/dashboard/activities', [AdminDashboardController::class, 'getActivities'])
            ->name('admin.dashboard.activities');
        
        Route::get('/dashboard/sales-data', [AdminDashboardController::class, 'getSalesData'])
            ->name('admin.dashboard.sales-data');
        
        Route::get('/dashboard/available-years', [AdminDashboardController::class, 'getAvailableYears'])
            ->name('admin.dashboard.available-years');
        
        Route::post('/logout', [AdminAuthController::class, 'logout'])
            ->name('admin.logout');
        
        Route::get('/export', [AdminAuthController::class, 'export'])
            ->name('admin.export');
        
        // Customer management routes
        Route::prefix('customers')->name('admin.customers.')->group(function () {
            Route::get('/', [AdminCustomerController::class, 'index'])->name('index');
            Route::post('/', [AdminCustomerController::class, 'store'])->name('store');
            Route::get('/{id}', [AdminCustomerController::class, 'show'])->name('show');
            Route::put('/{id}', [AdminCustomerController::class, 'update'])->name('update');
            Route::delete('/{id}', [AdminCustomerController::class, 'destroy'])->name('destroy');
            Route::get('/stats/data', [AdminCustomerController::class, 'stats'])->name('stats');
            // Membership routes
            Route::get('/membership/types', [AdminCustomerController::class, 'getMembershipTypes'])->name('membership.types');
            Route::put('/{id}/membership', [AdminCustomerController::class, 'updateMembership'])->name('membership.update');
            Route::get('/membership/stats', [AdminCustomerController::class, 'getMembershipStats'])->name('membership.stats');
        });
        
        // Product management routes
        Route::prefix('products')->name('admin.products.')->group(function () {
            Route::get('/', [AdminProductController::class, 'index'])->name('index');
            Route::post('/', [AdminProductController::class, 'store'])->name('store');
            Route::get('/{id}/data', [AdminProductController::class, 'show'])->name('show');
            Route::put('/{id}', [AdminProductController::class, 'update'])->name('update');
            Route::delete('/{id}', [AdminProductController::class, 'destroy'])->name('destroy');
            Route::get('/stats/data', [AdminProductController::class, 'stats'])->name('stats');
        });

        // Order management routes
        Route::prefix('orders')->name('admin.orders.')->group(function () {
            Route::get('/', [AdminOrderController::class, 'index'])->name('index');
            Route::get('/{id}', [AdminOrderController::class, 'show'])->name('show');
            Route::put('/{id}/status', [AdminOrderController::class, 'updateStatus'])->name('update.status');
            Route::delete('/{id}', [AdminOrderController::class, 'destroy'])->name('destroy');
            Route::get('/stats/data', [AdminOrderController::class, 'stats'])->name('stats');
            
            // Delivery proof routes
            Route::post('/{id}/delivery-proof', [AdminOrderController::class, 'uploadDeliveryProof'])->name('delivery-proof.upload');
            Route::delete('/{id}/delivery-proof', [AdminOrderController::class, 'deleteDeliveryProof'])->name('delivery-proof.delete');
        });

        // Appointment management routes
        Route::prefix('appointments')->name('admin.appointments.')->group(function () {
            Route::get('/', [AdminAppointmentController::class, 'index'])->name('index');
            Route::post('/', [AdminAppointmentController::class, 'store'])->name('store');
            Route::get('/{id}', [AdminAppointmentController::class, 'show'])->name('show');
            Route::put('/{id}', [AdminAppointmentController::class, 'update'])->name('update');
            Route::delete('/{id}', [AdminAppointmentController::class, 'destroy'])->name('destroy');
        });

        // Reports routes
        Route::prefix('reports')->name('admin.reports.')->group(function () {
            Route::get('/', [AdminReportController::class, 'index'])->name('index');
            Route::get('/revenue', [AdminReportController::class, 'revenue'])->name('revenue');
            Route::get('/customers', [AdminReportController::class, 'customers'])->name('customers');
            Route::get('/products', [AdminReportController::class, 'products'])->name('products');
        });

        // Settings route
        Route::get('/settings', function () {
            return view('admin.settings');
        })->name('admin.settings');

        // Address API routes
        Route::prefix('api/address')->name('admin.address.')->group(function () {
            Route::get('/provinces', [AdminAddressController::class, 'provinces'])->name('provinces');
            Route::get('/districts/{province_id}', [AdminAddressController::class, 'districts'])->name('districts');
            Route::get('/sub-districts/{district_id}', [AdminAddressController::class, 'subDistricts'])->name('subDistricts');
            Route::get('/full-address', [AdminAddressController::class, 'getFullAddress'])->name('fullAddress');
        });

        // Payment slip management routes
        Route::prefix('payment-slips')->name('admin.payment-slips.')->group(function () {
            Route::get('/', function() {
                return view('admin.payment_slips');
            })->name('index');
            Route::get('/api', [\App\Http\Controllers\PaymentSlipController::class, 'adminIndex'])->name('api.index');
            Route::put('/{slipId}/status', [\App\Http\Controllers\PaymentSlipController::class, 'adminUpdateStatus'])->name('update.status');
        });

        // Reward management routes
        Route::prefix('rewards')->name('admin.rewards.')->group(function () {
            Route::get('/', [AdminRewardController::class, 'index'])->name('index');
            Route::get('/{id}', [AdminRewardController::class, 'show'])->name('show');
            Route::put('/{id}/status', [AdminRewardController::class, 'updateStatus'])->name('update.status');
            Route::delete('/{id}', [AdminRewardController::class, 'destroy'])->name('destroy');
            Route::get('/stats/data', [AdminRewardController::class, 'stats'])->name('stats');
        });
    });
});

// Legacy routes
Route::get('/admin-test', function () {
    return view('admin-dashboard');
});

Route::get('/admin', function () {
    return redirect()->route('admin.login');
});

// Test address API (temporarily public for debugging)
Route::prefix('test/address')->group(function () {
    Route::get('/provinces', [AdminAddressController::class, 'provinces']);
    Route::get('/districts/{province_id}', [AdminAddressController::class, 'districts']);
    Route::get('/sub-districts/{district_id}', [AdminAddressController::class, 'subDistricts']);
    Route::get('/district/{id}', [AdminAddressController::class, 'getDistrictById']);
    Route::get('/subdistrict/{id}', [AdminAddressController::class, 'getSubDistrictById']);
});


// Telegram test route
Route::get('/telegram/test', function () {
    $telegramService = new TelegramService();
    $result = $telegramService->testConnection();

    return response()->json($result);
})->name('telegram.test');

// Test payment page (only in test mode)
Route::get('/payment/test/{order_id}', [PaymentController::class, 'testPaymentPage'])->name('payment.test');
