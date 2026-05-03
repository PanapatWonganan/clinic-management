<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'test/*', 'sanctum/csrf-cookie', 'storage/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_values(array_filter([
        'https://exquillermember.com',
        'https://www.exquillermember.com',
        // Non-production-only dev origins. Why: with supports_credentials=true,
        // widening this on production lets any dev-tunneled site forge auth'd
        // requests using a logged-in user's browser session.
        env('APP_ENV') !== 'production' ? 'http://exquillermember.com' : null,
        env('APP_ENV') !== 'production' ? 'http://www.exquillermember.com' : null,
        env('APP_ENV') !== 'production' ? 'http://localhost:3000' : null,
        env('APP_ENV') !== 'production' ? 'http://127.0.0.1:3000' : null,
        env('APP_ENV') !== 'production' ? 'http://localhost:8080' : null,
        env('APP_ENV') !== 'production' ? 'http://127.0.0.1:8080' : null,
    ])),

    // Wildcard localhost pattern — non-production only.
    'allowed_origins_patterns' => env('APP_ENV') !== 'production'
        ? ['/^http:\/\/localhost:\d+$/', '/^http:\/\/127\.0\.0\.1:\d+$/']
        : [],

    'allowed_headers' => ['*'],

    'exposed_headers' => ['*'],

    'max_age' => 86400,

    'supports_credentials' => true,

];
