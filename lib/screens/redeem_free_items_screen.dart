import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import '../models/checkout_item.dart';
import 'checkout_screen.dart';

class RedeemFreeItemsScreen extends StatefulWidget {
  final Map<String, dynamic> reward;

  const RedeemFreeItemsScreen({super.key, required this.reward});

  @override
  State<RedeemFreeItemsScreen> createState() => _RedeemFreeItemsScreenState();
}

class _RedeemFreeItemsScreenState extends State<RedeemFreeItemsScreen> {
  List<Map<String, dynamic>> products = [];
  Map<int, int> selectedProducts = {}; // productId -> quantity
  bool isLoadingProducts = true;
  bool isSubmitting = false;
  String? errorMessage;
  int remainingItems = 0;

  @override
  void initState() {
    super.initState();
    remainingItems = widget.reward['remaining_free_items'] ?? 0;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        isLoadingProducts = true;
        errorMessage = null;
      });

      final response = await ApiService.get('/redeemable-products');
      debugPrint('Redeemable products response: ${response.statusCode}');
      debugPrint('Redeemable products body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            products = List<Map<String, dynamic>>.from(data['data'] ?? []);
            isLoadingProducts = false;
          });
          debugPrint('Loaded ${products.length} products');
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load products';
            isLoadingProducts = false;
          });
        }
      } else {
        // Handle non-200 responses
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoadingProducts = false;
        });
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading products: $e';
        isLoadingProducts = false;
      });
      debugPrint('Exception loading products: $e');
    }
  }

  int get totalSelected {
    return selectedProducts.values.fold(0, (sum, qty) => sum + qty);
  }

  void _updateQuantity(int productId, int change) {
    setState(() {
      final current = selectedProducts[productId] ?? 0;
      final newQty = current + change;

      if (newQty <= 0) {
        selectedProducts.remove(productId);
      } else {
        // Check if we can add more
        final otherTotal = totalSelected - current;
        final maxCanAdd = remainingItems - otherTotal;

        if (newQty <= maxCanAdd) {
          selectedProducts[productId] = newQty;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('สามารถเลือกได้สูงสุด $remainingItems ชิ้น'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _submitRedemption() async {
    if (totalSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกสินค้าอย่างน้อย 1 รายการ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Build CheckoutItems from selected products (price = 0 for free items)
    final List<CheckoutItem> cartItems = [];
    for (final entry in selectedProducts.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      // Find product details
      final product = products.firstWhere(
        (p) => p['id'] == productId,
        orElse: () => <String, dynamic>{},
      );

      if (product.isNotEmpty) {
        cartItems.add(CheckoutItem(
          id: productId,
          name: product['name'] ?? 'Unknown',
          quantity: quantity,
          price: 0, // Free item - price is 0
          imagePath: product['image'] ?? '',
        ));
      }
    }

    // Build freeItemRedemption data for CheckoutScreen
    final isCombined = widget.reward['id'] == 'combined';
    final Map<String, dynamic> freeItemRedemption = {
      'items': selectedProducts.entries
          .map((e) => {'product_id': e.key, 'quantity': e.value})
          .toList(),
      'total_quantity': totalSelected,
    };

    // Add reward info
    if (isCombined) {
      final rewards = widget.reward['rewards'] as List<dynamic>?;
      if (rewards != null) {
        freeItemRedemption['reward_ids'] = rewards
            .where((r) => (r['remaining_free_items'] ?? 0) > 0)
            .map((r) => r['id'])
            .toList();
      }
      freeItemRedemption['is_combined'] = true;
    } else {
      // ส่ง reward_level สำหรับ auto-approve flow
      // ถ้ามี claimed_reward_id (เป็น int จริง) ก็ส่งไปด้วย
      final rewardId = widget.reward['id'];
      if (rewardId != null && rewardId is int) {
        freeItemRedemption['claimed_reward_id'] = rewardId;
      }
      // ส่ง level เพื่อให้ backend สร้าง claimed_reward อัตโนมัติถ้าไม่มี
      freeItemRedemption['reward_level'] = widget.reward['level'];
    }

    // Navigate to CheckoutScreen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartItems,
          isFreeItemOnly: true,
          freeItemRedemption: freeItemRedemption,
        ),
      ),
    );

    // If order was created successfully, pop back with success
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainPurple,
      appBar: const CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _buildProductList(),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'เลือกของแถม',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'สิทธิ์คงเหลือ: $remainingItems ชิ้น',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีสินค้าให้เลือก',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id'] as int;
    final quantity = selectedProducts[productId] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.mainPurple : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: product['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.card_giftcard,
                      color: Colors.grey[400],
                      size: 32,
                    ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Quantity selector
            _buildQuantitySelector(productId, quantity),
          ],
        ),
      ),
    );
  }

  void _showQuantityInputDialog(int productId, int currentQuantity) {
    final controller = TextEditingController(text: currentQuantity.toString());
    final current = selectedProducts[productId] ?? 0;
    final otherTotal = totalSelected - current;
    final maxCanAdd = remainingItems - otherTotal;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ระบุจำนวน'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'จำนวน (สูงสุด $maxCanAdd)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? 0;
              final validQty = newQty.clamp(0, maxCanAdd);
              setState(() {
                if (validQty <= 0) {
                  selectedProducts.remove(productId);
                } else {
                  selectedProducts[productId] = validQty;
                }
              });
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPink,
            ),
            child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(int productId, int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 0
                ? () => _updateQuantity(productId, -1)
                : null,
            icon: const Icon(Icons.remove),
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            color: quantity > 0 ? AppColors.mainPink : Colors.grey[400],
          ),
          // Tappable quantity to input number
          GestureDetector(
            onTap: () => _showQuantityInputDialog(productId, quantity),
            child: Container(
              constraints: const BoxConstraints(minWidth: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.mainPink.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: quantity > 0 ? AppColors.mainPink : Colors.grey[600],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: totalSelected < remainingItems
                ? () => _updateQuantity(productId, 1)
                : null,
            icon: const Icon(Icons.add),
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            color: totalSelected < remainingItems
                ? AppColors.mainPink
                : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'จำนวนที่เลือก',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$totalSelected / $remainingItems ชิ้น',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: totalSelected > 0
                        ? AppColors.mainPurple
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Submit button - สีชมพูให้โดดเด่น
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting || totalSelected == 0
                    ? null
                    : _submitRedemption,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'ยืนยันการแลก',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
