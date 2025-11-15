<?php

namespace App\Http\Controllers;

use App\Models\CustomerAddress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class CustomerAddressController extends Controller
{
    /**
     * Display a listing of user's addresses
     */
    public function index()
    {
        try {
            $user = Auth::user();
            $addresses = $user->getAllAddresses();

            return response()->json([
                'success' => true,
                'data' => $addresses,
                'message' => 'Addresses retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving addresses: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created address
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        
        // Check address limit (max 3)
        $addressCount = $user->customerAddresses()->count();
        if ($addressCount >= 3) {
            return response()->json([
                'success' => false,
                'message' => 'คุณสามารถเพิ่มที่อยู่ได้สูงสุด 3 แห่งเท่านั้น'
            ], 422);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'recipient_name' => 'required|string|max:100',
            'phone' => 'required|string|max:20',
            'address_line_1' => 'required|string',
            'address_line_2' => 'nullable|string',
            'district' => 'required|string|max:100',
            'province' => 'required|string|max:100',
            'postal_code' => 'required|string|max:10',
            'province_id' => 'required|integer',
            'district_id' => 'required|integer',
            'sub_district_id' => 'required|integer',
            'is_default' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $addressData = $validator->validated();
            
            // If this is the first address or explicitly set as default, make it default
            $isDefault = $request->boolean('is_default') || $addressCount === 0;
            
            if ($isDefault) {
                $address = CustomerAddress::createDefault($user->id, $addressData);
            } else {
                $address = CustomerAddress::create(array_merge($addressData, [
                    'user_id' => $user->id,
                    'is_default' => false
                ]));
            }

            return response()->json([
                'success' => true,
                'data' => $address,
                'message' => 'Address created successfully'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error creating address: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified address
     */
    public function show($id)
    {
        try {
            $user = Auth::user();
            $address = CustomerAddress::where('id', $id)
                ->where('user_id', $user->id)
                ->firstOrFail();

            return response()->json([
                'success' => true,
                'data' => $address
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Address not found'
            ], 404);
        }
    }

    /**
     * Update the specified address
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'recipient_name' => 'required|string|max:100',
            'phone' => 'required|string|max:20',
            'address_line_1' => 'required|string',
            'address_line_2' => 'nullable|string',
            'district' => 'required|string|max:100',
            'province' => 'required|string|max:100',
            'postal_code' => 'required|string|max:10',
            'province_id' => 'required|integer',
            'district_id' => 'required|integer',
            'sub_district_id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = Auth::user();
            $address = CustomerAddress::where('id', $id)
                ->where('user_id', $user->id)
                ->firstOrFail();

            $address->update($validator->validated());

            return response()->json([
                'success' => true,
                'data' => $address,
                'message' => 'Address updated successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating address: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified address
     */
    public function destroy($id)
    {
        try {
            $user = Auth::user();
            $address = CustomerAddress::where('id', $id)
                ->where('user_id', $user->id)
                ->firstOrFail();

            // Don't allow deleting default address if it's the only one
            if ($address->is_default && $user->customerAddresses()->count() > 1) {
                // Set another address as default before deleting
                $nextAddress = $user->customerAddresses()
                    ->where('id', '!=', $id)
                    ->first();
                    
                if ($nextAddress) {
                    CustomerAddress::setAsDefault($user->id, $nextAddress->id);
                }
            }

            // Don't allow deleting if it's the only address
            if ($user->customerAddresses()->count() === 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'ไม่สามารถลบที่อยู่ได้ เนื่องจากต้องมีที่อยู่อย่างน้อย 1 แห่ง'
                ], 422);
            }

            $address->delete();

            return response()->json([
                'success' => true,
                'message' => 'Address deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error deleting address: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Set address as default
     */
    public function setDefault($id)
    {
        try {
            $user = Auth::user();
            $address = CustomerAddress::where('id', $id)
                ->where('user_id', $user->id)
                ->firstOrFail();

            CustomerAddress::setAsDefault($user->id, $id);

            return response()->json([
                'success' => true,
                'message' => 'Default address updated successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error setting default address: ' . $e->getMessage()
            ], 500);
        }
    }
}