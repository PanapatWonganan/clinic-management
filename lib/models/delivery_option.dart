enum VehicleType { motorcycle, car }

enum DeliveryCompany { grab, lalamove }

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
    }
  }

  String get companyName {
    switch (company) {
      case DeliveryCompany.grab:
        return 'Grab';
      case DeliveryCompany.lalamove:
        return 'Lalamove';
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
    return DeliveryOption(
      vehicleType: json['vehicle_type'] == 'motorcycle' 
          ? VehicleType.motorcycle 
          : VehicleType.car,
      company: json['company'] == 'grab' 
          ? DeliveryCompany.grab 
          : DeliveryCompany.lalamove,
      displayName: json['display_name'],
      subtitle: json['estimated_time'],
      price: double.parse(json['price'].toString()),
      estimatedTime: json['estimated_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType == VehicleType.motorcycle ? 'motorcycle' : 'car',
      'company': company == DeliveryCompany.grab ? 'grab' : 'lalamove',
      'display_name': displayName,
      'price': price,
      'estimated_time': estimatedTime,
    };
  }

  // Get sample delivery options (fallback for when API is not available)
  static List<DeliveryOption> getSampleOptions() {
    return [
      // Motorcycle options
      DeliveryOption(
        vehicleType: VehicleType.motorcycle,
        company: DeliveryCompany.grab,
        displayName: 'Grab - มอเตอร์ไซค์',
        subtitle: '30-60 นาที',
        price: 45.0,
        estimatedTime: '30-60 นาที',
      ),
      DeliveryOption(
        vehicleType: VehicleType.motorcycle,
        company: DeliveryCompany.lalamove,
        displayName: 'Lalamove - มอเตอร์ไซค์',
        subtitle: '25-50 นาที',
        price: 40.0,
        estimatedTime: '25-50 นาที',
      ),
      // Car options
      DeliveryOption(
        vehicleType: VehicleType.car,
        company: DeliveryCompany.grab,
        displayName: 'Grab - รถยนต์',
        subtitle: '45-90 นาที',
        price: 80.0,
        estimatedTime: '45-90 นาที',
      ),
      DeliveryOption(
        vehicleType: VehicleType.car,
        company: DeliveryCompany.lalamove,
        displayName: 'Lalamove - รถยนต์',
        subtitle: '40-80 นาที',
        price: 75.0,
        estimatedTime: '40-80 นาที',
      ),
    ];
  }
}