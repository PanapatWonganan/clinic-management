<?php

namespace Tests\Feature;

use App\Services\OrderNumberService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderNumberUniquenessTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug C2: count()+1 was used to generate order numbers, which races
     * under concurrency. The new generator must produce unique values
     * even when called many times in tight succession.
     */
    public function test_order_numbers_are_unique_across_many_calls(): void
    {
        $seen = [];
        for ($i = 0; $i < 200; $i++) {
            $n = OrderNumberService::generate('ORD');
            $this->assertArrayNotHasKey($n, $seen, "duplicate order number $n at iter $i");
            $seen[$n] = true;
        }
    }

    public function test_order_number_uses_provided_prefix(): void
    {
        $n = OrderNumberService::generate('FREE');
        $this->assertStringStartsWith('FREE-', $n);
    }

    public function test_free_and_regular_prefixes_do_not_collide(): void
    {
        $regular = [];
        $free = [];
        for ($i = 0; $i < 50; $i++) {
            $regular[] = OrderNumberService::generate('ORD');
            $free[] = OrderNumberService::generate('FREE');
        }
        $this->assertSame(50, count(array_unique($regular)));
        $this->assertSame(50, count(array_unique($free)));
        $this->assertEmpty(array_intersect($regular, $free));
    }
}
