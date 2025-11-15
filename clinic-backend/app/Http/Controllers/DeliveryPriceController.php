<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\DeliveryPrice;
use App\Models\DeliveryPriceByDistrict;

class DeliveryPriceController extends Controller
{
    /**
     * Get all delivery options for a specific district
     */
    public function getDeliveryOptions($districtName)
    {
        $options = DeliveryPrice::getDeliveryOptions($districtName);
        
        if (!$options) {
            return response()->json([
                'success' => false,
                'message' => 'District not found',
                'data' => null
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Delivery options retrieved successfully',
            'data' => [
                'district_name' => $districtName,
                'delivery_options' => [
                    [
                        'company' => 'grab',
                        'vehicle_type' => 'motorcycle',
                        'price' => $options['grab_motorcycle'],
                        'display_name' => 'Grab - มอเตอร์ไซค์',
                        'estimated_time' => '30-60 นาที'
                    ],
                    [
                        'company' => 'grab',
                        'vehicle_type' => 'car',
                        'price' => $options['grab_car'],
                        'display_name' => 'Grab - รถยนต์',
                        'estimated_time' => '45-90 นาที'
                    ],
                    [
                        'company' => 'lalamove',
                        'vehicle_type' => 'motorcycle',
                        'price' => $options['lalamove_motorcycle'],
                        'display_name' => 'Lalamove - มอเตอร์ไซค์',
                        'estimated_time' => '25-50 นาที'
                    ],
                    [
                        'company' => 'lalamove',
                        'vehicle_type' => 'car',
                        'price' => $options['lalamove_car'],
                        'display_name' => 'Lalamove - รถยนต์',
                        'estimated_time' => '40-80 นาที'
                    ]
                ]
            ]
        ]);
    }

    /**
     * Get specific delivery price
     */
    public function getDeliveryPrice(Request $request)
    {
        $request->validate([
            'district_name' => 'required|string',
            'company' => 'required|in:grab,lalamove',
            'vehicle_type' => 'required|in:motorcycle,car'
        ]);

        $price = DeliveryPrice::getDeliveryPrice(
            $request->district_name,
            $request->company,
            $request->vehicle_type
        );

        if ($price === null) {
            return response()->json([
                'success' => false,
                'message' => 'Delivery price not found',
                'data' => null
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Delivery price retrieved successfully',
            'data' => [
                'district_name' => $request->district_name,
                'company' => $request->company,
                'vehicle_type' => $request->vehicle_type,
                'price' => $price
            ]
        ]);
    }

    /**
     * Get all districts with delivery service
     */
    public function getAvailableDistricts()
    {
        $districts = DeliveryPrice::select('district_name')
            ->orderBy('district_name')
            ->get()
            ->pluck('district_name');

        return response()->json([
            'success' => true,
            'message' => 'Available districts retrieved successfully',
            'data' => $districts
        ]);
    }

    /**
     * Get delivery options for suburban provinces (สมุทรปราการ, ปทุมธานี, นนทบุรี)
     */
    public function getDeliveryOptionsByProvince($provinceName, $districtName)
    {
        $options = DeliveryPriceByDistrict::getDeliveryOptions($provinceName, $districtName);
        
        if (!$options) {
            return response()->json([
                'success' => false,
                'message' => 'District not found in this province',
                'data' => null
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Delivery options retrieved successfully',
            'data' => [
                'province_name' => $provinceName,
                'district_name' => $districtName,
                'delivery_options' => [
                    [
                        'company' => 'grab',
                        'vehicle_type' => 'motorcycle',
                        'price' => $options['grab_motorcycle'],
                        'display_name' => 'Grab - มอเตอร์ไซค์',
                        'estimated_time' => '30-60 นาที'
                    ],
                    [
                        'company' => 'grab',
                        'vehicle_type' => 'car',
                        'price' => $options['grab_car'],
                        'display_name' => 'Grab - รถยนต์',
                        'estimated_time' => '45-90 นาที'
                    ],
                    [
                        'company' => 'lalamove',
                        'vehicle_type' => 'motorcycle',
                        'price' => $options['lalamove_motorcycle'],
                        'display_name' => 'Lalamove - มอเตอร์ไซค์',
                        'estimated_time' => '25-50 นาที'
                    ],
                    [
                        'company' => 'lalamove',
                        'vehicle_type' => 'car',
                        'price' => $options['lalamove_car'],
                        'display_name' => 'Lalamove - รถยนต์',
                        'estimated_time' => '40-80 นาที'
                    ]
                ]
            ]
        ]);
    }

    /**
     * Get available provinces for suburban delivery
     */
    public function getAvailableProvinces()
    {
        $provinces = DeliveryPriceByDistrict::getAvailableProvinces();

        return response()->json([
            'success' => true,
            'message' => 'Available provinces retrieved successfully',
            'data' => $provinces
        ]);
    }

    /**
     * Get districts for a specific province
     */
    public function getDistrictsByProvince($provinceName)
    {
        $districts = DeliveryPriceByDistrict::getDistrictsByProvince($provinceName);

        return response()->json([
            'success' => true,
            'message' => 'Districts retrieved successfully',
            'data' => $districts
        ]);
    }

    /**
     * Unified method to get delivery options (searches both Bangkok and suburban)
     */
    public function getUnifiedDeliveryOptions(Request $request)
    {
        $request->validate([
            'location_name' => 'required|string',
            'province_name' => 'nullable|string'
        ]);

        $locationName = $request->location_name;
        $provinceName = $request->province_name;

        // Log the incoming request for debugging
        \Log::info('Delivery Price Request', [
            'location_name' => $locationName,
            'province_name' => $provinceName,
        ]);

        $options = DeliveryPrice::getUnifiedDeliveryOptions($locationName, $provinceName);
        
        if (!$options) {
            return response()->json([
                'success' => false,
                'message' => 'Location not found',
                'data' => null
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Delivery options retrieved successfully',
            'data' => [
                'location_name' => $locationName,
                'province_name' => $provinceName,
                'delivery_options' => [
                    [
                        'company' => 'grab',
                        'vehicle_type' => 'motorcycle',
                        'price' => $options['grab_motorcycle'],
                        'display_name' => 'Grab - มอเตอร์ไซค์',
                        'estimated_time' => '30-60 นาที'
                    ],
                    [
                        'company' => 'grab',
                        'vehicle_type' => 'car',
                        'price' => $options['grab_car'],
                        'display_name' => 'Grab - รถยนต์',
                        'estimated_time' => '45-90 นาที'
                    ],
                    [
                        'company' => 'lalamove',
                        'vehicle_type' => 'motorcycle',
                        'price' => $options['lalamove_motorcycle'],
                        'display_name' => 'Lalamove - มอเตอร์ไซค์',
                        'estimated_time' => '25-50 นาที'
                    ],
                    [
                        'company' => 'lalamove',
                        'vehicle_type' => 'car',
                        'price' => $options['lalamove_car'],
                        'display_name' => 'Lalamove - รถยนต์',
                        'estimated_time' => '40-80 นาที'
                    ]
                ]
            ]
        ]);
    }
}