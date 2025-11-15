import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';

class OrderHistoryCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha:0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'คำสั่งซื้อ ${order.orderNumber}',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(order.orderDate),
                        style: AppTextStyles.body12Regular.copyWith(
                          color: AppColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.status.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: AppTextStyles.body12Regular.copyWith(
                        color: order.status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Product thumbnails
              Row(
                children: [
                  // Product images
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            order.items.length > 3 ? 3 : order.items.length,
                        itemBuilder: (context, index) {
                          if (index == 2 && order.items.length > 3) {
                            // Show "+X more" indicator
                            return Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.lightGray.withValues(alpha:0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${order.items.length - 2}',
                                  style: AppTextStyles.body12Regular.copyWith(
                                    color: AppColors.lightGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }

                          final item = order.items[index];
                          return Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.lightGray.withValues(alpha:0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imagePath.startsWith('http')
                                  ? Image.network(
                                      item.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.lightGray.withValues(alpha:0.1),
                                          child: const Icon(
                                            Icons.image,
                                            color: AppColors.lightGray,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      item.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.lightGray.withValues(alpha:0.1),
                                          child: const Icon(
                                            Icons.image,
                                            color: AppColors.lightGray,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Total items count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightPurple.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${order.items.fold(0, (sum, item) => sum + item.quantity)} ชิ้น',
                      style: AppTextStyles.body12Regular.copyWith(
                        color: AppColors.mainPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Divider
              Container(
                height: 1,
                color: AppColors.lightGray.withValues(alpha:0.2),
              ),

              const SizedBox(height: 16),

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยอดรวม',
                        style: AppTextStyles.body12Regular.copyWith(
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '฿${NumberFormat('#,##0').format(order.totalAmount)}',
                        style: AppTextStyles.heading16Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.status == OrderStatus.shipped) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.mainPurple.withValues(alpha:0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_shipping_outlined,
                                size: 16,
                                color: AppColors.mainPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ติดตาม',
                                style: AppTextStyles.body12Regular.copyWith(
                                  color: AppColors.mainPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.lightGray,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
