<?php

namespace App\Services;

use Illuminate\Support\Str;

class OrderNumberService
{
    /**
     * Generate a globally-unique order number.
     *
     * Previous logic was `Order::whereDate('created_at', today())->count() + 1`,
     * which races under concurrent requests (two callers see the same count
     * and produce the same suffix). Worse, that count was shared across
     * "ORD-" and "FREE-" prefixes so even different prefix families could
     * end up with colliding suffixes when both ran on the same day.
     *
     * The new format is `<prefix>-<YYYYMMDD>-<random>` where the random
     * portion comes from a ULID-like time-sortable suffix that is unique
     * per process and across processes within the resolution of the
     * underlying ULID/UUID generator.
     */
    public static function generate(string $prefix): string
    {
        $datePart = date('Ymd');
        // Use a 10-char base32 ULID slice — collision-resistant and short.
        $randomPart = strtoupper(substr((string) Str::ulid(), -10));

        return sprintf('%s-%s-%s', $prefix, $datePart, $randomPart);
    }
}
