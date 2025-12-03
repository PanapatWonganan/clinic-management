import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;

  const OrderSummaryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปคำสั่งซื้อ',
            style: AppTextStyles.heading16Medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleText,
            ),
          ),

          const SizedBox(height: 16),

          // Subtotal
          _buildSummaryRow(
            'ราคาสินค้า',
            '฿${subtotal.toStringAsFixed(0)}',
            false,
          ),

          const SizedBox(height: 12),

          // Discount
          if (discount > 0)
            _buildSummaryRow(
              'ส่วนลด',
              '-฿${discount.toStringAsFixed(0)}',
              false,
              valueColor: AppColors.mainPink,
            ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: AppColors.lightGray.withValues(alpha:0.3),
          ),

          const SizedBox(height: 16),

          // Total
          _buildSummaryRow(
            'ยอดรวมทั้งหมด',
            '฿${total.toStringAsFixed(0)}',
            true,
          ),

          const SizedBox(height: 16),

          // Reward info - removed hardcoded text
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isTotal, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.body14Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w600,
                )
              : AppTextStyles.body14Medium.copyWith(
                  color: AppColors.lightGray,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.heading16Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w700,
                )
              : AppTextStyles.body14Medium.copyWith(
                  color: valueColor ?? AppColors.purpleText,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
