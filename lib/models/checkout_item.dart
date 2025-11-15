class CheckoutItem {
  final int id;
  final String name;
  int quantity;
  final double price;
  final String imagePath;

  CheckoutItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imagePath,
  });

  double get totalPrice => price * quantity;
}