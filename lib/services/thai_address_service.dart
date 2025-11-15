import '../models/thai_address.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ThaiAddressService {
  static final ThaiAddressService _instance = ThaiAddressService._internal();
  factory ThaiAddressService() => _instance;
  ThaiAddressService._internal();

  static ThaiAddressService get instance => _instance;

  // Thai address data loaded from API
  List<Province> _provinces = [];

  final List<District> _districts = [];

  final List<SubDistrict> _subDistricts = [];

  // Get all provinces
  Future<List<Province>> getProvinces() async {
    if (_provinces.isEmpty) {
      await _loadProvincesFromAPI();
    }
    return List.from(_provinces);
  }

  Future<void> _loadProvincesFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/test/address/provinces'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] as List;
        _provinces = data
            .map((item) => Province(
                  id: item['id'],
                  nameTh: item['name_th'],
                  nameEn: item['name_en'] ?? '',
                ))
            .toList();
      }
    } catch (e) {
      // Fallback to default provinces if API fails
      _provinces = [
        Province(id: 1, nameTh: 'กรุงเทพมหานคร', nameEn: 'Bangkok'),
        Province(id: 2, nameTh: 'เชียงใหม่', nameEn: 'Chiang Mai'),
        Province(id: 3, nameTh: 'เชียงราย', nameEn: 'Chiang Rai'),
        Province(id: 4, nameTh: 'นนทบุรี', nameEn: 'Nonthaburi'),
      ];
    }
  }

  // Get districts by province ID
  Future<List<District>> getDistrictsByProvinceId(int provinceId) async {
    print('ThaiAddressService: Loading districts for province ID: $provinceId');
    try {
      final url = 'http://127.0.0.1:8000/test/address/districts/$provinceId';
      print('ThaiAddressService: Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      print('ThaiAddressService: Response status: ${response.statusCode}');
      print('ThaiAddressService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] as List;
        print('ThaiAddressService: Found ${data.length} districts');

        final districts = data
            .map((item) => District(
                  id: item['id'],
                  provinceId: item['province_id'],
                  nameTh: item['name_th'],
                  nameEn: item['name_en'] ?? '',
                ))
            .toList();

        print(
            'ThaiAddressService: Mapped districts: ${districts.map((d) => d.nameTh).join(', ')}');
        return districts;
      } else {
        print(
            'ThaiAddressService: API returned error status: ${response.statusCode}');
      }
    } catch (e) {
      print('ThaiAddressService: Error loading districts: $e');
    }

    // Fallback to sample districts if API fails
    print(
        'ThaiAddressService: Using fallback districts for province ID: $provinceId');
    return _getFallbackDistricts(provinceId);
  }

  // Get sub-districts by district ID
  Future<List<SubDistrict>> getSubDistrictsByDistrictId(int districtId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/test/address/sub-districts/$districtId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] as List;
        return data
            .map((item) => SubDistrict(
                  id: item['id'],
                  districtId: item['district_id'],
                  nameTh: item['name_th'],
                  nameEn: item['name_en'] ?? '',
                  postalCode: item['postal_code'] ?? '',
                ))
            .toList();
      }
    } catch (e) {
      print('Error loading sub-districts: $e');
    }

    // Fallback to sample sub-districts if API fails
    return _getFallbackSubDistricts(districtId);
  }

  // Get province by ID
  Future<Province?> getProvinceById(int id) async {
    if (_provinces.isEmpty) {
      await _loadProvincesFromAPI();
    }
    try {
      return _provinces.firstWhere((province) => province.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get district by ID
  Future<District?> getDistrictById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/test/address/district/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return District(
          id: data['id'],
          provinceId: data['province_id'],
          nameTh: data['name_th'],
          nameEn: data['name_en'] ?? '',
        );
      }
    } catch (e) {
      print('Error loading district by ID: $e');
    }
    return null;
  }

  // Get sub-district by ID
  Future<SubDistrict?> getSubDistrictById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/test/address/subdistrict/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubDistrict(
          id: data['id'],
          districtId: data['district_id'],
          nameTh: data['name_th'],
          nameEn: data['name_en'] ?? '',
          postalCode: data['postal_code'] ?? '',
        );
      }
    } catch (e) {
      print('Error loading sub-district by ID: $e');
    }
    return null;
  }

  // Search provinces by name
  Future<List<Province>> searchProvinces(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) return _provinces;

    return _provinces
        .where((province) =>
            province.nameTh.contains(query) ||
            province.nameEn.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get full address string
  Future<String> getFullAddress({
    int? provinceId,
    int? districtId,
    int? subDistrictId,
    String? address,
  }) async {
    final province =
        provinceId != null ? await getProvinceById(provinceId) : null;
    final district =
        districtId != null ? await getDistrictById(districtId) : null;
    final subDistrict =
        subDistrictId != null ? await getSubDistrictById(subDistrictId) : null;

    final parts = <String>[];
    if (address != null && address.isNotEmpty) parts.add(address);
    if (subDistrict != null) parts.add('ตำบล${subDistrict.nameTh}');
    if (district != null) parts.add('อำเภอ${district.nameTh}');
    if (province != null) parts.add('จังหวัด${province.nameTh}');
    if (subDistrict != null) parts.add(subDistrict.postalCode);

    return parts.join(' ');
  }

  // Fallback districts data when API is not available
  List<District> _getFallbackDistricts(int provinceId) {
    final Map<int, List<District>> fallbackData = {
      1: [
        // กรุงเทพมหานคร - ครบ 50 เขต
        District(id: 1, provinceId: 1, nameTh: 'พระนคร', nameEn: 'Phra Nakhon'),
        District(id: 2, provinceId: 1, nameTh: 'ดุสิต', nameEn: 'Dusit'),
        District(id: 3, provinceId: 1, nameTh: 'หนองจอก', nameEn: 'Nong Chok'),
        District(id: 4, provinceId: 1, nameTh: 'บางรัก', nameEn: 'Bang Rak'),
        District(id: 5, provinceId: 1, nameTh: 'บางเขน', nameEn: 'Bang Khen'),
        District(id: 6, provinceId: 1, nameTh: 'บางกะปิ', nameEn: 'Bang Kapi'),
        District(id: 7, provinceId: 1, nameTh: 'ปทุมวัน', nameEn: 'Pathum Wan'),
        District(
            id: 8,
            provinceId: 1,
            nameTh: 'ป้อมปราบศัตรูพ่าย',
            nameEn: 'Pom Prap Sattru Phai'),
        District(
            id: 9, provinceId: 1, nameTh: 'พระโขนง', nameEn: 'Phra Khanong'),
        District(id: 10, provinceId: 1, nameTh: 'มีนบุรี', nameEn: 'Min Buri'),
        District(
            id: 11, provinceId: 1, nameTh: 'ลาดกระบัง', nameEn: 'Lat Krabang'),
        District(id: 12, provinceId: 1, nameTh: 'ยานนาวา', nameEn: 'Yan Nawa'),
        District(
            id: 13,
            provinceId: 1,
            nameTh: 'สัมพันธวงศ์',
            nameEn: 'Samphanthawong'),
        District(id: 14, provinceId: 1, nameTh: 'พญาไท', nameEn: 'Phaya Thai'),
        District(id: 15, provinceId: 1, nameTh: 'ธนบุรี', nameEn: 'Thon Buri'),
        District(
            id: 16, provinceId: 1, nameTh: 'บางกอกใหญ่', nameEn: 'Bangkok Yai'),
        District(
            id: 17, provinceId: 1, nameTh: 'ห้วยขวาง', nameEn: 'Huai Khwang'),
        District(
            id: 18, provinceId: 1, nameTh: 'คลองเตย', nameEn: 'Khlong Toei'),
        District(
            id: 19, provinceId: 1, nameTh: 'สวนหลวง', nameEn: 'Suan Luang'),
        District(id: 20, provinceId: 1, nameTh: 'จตุจักร', nameEn: 'Chatuchak'),
        District(id: 21, provinceId: 1, nameTh: 'บางซื่อ', nameEn: 'Bang Sue'),
        District(id: 22, provinceId: 1, nameTh: 'บางปะอิน', nameEn: 'Bang Pho'),
        District(
            id: 23, provinceId: 1, nameTh: 'หนองแขม', nameEn: 'Nong Khaem'),
        District(
            id: 24, provinceId: 1, nameTh: 'ราษฎร์บูรณะ', nameEn: 'Rat Burana'),
        District(
            id: 25, provinceId: 1, nameTh: 'บางพลัด', nameEn: 'Bang Phlat'),
        District(id: 26, provinceId: 1, nameTh: 'ดินแดง', nameEn: 'Din Daeng'),
        District(id: 27, provinceId: 1, nameTh: 'บึงกุ่ม', nameEn: 'Bueng Kum'),
        District(id: 28, provinceId: 1, nameTh: 'สาทร', nameEn: 'Sathon'),
        District(
            id: 29,
            provinceId: 1,
            nameTh: 'บางคอแหลม',
            nameEn: 'Bang Kho Laem'),
        District(id: 30, provinceId: 1, nameTh: 'ประเวศ', nameEn: 'Prawet'),
        District(
            id: 31, provinceId: 1, nameTh: 'คลองสาน', nameEn: 'Khlong San'),
        District(
            id: 32, provinceId: 1, nameTh: 'ตลิ่งชัน', nameEn: 'Taling Chan'),
        District(
            id: 33, provinceId: 1, nameTh: 'บางกอกน้อย', nameEn: 'Bangkok Noi'),
        District(
            id: 34,
            provinceId: 1,
            nameTh: 'บางขุนเทียน',
            nameEn: 'Bang Khun Thian'),
        District(
            id: 35,
            provinceId: 1,
            nameTh: 'ภาษีเจริญ',
            nameEn: 'Phasi Charoen'),
        District(id: 36, provinceId: 1, nameTh: 'หนองจอก', nameEn: 'Nong Chok'),
        District(
            id: 37, provinceId: 1, nameTh: 'ราชเทวี', nameEn: 'Ratchathewi'),
        District(
            id: 38, provinceId: 1, nameTh: 'ลาดพร้าว', nameEn: 'Lat Phrao'),
        District(id: 39, provinceId: 1, nameTh: 'วัฒนา', nameEn: 'Watthana'),
        District(id: 40, provinceId: 1, nameTh: 'บางแค', nameEn: 'Bang Khae'),
        District(id: 41, provinceId: 1, nameTh: 'หลักสี่', nameEn: 'Lak Si'),
        District(id: 42, provinceId: 1, nameTh: 'สายไหม', nameEn: 'Sai Mai'),
        District(
            id: 43, provinceId: 1, nameTh: 'คันนายาว', nameEn: 'Khan Na Yao'),
        District(
            id: 44, provinceId: 1, nameTh: 'สะพานสูง', nameEn: 'Saphan Sung'),
        District(
            id: 45,
            provinceId: 1,
            nameTh: 'วังทองหลาง',
            nameEn: 'Wang Thonglang'),
        District(
            id: 46,
            provinceId: 1,
            nameTh: 'คลองสามวา',
            nameEn: 'Khlong Sam Wa'),
        District(id: 47, provinceId: 1, nameTh: 'บางนา', nameEn: 'Bang Na'),
        District(
            id: 48,
            provinceId: 1,
            nameTh: 'ทวีวัฒนา',
            nameEn: 'Thawi Watthana'),
        District(
            id: 49, provinceId: 1, nameTh: 'ทุ่งครุ', nameEn: 'Thung Khru'),
        District(id: 50, provinceId: 1, nameTh: 'บางบอน', nameEn: 'Bang Bon'),
      ],
      2: [
        // เชียงใหม่
        District(
            id: 51,
            provinceId: 2,
            nameTh: 'เมืองเชียงใหม่',
            nameEn: 'Mueang Chiang Mai'),
        District(id: 52, provinceId: 2, nameTh: 'จอมทอง', nameEn: 'Chom Thong'),
        District(id: 53, provinceId: 2, nameTh: 'แม่ริม', nameEn: 'Mae Rim'),
        District(id: 54, provinceId: 2, nameTh: 'สารภี', nameEn: 'Saraphi'),
        District(
            id: 55, provinceId: 2, nameTh: 'สันกำแพง', nameEn: 'San Kamphaeng'),
      ],
      3: [
        // เชียงราย
        District(
            id: 61,
            provinceId: 3,
            nameTh: 'เมืองเชียงราย',
            nameEn: 'Mueang Chiang Rai'),
        District(id: 62, provinceId: 3, nameTh: 'บ้านดู่', nameEn: 'Ban Du'),
        District(
            id: 63, provinceId: 3, nameTh: 'เชียงของ', nameEn: 'Chiang Khong'),
        District(id: 64, provinceId: 3, nameTh: 'เทิง', nameEn: 'Thoeng'),
      ],
      4: [
        // นนทบุรี
        District(
            id: 71,
            provinceId: 4,
            nameTh: 'เมืองนนทบุรี',
            nameEn: 'Mueang Nonthaburi'),
        District(
            id: 72, provinceId: 4, nameTh: 'บางกรวย', nameEn: 'Bang Kruai'),
        District(id: 73, provinceId: 4, nameTh: 'บางใหญ่', nameEn: 'Bang Yai'),
        District(
            id: 74,
            provinceId: 4,
            nameTh: 'บางบัวทอง',
            nameEn: 'Bang Bua Thong'),
        District(id: 75, provinceId: 4, nameTh: 'ไผ่', nameEn: 'Pai'),
        District(id: 76, provinceId: 4, nameTh: 'ปากเกร็ด', nameEn: 'Pak Kret'),
      ],
    };

    return fallbackData[provinceId] ?? [];
  }

  // Fallback sub-districts data when API is not available
  List<SubDistrict> _getFallbackSubDistricts(int districtId) {
    final Map<int, List<SubDistrict>> fallbackData = {
      // กรุงเทพมหานคร - เขตพระนคร
      1: [
        SubDistrict(
            id: 1,
            districtId: 1,
            nameTh: 'พระบรมมหาราชวัง',
            nameEn: 'Phra Borom Maha Ratchawang',
            postalCode: '10200'),
        SubDistrict(
            id: 2,
            districtId: 1,
            nameTh: 'วังบูรพาภิรมย์',
            nameEn: 'Wang Burapha Phirom',
            postalCode: '10200'),
        SubDistrict(
            id: 3,
            districtId: 1,
            nameTh: 'วัดราชบพิธ',
            nameEn: 'Wat Ratchabophit',
            postalCode: '10200'),
        SubDistrict(
            id: 4,
            districtId: 1,
            nameTh: 'สำราญราษฎร์',
            nameEn: 'Samranrat',
            postalCode: '10200'),
        SubDistrict(
            id: 5,
            districtId: 1,
            nameTh: 'ศิริราช',
            nameEn: 'Siriraj',
            postalCode: '10700'),
        SubDistrict(
            id: 6,
            districtId: 1,
            nameTh: 'บางยี่ขัน',
            nameEn: 'Bang Yi Khan',
            postalCode: '10700'),
        SubDistrict(
            id: 7,
            districtId: 1,
            nameTh: 'วัดสามพระยา',
            nameEn: 'Wat Sam Phraya',
            postalCode: '10200'),
        SubDistrict(
            id: 8,
            districtId: 1,
            nameTh: 'ชนะสงคราม',
            nameEn: 'Chana Songkhram',
            postalCode: '10200'),
        SubDistrict(
            id: 9,
            districtId: 1,
            nameTh: 'บวรนิเวศ',
            nameEn: 'Bowon Niwet',
            postalCode: '10200'),
        SubDistrict(
            id: 10,
            districtId: 1,
            nameTh: 'ตลาดยอด',
            nameEn: 'Talat Yot',
            postalCode: '10200'),
        SubDistrict(
            id: 11,
            districtId: 1,
            nameTh: 'พระนคร',
            nameEn: 'Phra Nakhon',
            postalCode: '10200'),
      ],
      // เขตดุสิต
      2: [
        SubDistrict(
            id: 12,
            districtId: 2,
            nameTh: 'ดุสิต',
            nameEn: 'Dusit',
            postalCode: '10300'),
        SubDistrict(
            id: 13,
            districtId: 2,
            nameTh: 'วชิรพยาบาล',
            nameEn: 'Wachiraphayaban',
            postalCode: '10300'),
        SubDistrict(
            id: 14,
            districtId: 2,
            nameTh: 'สวนจิตรลดา',
            nameEn: 'Suan Chitrlada',
            postalCode: '10300'),
        SubDistrict(
            id: 15,
            districtId: 2,
            nameTh: 'สี่แยกมหานาค',
            nameEn: 'Si Yaek Mahanak',
            postalCode: '10300'),
        SubDistrict(
            id: 16,
            districtId: 2,
            nameTh: 'ถนนนครไชยศรี',
            nameEn: 'Thanon Nakhon Chai Si',
            postalCode: '10300'),
      ],
      // เขตหนองจอก
      3: [
        SubDistrict(
            id: 17,
            districtId: 3,
            nameTh: 'กระทุ่มล้ม',
            nameEn: 'Krathum Lom',
            postalCode: '10530'),
        SubDistrict(
            id: 18,
            districtId: 3,
            nameTh: 'หนองจอก',
            nameEn: 'Nong Chok',
            postalCode: '10530'),
        SubDistrict(
            id: 19,
            districtId: 3,
            nameTh: 'คลองสิบ',
            nameEn: 'Khlong Sip',
            postalCode: '10530'),
        SubDistrict(
            id: 20,
            districtId: 3,
            nameTh: 'คลองสิบสอง',
            nameEn: 'Khlong Sip Song',
            postalCode: '10530'),
        SubDistrict(
            id: 21,
            districtId: 3,
            nameTh: 'โคกแฝด',
            nameEn: 'Khok Faet',
            postalCode: '10530'),
        SubDistrict(
            id: 22,
            districtId: 3,
            nameTh: 'ลำผักชี',
            nameEn: 'Lam Phak Chi',
            postalCode: '10530'),
        SubDistrict(
            id: 23,
            districtId: 3,
            nameTh: 'ลำต้อยติ่ง',
            nameEn: 'Lam Toi Ting',
            postalCode: '10530'),
      ],
      // เขตบางรัก
      4: [
        SubDistrict(
            id: 24,
            districtId: 4,
            nameTh: 'บางรัก',
            nameEn: 'Bang Rak',
            postalCode: '10500'),
        SubDistrict(
            id: 25,
            districtId: 4,
            nameTh: 'สีลม',
            nameEn: 'Si Lom',
            postalCode: '10500'),
        SubDistrict(
            id: 26,
            districtId: 4,
            nameTh: 'สุริยวงศ์',
            nameEn: 'Suriyawong',
            postalCode: '10500'),
        SubDistrict(
            id: 27,
            districtId: 4,
            nameTh: 'มหาพฤฒาราม',
            nameEn: 'Maha Phruettharam',
            postalCode: '10500'),
        SubDistrict(
            id: 28,
            districtId: 4,
            nameTh: 'บางรัก',
            nameEn: 'Bang Rak',
            postalCode: '10500'),
      ],
      // เขตบางเขน
      5: [
        SubDistrict(
            id: 29,
            districtId: 5,
            nameTh: 'อนุสาวรีย์',
            nameEn: 'Anusawari',
            postalCode: '10220'),
        SubDistrict(
            id: 30,
            districtId: 5,
            nameTh: 'บางเขน',
            nameEn: 'Bang Khen',
            postalCode: '10220'),
        SubDistrict(
            id: 31,
            districtId: 5,
            nameTh: 'ท่าแร้ง',
            nameEn: 'Tha Raeng',
            postalCode: '10220'),
      ],
      // เขตบางกะปิ
      6: [
        SubDistrict(
            id: 32,
            districtId: 6,
            nameTh: 'คลองจั่น',
            nameEn: 'Khlong Chan',
            postalCode: '10240'),
        SubDistrict(
            id: 33,
            districtId: 6,
            nameTh: 'หัวหมาก',
            nameEn: 'Hua Mak',
            postalCode: '10240'),
        SubDistrict(
            id: 34,
            districtId: 6,
            nameTh: 'บางกะปิ',
            nameEn: 'Bang Kapi',
            postalCode: '10240'),
      ],
      // เขตปทุมวัน
      7: [
        SubDistrict(
            id: 35,
            districtId: 7,
            nameTh: 'ปทุมวัน',
            nameEn: 'Pathum Wan',
            postalCode: '10330'),
        SubDistrict(
            id: 36,
            districtId: 7,
            nameTh: 'ลุมพินี',
            nameEn: 'Lumphini',
            postalCode: '10330'),
        SubDistrict(
            id: 37,
            districtId: 7,
            nameTh: 'รองเมือง',
            nameEn: 'Rong Mueang',
            postalCode: '10330'),
        SubDistrict(
            id: 38,
            districtId: 7,
            nameTh: 'วังใหม่',
            nameEn: 'Wang Mai',
            postalCode: '10330'),
      ],
      // เขตป้อมปราบศัตรูพ่าย
      8: [
        SubDistrict(
            id: 39,
            districtId: 8,
            nameTh: 'วัดโสมนัส',
            nameEn: 'Wat Sommanat',
            postalCode: '10100'),
        SubDistrict(
            id: 40,
            districtId: 8,
            nameTh: 'คลองมหานาค',
            nameEn: 'Khlong Mahanak',
            postalCode: '10100'),
        SubDistrict(
            id: 41,
            districtId: 8,
            nameTh: 'บ้านพานถม',
            nameEn: 'Ban Phan Thom',
            postalCode: '10100'),
        SubDistrict(
            id: 42,
            districtId: 8,
            nameTh: 'บวรนิเวศ',
            nameEn: 'Bowon Niwet',
            postalCode: '10200'),
      ],
      // เขตพระโขนง
      9: [
        SubDistrict(
            id: 43,
            districtId: 9,
            nameTh: 'บางจาก',
            nameEn: 'Bang Chak',
            postalCode: '10260'),
        SubDistrict(
            id: 44,
            districtId: 9,
            nameTh: 'พระโขนง',
            nameEn: 'Phra Khanong',
            postalCode: '10110'),
        SubDistrict(
            id: 45,
            districtId: 9,
            nameTh: 'คลองเตย',
            nameEn: 'Khlong Toei',
            postalCode: '10110'),
      ],
      // เขตมีนบุรี
      10: [
        SubDistrict(
            id: 46,
            districtId: 10,
            nameTh: 'มีนบุรี',
            nameEn: 'Min Buri',
            postalCode: '10510'),
        SubDistrict(
            id: 47,
            districtId: 10,
            nameTh: 'แสนแสบ',
            nameEn: 'Saen Saep',
            postalCode: '10510'),
      ],
      // เขตลาดกระบัง
      11: [
        SubDistrict(
            id: 48,
            districtId: 11,
            nameTh: 'ลาดกระบัง',
            nameEn: 'Lat Krabang',
            postalCode: '10520'),
        SubDistrict(
            id: 49,
            districtId: 11,
            nameTh: 'คลองสองต้นนุ่น',
            nameEn: 'Khlong Song Ton Nun',
            postalCode: '10520'),
        SubDistrict(
            id: 50,
            districtId: 11,
            nameTh: 'ลำปลาทิว',
            nameEn: 'Lam Pla Thio',
            postalCode: '10520'),
        SubDistrict(
            id: 51,
            districtId: 11,
            nameTh: 'ทับยาว',
            nameEn: 'Thap Yao',
            postalCode: '10520'),
        SubDistrict(
            id: 52,
            districtId: 11,
            nameTh: 'คูคต',
            nameEn: 'Khu Khot',
            postalCode: '10520'),
      ],
      // เขตยานนาวา
      12: [
        SubDistrict(
            id: 53,
            districtId: 12,
            nameTh: 'ช่องนนทรี',
            nameEn: 'Chong Nonsi',
            postalCode: '10120'),
        SubDistrict(
            id: 54,
            districtId: 12,
            nameTh: 'ยานนาวา',
            nameEn: 'Yan Nawa',
            postalCode: '10120'),
        SubDistrict(
            id: 55,
            districtId: 12,
            nameTh: 'ทุ่งมหาเมฆ',
            nameEn: 'Thung Mahamek',
            postalCode: '10120'),
      ],
      // เขตสัมพันธวงศ์
      13: [
        SubDistrict(
            id: 56,
            districtId: 13,
            nameTh: 'สัมพันธวงศ์',
            nameEn: 'Samphanthawong',
            postalCode: '10100'),
        SubDistrict(
            id: 57,
            districtId: 13,
            nameTh: 'ตลาดรถไฟ',
            nameEn: 'Talat Rot Fai',
            postalCode: '10100'),
        SubDistrict(
            id: 58,
            districtId: 13,
            nameTh: 'จักรวรรดิ',
            nameEn: 'Chakkrawat',
            postalCode: '10100'),
      ],
      // เขตพญาไท
      14: [
        SubDistrict(
            id: 59,
            districtId: 14,
            nameTh: 'พญาไท',
            nameEn: 'Phaya Thai',
            postalCode: '10400'),
        SubDistrict(
            id: 60,
            districtId: 14,
            nameTh: 'ทุ่งพญาไท',
            nameEn: 'Thung Phaya Thai',
            postalCode: '10400'),
        SubDistrict(
            id: 61,
            districtId: 14,
            nameTh: 'รางน้ำ',
            nameEn: 'Rang Nam',
            postalCode: '10400'),
        SubDistrict(
            id: 62,
            districtId: 14,
            nameTh: 'สามเสน',
            nameEn: 'Sam Sen',
            postalCode: '10400'),
      ],
      // เขตธนบุรี
      15: [
        SubDistrict(
            id: 63,
            districtId: 15,
            nameTh: 'ตลาดพลู',
            nameEn: 'Talat Phlu',
            postalCode: '10600'),
        SubDistrict(
            id: 64,
            districtId: 15,
            nameTh: 'บุคคโล',
            nameEn: 'Bukkhalo',
            postalCode: '10600'),
        SubDistrict(
            id: 65,
            districtId: 15,
            nameTh: 'หิรัญรูจี',
            nameEn: 'Hiran Ruchi',
            postalCode: '10600'),
        SubDistrict(
            id: 66,
            districtId: 15,
            nameTh: 'บางใหญ่',
            nameEn: 'Bang Yi Ruea',
            postalCode: '10600'),
        SubDistrict(
            id: 67,
            districtId: 15,
            nameTh: 'สำเหร่',
            nameEn: 'Sam Rae',
            postalCode: '10600'),
      ],
      // เขตบางกอกใหญ่
      16: [
        SubDistrict(
            id: 68,
            districtId: 16,
            nameTh: 'บ้านช่างหล่อ',
            nameEn: 'Ban Chang Lo',
            postalCode: '10600'),
        SubDistrict(
            id: 69,
            districtId: 16,
            nameTh: 'วัดท่าพระ',
            nameEn: 'Wat Tha Phra',
            postalCode: '10600'),
        SubDistrict(
            id: 70,
            districtId: 16,
            nameTh: 'วัดกัลยา',
            nameEn: 'Wat Kanlaya',
            postalCode: '10600'),
        SubDistrict(
            id: 71,
            districtId: 16,
            nameTh: 'ปากคลองภาษีเจริญ',
            nameEn: 'Pak Khlong Phasi Charoen',
            postalCode: '10600'),
      ],
      // เขตห้วยขวาง
      17: [
        SubDistrict(
            id: 72,
            districtId: 17,
            nameTh: 'ห้วยขวาง',
            nameEn: 'Huai Khwang',
            postalCode: '10310'),
        SubDistrict(
            id: 73,
            districtId: 17,
            nameTh: 'สุทธิสาร',
            nameEn: 'Sutthisan',
            postalCode: '10310'),
        SubDistrict(
            id: 74,
            districtId: 17,
            nameTh: 'ดินแดง',
            nameEn: 'Din Daeng',
            postalCode: '10400'),
      ],
      // เขตคลองเตย
      18: [
        SubDistrict(
            id: 75,
            districtId: 18,
            nameTh: 'คลองเตย',
            nameEn: 'Khlong Toei',
            postalCode: '10110'),
        SubDistrict(
            id: 76,
            districtId: 18,
            nameTh: 'คลองตัน',
            nameEn: 'Khlong Tan',
            postalCode: '10110'),
        SubDistrict(
            id: 77,
            districtId: 18,
            nameTh: 'พระโขนง',
            nameEn: 'Phra Khanong',
            postalCode: '10110'),
      ],
      // เขตสวนหลวง
      19: [
        SubDistrict(
            id: 78,
            districtId: 19,
            nameTh: 'สวนหลวง',
            nameEn: 'Suan Luang',
            postalCode: '10250'),
        SubDistrict(
            id: 79,
            districtId: 19,
            nameTh: 'ว่างทองหลาง',
            nameEn: 'Wang Thonglang',
            postalCode: '10310'),
      ],
      // เขตจตุจักร
      20: [
        SubDistrict(
            id: 80,
            districtId: 20,
            nameTh: 'จตุจักร',
            nameEn: 'Chatuchak',
            postalCode: '10900'),
        SubDistrict(
            id: 81,
            districtId: 20,
            nameTh: 'ลาดยาว',
            nameEn: 'Lat Yao',
            postalCode: '10900'),
        SubDistrict(
            id: 82,
            districtId: 20,
            nameTh: 'เสนานิคม',
            nameEn: 'Sena Nikhom',
            postalCode: '10900'),
        SubDistrict(
            id: 83,
            districtId: 20,
            nameTh: 'จันทรเกษม',
            nameEn: 'Chan Kasem',
            postalCode: '10900'),
      ],
      // เขตบางซื่อ
      21: [
        SubDistrict(
            id: 84,
            districtId: 21,
            nameTh: 'บางซื่อ',
            nameEn: 'Bang Sue',
            postalCode: '10800'),
        SubDistrict(
            id: 85,
            districtId: 21,
            nameTh: 'บางโพ',
            nameEn: 'Bang Pho',
            postalCode: '10800'),
        SubDistrict(
            id: 86,
            districtId: 21,
            nameTh: 'วงศ์ทอง',
            nameEn: 'Wong Sawang',
            postalCode: '10800'),
      ],
      // เขตบางปะอิน (แก้ไขเป็น บางพ)
      22: [
        SubDistrict(
            id: 87,
            districtId: 22,
            nameTh: 'บางพ',
            nameEn: 'Bang Pho',
            postalCode: '10160'),
        SubDistrict(
            id: 88,
            districtId: 22,
            nameTh: 'บ้านบาตร',
            nameEn: 'Ban Bat',
            postalCode: '10160'),
      ],
      // เขตหนองแขม
      23: [
        SubDistrict(
            id: 89,
            districtId: 23,
            nameTh: 'หนองแขม',
            nameEn: 'Nong Khaem',
            postalCode: '10160'),
        SubDistrict(
            id: 90,
            districtId: 23,
            nameTh: 'หนองค้างพลู',
            nameEn: 'Nong Khang Phlu',
            postalCode: '10160'),
        SubDistrict(
            id: 91,
            districtId: 23,
            nameTh: 'เพศร',
            nameEn: 'Phet',
            postalCode: '10160'),
      ],
      // เขตราษฎร์บูรณะ
      24: [
        SubDistrict(
            id: 92,
            districtId: 24,
            nameTh: 'ราษฎร์บูรณะ',
            nameEn: 'Rat Burana',
            postalCode: '10140'),
        SubDistrict(
            id: 93,
            districtId: 24,
            nameTh: 'บางปะกอก',
            nameEn: 'Bang Pakok',
            postalCode: '10140'),
      ],
      // เขตบางพลัด
      25: [
        SubDistrict(
            id: 94,
            districtId: 25,
            nameTh: 'บางพลัด',
            nameEn: 'Bang Phlat',
            postalCode: '10700'),
        SubDistrict(
            id: 95,
            districtId: 25,
            nameTh: 'บางอ้อ',
            nameEn: 'Bang O',
            postalCode: '10700'),
        SubDistrict(
            id: 96,
            districtId: 25,
            nameTh: 'บางยี่ขัน',
            nameEn: 'Bang Yi Khan',
            postalCode: '10700'),
        SubDistrict(
            id: 97,
            districtId: 25,
            nameTh: 'บางบำหรุ',
            nameEn: 'Bang Bamru',
            postalCode: '10700'),
      ],
      // เขตดินแดง
      26: [
        SubDistrict(
            id: 98,
            districtId: 26,
            nameTh: 'ดินแดง',
            nameEn: 'Din Daeng',
            postalCode: '10400'),
        SubDistrict(
            id: 99,
            districtId: 26,
            nameTh: 'ห้วยขวาง',
            nameEn: 'Huai Khwang',
            postalCode: '10310'),
      ],
      // เขตบึงกุ่ม
      27: [
        SubDistrict(
            id: 100,
            districtId: 27,
            nameTh: 'คลองกุ่ม',
            nameEn: 'Khlong Kum',
            postalCode: '10230'),
        SubDistrict(
            id: 101,
            districtId: 27,
            nameTh: 'บึงกุ่ม',
            nameEn: 'Bueng Kum',
            postalCode: '10230'),
      ],
      // เขตสาทร
      28: [
        SubDistrict(
            id: 102,
            districtId: 28,
            nameTh: 'สีลม',
            nameEn: 'Silom',
            postalCode: '10500'),
        SubDistrict(
            id: 103,
            districtId: 28,
            nameTh: 'ทุ่งมหาเมฆ',
            nameEn: 'Thung Mahamek',
            postalCode: '10120'),
        SubDistrict(
            id: 104,
            districtId: 28,
            nameTh: 'ยานนาวา',
            nameEn: 'Yan Nawa',
            postalCode: '10120'),
      ],
      // เขตบางคอแหลม
      29: [
        SubDistrict(
            id: 105,
            districtId: 29,
            nameTh: 'บางคอแหลม',
            nameEn: 'Bang Kho Laem',
            postalCode: '10120'),
        SubDistrict(
            id: 106,
            districtId: 29,
            nameTh: 'วัดพระยากราย',
            nameEn: 'Wat Phraya Krai',
            postalCode: '10120'),
        SubDistrict(
            id: 107,
            districtId: 29,
            nameTh: 'บางโคล่',
            nameEn: 'Bang Khlo',
            postalCode: '10120'),
      ],
      // เขตประเวศ
      30: [
        SubDistrict(
            id: 108,
            districtId: 30,
            nameTh: 'ประเวศ',
            nameEn: 'Prawet',
            postalCode: '10250'),
        SubDistrict(
            id: 109,
            districtId: 30,
            nameTh: 'หนองบอน',
            nameEn: 'Nong Bon',
            postalCode: '10250'),
        SubDistrict(
            id: 110,
            districtId: 30,
            nameTh: 'ดอกไม้',
            nameEn: 'Dok Mai',
            postalCode: '10250'),
        SubDistrict(
            id: 111,
            districtId: 30,
            nameTh: 'ศรีนครินทร์',
            nameEn: 'Si Nak Rin',
            postalCode: '10250'),
      ],
      // เขตคลองสาน
      31: [
        SubDistrict(
            id: 112,
            districtId: 31,
            nameTh: 'คลองสาน',
            nameEn: 'Khlong San',
            postalCode: '10600'),
        SubDistrict(
            id: 113,
            districtId: 31,
            nameTh: 'สมเด็จเจ้าพระยา',
            nameEn: 'Somdet Chao Phraya',
            postalCode: '10600'),
        SubDistrict(
            id: 114,
            districtId: 31,
            nameTh: 'บางลำภูล่าง',
            nameEn: 'Bang Lamphu Lang',
            postalCode: '10600'),
      ],
      // เขตตลิ่งชัน
      32: [
        SubDistrict(
            id: 115,
            districtId: 32,
            nameTh: 'ตลิ่งชัน',
            nameEn: 'Taling Chan',
            postalCode: '10170'),
        SubDistrict(
            id: 116,
            districtId: 32,
            nameTh: 'บางระมาด',
            nameEn: 'Bang Ramat',
            postalCode: '10170'),
        SubDistrict(
            id: 117,
            districtId: 32,
            nameTh: 'บางพรม',
            nameEn: 'Bang Phrom',
            postalCode: '10170'),
        SubDistrict(
            id: 118,
            districtId: 32,
            nameTh: 'ชิมพลี',
            nameEn: 'Chimphli',
            postalCode: '10170'),
        SubDistrict(
            id: 119,
            districtId: 32,
            nameTh: 'บ้านใหม่',
            nameEn: 'Ban Mai',
            postalCode: '10170'),
        SubDistrict(
            id: 120,
            districtId: 32,
            nameTh: 'บางก่อ',
            nameEn: 'Bang Ko',
            postalCode: '10170'),
        SubDistrict(
            id: 121,
            districtId: 32,
            nameTh: 'บางขุนศรี',
            nameEn: 'Bang Khun Si',
            postalCode: '10170'),
      ],
      // เขตบางกอกน้อย
      33: [
        SubDistrict(
            id: 122,
            districtId: 33,
            nameTh: 'บางกอกน้อย',
            nameEn: 'Bangkok Noi',
            postalCode: '10700'),
        SubDistrict(
            id: 123,
            districtId: 33,
            nameTh: 'บ้านช่างหล่อ',
            nameEn: 'Ban Chang Lo',
            postalCode: '10700'),
        SubDistrict(
            id: 124,
            districtId: 33,
            nameTh: 'บางขุนนนท์',
            nameEn: 'Bang Khun Non',
            postalCode: '10700'),
        SubDistrict(
            id: 125,
            districtId: 33,
            nameTh: 'ศิริราช',
            nameEn: 'Siriraj',
            postalCode: '10700'),
        SubDistrict(
            id: 126,
            districtId: 33,
            nameTh: 'อรุณอมรินทร์',
            nameEn: 'Arun Amarin',
            postalCode: '10700'),
      ],
      // เขตบางขุนเทียน
      34: [
        SubDistrict(
            id: 127,
            districtId: 34,
            nameTh: 'บางขุนเทียน',
            nameEn: 'Bang Khun Thian',
            postalCode: '10150'),
        SubDistrict(
            id: 128,
            districtId: 34,
            nameTh: 'จอมทอง',
            nameEn: 'Chom Thong',
            postalCode: '10150'),
        SubDistrict(
            id: 129,
            districtId: 34,
            nameTh: 'แสมดำ',
            nameEn: 'Saem Dam',
            postalCode: '10150'),
        SubDistrict(
            id: 130,
            districtId: 34,
            nameTh: 'คลองมะดัด',
            nameEn: 'Khlong Maduea',
            postalCode: '10150'),
        SubDistrict(
            id: 131,
            districtId: 34,
            nameTh: 'ท่าข้าม',
            nameEn: 'Tha Kham',
            postalCode: '10150'),
        SubDistrict(
            id: 132,
            districtId: 34,
            nameTh: 'บางมด',
            nameEn: 'Bang Mot',
            postalCode: '10150'),
        SubDistrict(
            id: 133,
            districtId: 34,
            nameTh: 'กกกอ',
            nameEn: 'Kok Kham',
            postalCode: '10150'),
      ],
      // เขตภาษีเจริญ
      35: [
        SubDistrict(
            id: 134,
            districtId: 35,
            nameTh: 'ภาษีเจริญ',
            nameEn: 'Phasi Charoen',
            postalCode: '10160'),
        SubDistrict(
            id: 135,
            districtId: 35,
            nameTh: 'บางแวก',
            nameEn: 'Bang Waek',
            postalCode: '10160'),
        SubDistrict(
            id: 136,
            districtId: 35,
            nameTh: 'บางจาก',
            nameEn: 'Bang Chak',
            postalCode: '10160'),
        SubDistrict(
            id: 137,
            districtId: 35,
            nameTh: 'คูหาสวรรค์',
            nameEn: 'Khu Hasawan',
            postalCode: '10160'),
        SubDistrict(
            id: 138,
            districtId: 35,
            nameTh: 'บางดวน',
            nameEn: 'Bang Duan',
            postalCode: '10160'),
        SubDistrict(
            id: 139,
            districtId: 35,
            nameTh: 'บางไผ่',
            nameEn: 'Bang Phai',
            postalCode: '10160'),
      ],
      // เขตราชเทวี
      37: [
        SubDistrict(
            id: 140,
            districtId: 37,
            nameTh: 'ราชเทวี',
            nameEn: 'Ratchathewi',
            postalCode: '10400'),
        SubDistrict(
            id: 141,
            districtId: 37,
            nameTh: 'ถนนเพชรบุรี',
            nameEn: 'Thanon Phetchaburi',
            postalCode: '10400'),
        SubDistrict(
            id: 142,
            districtId: 37,
            nameTh: 'มักกะสัน',
            nameEn: 'Makkasan',
            postalCode: '10400'),
        SubDistrict(
            id: 143,
            districtId: 37,
            nameTh: 'ราชปรารภ',
            nameEn: 'Ratchaprarop',
            postalCode: '10400'),
      ],
      // เขตลาดพร้าว
      38: [
        SubDistrict(
            id: 144,
            districtId: 38,
            nameTh: 'ลาดพร้าว',
            nameEn: 'Lat Phrao',
            postalCode: '10230'),
        SubDistrict(
            id: 145,
            districtId: 38,
            nameTh: 'จอมพล',
            nameEn: 'Chom Phon',
            postalCode: '10230'),
        SubDistrict(
            id: 146,
            districtId: 38,
            nameTh: 'จตุจักร',
            nameEn: 'Chatuchak',
            postalCode: '10900'),
      ],
      // เขตวัฒนา
      39: [
        SubDistrict(
            id: 147,
            districtId: 39,
            nameTh: 'คลองตันเหนือ',
            nameEn: 'Khlong Tan Nuea',
            postalCode: '10110'),
        SubDistrict(
            id: 148,
            districtId: 39,
            nameTh: 'คลองเตยเหนือ',
            nameEn: 'Khlong Toei Nuea',
            postalCode: '10110'),
        SubDistrict(
            id: 149,
            districtId: 39,
            nameTh: 'พระโขนงเหนือ',
            nameEn: 'Phra Khanong Nuea',
            postalCode: '10110'),
      ],
      // เขตบางแค
      40: [
        SubDistrict(
            id: 150,
            districtId: 40,
            nameTh: 'บางแค',
            nameEn: 'Bang Khae',
            postalCode: '10160'),
        SubDistrict(
            id: 151,
            districtId: 40,
            nameTh: 'บางแคเหนือ',
            nameEn: 'Bang Khae Nuea',
            postalCode: '10160'),
        SubDistrict(
            id: 152,
            districtId: 40,
            nameTh: 'หลักสอง',
            nameEn: 'Lak Song',
            postalCode: '10160'),
        SubDistrict(
            id: 153,
            districtId: 40,
            nameTh: 'บางพรหม',
            nameEn: 'Bang Phrom',
            postalCode: '10160'),
      ],
      // เขตหลักสี่
      41: [
        SubDistrict(
            id: 154,
            districtId: 41,
            nameTh: 'หลักสี่',
            nameEn: 'Lak Si',
            postalCode: '10210'),
        SubDistrict(
            id: 155,
            districtId: 41,
            nameTh: 'ตลาดบางเขน',
            nameEn: 'Talat Bang Khen',
            postalCode: '10210'),
        SubDistrict(
            id: 156,
            districtId: 41,
            nameTh: 'ทุ่งสองห้อง',
            nameEn: 'Thung Song Hong',
            postalCode: '10210'),
      ],
      // เขตสายไหม
      42: [
        SubDistrict(
            id: 157,
            districtId: 42,
            nameTh: 'สายไหม',
            nameEn: 'Sai Mai',
            postalCode: '10220'),
        SubDistrict(
            id: 158,
            districtId: 42,
            nameTh: 'คลองถนน',
            nameEn: 'Khlong Thanon',
            postalCode: '10220'),
        SubDistrict(
            id: 159,
            districtId: 42,
            nameTh: 'โคกแฝด',
            nameEn: 'Khok Faet',
            postalCode: '10220'),
        SubDistrict(
            id: 160,
            districtId: 42,
            nameTh: 'ออเงิน',
            nameEn: 'O Ngoen',
            postalCode: '10220'),
      ],
      // เขตคันนายาว
      43: [
        SubDistrict(
            id: 161,
            districtId: 43,
            nameTh: 'คันนายาว',
            nameEn: 'Khan Na Yao',
            postalCode: '10230'),
        SubDistrict(
            id: 162,
            districtId: 43,
            nameTh: 'รามอินทรา',
            nameEn: 'Ram Inthra',
            postalCode: '10230'),
      ],
      // เขตสะพานสูง
      44: [
        SubDistrict(
            id: 163,
            districtId: 44,
            nameTh: 'สะพานสูง',
            nameEn: 'Saphan Sung',
            postalCode: '10240'),
        SubDistrict(
            id: 164,
            districtId: 44,
            nameTh: 'ออเงิน',
            nameEn: 'O Ngoen',
            postalCode: '10240'),
      ],
      // เขตวังทองหลาง
      45: [
        SubDistrict(
            id: 165,
            districtId: 45,
            nameTh: 'วังทองหลาง',
            nameEn: 'Wang Thonglang',
            postalCode: '10310'),
        SubDistrict(
            id: 166,
            districtId: 45,
            nameTh: 'สะพานสูง',
            nameEn: 'Saphan Sung',
            postalCode: '10240'),
      ],
      // เขตคลองสามวา
      46: [
        SubDistrict(
            id: 167,
            districtId: 46,
            nameTh: 'คลองสามวา',
            nameEn: 'Khlong Sam Wa',
            postalCode: '10510'),
        SubDistrict(
            id: 168,
            districtId: 46,
            nameTh: 'บางชัน',
            nameEn: 'Bang Chan',
            postalCode: '10510'),
        SubDistrict(
            id: 169,
            districtId: 46,
            nameTh: 'ทรายกองดิน',
            nameEn: 'Sai Kong Din',
            postalCode: '10510'),
        SubDistrict(
            id: 170,
            districtId: 46,
            nameTh: 'ทรายกองดินใต้',
            nameEn: 'Sai Kong Din Tai',
            postalCode: '10510'),
      ],
      // เขตบางนา
      47: [
        SubDistrict(
            id: 171,
            districtId: 47,
            nameTh: 'บางนา',
            nameEn: 'Bang Na',
            postalCode: '10260'),
        SubDistrict(
            id: 172,
            districtId: 47,
            nameTh: 'บางนาเหนือ',
            nameEn: 'Bang Na Nuea',
            postalCode: '10260'),
        SubDistrict(
            id: 173,
            districtId: 47,
            nameTh: 'บางนาใต้',
            nameEn: 'Bang Na Tai',
            postalCode: '10260'),
      ],
      // เขตทวีวัฒนา
      48: [
        SubDistrict(
            id: 174,
            districtId: 48,
            nameTh: 'ทวีวัฒนา',
            nameEn: 'Thawi Watthana',
            postalCode: '10170'),
        SubDistrict(
            id: 175,
            districtId: 48,
            nameTh: 'ศาลาธรรมสพน์',
            nameEn: 'Sala Thammasop',
            postalCode: '10170'),
        SubDistrict(
            id: 176,
            districtId: 48,
            nameTh: 'บางแค',
            nameEn: 'Bang Khae',
            postalCode: '10160'),
      ],
      // เขตทุ่งครุ
      49: [
        SubDistrict(
            id: 177,
            districtId: 49,
            nameTh: 'ทุ่งครุ',
            nameEn: 'Thung Khru',
            postalCode: '10140'),
        SubDistrict(
            id: 178,
            districtId: 49,
            nameTh: 'บางโทรม',
            nameEn: 'Bang Thom',
            postalCode: '10140'),
        SubDistrict(
            id: 179,
            districtId: 49,
            nameTh: 'บางมด',
            nameEn: 'Bang Mot',
            postalCode: '10140'),
      ],
      // เขตบางบอน
      50: [
        SubDistrict(
            id: 180,
            districtId: 50,
            nameTh: 'บางบอน',
            nameEn: 'Bang Bon',
            postalCode: '10150'),
        SubDistrict(
            id: 181,
            districtId: 50,
            nameTh: 'บางบอนใต้',
            nameEn: 'Bang Bon Tai',
            postalCode: '10150'),
        SubDistrict(
            id: 182,
            districtId: 50,
            nameTh: 'คลองบางบอน',
            nameEn: 'Khlong Bang Bon',
            postalCode: '10150'),
      ],
      // เชียงใหม่
      51: [
        SubDistrict(
            id: 183,
            districtId: 51,
            nameTh: 'ศรีภูมิ',
            nameEn: 'Si Phum',
            postalCode: '50200'),
        SubDistrict(
            id: 184,
            districtId: 51,
            nameTh: 'พระสิงห์',
            nameEn: 'Phra Sing',
            postalCode: '50200'),
        SubDistrict(
            id: 185,
            districtId: 51,
            nameTh: 'หายยา',
            nameEn: 'Hai Ya',
            postalCode: '50100'),
      ],
      // นนทบุรี
      71: [
        SubDistrict(
            id: 186,
            districtId: 71,
            nameTh: 'สวนใหญ่',
            nameEn: 'Suan Yai',
            postalCode: '11000'),
        SubDistrict(
            id: 187,
            districtId: 71,
            nameTh: 'ตลาดขวัญ',
            nameEn: 'Talat Khwan',
            postalCode: '11000'),
        SubDistrict(
            id: 188,
            districtId: 71,
            nameTh: 'บางเขน',
            nameEn: 'Bang Khen',
            postalCode: '11000'),
      ],
    };

    return fallbackData[districtId] ?? [];
  }
}
