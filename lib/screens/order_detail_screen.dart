import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/order.dart';
import '../widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'order_tracking_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

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
                'รายละเอียดคำสั่งซื้อ',
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

              // Items section
              _buildItemsSection(),

              const SizedBox(height: 24),

              // Delivery info
              _buildDeliveryInfoCard(),

              const SizedBox(height: 24),

              // Payment info
              _buildPaymentInfoCard(),

              const SizedBox(height: 24),

              // Delivery proof (only for shipped orders)
              if (order.status == OrderStatus.shipped && order.deliveryProof != null)
                _buildDeliveryProofCard(),

              if (order.status == OrderStatus.shipped && order.deliveryProof != null)
                const SizedBox(height: 24),

              // Order summary
              _buildOrderSummaryCard(),

              const SizedBox(height: 32),

              // Action buttons
              _buildActionButtons(context),

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
                'คำสั่งซื้อ ${order.orderNumber}',
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
          _buildInfoRow('วันที่สั่งซื้อ',
              DateFormat('dd MMMM yyyy, HH:mm').format(order.orderDate)),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('หมายเลขติดตาม', order.trackingNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รายการสินค้า',
          style: AppTextStyles.heading16Medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 16),
        ...order.items
            .map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        width: 60,
                        height: 60,
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.body14Medium.copyWith(
                                color: AppColors.purpleText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'จำนวน ${item.quantity} ชิ้น',
                              style: AppTextStyles.body12Regular.copyWith(
                                color: AppColors.lightGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '฿${NumberFormat('#,##0').format(item.totalPrice)}',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
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
          _buildInfoRow('วิธีการจัดส่ง', order.deliveryMethod),
          const SizedBox(height: 12),
          _buildInfoRow('ที่อยู่จัดส่ง',
              '123/45 หมู่ 6 ซอยลาดพร้าว 15 แยก 3\nถนนลาดพร้าว แขวงจอมพล เขตจตุจักร\nกรุงเทพมหานคร 10900'),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
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
            'ข้อมูลการชำระเงิน',
            style: AppTextStyles.heading16Medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleText,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('วิธีการชำระเงิน', order.paymentMethod),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final subtotal = order.subtotal;
    final discount = order.discount;
    final deliveryFee = order.deliveryFee;

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
            'สรุปคำสั่งซื้อ',
            style: AppTextStyles.heading16Medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleText,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'ราคาสินค้า', '฿${NumberFormat('#,##0').format(subtotal)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
              'ค่าจัดส่ง', '฿${NumberFormat('#,##0').format(deliveryFee)}'),
          const SizedBox(height: 8),
          if (discount > 0) ...[
            _buildSummaryRow(
                'ส่วนลด', '-฿${NumberFormat('#,##0').format(discount)}',
                valueColor: AppColors.mainPink),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: AppColors.lightGray.withValues(alpha:0.3),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'ยอดรวมทั้งหมด',
            '฿${NumberFormat('#,##0').format(order.totalAmount)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (order.status == OrderStatus.shipped) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingScreen(order: order),
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
        ],
        if (order.status == OrderStatus.pending) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Show cancel confirmation dialog
                _showCancelDialog(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.mainPink,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'ยกเลิกคำสั่งซื้อ',
                style: AppTextStyles.button16.copyWith(
                  color: AppColors.mainPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'ยกเลิกคำสั่งซื้อ',
            style: AppTextStyles.heading16Medium,
          ),
          content: Text(
            'คุณต้องการยกเลิกคำสั่งซื้อ ${order.orderNumber} หรือไม่?',
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ไม่ยกเลิก',
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.lightGray,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle order cancellation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ยกเลิกคำสั่งซื้อสำเร็จ'),
                    backgroundColor: AppColors.mainPink,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ยกเลิก',
                style: AppTextStyles.body14Medium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.lightGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.purpleText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
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

  Widget _buildDeliveryProofCard() {
    if (order.deliveryProof == null) return const SizedBox.shrink();

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
                child: Text(
                  'จัดส่งแล้ว',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.mainPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Delivery proof image
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => _showDeliveryProofModal(context, order.deliveryProof!),
              child: Container(
                width: double.infinity,
                height: 200,
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
                    order.deliveryProof!.imageUrl,
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
          ),
          
          const SizedBox(height: 16),
          
          // Delivery proof details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('ชื่อไฟล์', order.deliveryProof!.originalFilename),
              const SizedBox(height: 12),
              _buildInfoRow('ขนาดไฟล์', order.deliveryProof!.fileSizeFormatted),
              const SizedBox(height: 12),
              _buildInfoRow('อัพโหลดเมื่อ', 
                DateFormat('dd MMMM yyyy, HH:mm').format(order.deliveryProof!.uploadedAt)),
              const SizedBox(height: 12),
              _buildInfoRow('อัพโหลดโดย', order.deliveryProof!.uploadedBy),
              if (order.deliveryProof!.notes != null && order.deliveryProof!.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow('หมายเหตุ', order.deliveryProof!.notes!),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // View full image button
          Builder(
            builder: (context) => SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _showDeliveryProofModal(context, order.deliveryProof!),
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
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // Background for full screen
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
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
