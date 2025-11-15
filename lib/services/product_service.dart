import 'api_service.dart';
import '../models/product_category.dart';

class ProductService {
  static final ProductService instance = ProductService._internal();
  ProductService._internal();

  // ดึงสินค้าหลักทั้งหมด (สำหรับ Home Screen)
  Future<List<ProductCategory>> getMainProducts({String? membershipType}) async {
    try {
      final response = await ApiService.get('/products?category=main');

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);

        if (data['success'] == true) {
          final productsData = data['data'] as List;
          return productsData
              .map((productJson) => ProductCategory.fromApi(productJson))
              .toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load main products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching main products: $e');
      // ถ้า API ล้มเหลว ให้ใช้ข้อมูล fallback
      return _getFallbackMainProducts(membershipType);
    }
  }

  // ดึงสินค้ารางวัลทั้งหมด (สำหรับ Rewards Screen)
  Future<List<Map<String, dynamic>>> getRewardProducts() async {
    try {
      final response = await ApiService.get('/products/rewards');

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);

        if (data['success'] == true) {
          final productsData = data['data'] as List;
          return productsData
              .map((productJson) => {
                    'id': productJson['id'],
                    'name': productJson['name'],
                    'description': productJson['description'],
                    'points': productJson['points'],
                    'image': productJson['image_url'],
                    'stock': productJson['stock'],
                  })
              .toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception(
            'Failed to load reward products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reward products: $e');
      // ถ้า API ล้มเหลว ให้ใช้ข้อมูล fallback
      return _getFallbackRewardProducts();
    }
  }

  // ดึงสินค้าทั้งหมด
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await ApiService.get('/products');

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);

        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load all products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all products: $e');
      return [];
    }
  }

  // ข้อมูล fallback สำหรับสินค้าหลัก (ถ้า API ล้มเหลว)
  List<ProductCategory> _getFallbackMainProducts(String? membershipType) {
    // ราคาที่ควรจะเป็น (ขึ้นอยู่กับ membership type ของ user)
    // สำหรับ exDoctor = 850, สำหรับอื่นๆ = 2500
    double price = membershipType == 'exDoctor' ? 850.0 : 2500.0;

    return [
      ProductCategory(
        id: 1,
        name: 'Fine บาง',
        quantity: 0,
        imagePath: 'assets/images/mask-group.png',
        price: price,
      ),
      ProductCategory(
        id: 2,
        name: 'Deep กลาง',
        quantity: 0,
        imagePath: 'assets/images/mask-group-1.png',
        price: price,
      ),
      ProductCategory(
        id: 3,
        name: 'Sub-Q โวลุ่ม',
        quantity: 0,
        imagePath: 'assets/images/mask-group-2.png',
        price: price,
      ),
      ProductCategory(
        id: 4,
        name: 'Implant แข็ง',
        quantity: 0,
        imagePath: 'assets/images/mask-group-3.png',
        price: price,
      ),
    ];
  }

  // ข้อมูล fallback สำหรับสินค้ารางวัล (ถ้า API ล้มเหลว)
  List<Map<String, dynamic>> _getFallbackRewardProducts() {
    return [
      {
        'id': 5,
        'name': 'แก้วน้ำสูญญากาศ Seagull',
        'description':
            'แก้วน้ำสูญญากาศคุณภาพสูง เก็บความเย็นได้นาน 24 ชั่วโมง และความร้อนได้นาน 12 ชั่วโมง ผลิตจากสแตนเลสสตีลเกรดพรีเมียม',
        'points': 800,
        'image': 'assets/images/product1.png',
        'stock': 50,
      },
      {
        'id': 6,
        'name': 'เครื่องดูดฝุ่น 2 IN 1 แบบถังกลม',
        'description':
            'เครื่องดูดฝุ่นอเนกประสงค์ ใช้ได้ทั้งดูดฝุ่นแห้งและเปียก พร้อมหัวดูดหลากหลายแบบ เหมาะสำหรับทำความสะอาดบ้าน',
        'points': 800,
        'image': 'assets/images/product2.png',
        'stock': 30,
      },
    ];
  }
}
