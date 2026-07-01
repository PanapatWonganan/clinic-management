import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/customer_address.dart';
import '../models/reward_product.dart';
import 'add_address_screen.dart';
import '../services/address_service.dart';
import '../services/reward_service.dart';
import '../widgets/custom_app_bar.dart';

class RewardDetailScreen extends StatefulWidget {
  final RewardProduct product;

  const RewardDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends State<RewardDetailScreen> {
  int quantity = 1;
  final int maxQuantity = 5;
  int? availablePoints;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await RewardService.instance.getPointsBalance();
      if (!mounted) return;
      setState(() {
        availablePoints = balance;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        availablePoints = 0;
      });
    }
  }

  void _incrementQuantity() {
    if (quantity < maxQuantity) {
      setState(() {
        quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  int get totalPoints => widget.product.points * quantity;
  bool get canExchange => totalPoints <= (availablePoints ?? 0);

  Future<void> _handleExchange() async {
    if (!canExchange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คะแนนไม่เพียงพอสำหรับการแลกรีวอร์ดนี้'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RedeemAddressSheet(
        product: widget.product,
        quantity: quantity,
        onSuccess: () async {
          final newBalance = await RewardService.instance.getPointsBalance();
          if (!mounted) return;
          setState(() {
            availablePoints = newBalance;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แลกของรางวัลสำเร็จ 🎉')),
          );
        },
        onError: (String message) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product.image;
    if (imageUrl == null) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            widget.product.fallbackIcon,
            size: 80,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    final isNetwork = imageUrl.startsWith('http');
    if (isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF3F4F6),
            child: Center(
              child: Icon(
                widget.product.fallbackIcon,
                size: 80,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF3F4F6),
          child: Center(
            child: Icon(
              widget.product.fallbackIcon,
              size: 80,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Page title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'รายละเอียดรีวอร์ด',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Product image
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFF8F9FA),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.08),
                            offset: const Offset(0, 4),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildProductImage(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Product details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purpleText,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Product description
                        Text(
                          widget.product.description ?? '',
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Points required
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple.withValues(alpha:0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.mainPurple.withValues(alpha:0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.mainPurple.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.stars,
                                  color: AppColors.mainPurple,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'คะแนนที่ใช้แลก',
                                      style: TextStyle(
                                        fontFamily: 'Prompt',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.product.points} คะแนน',
                                      style: const TextStyle(
                                        fontFamily: 'Prompt',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mainPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Available points
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.lightGray.withValues(alpha:0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'คะแนนปัจจุบันของคุณ',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.purpleText,
                                ),
                              ),
                              availablePoints == null
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.mainPink,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '$availablePoints คะแนน',
                                      style: const TextStyle(
                                        fontFamily: 'Prompt',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mainPink,
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Quantity selector
                        const Text(
                          'จำนวนที่ต้องการแลก',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purpleText,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.lightGray.withValues(alpha:0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'จำนวน',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.purpleText,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _decrementQuantity,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: quantity > 1
                                            ? AppColors.lightGray
                                            : AppColors.lightGray
                                                .withValues(alpha:0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 20,
                                        color: quantity > 1
                                            ? Colors.white
                                            : AppColors.lightGray,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontFamily: 'Prompt',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purpleText,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _incrementQuantity,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: quantity < maxQuantity
                                            ? AppColors.mainPink
                                            : AppColors.lightGray
                                                .withValues(alpha:0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: quantity < maxQuantity
                                            ? Colors.white
                                            : AppColors.lightGray,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Total points calculation
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.mainPurple.withValues(alpha:0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'รวมคะแนนที่ใช้',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.purpleText,
                                ),
                              ),
                              Text(
                                '$totalPoints คะแนน',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: canExchange
                                      ? AppColors.mainPurple
                                      : AppColors.mainPink,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!canExchange) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.mainPink.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.mainPink.withValues(alpha:0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.mainPink,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'คะแนนไม่เพียงพอสำหรับจำนวนที่เลือก',
                                    style: TextStyle(
                                      fontFamily: 'Prompt',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mainPink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom exchange button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canExchange ? () => _handleExchange() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canExchange
                        ? AppColors.mainPurple
                        : AppColors.lightGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    'แลกรีวอร์ด ($quantity ชิ้น)',
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet widget that loads addresses and confirms the redemption.
class _RedeemAddressSheet extends StatefulWidget {
  final RewardProduct product;
  final int quantity;
  final Future<void> Function() onSuccess;
  final void Function(String message) onError;

  const _RedeemAddressSheet({
    required this.product,
    required this.quantity,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_RedeemAddressSheet> createState() => _RedeemAddressSheetState();
}

class _RedeemAddressSheetState extends State<_RedeemAddressSheet> {
  List<CustomerAddress> _addresses = [];
  CustomerAddress? _selectedAddress;
  bool _isLoadingAddresses = true;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await AddressService.fetchAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _isLoadingAddresses = false;
        final defaultAddr = AddressService.getDefaultAddress(addresses);
        _selectedAddress = defaultAddr ?? (addresses.isNotEmpty ? addresses.first : null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_selectedAddress == null) return;
    setState(() {
      _isRedeeming = true;
    });
    try {
      await RewardService.instance.redeem(
        productId: widget.product.id,
        quantity: widget.quantity,
        shippingAddressId: _selectedAddress!.id,
        notes: null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onSuccess();
    } on RewardException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRedeeming = false;
      });
      widget.onError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRedeeming = false;
      });
      widget.onError('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'เลือกที่อยู่จัดส่ง',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'ระบุที่อยู่สำหรับจัดส่งของรางวัล',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
          ),

          const Divider(height: 1),

          // Address list / empty state / loader
          Expanded(
            child: _isLoadingAddresses
                ? const Center(child: CircularProgressIndicator())
                : _addresses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Color(0xFFD1D5DB),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'ยังไม่มีที่อยู่จัดส่ง',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'กรุณาเพิ่มที่อยู่เพื่อรับของรางวัล',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AddAddressScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_location_alt),
                                  label: const Text(
                                    'เพิ่มที่อยู่จัดส่ง',
                                    style: TextStyle(
                                      fontFamily: 'Prompt',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _addresses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final address = _addresses[index];
                          final isSelected = _selectedAddress?.id == address.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAddress = address;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppColors.mainPurple
                                        : const Color(0xFFD1D5DB),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              address.recipientName,
                                              style: TextStyle(
                                                fontFamily: 'Prompt',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.mainPurple
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                            if (address.isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.mainPurple.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'ค่าเริ่มต้น',
                                                  style: TextStyle(
                                                    fontFamily: 'Prompt',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.mainPurple,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.phone,
                                          style: const TextStyle(
                                            fontFamily: 'Prompt',
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${address.addressLine1}, ${address.district}, ${address.province} ${address.postalCode}',
                                          style: const TextStyle(
                                            fontFamily: 'Prompt',
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Confirm button
          if (_addresses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_selectedAddress != null && !_isRedeeming)
                        ? _confirm
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainPurple,
                      disabledBackgroundColor: AppColors.lightGray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isRedeeming
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'ยืนยันการแลกของรางวัล',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
