import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class RewardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rewardItem;

  const RewardDetailScreen({
    super.key,
    required this.rewardItem,
  });

  @override
  State<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends State<RewardDetailScreen> {
  int quantity = 1;
  final int maxQuantity = 5;
  final int availablePoints = 1000000; // Mock available points

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

  int get totalPoints => (widget.rewardItem['points'] as int) * quantity;
  bool get canExchange => totalPoints <= availablePoints;

  void _handleExchange() {
    if (!canExchange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คะแนนไม่เพียงพอสำหรับการแลกรีวอร์ดนี้'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'แลกรีวอร์ดสำเร็จ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'รีวอร์ดของคุณจะถูกส่งภายใน 3-5 วันทำการ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to rewards screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
                        child: widget.rewardItem['image'].startsWith('http')
                            ? Image.network(
                                widget.rewardItem['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF3F4F6),
                                    child: const Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                widget.rewardItem['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF3F4F6),
                                    child: const Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  );
                                },
                              ),
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
                          widget.rewardItem['name'],
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
                          widget.rewardItem['description'],
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
                                      '${widget.rewardItem['points']} คะแนน',
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
                              Text(
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
                  onPressed: canExchange ? _handleExchange : null,
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
