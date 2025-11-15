<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class PaySolutionsService
{
    protected $apiKey;
    protected $secretKey;
    protected $merchantId;
    protected $apiUrl;
    protected $paymentUrl;
    protected $testMode;

    public function __construct()
    {
        $this->testMode = config('paysolutions.test_mode');
        $this->apiKey = config('paysolutions.api_key');
        $this->secretKey = config('paysolutions.secret_key');
        $this->merchantId = config('paysolutions.merchant_id');

        // Use test URLs if in test mode
        $this->apiUrl = $this->testMode
            ? config('paysolutions.test_api_url')
            : config('paysolutions.api_url');

        $this->paymentUrl = $this->testMode
            ? config('paysolutions.test_payment_url')
            : config('paysolutions.payment_url');
    }

    /**
     * Get API headers for authentication
     */
    protected function getHeaders(): array
    {
        return [
            'apikey' => $this->apiKey,
            'secretkey' => $this->secretKey,
            'merchantId' => $this->merchantId,
            'Content-Type' => 'application/json',
        ];
    }

    /**
     * Create payment transaction
     */
    public function createPayment(array $paymentData): array
    {
        try {
            // Test mode: return mock response
            if ($this->testMode) {
                return $this->mockCreatePayment($paymentData);
            }

            $response = Http::withHeaders($this->getHeaders())
                ->post($this->apiUrl . '/order/orderdetailpost', $paymentData);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $response->json(),
                ];
            }

            Log::error('PaySolutions payment creation failed', [
                'response' => $response->json(),
                'status' => $response->status(),
            ]);

            return [
                'success' => false,
                'message' => 'Failed to create payment',
                'error' => $response->json(),
            ];

        } catch (Exception $e) {
            Log::error('PaySolutions API error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return [
                'success' => false,
                'message' => 'Payment service error: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Generate payment URL
     */
    public function generatePaymentUrl(string $orderId, float $amount, array $options = []): string
    {
        $params = [
            'merchantId' => $this->merchantId,
            'orderId' => $orderId,
            'amount' => number_format($amount, 2, '.', ''),
            'currency' => config('paysolutions.currency'),
            'language' => config('paysolutions.language'),
            'callbackUrl' => config('paysolutions.callback_url'),
            'returnUrl' => config('paysolutions.return_url'),
            'cancelUrl' => config('paysolutions.cancel_url'),
        ];

        // Add optional parameters
        $params = array_merge($params, $options);

        // Generate signature
        $params['signature'] = $this->generateSignature($params);

        // Test mode: return test URL
        if ($this->testMode) {
            $queryString = http_build_query($params);
            return route('payment.test', ['order_id' => $orderId]) . '?' . $queryString;
        }

        $queryString = http_build_query($params);
        return $this->paymentUrl . '?' . $queryString;
    }

    /**
     * Generate signature for payment request
     */
    protected function generateSignature(array $params): string
    {
        // Sort parameters
        ksort($params);

        // Create string to sign
        $stringToSign = '';
        foreach ($params as $key => $value) {
            if ($key !== 'signature') {
                $stringToSign .= $key . '=' . $value . '&';
            }
        }
        $stringToSign = rtrim($stringToSign, '&');

        // Add secret key
        $stringToSign .= $this->secretKey;

        // Generate hash
        return hash('sha256', $stringToSign);
    }

    /**
     * Verify callback signature
     */
    public function verifyCallback(array $callbackData): bool
    {
        if (!isset($callbackData['signature'])) {
            return false;
        }

        $receivedSignature = $callbackData['signature'];
        unset($callbackData['signature']);

        $calculatedSignature = $this->generateSignature($callbackData);

        return hash_equals($calculatedSignature, $receivedSignature);
    }

    /**
     * Get payment status
     */
    public function getPaymentStatus(string $transactionId): array
    {
        try {
            // Test mode: return mock status
            if ($this->testMode) {
                return $this->mockGetPaymentStatus($transactionId);
            }

            $response = Http::withHeaders($this->getHeaders())
                ->get($this->apiUrl . '/order/status/' . $transactionId);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $response->json(),
                ];
            }

            return [
                'success' => false,
                'message' => 'Failed to get payment status',
            ];

        } catch (Exception $e) {
            Log::error('PaySolutions get status error', [
                'message' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => 'Error getting payment status',
            ];
        }
    }

    /**
     * Mock create payment for test mode
     */
    protected function mockCreatePayment(array $paymentData): array
    {
        return [
            'success' => true,
            'data' => [
                'transaction_id' => 'TEST_' . uniqid(),
                'order_id' => $paymentData['order_id'] ?? uniqid(),
                'amount' => $paymentData['amount'] ?? 0,
                'currency' => 'THB',
                'status' => 'pending',
                'payment_url' => route('payment.test', ['order_id' => $paymentData['order_id'] ?? uniqid()]),
                'created_at' => now()->toDateTimeString(),
            ],
        ];
    }

    /**
     * Mock get payment status for test mode
     */
    protected function mockGetPaymentStatus(string $transactionId): array
    {
        return [
            'success' => true,
            'data' => [
                'transaction_id' => $transactionId,
                'status' => 'success',
                'paid_at' => now()->toDateTimeString(),
            ],
        ];
    }

    /**
     * Check if in test mode
     */
    public function isTestMode(): bool
    {
        return $this->testMode;
    }
}
