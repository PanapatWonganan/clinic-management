<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    // Sample Thai address data - In production, this would come from a database
    private static $provinces = [
        ['id' => 1, 'name_th' => 'กรุงเทพมหานคร', 'name_en' => 'Bangkok'],
        ['id' => 2, 'name_th' => 'เชียงใหม่', 'name_en' => 'Chiang Mai'],
        ['id' => 3, 'name_th' => 'เชียงราย', 'name_en' => 'Chiang Rai'],
        ['id' => 4, 'name_th' => 'นนทบุรี', 'name_en' => 'Nonthaburi'],
        ['id' => 5, 'name_th' => 'ปทุมธานี', 'name_en' => 'Pathum Thani'],
        ['id' => 6, 'name_th' => 'สมุทรปราการ', 'name_en' => 'Samut Prakan'],
        ['id' => 7, 'name_th' => 'ภูเก็ต', 'name_en' => 'Phuket'],
        ['id' => 8, 'name_th' => 'สงขลา', 'name_en' => 'Songkhla'],
        ['id' => 9, 'name_th' => 'ขอนแก่น', 'name_en' => 'Khon Kaen'],
        ['id' => 10, 'name_th' => 'นครราชสีมา', 'name_en' => 'Nakhon Ratchasima'],
    ];

    private static $districts = [
        // Bangkok Districts (50 เขต)
        ['id' => 1, 'province_id' => 1, 'name_th' => 'พระนคร', 'name_en' => 'Phra Nakhon'],
        ['id' => 2, 'province_id' => 1, 'name_th' => 'ดุสิต', 'name_en' => 'Dusit'],
        ['id' => 3, 'province_id' => 1, 'name_th' => 'หนองจอก', 'name_en' => 'Nong Chok'],
        ['id' => 4, 'province_id' => 1, 'name_th' => 'บางรัก', 'name_en' => 'Bang Rak'],
        ['id' => 5, 'province_id' => 1, 'name_th' => 'บางเขน', 'name_en' => 'Bang Khen'],
        ['id' => 6, 'province_id' => 1, 'name_th' => 'บางกะปิ', 'name_en' => 'Bang Kapi'],
        ['id' => 7, 'province_id' => 1, 'name_th' => 'ปทุมวัน', 'name_en' => 'Pathum Wan'],
        ['id' => 8, 'province_id' => 1, 'name_th' => 'ป้อมปราบศัตรูพ่าย', 'name_en' => 'Pom Prap Sattru Phai'],
        ['id' => 9, 'province_id' => 1, 'name_th' => 'พระโขนง', 'name_en' => 'Phra Khanong'],
        ['id' => 10, 'province_id' => 1, 'name_th' => 'มีนบุรี', 'name_en' => 'Min Buri'],
        ['id' => 11, 'province_id' => 1, 'name_th' => 'ลาดกระบัง', 'name_en' => 'Lat Krabang'],
        ['id' => 12, 'province_id' => 1, 'name_th' => 'ยานนาวา', 'name_en' => 'Yan Nawa'],
        ['id' => 13, 'province_id' => 1, 'name_th' => 'สัมพันธวงศ์', 'name_en' => 'Samphanthawong'],
        ['id' => 14, 'province_id' => 1, 'name_th' => 'บางซื่อ', 'name_en' => 'Bang Sue'],
        ['id' => 15, 'province_id' => 1, 'name_th' => 'บางพลัด', 'name_en' => 'Bang Phlat'],
        ['id' => 16, 'province_id' => 1, 'name_th' => 'ดินแดง', 'name_en' => 'Din Daeng'],
        ['id' => 17, 'province_id' => 1, 'name_th' => 'บึงกุ่ม', 'name_en' => 'Bueng Kum'],
        ['id' => 18, 'province_id' => 1, 'name_th' => 'สาทร', 'name_en' => 'Sathon'],
        ['id' => 19, 'province_id' => 1, 'name_th' => 'บางนา', 'name_en' => 'Bang Na'],
        ['id' => 20, 'province_id' => 1, 'name_th' => 'ภาษีเจริญ', 'name_en' => 'Phasi Charoen'],
        ['id' => 21, 'province_id' => 1, 'name_th' => 'หนองแขม', 'name_en' => 'Nong Khaem'],
        ['id' => 22, 'province_id' => 1, 'name_th' => 'ราษฎร์บูรณะ', 'name_en' => 'Rat Burana'],
        ['id' => 23, 'province_id' => 1, 'name_th' => 'บางแค', 'name_en' => 'Bang Khae'],
        ['id' => 24, 'province_id' => 1, 'name_th' => 'หลักสี่', 'name_en' => 'Lak Si'],
        ['id' => 25, 'province_id' => 1, 'name_th' => 'สายไหม', 'name_en' => 'Sai Mai'],
        ['id' => 26, 'province_id' => 1, 'name_th' => 'คันนายาว', 'name_en' => 'Khan Na Yao'],
        ['id' => 27, 'province_id' => 1, 'name_th' => 'สะพานพุทธ', 'name_en' => 'Saphan Phut'],
        ['id' => 28, 'province_id' => 1, 'name_th' => 'วังทองหลาง', 'name_en' => 'Wang Thonglang'],
        ['id' => 29, 'province_id' => 1, 'name_th' => 'คลองสาน', 'name_en' => 'Khlong San'],
        ['id' => 30, 'province_id' => 1, 'name_th' => 'ตลิ่งชัน', 'name_en' => 'Taling Chan'],
        ['id' => 31, 'province_id' => 1, 'name_th' => 'บางกอกใหญ่', 'name_en' => 'Bangkok Yai'],
        ['id' => 32, 'province_id' => 1, 'name_th' => 'บางกอกน้อย', 'name_en' => 'Bangkok Noi'],
        ['id' => 33, 'province_id' => 1, 'name_th' => 'บางขุนเทียน', 'name_en' => 'Bang Khun Thian'],
        ['id' => 34, 'province_id' => 1, 'name_th' => 'จอมทอง', 'name_en' => 'Chom Thong'],
        ['id' => 35, 'province_id' => 1, 'name_th' => 'ดอนเมือง', 'name_en' => 'Don Mueang'],
        ['id' => 36, 'province_id' => 1, 'name_th' => 'ราชเทวี', 'name_en' => 'Ratchathewi'],
        ['id' => 37, 'province_id' => 1, 'name_th' => 'ลาดพร้าว', 'name_en' => 'Lat Phrao'],
        ['id' => 38, 'province_id' => 1, 'name_th' => 'วัฒนา', 'name_en' => 'Watthana'],
        ['id' => 39, 'province_id' => 1, 'name_th' => 'บางคอแหลม', 'name_en' => 'Bang Kho Laem'],
        ['id' => 40, 'province_id' => 1, 'name_th' => 'ประเวศ', 'name_en' => 'Prawet'],
        ['id' => 41, 'province_id' => 1, 'name_th' => 'คลองเตย', 'name_en' => 'Khlong Toei'],
        ['id' => 42, 'province_id' => 1, 'name_th' => 'สวนหลวง', 'name_en' => 'Suan Luang'],
        ['id' => 43, 'province_id' => 1, 'name_th' => 'จตุจักร', 'name_en' => 'Chatuchak'],
        ['id' => 44, 'province_id' => 1, 'name_th' => 'บางบอน', 'name_en' => 'Bang Bon'],
        ['id' => 45, 'province_id' => 1, 'name_th' => 'ลาดกระบัง', 'name_en' => 'Lat Krabang'],
        ['id' => 46, 'province_id' => 1, 'name_th' => 'บางแคอำเภอ', 'name_en' => 'Bang Khae District'],
        ['id' => 47, 'province_id' => 1, 'name_th' => 'ธนบุรี', 'name_en' => 'Thon Buri'],
        ['id' => 48, 'province_id' => 1, 'name_th' => 'บวรเขต', 'name_en' => 'Bua Khwan'],
        ['id' => 49, 'province_id' => 1, 'name_th' => 'พญาไท', 'name_en' => 'Phaya Thai'],
        ['id' => 50, 'province_id' => 1, 'name_th' => 'ทวีวัฒนา', 'name_en' => 'Thawi Watthana'],
        
        // Chiang Mai Districts
        ['id' => 51, 'province_id' => 2, 'name_th' => 'เมืองเชียงใหม่', 'name_en' => 'Mueang Chiang Mai'],
        ['id' => 52, 'province_id' => 2, 'name_th' => 'จอมทอง', 'name_en' => 'Chom Thong'],
        ['id' => 53, 'province_id' => 2, 'name_th' => 'แม่ริม', 'name_en' => 'Mae Rim'],
        ['id' => 54, 'province_id' => 2, 'name_th' => 'สันกำแพง', 'name_en' => 'San Kamphaeng'],
        ['id' => 55, 'province_id' => 2, 'name_th' => 'สันป่าตอง', 'name_en' => 'San Pa Tong'],
        
        // Chiang Rai Districts
        ['id' => 56, 'province_id' => 3, 'name_th' => 'เมืองเชียงราย', 'name_en' => 'Mueang Chiang Rai'],
        ['id' => 57, 'province_id' => 3, 'name_th' => 'แม่จัน', 'name_en' => 'Mae Jan'],
        ['id' => 58, 'province_id' => 3, 'name_th' => 'แม่สาย', 'name_en' => 'Mae Sai'],
        
        // Nonthaburi Districts
        ['id' => 59, 'province_id' => 4, 'name_th' => 'เมืองนนทบุรี', 'name_en' => 'Mueang Nonthaburi'],
        ['id' => 60, 'province_id' => 4, 'name_th' => 'บางกรวย', 'name_en' => 'Bang Kruai'],
        ['id' => 61, 'province_id' => 4, 'name_th' => 'บางใหญ่', 'name_en' => 'Bang Yai'],
        ['id' => 62, 'province_id' => 4, 'name_th' => 'ไผ่', 'name_en' => 'Pai'],
        ['id' => 63, 'province_id' => 4, 'name_th' => 'บางบัวทอง', 'name_en' => 'Bang Bua Thong'],
        ['id' => 64, 'province_id' => 4, 'name_th' => 'ปากเกร็ด', 'name_en' => 'Pak Kret'],
        ['id' => 65, 'province_id' => 4, 'name_th' => 'ไทรน้อย', 'name_en' => 'Sai Noi'],
        
        // Pathum Thani Districts (Province ID = 5)
        ['id' => 66, 'province_id' => 5, 'name_th' => 'เมืองปทุมธานี', 'name_en' => 'Mueang Pathum Thani'],
        ['id' => 67, 'province_id' => 5, 'name_th' => 'คลองหลวง', 'name_en' => 'Khlong Luang'],
        ['id' => 68, 'province_id' => 5, 'name_th' => 'ธัญบุรี', 'name_en' => 'Thanyaburi'],
        ['id' => 69, 'province_id' => 5, 'name_th' => 'ลำลูกกา', 'name_en' => 'Lam Luk Ka'],
        ['id' => 70, 'province_id' => 5, 'name_th' => 'หนองเสือ', 'name_en' => 'Nong Suea'],
        ['id' => 71, 'province_id' => 5, 'name_th' => 'ลาดหลุมแก้ว', 'name_en' => 'Lat Lum Kaeo'],
        ['id' => 72, 'province_id' => 5, 'name_th' => 'สามโคก', 'name_en' => 'Sam Khok'],
        
        // Samut Prakan Districts (Province ID = 6)
        ['id' => 73, 'province_id' => 6, 'name_th' => 'เมืองสมุทรปราการ', 'name_en' => 'Mueang Samut Prakan'],
        ['id' => 74, 'province_id' => 6, 'name_th' => 'บางพลี', 'name_en' => 'Bang Phli'],
        ['id' => 75, 'province_id' => 6, 'name_th' => 'บางบ่อ', 'name_en' => 'Bang Bo'],
        ['id' => 76, 'province_id' => 6, 'name_th' => 'พระประแดง', 'name_en' => 'Phra Pradaeng'],
        ['id' => 77, 'province_id' => 6, 'name_th' => 'พระสมุทรเจดีย์', 'name_en' => 'Phra Samut Chedi'],
        ['id' => 78, 'province_id' => 6, 'name_th' => 'บางเสาธง', 'name_en' => 'Bang Sao Thong'],
    ];

    private static $subDistricts = [
        // Bangkok - Phra Nakhon Sub-districts
        ['id' => 1, 'district_id' => 1, 'name_th' => 'พระบรมมหาราชวัง', 'name_en' => 'Phra Borom Maha Ratchawang', 'postal_code' => '10200'],
        ['id' => 2, 'district_id' => 1, 'name_th' => 'วังบูรพาภิรมย์', 'name_en' => 'Wang Burapha Phirom', 'postal_code' => '10200'],
        ['id' => 3, 'district_id' => 1, 'name_th' => 'วัดราชบพิธ', 'name_en' => 'Wat Ratchabophit', 'postal_code' => '10200'],
        ['id' => 4, 'district_id' => 1, 'name_th' => 'สำราญราษฎร์', 'name_en' => 'Samran Rat', 'postal_code' => '10200'],
        ['id' => 5, 'district_id' => 1, 'name_th' => 'ศิริราช', 'name_en' => 'Siriraj', 'postal_code' => '10700'],
        
        // Bangkok - Bang Rak Sub-districts
        ['id' => 6, 'district_id' => 4, 'name_th' => 'มหาพฤฒาราม', 'name_en' => 'Maha Phruettharam', 'postal_code' => '10500'],
        ['id' => 7, 'district_id' => 4, 'name_th' => 'สีลม', 'name_en' => 'Silom', 'postal_code' => '10500'],
        ['id' => 8, 'district_id' => 4, 'name_th' => 'สุริยวงศ์', 'name_en' => 'Suriyawong', 'postal_code' => '10500'],
        ['id' => 9, 'district_id' => 4, 'name_th' => 'บางรัก', 'name_en' => 'Bang Rak', 'postal_code' => '10500'],
        
        // Bangkok - Pathum Wan Sub-districts
        ['id' => 10, 'district_id' => 7, 'name_th' => 'ปทุมวัน', 'name_en' => 'Pathum Wan', 'postal_code' => '10330'],
        ['id' => 11, 'district_id' => 7, 'name_th' => 'ลุมพินี', 'name_en' => 'Lumpini', 'postal_code' => '10330'],
        ['id' => 12, 'district_id' => 7, 'name_th' => 'ทุ่งมหาเมฆ', 'name_en' => 'Thung Maha Mek', 'postal_code' => '10120'],
        ['id' => 13, 'district_id' => 7, 'name_th' => 'รองเมือง', 'name_en' => 'Rong Muang', 'postal_code' => '10330'],
        
        // Bangkok - Yan Nawa Sub-districts (District ID 12)
        ['id' => 19, 'district_id' => 12, 'name_th' => 'ยานนาวา', 'name_en' => 'Yan Nawa', 'postal_code' => '10120'],
        ['id' => 20, 'district_id' => 12, 'name_th' => 'ช่องนนทรี', 'name_en' => 'Chong Nonsi', 'postal_code' => '10120'],
        ['id' => 21, 'district_id' => 12, 'name_th' => 'บางโพงพาง', 'name_en' => 'Bang Phongphang', 'postal_code' => '10120'],
        
        // Bangkok - Sathon Sub-districts (District ID 18)
        ['id' => 22, 'district_id' => 18, 'name_th' => 'สีลม', 'name_en' => 'Silom', 'postal_code' => '10500'],
        ['id' => 23, 'district_id' => 18, 'name_th' => 'ยานนาวา', 'name_en' => 'Yan Nawa', 'postal_code' => '10120'],
        ['id' => 24, 'district_id' => 18, 'name_th' => 'ทุ่งมหาเมฆ', 'name_en' => 'Thung Maha Mek', 'postal_code' => '10120'],
        
        // Bangkok - Chatuchak Sub-districts (District ID 43)
        ['id' => 25, 'district_id' => 43, 'name_th' => 'จตุจักร', 'name_en' => 'Chatuchak', 'postal_code' => '10900'],
        ['id' => 26, 'district_id' => 43, 'name_th' => 'ลาดยาว', 'name_en' => 'Lat Yao', 'postal_code' => '10900'],
        ['id' => 27, 'district_id' => 43, 'name_th' => 'จันทรเกษม', 'name_en' => 'Jatujak', 'postal_code' => '10900'],
        ['id' => 28, 'district_id' => 43, 'name_th' => 'สีกัน', 'name_en' => 'Sikan', 'postal_code' => '10900'],
        
        // Bangkok - Watthana Sub-districts (District ID 38)
        ['id' => 29, 'district_id' => 38, 'name_th' => 'พระโขนง', 'name_en' => 'Phra Khanong', 'postal_code' => '10110'],
        ['id' => 30, 'district_id' => 38, 'name_th' => 'พระโขนงเหนือ', 'name_en' => 'Phra Khanong Nuea', 'postal_code' => '10110'],
        ['id' => 31, 'district_id' => 38, 'name_th' => 'คลองเตย', 'name_en' => 'Khlong Toei', 'postal_code' => '10110'],
        ['id' => 32, 'district_id' => 38, 'name_th' => 'คลองตัน', 'name_en' => 'Khlong Tan', 'postal_code' => '10110'],
        
        // Bangkok - Phaya Thai Sub-districts (District ID 49)
        ['id' => 33, 'district_id' => 49, 'name_th' => 'พญาไท', 'name_en' => 'Phaya Thai', 'postal_code' => '10400'],
        ['id' => 34, 'district_id' => 49, 'name_th' => 'ราชเทวี', 'name_en' => 'Ratchathewi', 'postal_code' => '10400'],
        ['id' => 35, 'district_id' => 49, 'name_th' => 'ทุ่งพญาไท', 'name_en' => 'Thung Phaya Thai', 'postal_code' => '10400'],
        
        // Bangkok - Thawi Watthana Sub-districts (District ID 50)
        ['id' => 36, 'district_id' => 50, 'name_th' => 'ทวีวัฒนา', 'name_en' => 'Thawi Watthana', 'postal_code' => '10170'],
        ['id' => 37, 'district_id' => 50, 'name_th' => 'ศาลาธรรมสพน์', 'name_en' => 'Sala Thammasop', 'postal_code' => '10170'],
        ['id' => 38, 'district_id' => 50, 'name_th' => 'บางแค', 'name_en' => 'Bang Khae', 'postal_code' => '10160'],
        
        // Bangkok - Dusit Sub-districts (District ID 2)
        ['id' => 87, 'district_id' => 2, 'name_th' => 'ดุสิต', 'name_en' => 'Dusit', 'postal_code' => '10300'],
        ['id' => 88, 'district_id' => 2, 'name_th' => 'วชิรพยาบาล', 'name_en' => 'Wachiraphayaban', 'postal_code' => '10300'],
        ['id' => 89, 'district_id' => 2, 'name_th' => 'สวนจิตรลดา', 'name_en' => 'Suan Chitralada', 'postal_code' => '10300'],
        ['id' => 90, 'district_id' => 2, 'name_th' => 'สีแยก', 'name_en' => 'Si Yaek', 'postal_code' => '10300'],
        
        // Bangkok - Nong Chok Sub-districts (District ID 3)
        ['id' => 91, 'district_id' => 3, 'name_th' => 'หนองจอก', 'name_en' => 'Nong Chok', 'postal_code' => '10530'],
        ['id' => 92, 'district_id' => 3, 'name_th' => 'กระทุ่มล้อม', 'name_en' => 'Krathum Lom', 'postal_code' => '10530'],
        ['id' => 93, 'district_id' => 3, 'name_th' => 'คลองสิบ', 'name_en' => 'Khlong Sip', 'postal_code' => '10530'],
        ['id' => 94, 'district_id' => 3, 'name_th' => 'คลองสิบสอง', 'name_en' => 'Khlong Sip Song', 'postal_code' => '10530'],
        
        // Bangkok - Bang Khen Sub-districts (District ID 5)
        ['id' => 95, 'district_id' => 5, 'name_th' => 'บางเขน', 'name_en' => 'Bang Khen', 'postal_code' => '10220'],
        ['id' => 96, 'district_id' => 5, 'name_th' => 'ท่าแร้ง', 'name_en' => 'Tha Raeng', 'postal_code' => '10220'],
        ['id' => 97, 'district_id' => 5, 'name_th' => 'อนุสาวรีย์', 'name_en' => 'Anusawari', 'postal_code' => '10220'],
        
        // Bangkok - Bang Kapi Sub-districts (District ID 6)
        ['id' => 98, 'district_id' => 6, 'name_th' => 'บางกะปิ', 'name_en' => 'Bang Kapi', 'postal_code' => '10240'],
        ['id' => 99, 'district_id' => 6, 'name_th' => 'คลองจั่น', 'name_en' => 'Khlong Chan', 'postal_code' => '10240'],
        ['id' => 100, 'district_id' => 6, 'name_th' => 'หัวหมาก', 'name_en' => 'Hua Mak', 'postal_code' => '10240'],
        
        // Bangkok - Pom Prap Sattru Phai Sub-districts (District ID 8)
        ['id' => 101, 'district_id' => 8, 'name_th' => 'บ้านพานถม', 'name_en' => 'Ban Phan Thom', 'postal_code' => '10100'],
        ['id' => 102, 'district_id' => 8, 'name_th' => 'บ้านบัว', 'name_en' => 'Ban Bat', 'postal_code' => '10100'],
        ['id' => 103, 'district_id' => 8, 'name_th' => 'วัดท่าพระ', 'name_en' => 'Wat Tha Phra', 'postal_code' => '10100'],
        
        // Bangkok - Phra Khanong Sub-districts (District ID 9)
        ['id' => 104, 'district_id' => 9, 'name_th' => 'พระโขนง', 'name_en' => 'Phra Khanong', 'postal_code' => '10110'],
        ['id' => 105, 'district_id' => 9, 'name_th' => 'บางจาก', 'name_en' => 'Bang Chak', 'postal_code' => '10260'],
        ['id' => 106, 'district_id' => 9, 'name_th' => 'บางนา', 'name_en' => 'Bang Na', 'postal_code' => '10260'],
        
        // Bangkok - Min Buri Sub-districts (District ID 10)
        ['id' => 107, 'district_id' => 10, 'name_th' => 'มีนบุรี', 'name_en' => 'Min Buri', 'postal_code' => '10510'],
        ['id' => 108, 'district_id' => 10, 'name_th' => 'แสนแสบ', 'name_en' => 'Saen Saeb', 'postal_code' => '10510'],
        ['id' => 109, 'district_id' => 10, 'name_th' => 'นวมินทราชินี', 'name_en' => 'Nawamin Rachini', 'postal_code' => '10510'],
        
        // Bangkok - Lat Krabang Sub-districts (District ID 11)
        ['id' => 39, 'district_id' => 11, 'name_th' => 'ลาดกระบัง', 'name_en' => 'Lat Krabang', 'postal_code' => '10520'],
        ['id' => 40, 'district_id' => 11, 'name_th' => 'คลองสองต้นนุ่น', 'name_en' => 'Khlong Song Ton Nun', 'postal_code' => '10520'],
        ['id' => 41, 'district_id' => 11, 'name_th' => 'คลองสามประเทศ', 'name_en' => 'Khlong Sam Prawet', 'postal_code' => '10520'],
        ['id' => 42, 'district_id' => 11, 'name_th' => 'ลำปลาทิว', 'name_en' => 'Lam Pla Thio', 'postal_code' => '10520'],
        ['id' => 43, 'district_id' => 11, 'name_th' => 'ทับยาว', 'name_en' => 'Thap Yao', 'postal_code' => '10520'],
        
        // Bangkok - Samphanthawong Sub-districts (District ID 13)
        ['id' => 110, 'district_id' => 13, 'name_th' => 'สัมพันธวงศ์', 'name_en' => 'Samphanthawong', 'postal_code' => '10100'],
        ['id' => 111, 'district_id' => 13, 'name_th' => 'ตลาดรอดฟ้าย', 'name_en' => 'Talat Rod Fai', 'postal_code' => '10100'],
        ['id' => 112, 'district_id' => 13, 'name_th' => 'ชากพระ', 'name_en' => 'Chakkraphatdiphong', 'postal_code' => '10100'],
        
        // Bangkok - Bang Sue Sub-districts (District ID 14)
        ['id' => 113, 'district_id' => 14, 'name_th' => 'บางซื่อ', 'name_en' => 'Bang Sue', 'postal_code' => '10800'],
        ['id' => 114, 'district_id' => 14, 'name_th' => 'บ้านเสือก้าน', 'name_en' => 'Ban Sue Kan', 'postal_code' => '10800'],
        ['id' => 115, 'district_id' => 14, 'name_th' => 'วงศ์เสวย์', 'name_en' => 'Wong Sawang', 'postal_code' => '10800'],
        
        // Bangkok - Bang Phlat Sub-districts (District ID 15)
        ['id' => 116, 'district_id' => 15, 'name_th' => 'บางพลัด', 'name_en' => 'Bang Phlat', 'postal_code' => '10700'],
        ['id' => 117, 'district_id' => 15, 'name_th' => 'บางอ้อ', 'name_en' => 'Bang O', 'postal_code' => '10700'],
        ['id' => 118, 'district_id' => 15, 'name_th' => 'บางบำหรุ', 'name_en' => 'Bang Bamru', 'postal_code' => '10700'],
        
        // Bangkok - Din Daeng Sub-districts (District ID 16)
        ['id' => 119, 'district_id' => 16, 'name_th' => 'ดินแดง', 'name_en' => 'Din Daeng', 'postal_code' => '10400'],
        ['id' => 120, 'district_id' => 16, 'name_th' => 'หวยขวาง', 'name_en' => 'Huai Khwang', 'postal_code' => '10310'],
        ['id' => 121, 'district_id' => 16, 'name_th' => 'สามเสนใน', 'name_en' => 'Sam Sen Nai', 'postal_code' => '10400'],
        
        // Bangkok - Bueng Kum Sub-districts (District ID 17)
        ['id' => 122, 'district_id' => 17, 'name_th' => 'บึงกุ่ม', 'name_en' => 'Bueng Kum', 'postal_code' => '10230'],
        ['id' => 123, 'district_id' => 17, 'name_th' => 'คลองกุ่ม', 'name_en' => 'Khlong Kum', 'postal_code' => '10230'],
        ['id' => 124, 'district_id' => 17, 'name_th' => 'ลำต้าไผ่', 'name_en' => 'Lam Ta Phai', 'postal_code' => '10230'],
        
        // Bangkok - Bang Na Sub-districts (District ID 19)
        ['id' => 125, 'district_id' => 19, 'name_th' => 'บางนา', 'name_en' => 'Bang Na', 'postal_code' => '10260'],
        ['id' => 126, 'district_id' => 19, 'name_th' => 'บางนาเหนือ', 'name_en' => 'Bang Na Nuea', 'postal_code' => '10260'],
        ['id' => 127, 'district_id' => 19, 'name_th' => 'บางนาใต้', 'name_en' => 'Bang Na Tai', 'postal_code' => '10260'],
        
        // Bangkok - Phasi Charoen Sub-districts (District ID 20)
        ['id' => 128, 'district_id' => 20, 'name_th' => 'ภาษีเจริญ', 'name_en' => 'Phasi Charoen', 'postal_code' => '10160'],
        ['id' => 129, 'district_id' => 20, 'name_th' => 'คูหาสวรรค์', 'name_en' => 'Khu Ha Sawan', 'postal_code' => '10160'],
        ['id' => 130, 'district_id' => 20, 'name_th' => 'บางวา', 'name_en' => 'Bang Wa', 'postal_code' => '10160'],
        
        // Bangkok - Nong Khaem Sub-districts (District ID 21)
        ['id' => 131, 'district_id' => 21, 'name_th' => 'หนองแขม', 'name_en' => 'Nong Khaem', 'postal_code' => '10160'],
        ['id' => 132, 'district_id' => 21, 'name_th' => 'นาคลอง', 'name_en' => 'Na Khlong', 'postal_code' => '10160'],
        ['id' => 133, 'district_id' => 21, 'name_th' => 'เขตภาษีเจริญ', 'name_en' => 'Khet Phasi Charoen', 'postal_code' => '10160'],
        
        // Bangkok - Rat Burana Sub-districts (District ID 22)
        ['id' => 134, 'district_id' => 22, 'name_th' => 'ราษฎร์บูรณะ', 'name_en' => 'Rat Burana', 'postal_code' => '10140'],
        ['id' => 135, 'district_id' => 22, 'name_th' => 'บางปะกอก', 'name_en' => 'Bang Pakok', 'postal_code' => '10140'],
        ['id' => 136, 'district_id' => 22, 'name_th' => 'ห้วยขวาง', 'name_en' => 'Huai Khwang', 'postal_code' => '10140'],
        
        // Bangkok - Bang Khae Sub-districts (District ID 23)
        ['id' => 137, 'district_id' => 23, 'name_th' => 'บางแค', 'name_en' => 'Bang Khae', 'postal_code' => '10160'],
        ['id' => 138, 'district_id' => 23, 'name_th' => 'บางแคเหนือ', 'name_en' => 'Bang Khae Nuea', 'postal_code' => '10160'],
        ['id' => 139, 'district_id' => 23, 'name_th' => 'บางพร้อม', 'name_en' => 'Bang Prom', 'postal_code' => '10160'],
        
        // Bangkok - Lak Si Sub-districts (District ID 24)
        ['id' => 140, 'district_id' => 24, 'name_th' => 'หลักสี่', 'name_en' => 'Lak Si', 'postal_code' => '10210'],
        ['id' => 141, 'district_id' => 24, 'name_th' => 'ตลาดบางเก็น', 'name_en' => 'Talat Bang Ken', 'postal_code' => '10210'],
        ['id' => 142, 'district_id' => 24, 'name_th' => 'ทุ่งสองห้อง', 'name_en' => 'Thung Song Hong', 'postal_code' => '10210'],
        
        // Bangkok - Sai Mai Sub-districts (District ID 25)
        ['id' => 143, 'district_id' => 25, 'name_th' => 'สายไหม', 'name_en' => 'Sai Mai', 'postal_code' => '10220'],
        ['id' => 144, 'district_id' => 25, 'name_th' => 'คลองถนน้อม', 'name_en' => 'Khlong Thanon', 'postal_code' => '10220'],
        ['id' => 145, 'district_id' => 25, 'name_th' => 'อ้อมเกต', 'name_en' => 'Om Kret', 'postal_code' => '10220'],
        
        // Bangkok - Khan Na Yao Sub-districts (District ID 26)
        ['id' => 146, 'district_id' => 26, 'name_th' => 'คันนายาว', 'name_en' => 'Khan Na Yao', 'postal_code' => '10230'],
        ['id' => 147, 'district_id' => 26, 'name_th' => 'รามคำแหง', 'name_en' => 'Ram Kham Haeng', 'postal_code' => '10240'],
        ['id' => 148, 'district_id' => 26, 'name_th' => 'สะพานสูง', 'name_en' => 'Saphan Sung', 'postal_code' => '10240'],
        
        // Bangkok - Ratchathewi Sub-districts (District ID 36)
        ['id' => 149, 'district_id' => 36, 'name_th' => 'ราชเทวี', 'name_en' => 'Ratchathewi', 'postal_code' => '10400'],
        ['id' => 150, 'district_id' => 36, 'name_th' => 'มัคคะสัน', 'name_en' => 'Makkasan', 'postal_code' => '10400'],
        ['id' => 151, 'district_id' => 36, 'name_th' => 'พญาไท', 'name_en' => 'Phaya Thai', 'postal_code' => '10400'],
        
        // Bangkok - Lat Phrao Sub-districts (District ID 37)
        ['id' => 152, 'district_id' => 37, 'name_th' => 'ลาดพร้าว', 'name_en' => 'Lat Phrao', 'postal_code' => '10230'],
        ['id' => 153, 'district_id' => 37, 'name_th' => 'จอมพล', 'name_en' => 'Chom Phon', 'postal_code' => '10900'],
        ['id' => 154, 'district_id' => 37, 'name_th' => 'วังทองหลาง', 'name_en' => 'Wang Thong Lang', 'postal_code' => '10310'],
        
        // Bangkok - Klongtoei Sub-districts (District ID 41)
        ['id' => 155, 'district_id' => 41, 'name_th' => 'คลองเตย', 'name_en' => 'Khlong Toei', 'postal_code' => '10110'],
        ['id' => 156, 'district_id' => 41, 'name_th' => 'คลองตัน', 'name_en' => 'Khlong Tan', 'postal_code' => '10110'],
        ['id' => 157, 'district_id' => 41, 'name_th' => 'พระโขนง', 'name_en' => 'Phra Khanong', 'postal_code' => '10110'],
        
        // Bangkok - Min Buri Sub-districts (District ID 10)
        ['id' => 158, 'district_id' => 10, 'name_th' => 'มีนบุรี', 'name_en' => 'Min Buri', 'postal_code' => '10510'],
        ['id' => 159, 'district_id' => 10, 'name_th' => 'แสนแสบ', 'name_en' => 'Saen Saeb', 'postal_code' => '10510'],
        ['id' => 160, 'district_id' => 10, 'name_th' => 'นวมินทราชินี', 'name_en' => 'Nawamin Rachini', 'postal_code' => '10510'],
        
        // Bangkok - Bang Phlat Sub-districts (District ID 15)
        ['id' => 161, 'district_id' => 15, 'name_th' => 'บางพลัด', 'name_en' => 'Bang Phlat', 'postal_code' => '10700'],
        ['id' => 162, 'district_id' => 15, 'name_th' => 'บางอ้อ', 'name_en' => 'Bang O', 'postal_code' => '10700'],
        ['id' => 163, 'district_id' => 15, 'name_th' => 'บางบำหรุ', 'name_en' => 'Bang Bamru', 'postal_code' => '10700'],
        
        // Bangkok - Din Daeng Sub-districts (District ID 16)
        ['id' => 164, 'district_id' => 16, 'name_th' => 'ดินแดง', 'name_en' => 'Din Daeng', 'postal_code' => '10400'],
        ['id' => 165, 'district_id' => 16, 'name_th' => 'หวยขวาง', 'name_en' => 'Huai Khwang', 'postal_code' => '10310'],
        ['id' => 166, 'district_id' => 16, 'name_th' => 'สามเสนใน', 'name_en' => 'Sam Sen Nai', 'postal_code' => '10400'],
        
        // Bangkok - Bueng Kum Sub-districts (District ID 17)
        ['id' => 167, 'district_id' => 17, 'name_th' => 'บึงกุ่ม', 'name_en' => 'Bueng Kum', 'postal_code' => '10230'],
        ['id' => 168, 'district_id' => 17, 'name_th' => 'คลองกุ่ม', 'name_en' => 'Khlong Kum', 'postal_code' => '10230'],
        ['id' => 169, 'district_id' => 17, 'name_th' => 'ลำต้าไผ่', 'name_en' => 'Lam Ta Phai', 'postal_code' => '10230'],
        
        // Bangkok - Phasi Charoen Sub-districts (District ID 20)
        ['id' => 170, 'district_id' => 20, 'name_th' => 'ภาษีเจริญ', 'name_en' => 'Phasi Charoen', 'postal_code' => '10160'],
        ['id' => 171, 'district_id' => 20, 'name_th' => 'คูหาสวรรค์', 'name_en' => 'Khu Ha Sawan', 'postal_code' => '10160'],
        ['id' => 172, 'district_id' => 20, 'name_th' => 'บางวา', 'name_en' => 'Bang Wa', 'postal_code' => '10160'],
        
        // Bangkok - Sai Mai Sub-districts (District ID 25)
        ['id' => 173, 'district_id' => 25, 'name_th' => 'สายไหม', 'name_en' => 'Sai Mai', 'postal_code' => '10220'],
        ['id' => 174, 'district_id' => 25, 'name_th' => 'คลองถนน้อม', 'name_en' => 'Khlong Thanon', 'postal_code' => '10220'],
        ['id' => 175, 'district_id' => 25, 'name_th' => 'อ้อมเกต', 'name_en' => 'Om Kret', 'postal_code' => '10220'],
        
        // Bangkok - Saphan Phut Sub-districts (District ID 27)
        ['id' => 176, 'district_id' => 27, 'name_th' => 'สะพานพุทธ', 'name_en' => 'Saphan Phut', 'postal_code' => '10100'],
        ['id' => 177, 'district_id' => 27, 'name_th' => 'ตลาดพลู', 'name_en' => 'Talat Phlu', 'postal_code' => '10100'],
        ['id' => 178, 'district_id' => 27, 'name_th' => 'คลองสาน', 'name_en' => 'Khlong San', 'postal_code' => '10600'],
        
        // Bangkok - Wang Thonglang Sub-districts (District ID 28)
        ['id' => 179, 'district_id' => 28, 'name_th' => 'วังทองหลาง', 'name_en' => 'Wang Thonglang', 'postal_code' => '10310'],
        ['id' => 180, 'district_id' => 28, 'name_th' => 'ลาดพร้าว', 'name_en' => 'Lat Phrao', 'postal_code' => '10230'],
        ['id' => 181, 'district_id' => 28, 'name_th' => 'สาปัดดู', 'name_th' => 'Saphan Du', 'postal_code' => '10310'],
        
        // Bangkok - Khlong San Sub-districts (District ID 29)
        ['id' => 182, 'district_id' => 29, 'name_th' => 'คลองสาน', 'name_en' => 'Khlong San', 'postal_code' => '10600'],
        ['id' => 183, 'district_id' => 29, 'name_th' => 'ตลาดพลู', 'name_en' => 'Talat Phlu', 'postal_code' => '10600'],
        ['id' => 184, 'district_id' => 29, 'name_th' => 'บ้านคล้อ', 'name_en' => 'Ban Kho', 'postal_code' => '10600'],
        
        // Bangkok - Taling Chan Sub-districts (District ID 30)
        ['id' => 185, 'district_id' => 30, 'name_th' => 'ตลิ่งชัน', 'name_en' => 'Taling Chan', 'postal_code' => '10170'],
        ['id' => 186, 'district_id' => 30, 'name_th' => 'บางราก้าย', 'name_en' => 'Bang Ramat', 'postal_code' => '10170'],
        ['id' => 187, 'district_id' => 30, 'name_th' => 'ตลาดบางเก็น', 'name_en' => 'Talat Bang Ken', 'postal_code' => '10170'],
        
        // Bangkok - Bangkok Yai Sub-districts (District ID 31)
        ['id' => 188, 'district_id' => 31, 'name_th' => 'บางกอกใหญ่', 'name_en' => 'Bangkok Yai', 'postal_code' => '10600'],
        ['id' => 189, 'district_id' => 31, 'name_th' => 'วัดกัลยาณิวัต', 'name_en' => 'Wat Kalyaniwat', 'postal_code' => '10600'],
        ['id' => 190, 'district_id' => 31, 'name_th' => 'วัดท่าพระ', 'name_en' => 'Wat Tha Phra', 'postal_code' => '10600'],
        
        // Bangkok - Bangkok Noi Sub-districts (District ID 32)
        ['id' => 191, 'district_id' => 32, 'name_th' => 'บางกอกน้อย', 'name_en' => 'Bangkok Noi', 'postal_code' => '10700'],
        ['id' => 192, 'district_id' => 32, 'name_th' => 'ศิริราช', 'name_en' => 'Siriraj', 'postal_code' => '10700'],
        ['id' => 193, 'district_id' => 32, 'name_th' => 'บ้านจาก', 'name_en' => 'Ban Chang Lo', 'postal_code' => '10700'],
        
        // Bangkok - Bang Khun Thian Sub-districts (District ID 33)
        ['id' => 194, 'district_id' => 33, 'name_th' => 'บางขุนเทียน', 'name_en' => 'Bang Khun Thian', 'postal_code' => '10150'],
        ['id' => 195, 'district_id' => 33, 'name_th' => 'จอมทอง', 'name_en' => 'Chom Thong', 'postal_code' => '10150'],
        ['id' => 196, 'district_id' => 33, 'name_th' => 'บางมด', 'name_en' => 'Bang Mot', 'postal_code' => '10150'],
        
        // Bangkok - Chom Thong Sub-districts (District ID 34)
        ['id' => 197, 'district_id' => 34, 'name_th' => 'จอมทอง', 'name_en' => 'Chom Thong', 'postal_code' => '10150'],
        ['id' => 198, 'district_id' => 34, 'name_th' => 'บางขุนเทียน', 'name_en' => 'Bang Khun Thian', 'postal_code' => '10150'],
        ['id' => 199, 'district_id' => 34, 'name_th' => 'บางมด', 'name_en' => 'Bang Mot', 'postal_code' => '10150'],
        
        // Bangkok - Don Mueang Sub-districts (District ID 35)
        ['id' => 200, 'district_id' => 35, 'name_th' => 'ดอนเมือง', 'name_en' => 'Don Mueang', 'postal_code' => '10210'],
        ['id' => 201, 'district_id' => 35, 'name_th' => 'สีกัน', 'name_en' => 'Si Kan', 'postal_code' => '10210'],
        ['id' => 202, 'district_id' => 35, 'name_th' => 'สวนหลวง', 'name_en' => 'Suan Luang', 'postal_code' => '10210'],
        
        // Bangkok - Bang Kho Laem Sub-districts (District ID 39)
        ['id' => 203, 'district_id' => 39, 'name_th' => 'บางคอแหลม', 'name_en' => 'Bang Kho Laem', 'postal_code' => '10120'],
        ['id' => 204, 'district_id' => 39, 'name_th' => 'บางโคล่', 'name_en' => 'Bang Khlo', 'postal_code' => '10120'],
        ['id' => 205, 'district_id' => 39, 'name_th' => 'วัดพระยา', 'name_en' => 'Wat Phraya', 'postal_code' => '10120'],
        
        // Bangkok - Prawet Sub-districts (District ID 40)
        ['id' => 206, 'district_id' => 40, 'name_th' => 'ประเวศ', 'name_en' => 'Prawet', 'postal_code' => '10250'],
        ['id' => 207, 'district_id' => 40, 'name_th' => 'หนองบอน', 'name_en' => 'Nong Bon', 'postal_code' => '10250'],
        ['id' => 208, 'district_id' => 40, 'name_th' => 'ดอกไม้', 'name_en' => 'Dok Mai', 'postal_code' => '10250'],
        
        // Bangkok - Suan Luang Sub-districts (District ID 42)
        ['id' => 209, 'district_id' => 42, 'name_th' => 'สวนหลวง', 'name_en' => 'Suan Luang', 'postal_code' => '10250'],
        ['id' => 210, 'district_id' => 42, 'name_th' => 'พัฒนาการ', 'name_en' => 'Phatthana Kan', 'postal_code' => '10250'],
        ['id' => 211, 'district_id' => 42, 'name_th' => 'วัดศรีเอียง', 'name_en' => 'Wat Si Eiang', 'postal_code' => '10250'],
        
        // Bangkok - Bang Bon Sub-districts (District ID 44)
        ['id' => 212, 'district_id' => 44, 'name_th' => 'บางบอน', 'name_en' => 'Bang Bon', 'postal_code' => '10150'],
        ['id' => 213, 'district_id' => 44, 'name_th' => 'คลองบางบอน', 'name_en' => 'Khlong Bang Bon', 'postal_code' => '10150'],
        ['id' => 214, 'district_id' => 44, 'name_th' => 'คลองแสนแสบ', 'name_en' => 'Khlong Saen Saep', 'postal_code' => '10150'],
        
        // Bangkok - Thon Buri Sub-districts (District ID 47)
        ['id' => 215, 'district_id' => 47, 'name_th' => 'ธนบุรี', 'name_en' => 'Thon Buri', 'postal_code' => '10600'],
        ['id' => 216, 'district_id' => 47, 'name_th' => 'ตลาดพลู', 'name_en' => 'Talat Phlu', 'postal_code' => '10600'],
        ['id' => 217, 'district_id' => 47, 'name_th' => 'หิรัญรูจี', 'name_en' => 'Hiran Ruchi', 'postal_code' => '10600'],
        
        // Bangkok - Bang Khae District Sub-districts (District ID 46)
        ['id' => 218, 'district_id' => 46, 'name_th' => 'บางแคอำเภอ', 'name_en' => 'Bang Khae Amphoe', 'postal_code' => '10160'],
        ['id' => 219, 'district_id' => 46, 'name_th' => 'บางแค', 'name_en' => 'Bang Khae', 'postal_code' => '10160'],
        ['id' => 220, 'district_id' => 46, 'name_th' => 'บางพร้อม', 'name_en' => 'Bang Prom', 'postal_code' => '10160'],
        
        // Bangkok - Lat Krabang 2nd Sub-districts (District ID 45 - ซ้ำ)
        ['id' => 221, 'district_id' => 45, 'name_th' => 'ลาดกระบัง', 'name_en' => 'Lat Krabang', 'postal_code' => '10520'],
        ['id' => 222, 'district_id' => 45, 'name_th' => 'คลองสองต้นนุ่น', 'name_en' => 'Khlong Song Ton Nun', 'postal_code' => '10520'],
        ['id' => 223, 'district_id' => 45, 'name_th' => 'คลองสามประเทศ', 'name_en' => 'Khlong Sam Prawet', 'postal_code' => '10520'],
        
        // Bangkok - Bua Khwan Sub-districts (District ID 48)
        ['id' => 224, 'district_id' => 48, 'name_th' => 'บวรเขต', 'name_en' => 'Bua Khwan', 'postal_code' => '10230'],
        ['id' => 225, 'district_id' => 48, 'name_th' => 'บึงกุ่ม', 'name_en' => 'Bueng Kum', 'postal_code' => '10230'],
        ['id' => 226, 'district_id' => 48, 'name_th' => 'คลองกุ่ม', 'name_en' => 'Khlong Kum', 'postal_code' => '10230'],
        
        // Chiang Mai - Mueang Chiang Mai Sub-districts (District ID 51)
        ['id' => 44, 'district_id' => 51, 'name_th' => 'ศรีภูมิ', 'name_en' => 'Si Phum', 'postal_code' => '50200'],
        ['id' => 45, 'district_id' => 51, 'name_th' => 'ป่าตัน', 'name_en' => 'Pa Tan', 'postal_code' => '50300'],
        ['id' => 46, 'district_id' => 51, 'name_th' => 'หายยา', 'name_en' => 'Hai Ya', 'postal_code' => '50100'],
        ['id' => 47, 'district_id' => 51, 'name_th' => 'ช่างม่อย', 'name_en' => 'Chang Moi', 'postal_code' => '50300'],
        ['id' => 48, 'district_id' => 51, 'name_th' => 'วัดเกต', 'name_en' => 'Wat Ket', 'postal_code' => '50000'],
        
        // Chiang Mai - Mae Rim Sub-districts (District ID 53)
        ['id' => 49, 'district_id' => 53, 'name_th' => 'แม่ริม', 'name_en' => 'Mae Rim', 'postal_code' => '50180'],
        ['id' => 50, 'district_id' => 53, 'name_th' => 'ดงแก้ว', 'name_en' => 'Dong Kaeo', 'postal_code' => '50180'],
        ['id' => 51, 'district_id' => 53, 'name_th' => 'ริมใต้', 'name_en' => 'Rim Tai', 'postal_code' => '50180'],
        
        // Nonthaburi - Mueang Nonthaburi Sub-districts (District ID 59)
        ['id' => 52, 'district_id' => 59, 'name_th' => 'สวนใหญ่', 'name_en' => 'Suan Yai', 'postal_code' => '11000'],
        ['id' => 53, 'district_id' => 59, 'name_th' => 'ตลาดขวัญ', 'name_en' => 'Talat Khwan', 'postal_code' => '11000'],
        ['id' => 54, 'district_id' => 59, 'name_th' => 'บางกระสอ', 'name_en' => 'Bang Kra So', 'postal_code' => '11000'],
        ['id' => 55, 'district_id' => 59, 'name_th' => 'บ้านใหม่', 'name_en' => 'Ban Mai', 'postal_code' => '11000'],
        
        // Nonthaburi - Bang Kruai Sub-districts (District ID 60)
        ['id' => 56, 'district_id' => 60, 'name_th' => 'บางกรวย', 'name_en' => 'Bang Kruai', 'postal_code' => '11130'],
        ['id' => 57, 'district_id' => 60, 'name_th' => 'บางแม่นาง', 'name_en' => 'Bang Mae Nang', 'postal_code' => '11130'],
        ['id' => 58, 'district_id' => 60, 'name_th' => 'มหาสวัสดิ์', 'name_en' => 'Maha Sawat', 'postal_code' => '11130'],
        ['id' => 59, 'district_id' => 60, 'name_th' => 'พลายบางเลน', 'name_en' => 'Plai Bang Len', 'postal_code' => '11130'],
        
        // Nonthaburi - Bang Yai Sub-districts (District ID 61)
        ['id' => 60, 'district_id' => 61, 'name_th' => 'บางใหญ่', 'name_en' => 'Bang Yai', 'postal_code' => '11140'],
        ['id' => 61, 'district_id' => 61, 'name_th' => 'บางแม่นาง', 'name_en' => 'Bang Mae Nang', 'postal_code' => '11140'],
        ['id' => 62, 'district_id' => 61, 'name_th' => 'เสาธงหิน', 'name_en' => 'Sao Thong Hin', 'postal_code' => '11140'],
        
        // Pathum Thani - Mueang Pathum Thani Sub-districts (District ID 66)
        ['id' => 63, 'district_id' => 66, 'name_th' => 'บ้านกลาง', 'name_en' => 'Ban Klang', 'postal_code' => '12000'],
        ['id' => 64, 'district_id' => 66, 'name_th' => 'บางพูน', 'name_en' => 'Bang Phun', 'postal_code' => '12000'],
        ['id' => 65, 'district_id' => 66, 'name_th' => 'บางปรอก', 'name_en' => 'Bang Prok', 'postal_code' => '12000'],
        ['id' => 66, 'district_id' => 66, 'name_th' => 'บางคา', 'name_en' => 'Bang Kha', 'postal_code' => '12000'],
        
        // Pathum Thani - Khlong Luang Sub-districts (District ID 67)
        ['id' => 67, 'district_id' => 67, 'name_th' => 'คลองหลวง', 'name_en' => 'Khlong Luang', 'postal_code' => '12120'],
        ['id' => 68, 'district_id' => 67, 'name_th' => 'คลองหก', 'name_en' => 'Khlong Hok', 'postal_code' => '12120'],
        ['id' => 69, 'district_id' => 67, 'name_th' => 'คลองสาม', 'name_en' => 'Khlong Sam', 'postal_code' => '12120'],
        ['id' => 70, 'district_id' => 67, 'name_th' => 'รังสิต', 'name_en' => 'Rangsit', 'postal_code' => '12000'],
        
        // Pathum Thani - Thanyaburi Sub-districts (District ID 68)
        ['id' => 71, 'district_id' => 68, 'name_th' => 'ประชาธิปัตย์', 'name_en' => 'Prachathipat', 'postal_code' => '12130'],
        ['id' => 72, 'district_id' => 68, 'name_th' => 'บึงยี่โถ', 'name_en' => 'Bueng Yi Tho', 'postal_code' => '12130'],
        ['id' => 73, 'district_id' => 68, 'name_th' => 'บึงน้ำรักษ์', 'name_en' => 'Bueng Nam Rak', 'postal_code' => '12130'],
        ['id' => 74, 'district_id' => 68, 'name_th' => 'รังสิต', 'name_en' => 'Rangsit', 'postal_code' => '12000'],
        
        // Samut Prakan - Mueang Samut Prakan Sub-districts (District ID 73)
        ['id' => 75, 'district_id' => 73, 'name_th' => 'ปากน้ำ', 'name_en' => 'Pak Nam', 'postal_code' => '10270'],
        ['id' => 76, 'district_id' => 73, 'name_th' => 'ท่าข้าม', 'name_en' => 'Tha Kham', 'postal_code' => '10270'],
        ['id' => 77, 'district_id' => 73, 'name_th' => 'นาเกลือ', 'name_en' => 'Na Kluea', 'postal_code' => '10270'],
        ['id' => 78, 'district_id' => 73, 'name_th' => 'แสมดำ', 'name_en' => 'Saem Dam', 'postal_code' => '10270'],
        
        // Samut Prakan - Bang Phli Sub-districts (District ID 74)
        ['id' => 79, 'district_id' => 74, 'name_th' => 'บางพลีใหญ่', 'name_en' => 'Bang Phli Yai', 'postal_code' => '10540'],
        ['id' => 80, 'district_id' => 74, 'name_th' => 'บางพลีน้อย', 'name_en' => 'Bang Phli Noi', 'postal_code' => '10540'],
        ['id' => 81, 'district_id' => 74, 'name_th' => 'บางชะอำ', 'name_en' => 'Bang Cha Am', 'postal_code' => '10540'],
        ['id' => 82, 'district_id' => 74, 'name_th' => 'หนองปรือ', 'name_en' => 'Nong Prue', 'postal_code' => '10540'],
        
        // Samut Prakan - Phra Pradaeng Sub-districts (District ID 76)
        ['id' => 83, 'district_id' => 76, 'name_th' => 'พระประแดง', 'name_en' => 'Phra Pradaeng', 'postal_code' => '10130'],
        ['id' => 84, 'district_id' => 76, 'name_th' => 'ตลาดพลู', 'name_en' => 'Talat Phlu', 'postal_code' => '10130'],
        ['id' => 85, 'district_id' => 76, 'name_th' => 'บางกะเจ้า', 'name_en' => 'Bang Ka Chao', 'postal_code' => '10130'],
        ['id' => 86, 'district_id' => 76, 'name_th' => 'บางโคล่', 'name_en' => 'Bang Khlo', 'postal_code' => '10130'],
    ];

    public function provinces()
    {
        return response()->json([
            'success' => true,
            'data' => self::$provinces
        ]);
    }

    public function districts($provinceId)
    {
        $districts = array_filter(self::$districts, function($district) use ($provinceId) {
            return $district['province_id'] == $provinceId;
        });

        return response()->json([
            'success' => true,
            'data' => array_values($districts)
        ]);
    }

    public function subDistricts($districtId)
    {
        $subDistricts = array_filter(self::$subDistricts, function($subDistrict) use ($districtId) {
            return $subDistrict['district_id'] == $districtId;
        });

        return response()->json([
            'success' => true,
            'data' => array_values($subDistricts)
        ]);
    }

    public function getFullAddress(Request $request)
    {
        $provinceId = $request->input('province_id');
        $districtId = $request->input('district_id');
        $subDistrictId = $request->input('sub_district_id');
        $address = $request->input('address', '');

        $province = collect(self::$provinces)->firstWhere('id', $provinceId);
        $district = collect(self::$districts)->firstWhere('id', $districtId);
        $subDistrict = collect(self::$subDistricts)->firstWhere('id', $subDistrictId);

        $parts = [];
        if (!empty($address)) $parts[] = $address;
        if ($subDistrict) $parts[] = 'ตำบล' . $subDistrict['name_th'];
        if ($district) $parts[] = 'อำเภอ' . $district['name_th'];
        if ($province) $parts[] = 'จังหวัด' . $province['name_th'];
        if ($subDistrict) $parts[] = $subDistrict['postal_code'];

        $fullAddress = implode(' ', $parts);

        return response()->json([
            'success' => true,
            'data' => [
                'full_address' => $fullAddress,
                'province' => $province,
                'district' => $district,
                'sub_district' => $subDistrict
            ]
        ]);
    }

    public function getDistrictById($id)
    {
        $district = collect(self::$districts)->firstWhere('id', (int)$id);
        
        if (!$district) {
            return response()->json([
                'success' => false,
                'message' => 'District not found'
            ], 404);
        }

        return response()->json($district);
    }

    public function getSubDistrictById($id)
    {
        $subDistrict = collect(self::$subDistricts)->firstWhere('id', (int)$id);
        
        if (!$subDistrict) {
            return response()->json([
                'success' => false,
                'message' => 'Sub-district not found'
            ], 404);
        }

        return response()->json($subDistrict);
    }
}