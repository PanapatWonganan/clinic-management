<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliveryPrice extends Model
{
    protected $fillable = [
        'district_name',
        'grab_motorcycle_price',
        'grab_car_price',
        'lalamove_motorcycle_price',
        'lalamove_car_price',
    ];

    protected $casts = [
        'grab_motorcycle_price' => 'decimal:2',
        'grab_car_price' => 'decimal:2',
        'lalamove_motorcycle_price' => 'decimal:2',
        'lalamove_car_price' => 'decimal:2',
    ];

    /**
     * Get delivery price by district and options
     */
    public static function getDeliveryPrice($districtName, $company, $vehicleType)
    {
        $delivery = self::where('district_name', $districtName)->first();
        
        if (!$delivery) {
            return null;
        }

        $fieldMap = [
            'grab_motorcycle' => 'grab_motorcycle_price',
            'grab_car' => 'grab_car_price',
            'lalamove_motorcycle' => 'lalamove_motorcycle_price',
            'lalamove_car' => 'lalamove_car_price',
        ];

        $key = strtolower($company) . '_' . strtolower($vehicleType);
        
        return $delivery->{$fieldMap[$key] ?? null} ?? null;
    }

    /**
     * Get all delivery options for a district
     */
    public static function getDeliveryOptions($districtName)
    {
        $delivery = self::where('district_name', $districtName)->first();
        
        if (!$delivery) {
            return null;
        }

        return [
            'grab_motorcycle' => $delivery->grab_motorcycle_price,
            'grab_car' => $delivery->grab_car_price,
            'lalamove_motorcycle' => $delivery->lalamove_motorcycle_price,
            'lalamove_car' => $delivery->lalamove_car_price,
        ];
    }

    /**
     * Get delivery options for any location (แขวง in Bangkok or อำเภอ in other provinces)
     * This is a unified method that searches both Bangkok districts and suburban districts
     */
    public static function getUnifiedDeliveryOptions($locationName, $provinceName = null)
    {
        // Try different variations of location name for Bangkok districts
        $bangkokVariations = [
            $locationName,
            'แขวง' . $locationName,
            str_replace('แขวง', '', $locationName),
        ];

        foreach ($bangkokVariations as $variation) {
            $bangkokOptions = self::getDeliveryOptions($variation);
            if ($bangkokOptions !== null) {
                return $bangkokOptions;
            }
        }

        // If not found and province is specified, try suburban districts
        if ($provinceName && class_exists('App\Models\DeliveryPriceByDistrict')) {
            // Try different variations for suburban districts
            $districtVariations = [
                $locationName,
                'อำเภอ' . $locationName,
                str_replace('อำเภอ', '', $locationName),
            ];
            
            foreach ($districtVariations as $variation) {
                $suburbanOptions = \App\Models\DeliveryPriceByDistrict::getDeliveryOptions($provinceName, $variation);
                if ($suburbanOptions !== null) {
                    return $suburbanOptions;
                }
            }
        }

        return null;
    }

    /**
     * Get unified delivery price for any location
     */
    public static function getUnifiedDeliveryPrice($locationName, $company, $vehicleType, $provinceName = null)
    {
        // First try Bangkok districts
        $bangkokPrice = self::getDeliveryPrice($locationName, $company, $vehicleType);
        if ($bangkokPrice !== null) {
            return $bangkokPrice;
        }

        // If not found and province is specified, try suburban districts
        if ($provinceName && class_exists('App\Models\DeliveryPriceByDistrict')) {
            return \App\Models\DeliveryPriceByDistrict::getDeliveryPrice($provinceName, $locationName, $company, $vehicleType);
        }

        return null;
    }
}
