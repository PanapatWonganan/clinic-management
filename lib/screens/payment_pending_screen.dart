import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PaymentPendingScreen extends StatefulWidget {
  final String orderNumber;
  final String orderId;
  final double totalAmount;
  final String paymentMethod;
  final String orderStatus;

  const PaymentPendingScreen({
    super.key,
    required this.orderNumber,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.orderStatus,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> {
  List<File> uploadedSlips = [];
  bool isUploading = false;
  String currentOrderStatus = '';

  @override
  void initState() {
    super.initState();
    currentOrderStatus = widget.orderStatus;
    if (widget.paymentMethod == 'promptpay') {
      _loadExistingSlips();
    }
  }

  Future<void> _loadExistingSlips() async {
    try {
      final response =
          await ApiService.get('/orders/${widget.orderId}/payment-slips');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // For now, we'll just show the count since we can't easily convert URLs to Files
          // In a real app, you might want to show thumbnails of existing slips
          print('Existing slips: ${data['data'].length}');
        }
      }
    } catch (e) {
      print('Error loading existing slips: $e');
    }
  }

  Future<void> _showUploadOptions() async {
    if (uploadedSlips.length >= 5) {
      _showErrorMessage('สามารถอัปโหลดสลิปได้สูงสุด 5 ไฟล์เท่านั้น');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'เลือกวิธีอัปโหลดสลิป',
                style: AppTextStyles.body16Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildUploadOptionButton(
                      icon: Icons.camera_alt,
                      title: 'ถ่ายรูป',
                      subtitle: 'เปิดกล้องถ่ายรูปสลิป',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadOptionButton(
                      icon: Icons.photo_library,
                      title: 'เลือกจากอัลบั้ม',
                      subtitle: 'เลือกรูปจากแกลเลอรี่',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildUploadOptionButton(
                  icon: Icons.folder_open,
                  title: 'เลือกไฟล์',
                  subtitle: 'เลือกไฟล์จากเครื่อง (PDF, JPG, PNG)',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.lightGray.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mainPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: AppColors.mainPurple,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.body12Regular.copyWith(
                color: AppColors.purpleText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.body12Regular.copyWith(
                color: AppColors.lightGray,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _addSlipFile(File(image.path));
      }
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาดในการเปิดกล้อง');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _addSlipFile(File(image.path));
      }
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาดในการเลือกรูปภาพ');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        _addSlipFile(File(result.files.single.path!));
      }
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาดในการเลือกไฟล์');
    }
  }

  void _addSlipFile(File file) {
    if (uploadedSlips.length >= 5) {
      _showErrorMessage('สามารถอัปโหลดสลิปได้สูงสุด 5 ไฟล์เท่านั้น');
      return;
    }

    setState(() {
      uploadedSlips.add(file);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มสลิปสำเร็จ'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeSlip(int index) {
    setState(() {
      uploadedSlips.removeAt(index);
    });
  }

  String _getFileSizeString(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _uploadSlips() async {
    if (uploadedSlips.isEmpty) {
      _showErrorMessage('กรุณาเลือกสลิปการโอนเงินก่อน');
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final response = await ApiService.uploadFiles(
        '/payment-slips/upload',
        uploadedSlips,
        data: {'order_id': widget.orderId},
        fileFieldName: 'files',
      );

      setState(() {
        isUploading = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            currentOrderStatus = 'payment_uploaded';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัปโหลดสลิปสำเร็จ กรุณารอการตรวจสอบ'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorMessage(
              responseData['message'] ?? 'เกิดข้อผิดพลาดในการอัปโหลด');
        }
      } else {
        _showErrorMessage('เกิดข้อผิดพลาดในการเชื่อมต่อ');
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      _showErrorMessage('เกิดข้อผิดพลาดในการอัปโหลด: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.mainPink,
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'รอการชำระเงิน';
      case 'payment_uploaded':
        return 'อัปโหลดสลิปแล้ว';
      case 'paid':
        return 'ชำระเงินแล้ว';
      case 'confirmed':
        return 'ยืนยันคำสั่งซื้อ';
      case 'processing':
        return 'กำลังเตรียมสินค้า';
      case 'shipped':
        return 'จัดส่งแล้ว';
      case 'delivered':
        return 'ส่งถึงแล้ว';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'payment_uploaded':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'confirmed':
        return AppColors.mainPurple;
      case 'processing':
        return AppColors.mainPink;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.lightGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool needsPayment = currentOrderStatus == 'pending_payment' ||
        currentOrderStatus == 'payment_uploaded';
    final bool isPromptPay = widget.paymentMethod == 'promptpay';
    final bool showUploadArea = isPromptPay && needsPayment;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _getStatusColor(currentOrderStatus)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentOrderStatus == 'paid'
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: _getStatusColor(currentOrderStatus),
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Status title
                    Text(
                      _getStatusText(currentOrderStatus),
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status message
                    Text(
                      currentOrderStatus == 'pending_payment'
                          ? 'กรุณาดำเนินการชำระเงินเพื่อให้เราประมวลผลคำสั่งซื้อของคุณ'
                          : currentOrderStatus == 'payment_uploaded'
                              ? 'เราได้รับสลิปการโอนเงินของคุณแล้ว\nกรุณารอการตรวจสอบ 1-2 ชั่วโมง'
                              : 'คำสั่งซื้อของคุณได้รับการยืนยันแล้ว',
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
                        color: AppColors.lightPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.mainPurple.withOpacity(0.2),
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
                                widget.orderNumber,
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
                                DateFormat('d MMMM yyyy', 'th')
                                    .format(DateTime.now()),
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.purpleText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Payment method
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'วิธีการชำระเงิน',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.lightGray,
                                ),
                              ),
                              Text(
                                widget.paymentMethod == 'promptpay'
                                    ? 'พร้อมเพย์'
                                    : 'บัตรเครดิต',
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
                                '฿${widget.totalAmount.toStringAsFixed(0)}',
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

                    // PromptPay payment section
                    if (showUploadArea) ...[
                      const SizedBox(height: 32),

                      // QR Code section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightGray.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'สแกน QR Code เพื่อชำระเงิน',
                              style: AppTextStyles.body14Medium.copyWith(
                                color: AppColors.purpleText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // QR Code placeholder
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'QR CODE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Bank info
                            Column(
                              children: [
                                Text(
                                  'ธนาคารกสิกรไทย',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: AppColors.purpleText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'บจก. เอ๊กควิวเลอร์ (ไทยแลนด์) จำกัด',
                                  style: AppTextStyles.body12Regular.copyWith(
                                    color: AppColors.lightGray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '2088053853',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: AppColors.purpleText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upload slip section
                      Text(
                        'แนบสลิปการโอนเงิน',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Upload area
                      GestureDetector(
                        onTap: isUploading ? null : _showUploadOptions,
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.mainPurple.withOpacity(0.3),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isUploading)
                                const CircularProgressIndicator(
                                  color: AppColors.mainPurple,
                                  strokeWidth: 2,
                                )
                              else
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: AppColors.mainPurple,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                isUploading
                                    ? 'กำลังอัปโหลด...'
                                    : 'คลิกเพื่ออัปโหลดสลิป',
                                style: AppTextStyles.body12Regular.copyWith(
                                  color: AppColors.mainPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!isUploading)
                                Text(
                                  'สามารถอัปโหลดได้สูงสุด 5 ไฟล์',
                                  style: AppTextStyles.body12Regular.copyWith(
                                    color: AppColors.lightGray,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Uploaded slips list
                      if (uploadedSlips.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'สลิปที่เพิ่มแล้ว (${uploadedSlips.length}/5)',
                              style: AppTextStyles.body12Regular.copyWith(
                                color: AppColors.purpleText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...uploadedSlips.asMap().entries.map((entry) {
                              int index = entry.key;
                              File slip = entry.value;
                              String fileName = slip.path.split('/').last;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.lightGray.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_outlined,
                                      size: 20,
                                      color: AppColors.mainPurple,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileName,
                                            style: AppTextStyles.body12Regular
                                                .copyWith(
                                              color: AppColors.purpleText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _getFileSizeString(slip),
                                            style: AppTextStyles.body12Regular
                                                .copyWith(
                                              color: AppColors.lightGray,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeSlip(index),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.lightGray,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Upload button (only for PromptPay and if needs payment)
                    if (showUploadArea && uploadedSlips.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isUploading ? null : _uploadSlips,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isUploading ? 'กำลังอัปโหลด...' : 'ยืนยันสลิป',
                            style: AppTextStyles.button16.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Back to home button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                            (route) => false,
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
                          'กลับสู่หน้าหลัก',
                          style: AppTextStyles.button16.copyWith(
                            color: AppColors.mainPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
