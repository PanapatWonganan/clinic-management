<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\DeliveryPriceByDistrict;

class SuburbanDeliveryPriceSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Note: This contains sample data. Replace with actual data from Google Sheets.
     */
    public function run(): void
    {
        // Sample data for 3 provinces - Replace with actual data from your Google Sheets
        $deliveryPrices = [
            // สมุทรปราการ
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'อำเภอเมืองสมุทรปราการ', 'grab_motorcycle_price' => 180, 'grab_car_price' => 320, 'lalamove_motorcycle_price' => 160, 'lalamove_car_price' => 280],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'อำเภอบางพลี', 'grab_motorcycle_price' => 200, 'grab_car_price' => 350, 'lalamove_motorcycle_price' => 180, 'lalamove_car_price' => 310],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'อำเภอบางบ่อ', 'grab_motorcycle_price' => 220, 'grab_car_price' => 380, 'lalamove_motorcycle_price' => 200, 'lalamove_car_price' => 340],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'อำเภอพระประแดง', 'grab_motorcycle_price' => 190, 'grab_car_price' => 330, 'lalamove_motorcycle_price' => 170, 'lalamove_car_price' => 290],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'อำเภอพระสมุทรเจดีย์', 'grab_motorcycle_price' => 240, 'grab_car_price' => 420, 'lalamove_motorcycle_price' => 220, 'lalamove_car_price' => 380],

            // ปทุมธานี
            ['province_name' => 'ปทุมธานี', 'district_name' => 'อำเภอเมืองปทุมธานี', 'grab_motorcycle_price' => 170, 'grab_car_price' => 300, 'lalamove_motorcycle_price' => 150, 'lalamove_car_price' => 260],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'อำเภอคลองหลวง', 'grab_motorcycle_price' => 190, 'grab_car_price' => 340, 'lalamove_motorcycle_price' => 170, 'lalamove_car_price' => 300],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'อำเภอธัญบุรี', 'grab_motorcycle_price' => 200, 'grab_car_price' => 360, 'lalamove_motorcycle_price' => 180, 'lalamove_car_price' => 320],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'อำเภอรังสิต', 'grab_motorcycle_price' => 210, 'grab_car_price' => 380, 'lalamove_motorcycle_price' => 190, 'lalamove_car_price' => 340],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'อำเภอลำลูกกา', 'grab_motorcycle_price' => 230, 'grab_car_price' => 410, 'lalamove_motorcycle_price' => 210, 'lalamove_car_price' => 370],

            // นนทบุรี
            ['province_name' => 'นนทบุรี', 'district_name' => 'อำเภอเมืองนนทบุรี', 'grab_motorcycle_price' => 160, 'grab_car_price' => 280, 'lalamove_motorcycle_price' => 140, 'lalamove_car_price' => 240],
            ['province_name' => 'นนทบุรี', 'district_name' => 'อำเภอปากเกร็ด', 'grab_motorcycle_price' => 180, 'grab_car_price' => 320, 'lalamove_motorcycle_price' => 160, 'lalamove_car_price' => 280],
            ['province_name' => 'นนทบุรี', 'district_name' => 'อำเภอบางใหญ่', 'grab_motorcycle_price' => 200, 'grab_car_price' => 350, 'lalamove_motorcycle_price' => 180, 'lalamove_car_price' => 310],
            ['province_name' => 'นนทบุรี', 'district_name' => 'อำเภอบางกรวย', 'grab_motorcycle_price' => 220, 'grab_car_price' => 390, 'lalamove_motorcycle_price' => 200, 'lalamove_car_price' => 350],
            ['province_name' => 'นนทบุรี', 'district_name' => 'อำเภอบางบัวทอง', 'grab_motorcycle_price' => 240, 'grab_car_price' => 420, 'lalamove_motorcycle_price' => 220, 'lalamove_car_price' => 380],
            ['province_name' => 'นนทบุรี', 'district_name' => 'อำเภอไทรน้อย', 'grab_motorcycle_price' => 250, 'grab_car_price' => 440, 'lalamove_motorcycle_price' => 230, 'lalamove_car_price' => 400],
        ];

        foreach ($deliveryPrices as $price) {
            DeliveryPriceByDistrict::create($price);
        }
    }
}