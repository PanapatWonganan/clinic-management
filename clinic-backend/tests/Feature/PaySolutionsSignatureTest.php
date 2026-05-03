<?php

namespace Tests\Feature;

use App\Services\PaySolutionsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaySolutionsSignatureTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug H3: generatePaymentUrl previously emitted no signature even though
     * verifyCallback expected one. The two halves were inconsistent. The fix
     * makes generatePaymentUrl include a signature derived from the same
     * ksort+secret scheme that verifyCallback uses, so a legitimate callback
     * produced from the URL we emitted will validate, and a tampered one
     * won't.
     */
    public function test_generated_payment_url_includes_signature(): void
    {
        config(['paysolutions.test_mode' => false]);
        config(['paysolutions.secret_key' => 'secret-xyz']);
        config(['paysolutions.merchant_id' => '12345678']);

        $svc = new PaySolutionsService;
        $url = $svc->generatePaymentUrl('ORD-1', 200.00, [
            'customerEmail' => 'a@b.com',
            'productName' => 'thing',
        ]);

        parse_str(parse_url($url, PHP_URL_QUERY), $params);
        $this->assertArrayHasKey('signature', $params);
        $this->assertNotEmpty($params['signature']);
    }

    public function test_callback_signature_round_trips(): void
    {
        config(['paysolutions.test_mode' => false]);
        config(['paysolutions.secret_key' => 'secret-xyz']);
        config(['paysolutions.merchant_id' => '12345678']);

        $svc = new PaySolutionsService;
        $url = $svc->generatePaymentUrl('ORD-2', 500.00, [
            'customerEmail' => 'a@b.com',
            'productName' => 'thing',
        ]);
        parse_str(parse_url($url, PHP_URL_QUERY), $params);

        $this->assertTrue($svc->verifyCallback($params));

        // Tamper the amount and the signature should fail.
        $tampered = $params;
        $tampered['total'] = 1;
        $this->assertFalse($svc->verifyCallback($tampered));
    }

    public function test_verify_callback_rejects_missing_signature(): void
    {
        $svc = new PaySolutionsService;
        $this->assertFalse($svc->verifyCallback(['order_id' => 'X', 'status' => 'success']));
    }
}
