import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../models/order.dart';
import 'home_screen.dart';
import 'order_tracking_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String? orderNumber;
  final double? totalAmount;
  
  const PaymentSuccessScreen({
    super.key,
    this.orderNumber,
    this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon with circle background
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Success title
                    Text(
                      'ชำระเงินสำเร็จ',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Success message
                    Text(
                      'ขอบคุณสำหรับการสั่งซื้อ\nสินค้าของคุณจะถูกจัดส่งภายใน 1-2 ชั่วโมง',
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.lightGray,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Order details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.mainPurple.withValues(alpha:0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Order number
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'หมายเลขคำสั่งซื้อ',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.lightGray,
                                ),
                              ),
                              Text(
                                orderNumber ?? '#EX240001',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.purpleText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Order date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'วันที่สั่งซื้อ',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.lightGray,
                                ),
                              ),
                              Text(
                                DateFormat('d MMMM yyyy', 'th').format(DateTime.now()),
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.purpleText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Total amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ยอดรวม',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.lightGray,
                                ),
                              ),
                              Text(
                                '฿${totalAmount?.toStringAsFixed(0) ?? '25,050'}',
                                style: AppTextStyles.heading16Medium.copyWith(
                                  color: AppColors.mainPink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Delivery info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightGray.withValues(alpha:0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.mainPink.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: AppColors.mainPink,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'จัดส่งโดยมอเตอร์ไซค์',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: AppColors.purpleText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'คาดว่าจะได้รับภายใน 1-2 ชั่วโมง',
                                  style: AppTextStyles.body12Regular.copyWith(
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom buttons
              Column(
                children: [
                  // Track order button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Create a mock order for tracking
                        final mockOrder = Order(
                          id: '1',
                          orderNumber: orderNumber ?? 'EX240001',
                          orderDate: DateTime.now(),
                          totalAmount: totalAmount ?? 25050.0,
                          subtotal: (totalAmount ?? 25050.0) - 50,
                          deliveryFee: 50,
                          status: OrderStatus.pending,
                          deliveryMethod: 'มอเตอร์ไซค์',
                          paymentMethod: 'บัตรเครดิต',
                          items: [],
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderTrackingScreen(order: mockOrder),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.mainPurple,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'ติดตามคำสั่งซื้อ',
                        style: AppTextStyles.button16.copyWith(
                          color: AppColors.mainPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Continue shopping button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate back to home screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'กลับสู่หน้าหลัก',
                        style: AppTextStyles.button16.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
