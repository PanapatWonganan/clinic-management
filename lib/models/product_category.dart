class ProductCategory {
  final int id;
  final String name;
  int quantity;
  final String imagePath;
  final double price;
  final int stock;

  ProductCategory({
    required this.id,
    required this.name,
    required this.quantity,
    required this.imagePath,
    required this.price,
    this.stock = 0,
  });

  // สำหรับสร้าง ProductCategory จากข้อมูล API
  factory ProductCategory.fromApi(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      quantity: 0, // quantity เริ่มต้นเป็น 0 (จำนวนที่เลือกซื้อ)
      imagePath: json['image_url'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: json['stock'] ?? 0,
    );
  }

  // แปลงเป็น Map สำหรับส่งไป API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'imagePath': imagePath,
      'price': price,
      'stock': stock,
    };
  }
}
