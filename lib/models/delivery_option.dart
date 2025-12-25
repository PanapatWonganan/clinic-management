enum VehicleType { motorcycle, car, parcel }

enum DeliveryCompany { grab, lalamove, parcel }

class DeliveryOption {
  final VehicleType vehicleType;
  final DeliveryCompany company;
  final String displayName;
  final String subtitle;
  final double price;
  final String estimatedTime;

  DeliveryOption({
    required this.vehicleType,
    required this.company,
    required this.displayName,
    required this.subtitle,
    required this.price,
    required this.estimatedTime,
  });

  String get vehicleTypeName {
    switch (vehicleType) {
      case VehicleType.motorcycle:
        return 'มอเตอร์ไซค์';
      case VehicleType.car:
        return 'รถยนต์';
      case VehicleType.parcel:
        return 'พัสดุ';
    }
  }

  String get companyName {
    switch (company) {
      case DeliveryCompany.grab:
        return 'Grab';
      case DeliveryCompany.lalamove:
        return 'Lalamove';
      case DeliveryCompany.parcel:
        return 'พัสดุ';
    }
  }

  String get companyCode {
    switch (company) {
      case DeliveryCompany.grab:
        return 'grab';
      case DeliveryCompany.lalamove:
        return 'lalamove';
      case DeliveryCompany.parcel:
        return 'parcel';
    }
  }

  String get fullDisplayName {
    return '$companyName - $vehicleTypeName';
  }

  // Get available companies for vehicle type
  static List<DeliveryCompany> getCompaniesForVehicle(VehicleType vehicleType) {
    return [DeliveryCompany.grab, DeliveryCompany.lalamove];
  }

  // Factory methods for creating delivery options from API data
  factory DeliveryOption.fromJson(Map<String, dynamic> json) {
    VehicleType vehicleType;
    switch (json['vehicle_type']) {
      case 'motorcycle':
        vehicleType = VehicleType.motorcycle;
        break;
      case 'parcel':
        vehicleType = VehicleType.parcel;
        break;
      default:
        vehicleType = VehicleType.car;
    }

    DeliveryCompany company;
    switch (json['company']) {
      case 'grab':
        company = DeliveryCompany.grab;
        break;
      case 'parcel':
        company = DeliveryCompany.parcel;
        break;
      default:
        company = DeliveryCompany.lalamove;
    }

    return DeliveryOption(
      vehicleType: vehicleType,
      company: company,
      displayName: json['display_name'],
      subtitle: json['estimated_time'],
      price: double.parse(json['price'].toString()),
      estimatedTime: json['estimated_time'],
    );
  }

  Map<String, dynamic> toJson() {
    String vehicleTypeStr;
    switch (vehicleType) {
      case VehicleType.motorcycle:
        vehicleTypeStr = 'motorcycle';
        break;
      case VehicleType.parcel:
        vehicleTypeStr = 'parcel';
        break;
      default:
        vehicleTypeStr = 'car';
    }

    return {
      'vehicle_type': vehicleTypeStr,
      'company': companyCode,
      'display_name': displayName,
      'price': price,
      'estimated_time': estimatedTime,
    };
  }

  /// Calculate parcel delivery price based on quantity (boxes)
  /// 1 box = 50 THB
  /// 2-49 boxes = 100 THB
  /// 50-99 boxes = 180 THB
  /// 100-199 boxes = 250 THB
  /// 200-300 boxes = 350 THB
  /// >300 boxes = 500 THB
  static double calculateParcelPrice(int quantity) {
    if (quantity <= 0) return 0;
    if (quantity <= 1) return 50;
    if (quantity <= 49) return 100;
    if (quantity <= 99) return 180;
    if (quantity <= 199) return 250;
    if (quantity <= 300) return 350;
    return 500;
  }

  /// Get parcel delivery option with calculated price
  static DeliveryOption getParcelOption(int quantity) {
    final price = calculateParcelPrice(quantity);
    return DeliveryOption(
      vehicleType: VehicleType.parcel,
      company: DeliveryCompany.parcel,
      displayName: 'จัดส่งพัสดุ',
      subtitle: '2-5 วันทำการ',
      price: price,
      estimatedTime: '2-5 วันทำการ',
    );
  }

  // Get sample delivery options (fallback for when API is not available)
  // Using average prices from delivery_prices table
  static List<DeliveryOption> getSampleOptions() {
    return [
      // Motorcycle options
      DeliveryOption(
        vehicleType: VehicleType.motorcycle,
        company: DeliveryCompany.grab,
        displayName: 'Grab - มอเตอร์ไซค์',
        subtitle: '30-60 นาที',
        price: 108.0,
        estimatedTime: '30-60 นาที',
      ),
      DeliveryOption(
        vehicleType: VehicleType.motorcycle,
        company: DeliveryCompany.lalamove,
        displayName: 'Lalamove - มอเตอร์ไซค์',
        subtitle: '25-50 นาที',
        price: 103.0,
        estimatedTime: '25-50 นาที',
      ),
      // Car options
      DeliveryOption(
        vehicleType: VehicleType.car,
        company: DeliveryCompany.grab,
        displayName: 'Grab - รถยนต์',
        subtitle: '45-90 นาที',
        price: 195.0,
        estimatedTime: '45-90 นาที',
      ),
      DeliveryOption(
        vehicleType: VehicleType.car,
        company: DeliveryCompany.lalamove,
        displayName: 'Lalamove - รถยนต์',
        subtitle: '40-80 นาที',
        price: 191.0,
        estimatedTime: '40-80 นาที',
      ),
    ];
  }
}