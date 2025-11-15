<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliveryPriceByDistrict extends Model
{
    protected $table = 'delivery_prices_by_district';
    
    protected $fillable = [
        'province_name',
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
     * Get delivery price by province, district and options
     */
    public static function getDeliveryPrice($provinceName, $districtName, $company, $vehicleType)
    {
        $delivery = self::where('province_name', $provinceName)
                       ->where('district_name', $districtName)
                       ->first();
        
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
     * Get all delivery options for a district in a province
     */
    public static function getDeliveryOptions($provinceName, $districtName)
    {
        // Try different variations of district name
        $districtVariations = [
            $districtName,
            'อำเภอ' . $districtName,
            str_replace('อำเภอ', '', $districtName),
        ];

        $delivery = null;
        foreach ($districtVariations as $variation) {
            $delivery = self::where('province_name', $provinceName)
                           ->where('district_name', $variation)
                           ->first();
            if ($delivery) {
                break;
            }
        }
        
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
     * Get all districts for a province
     */
    public static function getDistrictsByProvince($provinceName)
    {
        return self::where('province_name', $provinceName)
                  ->select('district_name')
                  ->orderBy('district_name')
                  ->get()
                  ->pluck('district_name');
    }

    /**
     * Get all available provinces
     */
    public static function getAvailableProvinces()
    {
        return self::select('province_name')
                  ->distinct()
                  ->orderBy('province_name')
                  ->get()
                  ->pluck('province_name');
    }
}
