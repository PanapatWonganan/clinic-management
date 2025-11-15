<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\DeliveryPriceByDistrict;

class DeliveryPriceByDistrictSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Complete data from CSV: Provincial delivery prices
        $deliveryPrices = [
            // สมุทรปราการ
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'เมืองสมุทรปราการ', 'grab_motorcycle_price' => 209, 'grab_car_price' => 347, 'lalamove_motorcycle_price' => 208, 'lalamove_car_price' => 262],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'บางบ่อ', 'grab_motorcycle_price' => 394, 'grab_car_price' => 541, 'lalamove_motorcycle_price' => 392, 'lalamove_car_price' => 355],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'บางพลี', 'grab_motorcycle_price' => 238, 'grab_car_price' => 380, 'lalamove_motorcycle_price' => 221, 'lalamove_car_price' => 273],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'พระประแดง', 'grab_motorcycle_price' => 237, 'grab_car_price' => 356, 'lalamove_motorcycle_price' => 205, 'lalamove_car_price' => 305],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'พระสมุทรเจดีย์', 'grab_motorcycle_price' => 463, 'grab_car_price' => 491, 'lalamove_motorcycle_price' => 377, 'lalamove_car_price' => 382],
            ['province_name' => 'สมุทรปราการ', 'district_name' => 'บางเสาธง', 'grab_motorcycle_price' => 334, 'grab_car_price' => 461, 'lalamove_motorcycle_price' => 275, 'lalamove_car_price' => 309],
            
            // ปทุมธานี  
            ['province_name' => 'ปทุมธานี', 'district_name' => 'เมืองปทุมธานี', 'grab_motorcycle_price' => 497, 'grab_car_price' => 590, 'lalamove_motorcycle_price' => 340, 'lalamove_car_price' => 382],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'สามโคก', 'grab_motorcycle_price' => 552, 'grab_car_price' => 606, 'lalamove_motorcycle_price' => 637, 'lalamove_car_price' => 463],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'ลาดหลุมแก้ว', 'grab_motorcycle_price' => 623, 'grab_car_price' => 703, 'lalamove_motorcycle_price' => 596, 'lalamove_car_price' => 484],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'คลองหลวง', 'grab_motorcycle_price' => 553, 'grab_car_price' => 652, 'lalamove_motorcycle_price' => 479, 'lalamove_car_price' => 457],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'ลำลูกกา', 'grab_motorcycle_price' => 283, 'grab_car_price' => 466, 'lalamove_motorcycle_price' => 306, 'lalamove_car_price' => 343],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'ธัญบุรี', 'grab_motorcycle_price' => 418, 'grab_car_price' => 524, 'lalamove_motorcycle_price' => 331, 'lalamove_car_price' => 345],
            ['province_name' => 'ปทุมธานี', 'district_name' => 'หนองเสือ', 'grab_motorcycle_price' => 677, 'grab_car_price' => 729, 'lalamove_motorcycle_price' => 654, 'lalamove_car_price' => 517],
            
            // นนทบุรี
            ['province_name' => 'นนทบุรี', 'district_name' => 'เมืองนนทบุรี', 'grab_motorcycle_price' => 226, 'grab_car_price' => 382, 'lalamove_motorcycle_price' => 207, 'lalamove_car_price' => 279],
            ['province_name' => 'นนทบุรี', 'district_name' => 'ปากเกร็ด', 'grab_motorcycle_price' => 269, 'grab_car_price' => 433, 'lalamove_motorcycle_price' => 245, 'lalamove_car_price' => 309],
            ['province_name' => 'นนทบุรี', 'district_name' => 'บางบัวทอง', 'grab_motorcycle_price' => 469, 'grab_car_price' => 640, 'lalamove_motorcycle_price' => 422, 'lalamove_car_price' => 390],
            ['province_name' => 'นนทบุรี', 'district_name' => 'บางใหญ่', 'grab_motorcycle_price' => 400, 'grab_car_price' => 502, 'lalamove_motorcycle_price' => 362, 'lalamove_car_price' => 362],
            ['province_name' => 'นนทบุรี', 'district_name' => 'บางกรวย', 'grab_motorcycle_price' => 229, 'grab_car_price' => 341, 'lalamove_motorcycle_price' => 267, 'lalamove_car_price' => 300],
            ['province_name' => 'นนทบุรี', 'district_name' => 'ไทรน้อย', 'grab_motorcycle_price' => 574, 'grab_car_price' => 662, 'lalamove_motorcycle_price' => 574, 'lalamove_car_price' => 483],
        ];

        foreach ($deliveryPrices as $price) {
            DeliveryPriceByDistrict::create($price);
        }
    }
}
