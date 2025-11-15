<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Role;
use App\Models\MembershipBundleDeal;

class MembershipPricingController extends Controller
{
    /**
     * Get all membership roles with their bundle deals
     */
    public function getRoles()
    {
        try {
            $roles = Role::with(['activeBundleDeals' => function ($query) {
                $query->orderBy('level');
            }])->where('is_active', true)->orderBy('level')->get();

            return response()->json([
                'success' => true,
                'data' => $roles,
                'message' => 'Membership roles retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve membership roles',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get bundle deals for specific role
     */
    public function getRoleBundleDeals($roleId)
    {
        try {
            $role = Role::with(['activeBundleDeals' => function ($query) {
                $query->orderBy('level');
            }])->find($roleId);

            if (!$role) {
                return response()->json([
                    'success' => false,
                    'message' => 'Role not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'role' => $role,
                    'bundle_deals' => $role->activeBundleDeals
                ],
                'message' => 'Bundle deals retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve bundle deals',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculate pricing for given quantity and role
     */
    public function calculatePricing(Request $request)
    {
        $request->validate([
            'role_id' => 'required|exists:roles,id',
            'quantity' => 'required|integer|min:1'
        ]);

        try {
            $roleId = $request->role_id;
            $quantity = $request->quantity;

            $role = Role::find($roleId);
            $calculation = MembershipBundleDeal::calculateBestDeal($roleId, $quantity);

            if (!$calculation) {
                // No bundle deal available, use regular pricing
                $unitPrice = 2500.00; // Default unit price
                $totalPrice = $quantity * $unitPrice;

                return response()->json([
                    'success' => true,
                    'data' => [
                        'role' => $role,
                        'quantity' => $quantity,
                        'unit_price' => $unitPrice,
                        'total_price' => $totalPrice,
                        'total_savings' => 0,
                        'has_bundle_deal' => false,
                        'message' => 'Regular pricing applied - no bundle deals available'
                    ]
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'role' => $role,
                    'quantity' => $quantity,
                    'bundle_calculation' => $calculation,
                    'has_bundle_deal' => true,
                    'summary' => [
                        'total_items_received' => $calculation['total_paid_items'] + $calculation['total_free_items'] + $calculation['remaining_items'],
                        'total_paid_items' => $calculation['total_paid_items'] + $calculation['remaining_items'],
                        'total_free_items' => $calculation['total_free_items'],
                        'total_price' => $calculation['total_price'],
                        'total_savings' => $calculation['total_savings'],
                        'bundles_applied' => $calculation['bundles_count'],
                        'bundle_deal' => $calculation['bundle_deal']->display_name,
                    ]
                ],
                'message' => 'Pricing calculated with bundle deals'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to calculate pricing',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get pricing tiers for home page display
     */
    public function getPricingTiers($roleId)
    {
        try {
            $role = Role::with(['activeBundleDeals' => function ($query) {
                $query->orderBy('level');
            }])->find($roleId);

            if (!$role) {
                return response()->json([
                    'success' => false,
                    'message' => 'Role not found'
                ], 404);
            }

            // Format for home page display (3 levels)
            $tiers = $role->activeBundleDeals->map(function ($deal) {
                return [
                    'id' => $deal->id,
                    'level' => $deal->level,
                    'name' => $deal->display_name,
                    'description' => $deal->description,
                    'required_quantity' => $deal->required_quantity,
                    'free_quantity' => $deal->free_quantity,
                    'total_quantity' => $deal->total_quantity,
                    'price' => $deal->total_price,
                    'original_value' => $deal->total_value,
                    'savings' => $deal->savings_amount,
                    'savings_percentage' => $deal->savings_percentage,
                    'unit_price' => $deal->unit_price,
                    'effective_price_per_unit' => $deal->effective_price_per_unit,
                    'badge_text' => $deal->level == 3 ? 'BEST VALUE' : ($deal->level == 2 ? 'POPULAR' : 'STARTER'),
                    'highlight' => $deal->level == 2, // Highlight level 2 as popular
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'role' => [
                        'id' => $role->id,
                        'name' => $role->name,
                        'display_name' => $role->display_name,
                        'description' => $role->description,
                    ],
                    'pricing_tiers' => $tiers,
                    'currency' => 'THB',
                    'unit_name' => 'กล่อง'
                ],
                'message' => 'Pricing tiers retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve pricing tiers',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
