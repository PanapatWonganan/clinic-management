<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class StockService
{
    /**
     * Atomically decrement product stock.
     *
     * Uses a single conditional UPDATE so that two concurrent callers cannot
     * both pass a "stock >= qty" check and then double-spend the row. The
     * UPDATE only matches if there is still enough stock; the affected-row
     * count tells us whether we won the race.
     *
     * Returns true on success, false if there wasn't enough stock.
     */
    public static function tryDecrement(int $productId, int $quantity): bool
    {
        if ($quantity <= 0) {
            return true;
        }

        $affected = DB::table('products')
            ->where('id', $productId)
            ->where('stock', '>=', $quantity)
            ->update([
                'stock' => DB::raw('stock - '.(int) $quantity),
                'updated_at' => now(),
            ]);

        return $affected > 0;
    }

    /**
     * Atomically increment stock back (e.g. on cancellation).
     */
    public static function increment(int $productId, int $quantity): void
    {
        if ($quantity <= 0) {
            return;
        }

        DB::table('products')
            ->where('id', $productId)
            ->update([
                'stock' => DB::raw('stock + '.(int) $quantity),
                'updated_at' => now(),
            ]);
    }
}
