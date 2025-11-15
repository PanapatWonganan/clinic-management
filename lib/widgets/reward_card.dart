import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class RewardCard extends StatefulWidget {
  final Map<String, dynamic>? availableReward;
  final Function(Map<String, dynamic>)? onClaim;

  const RewardCard({
    super.key,
    this.availableReward,
    this.onClaim,
  });

  @override
  State<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<RewardCard> {
  bool isClaimSelected = false;

  double _parseToDouble(dynamic value, double fallback) {
    if (value == null) return fallback;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      // Handle malformed string like "2500.002500.002500.002500.002500.00"
      // Extract the first valid number
      final parts = value.split('.');
      if (parts.isNotEmpty) {
        final firstPart = parts[0];
        final parsed = double.tryParse(firstPart);
        if (parsed != null) return parsed;
      }

      // Try parsing the whole string as a fallback
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }

    return fallback;
  }

  String _formatPrice(double price) {
    return price.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.availableReward;

    // ถ้าไม่มี reward ที่สามารถแลกได้ ให้ซ่อน widget
    if (reward == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.3),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คุณได้รับสิทธิ์ ${reward['required_quantity']} ชิ้น ฟรี ${reward['earned_free_items']} ชิ้น (คละได้)',
                  style: AppTextStyles.heading16Medium.copyWith(
                    fontSize: 15,
                    color: AppColors.mainPink,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isClaimSelected,
                          onChanged: (value) {
                            setState(() {
                              isClaimSelected = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'แลกของแถม',
                          style: AppTextStyles.body14Medium.copyWith(
                            color: AppColors.lightGray,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 76,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.badgeBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Level ${reward['level']}',
                          style: AppTextStyles.body14Medium.copyWith(
                            color: AppColors.lightGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha:0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ราคาสินค้า',
                    style: AppTextStyles.heading16Medium.copyWith(
                      color: AppColors.purpleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${_formatPrice(_parseToDouble(reward['unit_price'], 2500) * _parseToDouble(reward['required_quantity'], 5))}.-',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: const Color(0xFF7D7D7D),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatPrice(_parseToDouble(reward['savings_amount'], 15000))}.-',
                        style: AppTextStyles.heading16Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ปุ่มแลกรางวัล (แสดงเมื่อเลือก checkbox)
          if (isClaimSelected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          isClaimSelected = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.mainPink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'สะสมต่อ',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.mainPink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.onClaim != null) {
                          widget.onClaim!(reward);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'แลกเลย',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}