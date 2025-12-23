import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/api_service.dart';
import '../screens/redeem_free_items_screen.dart';

class RewardCard extends StatefulWidget {
  final Map<String, dynamic>? availableReward;
  final Function(Map<String, dynamic>)? onClaim;
  final Function(Map<String, dynamic>)? onApplyToCart; // ใช้ reward เป็นส่วนลดในตะกร้า
  final int? cartQuantity; // จำนวนสินค้าในตะกร้า
  final double? currentQuantity; // จำนวนที่ซื้อไปแล้ว
  final List<dynamic>? levelProgress; // ข้อมูล level ทั้งหมด
  final double? productPrice; // ราคาสินค้าต่อชิ้น (default: 2500)
  final VoidCallback? onRewardClaimed; // callback เมื่อแลกรางวัลสำเร็จ (reload data)

  const RewardCard({
    super.key,
    this.availableReward,
    this.onClaim,
    this.onApplyToCart,
    this.cartQuantity,
    this.currentQuantity,
    this.levelProgress,
    this.productPrice,
    this.onRewardClaimed,
  });

  @override
  State<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<RewardCard> {
  bool isClaimSelected = false;
  String selectedRewardType = 'projected'; // 'existing' or 'projected'

  // ราคาสินค้าต่อชิ้น (ใช้ productPrice ที่ส่งมา หรือ default 2500)
  double get _productPrice => widget.productPrice ?? 2500.0;

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

  Widget _buildRewardOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body14Medium.copyWith(
                      color: isSelected ? color : AppColors.greyText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption10.copyWith(
                      color: isSelected ? color.withValues(alpha: 0.8) : AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.availableReward;

    // คำนวณ projected reward จาก cart
    final projected = _calculateProjectedReward();
    final hasCartItems = widget.cartQuantity != null && widget.cartQuantity! > 0;
    final hasExistingReward = reward != null && (reward['earned_free_items'] ?? 0) > 0;
    final hasProjectedReward = hasCartItems && projected['level'] > 0;

    // ถ้าไม่มี reward เดิม และไม่มี projected reward ให้ซ่อน widget
    if (!hasExistingReward && !hasProjectedReward) {
      return const SizedBox.shrink();
    }

    // มีทั้ง 2 ตัวเลือก
    final showBothOptions = hasExistingReward && hasProjectedReward;

    // กำหนดค่าตาม selection
    final useProjected = showBothOptions
        ? selectedRewardType == 'projected'
        : hasProjectedReward;

    final displayLevel = useProjected ? projected['level'] : (reward?['level'] ?? 0);
    final displayFreeItems = useProjected ? projected['free_items'] : (reward?['earned_free_items'] ?? 0);

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
                // แสดง 2 ตัวเลือกถ้ามีทั้ง existing และ projected
                if (showBothOptions) ...[
                  Text(
                    'เลือกสิทธิ์ที่ต้องการแลก',
                    style: AppTextStyles.heading16Medium.copyWith(
                      fontSize: 15,
                      color: AppColors.purpleText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ตัวเลือก 1: Reward เก่า
                  _buildRewardOption(
                    title: 'สิทธิ์สะสมเดิม',
                    subtitle: 'Level ${reward!['level']} - ฟรี ${reward['earned_free_items']} ชิ้น',
                    isSelected: selectedRewardType == 'existing',
                    onTap: () => setState(() => selectedRewardType = 'existing'),
                    color: AppColors.lightGray,
                  ),
                  const SizedBox(height: 8),
                  // ตัวเลือก 2: Projected reward
                  _buildRewardOption(
                    title: 'รวมออร์เดอร์ใหม่',
                    subtitle: 'Level ${projected['level']} - ฟรี ${projected['free_items']} ชิ้น (${projected['total_quantity']} ชิ้น)',
                    isSelected: selectedRewardType == 'projected',
                    onTap: () => setState(() => selectedRewardType = 'projected'),
                    color: AppColors.mainPink,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // แสดงเดี่ยวๆ
                  Text(
                    useProjected
                        ? 'สั่งซื้อ ${projected['total_quantity']} ชิ้น ฟรี $displayFreeItems ชิ้น (คละได้)'
                        : 'คุณได้รับสิทธิ์ ${reward?['required_quantity'] ?? 0} ชิ้น ฟรี $displayFreeItems ชิ้น (คละได้)',
                    style: AppTextStyles.heading16Medium.copyWith(
                      fontSize: 15,
                      color: AppColors.mainPink,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
                        color: useProjected ? AppColors.mainPink.withValues(alpha: 0.2) : AppColors.badgeBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Level $displayLevel',
                          style: AppTextStyles.body14Medium.copyWith(
                            color: useProjected ? AppColors.mainPink : AppColors.lightGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              // คำนวณราคาตาม projected หรือ reward (ใช้ _productPrice = 2500)
              final originalPrice = useProjected
                  ? (projected['total_quantity'] as int) * _productPrice
                  : _productPrice * _parseToDouble(reward?['required_quantity'], 5);
              final savingsAmount = useProjected
                  ? (projected['free_items'] as int) * _productPrice
                  : _parseToDouble(reward?['savings_amount'], 0);

              return Container(
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
                        useProjected ? 'ราคารวม' : 'ราคาสินค้า',
                        style: AppTextStyles.heading16Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_formatPrice(originalPrice)}.-',
                            style: AppTextStyles.body14Medium.copyWith(
                              color: const Color(0xFF7D7D7D),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ลด ${_formatPrice(savingsAmount)}.-',
                            style: AppTextStyles.heading16Medium.copyWith(
                              color: AppColors.mainPink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
                      onPressed: () => _showRewardConfirmationDialog(context, reward ?? {}),
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

  // คำนวณ projected reward จาก cart quantity + current quantity
  Map<String, dynamic> _calculateProjectedReward() {
    final totalQuantity = (widget.currentQuantity ?? 0) + (widget.cartQuantity ?? 0);

    // ใช้ข้อมูล level จาก API (levelProgress)
    final levels = widget.levelProgress;
    if (levels == null || levels.isEmpty) {
      return {
        'level': 0,
        'free_items': 0,
        'required_quantity': 0,
        'total_quantity': totalQuantity.toInt(),
      };
    }

    // หา level สูงสุดที่ qualify (เรียงจาก level สูงไปต่ำ)
    int qualifiedLevel = 0;
    int qualifiedFreeItems = 0;
    int requiredQuantity = 0;

    for (int i = levels.length - 1; i >= 0; i--) {
      final level = levels[i];
      // Parse required_quantity as double to handle both string and num values
      final requiredRaw = level['required_quantity'];
      final required = requiredRaw is num
          ? requiredRaw.toDouble()
          : double.tryParse(requiredRaw?.toString() ?? '0') ?? 0;
      if (totalQuantity >= required) {
        // Parse level as int
        final levelRaw = level['level'] ?? i + 1;
        qualifiedLevel = levelRaw is int
            ? levelRaw
            : int.tryParse(levelRaw?.toString() ?? '0') ?? (i + 1);
        // ใช้ free_quantity จาก API - parse as int
        final freeRaw = level['free_quantity'] ?? 0;
        qualifiedFreeItems = freeRaw is int
            ? freeRaw
            : int.tryParse(freeRaw?.toString() ?? '0') ?? 0;
        requiredQuantity = required.toInt();
        break;
      }
    }

    return {
      'level': qualifiedLevel,
      'free_items': qualifiedFreeItems,
      'required_quantity': requiredQuantity,
      'total_quantity': totalQuantity.toInt(),
    };
  }

  // เรียก API บันทึกการแลกรางวัลลง database
  Future<void> _claimRewardToDatabase(int level, BuildContext context) async {
    try {
      debugPrint('Claiming reward level $level to database...');

      final response = await ApiService.post('/membership/claim-reward', {
        'level': level,
        'reward_type': 'bundle_deal',
      });

      debugPrint('Claim reward response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('Reward claimed successfully!');
          // Reload membership data
          if (widget.onRewardClaimed != null) {
            widget.onRewardClaimed!();
          }
        } else {
          debugPrint('Claim failed: ${data['message']}');
          // แสดง error ถ้ามี (เช่น แลกไปแล้ว)
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'เกิดข้อผิดพลาด'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Handle error responses (422, 400, 500, etc.)
        debugPrint('Claim error: ${response.statusCode} - ${response.body}');
        final data = json.decode(response.body);
        String errorMessage = 'เกิดข้อผิดพลาด';

        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['errors'] != null) {
          // Laravel validation errors
          final errors = data['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first is List
              ? errors.values.first[0]
              : errors.values.first.toString();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRewardConfirmationDialog(BuildContext context, Map<String, dynamic> reward) {
    // คำนวณ projected reward
    final projected = _calculateProjectedReward();
    final hasCartItems = widget.cartQuantity != null && widget.cartQuantity! > 0;
    final hasExistingReward = reward.isNotEmpty && (reward['earned_free_items'] ?? 0) > 0;
    final hasProjectedReward = hasCartItems && projected['level'] > 0;
    final showBothOptions = hasExistingReward && hasProjectedReward;

    // ใช้ selectedRewardType ตาม user เลือก
    final useProjected = showBothOptions
        ? selectedRewardType == 'projected'
        : hasProjectedReward;

    final freeItems = useProjected ? projected['free_items'] : (reward['earned_free_items'] ?? 0);
    // ใช้ _productPrice (2500) แทน unit_price จาก API
    final discountAmount = freeItems * _productPrice;
    final levelName = useProjected
        ? 'Level ${projected['level']}'
        : (reward['display_name'] ?? 'Level ${reward['level']}');
    final totalQuantity = useProjected ? projected['total_quantity'] : (reward['required_quantity'] ?? 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mainPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: AppColors.mainPink,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ยืนยันการแลกสิทธิ์',
                style: AppTextStyles.heading16Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mainPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                levelName,
                style: AppTextStyles.body12Regular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reward details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // จำนวนชิ้น
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        useProjected ? 'จำนวนที่สั่งซื้อรวม' : 'จำนวนที่สะสม',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                      Text(
                        '$totalQuantity ชิ้น',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Free items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'สินค้าฟรี',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                      Text(
                        '$freeItems ชิ้น',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Discount amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ส่วนลดที่ได้รับ',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                      Text(
                        '${_formatPrice(discountAmount)} บาท',
                        style: AppTextStyles.heading16Medium.copyWith(
                          color: AppColors.mainPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.greyText.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ส่วนลดจะถูกนำไปใช้ในหน้าชำระเงิน',
                    style: AppTextStyles.caption10.copyWith(
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.body14Medium.copyWith(
                color: AppColors.lightGray,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // สร้าง reward data ตาม selection (existing หรือ projected)
              // ใช้ _productPrice (2500) เป็น unit_price เสมอ
              final rewardToApply = useProjected
                  ? {
                      'level': projected['level'],
                      'required_quantity': projected['required_quantity'],
                      'earned_free_items': projected['free_items'],
                      'unit_price': _productPrice, // ใช้ราคาสินค้าจริง (2500)
                      'display_name': 'Level ${projected['level']}',
                      'total_quantity': projected['total_quantity'],
                      'is_projected': true, // flag ให้รู้ว่าเป็น projected
                    }
                  : {
                      ...reward,
                      'unit_price': _productPrice, // override ให้ใช้ราคาจริง (2500)
                    };

              // ถ้าเป็น "สิทธิ์สะสมเดิม" (existing) → ไปหน้าเลือกของแถมและ checkout เลย
              if (!useProjected && reward.isNotEmpty) {
                // คำนวณจำนวนของแถมที่เหลือ
                final freeItems = int.tryParse(reward['earned_free_items']?.toString() ?? '0') ?? 0;
                final claimedItems = int.tryParse(reward['claimed_free_items']?.toString() ?? '0') ?? 0;
                final remainingItems = freeItems - claimedItems;

                if (remainingItems > 0 && context.mounted) {
                  // สร้าง reward data สำหรับ RedeemFreeItemsScreen
                  final rewardData = {
                    'id': reward['id'],
                    'level': reward['level'],
                    'display_name': reward['display_name'] ?? 'Level ${reward['level']}',
                    'remaining_free_items': remainingItems,
                    'earned_free_items': freeItems,
                    'claimed_free_items': claimedItems,
                  };

                  // Navigate ไปหน้าเลือกของแถม
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RedeemFreeItemsScreen(reward: rewardData),
                    ),
                  );

                  // ถ้าแลกสำเร็จ → refresh data
                  if (result == true && widget.onRewardClaimed != null) {
                    widget.onRewardClaimed!();
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ไม่มีของแถมคงเหลือให้แลก'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              // Apply reward to cart (สำหรับ projected reward ที่ต้องซื้อสินค้าด้วย)
              if (widget.onApplyToCart != null) {
                widget.onApplyToCart!(rewardToApply);
              } else if (widget.onClaim != null) {
                widget.onClaim!(rewardToApply);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'ยืนยันแลกสิทธิ์',
              style: AppTextStyles.body14Medium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}