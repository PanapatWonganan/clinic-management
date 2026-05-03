<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Membership Pricing
    |--------------------------------------------------------------------------
    |
    | Per-membership-tier overrides for the main product price. Used to be
    | hard-coded as 850 in two places inside ProductController; pulling the
    | value here gives us a single source of truth and lets ops change the
    | doctor price without a code redeploy.
    |
    */
    'main_product_price_overrides' => [
        'exDoctor' => env('EXDOCTOR_MAIN_PRODUCT_PRICE', 850.00),
    ],
];
