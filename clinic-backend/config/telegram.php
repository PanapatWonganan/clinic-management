<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Telegram Bot Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for Telegram Bot API integration
    |
    */

    'bot_token' => env('TELEGRAM_BOT_TOKEN'),
    
    'chat_id' => env('TELEGRAM_CHAT_ID'),
    
    'notifications' => [
        'new_order' => env('TELEGRAM_NOTIFY_NEW_ORDER', true),
        'status_update' => env('TELEGRAM_NOTIFY_STATUS_UPDATE', true),
        'payment_slip' => env('TELEGRAM_NOTIFY_PAYMENT_SLIP', true),
        'payment_success' => env('TELEGRAM_NOTIFY_PAYMENT_SUCCESS', true),
        'daily_sales_report' => env('TELEGRAM_NOTIFY_DAILY_SALES', true),
        'low_stock' => env('TELEGRAM_NOTIFY_LOW_STOCK', true),
    ],
    
    'timeout' => env('TELEGRAM_TIMEOUT', 10),
    
    'low_stock_threshold' => env('TELEGRAM_LOW_STOCK_THRESHOLD', 5),
    
    'webhook' => [
        'enabled' => env('TELEGRAM_WEBHOOK_ENABLED', false),
        'url' => env('TELEGRAM_WEBHOOK_URL'),
    ],
];