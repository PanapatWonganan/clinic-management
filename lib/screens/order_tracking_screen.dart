import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_config.dart';
import '../models/order.dart';
import '../widgets/custom_app_bar.dart';
import 'order_history_screen.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Order currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;

    // Simulate order status updates
    _simulateOrderProgress();
  }

  void _simulateOrderProgress() {
    if (currentOrder.status != OrderStatus.shipped) {
      // Simulate status progression every 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            switch (currentOrder.status) {
              case OrderStatus.pending:
                currentOrder = Order(
                  id: currentOrder.id,
                  orderNumber: currentOrder.orderNumber,
                  orderDate: currentOrder.orderDate,
                  totalAmount: currentOrder.totalAmount,
                  status: OrderStatus.confirmed,
                  deliveryMethod: currentOrder.deliveryMethod,
                  paymentMethod: currentOrder.paymentMethod,
                  trackingNumber: currentOrder.trackingNumber,
                  items: currentOrder.items,
                  deliveryProof: currentOrder.deliveryProof,
                );
                break;
              case OrderStatus.confirmed:
                currentOrder = Order(
                  id: currentOrder.id,
                  orderNumber: currentOrder.orderNumber,
                  orderDate: currentOrder.orderDate,
                  totalAmount: currentOrder.totalAmount,
                  status: OrderStatus.processing,
                  deliveryMethod: currentOrder.deliveryMethod,
                  paymentMethod: currentOrder.paymentMethod,
                  trackingNumber: currentOrder.trackingNumber,
                  items: currentOrder.items,
                  deliveryProof: currentOrder.deliveryProof,
                );
                break;
              case OrderStatus.processing:
                currentOrder = Order(
                  id: currentOrder.id,
                  orderNumber: currentOrder.orderNumber,
                  orderDate: currentOrder.orderDate,
                  totalAmount: currentOrder.totalAmount,
                  status: OrderStatus.shipped,
                  deliveryMethod: currentOrder.deliveryMethod,
                  paymentMethod: currentOrder.paymentMethod,
                  trackingNumber: currentOrder.trackingNumber ??
                      'TH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  items: currentOrder.items,
                  deliveryProof: currentOrder.deliveryProof ?? DeliveryProof(
                    id: '1',
                    imageUrl: '${AppConfig.storageBaseUrl}/delivery_proofs/delivery_proof_demo_1.jpg',
                    originalFilename: 'delivery_proof_demo_1.jpg',
                    fileSizeFormatted: '2.3 MB',
                    uploadedAt: DateTime.now(),
                    uploadedBy: 'Admin',
                    notes: 'สินค้าส่งถึงแล้ว ได้รับเรียบร้อย',
                  ),
                );
                break;
              case OrderStatus.shipped:
                // Keep as shipped - final status
                break;
              default:
                break;
            }
          });

          // Continue simulation if not shipped
          if (currentOrder.status != OrderStatus.shipped) {
            _simulateOrderProgress();
          }
        }
      });
    }
  }

  void _navigateToOrderHistory() {
    // Show completion message first
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คำสั่งซื้อเสร็จสิ้นแล้ว! กำลังไปยังประวัติการสั่งซื้อ'),
        backgroundColor: AppColors.mainPurple,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to order history
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OrderHistoryScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'ติดตามคำสั่งซื้อ',
                style: AppTextStyles.heading16Medium.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleText,
                ),
              ),

              const SizedBox(height: 24),

              // Order info card
              _buildOrderInfoCard(),

              const SizedBox(height: 24),

              // Progress timeline
              _buildProgressTimeline(),

              const SizedBox(height: 24),

              // Delivery info
              _buildDeliveryInfoCard(),

              const SizedBox(height: 24),

              // Delivery proof (only for shipped orders)
              if (currentOrder.status == OrderStatus.shipped && currentOrder.deliveryProof != null)
                _buildDeliveryProofCard(),

              if (currentOrder.status == OrderStatus.shipped && currentOrder.deliveryProof != null)
                const SizedBox(height: 24),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'คำสั่งซื้อ ${currentOrder.orderNumber}',
                style: AppTextStyles.heading16Medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleText,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: currentOrder.status.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentOrder.status.displayName,
                  style: AppTextStyles.body12Regular.copyWith(
                    color: currentOrder.status.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'วันที่สั่งซื้อ: ',
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.lightGray,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(currentOrder.orderDate),
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (currentOrder.trackingNumber != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'หมายเลขติดตาม: ',
                  style: AppTextStyles.body14Medium.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
                Text(
                  currentOrder.trackingNumber!,
                  style: AppTextStyles.body14Medium.copyWith(
                    color: AppColors.purpleText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTimeline() {
    final steps = [
      {
        'status': OrderStatus.confirmed,
        'title': 'ยืนยันคำสั่งซื้อ',
        'subtitle': 'คำสั่งซื้อได้รับการยืนยันแล้ว'
      },
      {
        'status': OrderStatus.processing,
        'title': 'กำลังเตรียมสินค้า',
        'subtitle': 'เจ้าหน้าที่กำลังเตรียมสินค้าของคุณ'
      },
      {
        'status': OrderStatus.shipped,
        'title': 'จัดส่งแล้ว',
        'subtitle': 'สินค้าอยู่ระหว่างการจัดส่ง'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'สถานะการจัดส่ง',
            style: AppTextStyles.heading16Medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleText,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final stepStatus = step['status'] as OrderStatus;
              final isCompleted = _isStepCompleted(stepStatus);
              final isCurrent = currentOrder.status == stepStatus;

              return Column(
                children: [
                  Row(
                    children: [
                      // Timeline dot
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isCurrent
                              ? AppColors.mainPurple
                              : AppColors.lightGray.withValues(alpha:0.3),
                          border: Border.all(
                            color: isCompleted || isCurrent
                                ? AppColors.mainPurple
                                : AppColors.lightGray.withValues(alpha:0.3),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : isCurrent
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                      ),

                      const SizedBox(width: 16),

                      // Step content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: AppTextStyles.body14Medium.copyWith(
                                color: isCompleted || isCurrent
                                    ? AppColors.purpleText
                                    : AppColors.lightGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['subtitle'] as String,
                              style: AppTextStyles.body12Regular.copyWith(
                                color: isCompleted || isCurrent
                                    ? AppColors.lightGray
                                    : AppColors.lightGray.withValues(alpha:0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Time or status indicator
                      if (isCompleted)
                        Text(
                          'เสร็จสิ้น',
                          style: AppTextStyles.body12Regular.copyWith(
                            color: AppColors.mainPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mainPink.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'กำลังดำเนินการ',
                            style: AppTextStyles.caption10.copyWith(
                              color: AppColors.mainPink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Timeline line
                  if (index < steps.length - 1)
                    Container(
                      margin:
                          const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                      height: 24,
                      width: 2,
                      color: isCompleted
                          ? AppColors.mainPurple
                          : AppColors.lightGray.withValues(alpha:0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isStepCompleted(OrderStatus stepStatus) {
    final currentIndex = _getStatusIndex(currentOrder.status);
    final stepIndex = _getStatusIndex(stepStatus);
    return currentIndex > stepIndex;
  }

  int _getStatusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.processing:
        return 2;
      case OrderStatus.shipped:
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'ข้อมูลการจัดส่ง',
            style: AppTextStyles.heading16Medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mainPink.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeliveryIcon(),
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
                      currentOrder.deliveryMethod,
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.purpleText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'จัดส่งภายใน 1-2 วันทำการ',
                      style: AppTextStyles.body12Regular.copyWith(
                        color: AppColors.lightGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ที่อยู่จัดส่ง',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.lightGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '123/45 หมู่ 6 ซอยลาดพร้าว 15 แยก 3\nถนนลาดพร้าว แขวงจอมพล เขตจตุจักร\nกรุงเทพมหานคร 10900',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.purpleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeliveryIcon() {
    switch (currentOrder.deliveryMethod) {
      case 'มอเตอร์ไซค์':
        return Icons.two_wheeler;
      case 'รถยนต์':
        return Icons.directions_car;
      case 'Grab':
        return Icons.delivery_dining;
      default:
        return Icons.local_shipping;
    }
  }

  Widget _buildDeliveryProofCard() {
    if (currentOrder.deliveryProof == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'หลักฐานการจัดส่ง',
                style: AppTextStyles.heading16Medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mainPurple.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.mainPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ได้รับแล้ว',
                      style: AppTextStyles.body12Regular.copyWith(
                        color: AppColors.mainPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Delivery proof image
          GestureDetector(
            onTap: () => _showDeliveryProofModal(context, currentOrder.deliveryProof!),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.lightGray.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  currentOrder.deliveryProof!.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.lightGray.withValues(alpha:0.1),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainPurple),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.lightGray.withValues(alpha:0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            color: AppColors.lightGray,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ไม่สามารถโหลดรูปภาพได้',
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Delivery message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mainPurple.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.mainPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สินค้าได้จัดส่งเรียบร้อยแล้ว',
                        style: AppTextStyles.body12Regular.copyWith(
                          color: AppColors.mainPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (currentOrder.deliveryProof!.notes != null && 
                          currentOrder.deliveryProof!.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentOrder.deliveryProof!.notes!,
                          style: AppTextStyles.body12Regular.copyWith(
                            color: AppColors.purpleText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // View full image button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _showDeliveryProofModal(context, currentOrder.deliveryProof!),
              icon: const Icon(Icons.zoom_in, size: 20),
              label: Text(
                'ดูภาพขนาดเต็ม',
                style: AppTextStyles.body14Medium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.mainPurple,
                  width: 1.5,
                ),
                foregroundColor: AppColors.mainPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryProofModal(BuildContext context, DeliveryProof deliveryProof) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Background
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                ),
              ),
              
              // Image
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    deliveryProof.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              
              // Image info at bottom
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'หลักฐานการจัดส่ง',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryProof.originalFilename,
                        style: AppTextStyles.body12Regular.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'อัพโหลดเมื่อ ${DateFormat('dd/MM/yyyy HH:mm').format(deliveryProof.uploadedAt)}',
                        style: AppTextStyles.body12Regular.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
