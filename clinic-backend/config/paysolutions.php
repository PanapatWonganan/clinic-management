<?php

return [
    /*
    |--------------------------------------------------------------------------
    | PaySolutions Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for PaySolutions Payment Gateway
    |
    */

    // Test mode (true = sandbox, false = production)
    'test_mode' => env('PAYSOLUTIONS_TEST_MODE', true),

    // API Credentials
    'api_key' => env('PAYSOLUTIONS_API_KEY', 'test_api_key'),
    'secret_key' => env('PAYSOLUTIONS_SECRET_KEY', 'test_secret_key'),
    'merchant_id' => env('PAYSOLUTIONS_MERCHANT_ID', 'test_merchant_id'),

    // API URLs
    'api_url' => env('PAYSOLUTIONS_API_URL', 'https://apis.paysolutions.asia'),
    'payment_url' => env('PAYSOLUTIONS_PAYMENT_URL', 'https://www.thaiepay.com/epaylink/payment.aspx'),

    // Callback URLs
    'callback_url' => env('PAYSOLUTIONS_CALLBACK_URL', env('APP_URL') . '/api/payment/callback'),
    'return_url' => env('PAYSOLUTIONS_RETURN_URL', env('APP_URL') . '/payment/success'),
    'cancel_url' => env('PAYSOLUTIONS_CANCEL_URL', env('APP_URL') . '/payment/cancel'),

    // Payment Settings
    'currency' => env('PAYSOLUTIONS_CURRENCY', 'THB'),
    'language' => env('PAYSOLUTIONS_LANGUAGE', 'TH'),

    // Test Mode Settings
    'test_api_url' => 'https://sandbox.apis.paysolutions.asia',
    'test_payment_url' => 'https://sandbox.thaiepay.com/epaylink/payment.aspx',

    // Payment Methods
    'payment_methods' => [
        'credit_card' => 'Credit/Debit Card',
        'promptpay' => 'PromptPay',
        'qr_code' => 'QR Code',
        'internet_banking' => 'Internet Banking',
    ],

    // Transaction timeout (in minutes)
    'timeout' => env('PAYSOLUTIONS_TIMEOUT', 30),
];
