import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/api_service.dart';

class PaymentMethodCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final Function(String?) onChanged;

  const PaymentMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();

  // Static method to get uploaded slips from a PaymentMethodCard
  static Future<bool> uploadSlipsFromCard(
      GlobalKey<State<PaymentMethodCard>> key, String orderId) async {
    final state = key.currentState;
    if (state != null && state is _PaymentMethodCardState) {
      return await state.uploadSlipsToServer(orderId);
    }
    return true; // Return true if no slips to upload
  }
}

class _PaymentMethodCardState extends State<PaymentMethodCard> {
  // State variables for slip upload
  List<PlatformFile> uploadedSlips = [];
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.value == widget.groupValue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onChanged(widget.value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.mainPurple
                    : AppColors.lightGray.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AppColors.mainPurple.withOpacity(0.05)
                  : Colors.white,
            ),
            child: Column(
              children: [
                // Main payment method row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.mainPurple.withOpacity(0.1)
                            : AppColors.lightGray.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isSelected
                            ? AppColors.mainPurple
                            : AppColors.lightGray,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.body14Medium.copyWith(
                              color: AppColors.purpleText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: widget.value,
                      groupValue: widget.groupValue,
                      onChanged: widget.onChanged,
                      activeColor: AppColors.mainPurple,
                    ),
                  ],
                ),

                // Expanded content when selected
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.lightGray.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: _buildExpandedContent(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    switch (widget.value) {
      case 'credit_card':
        return _buildCreditCardForm();
      case 'promptpay':
        return _buildPromptPayQR();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCreditCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info icon and title
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mainPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.payment,
                color: AppColors.mainPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชำระผ่าน Payment Gateway',
                    style: AppTextStyles.body14Medium.copyWith(
                      color: AppColors.purpleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ปลอดภัย รวดเร็ว ทันใจ',
                    style: AppTextStyles.body12Regular.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Divider
        Container(
          height: 1,
          color: AppColors.lightGray.withOpacity(0.2),
        ),

        const SizedBox(height: 20),

        // Description
        Text(
          'คุณจะถูกนำไปยังหน้าชำระเงินที่ปลอดภัยเพื่อกรอกข้อมูลบัตร',
          style: AppTextStyles.body14Medium.copyWith(
            color: AppColors.purpleText,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // Features
        _buildFeatureItem(
          icon: Icons.credit_card,
          title: 'รองรับบัตรทุกประเภท',
          subtitle: 'Visa, Mastercard, JCB',
        ),

        const SizedBox(height: 12),

        _buildFeatureItem(
          icon: Icons.flash_on,
          title: 'ชำระเงินทันที',
          subtitle: 'ไม่ต้องรอการตรวจสอบจากเจ้าหน้าที่',
        ),

        const SizedBox(height: 12),

        _buildFeatureItem(
          icon: Icons.security,
          title: 'ปลอดภัย 100%',
          subtitle: 'เข้ารหัสข้อมูลด้วยมาตรฐาน PCI DSS',
        ),

        const SizedBox(height: 20),

        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.mainPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.mainPurple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'กดปุ่ม "ยืนยันคำสั่งซื้อ" เพื่อไปยังหน้าชำระเงิน',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.purpleText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.mainPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.mainPurple,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.body12Regular.copyWith(
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptPayQR() {
    return Column(
      children: [
        Text(
          'สแกน QR Code เพื่อชำระเงิน',
          style: AppTextStyles.body14Medium.copyWith(
            color: AppColors.purpleText,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // QR Code
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
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
          ),
        ),

        const SizedBox(height: 16),

        // Bank information
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
              'Kasikorn Bank',
              style: AppTextStyles.body12Regular.copyWith(
                color: AppColors.lightGray,
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
                  isUploading ? 'กำลังอัปโหลด...' : 'คลิกเพื่ออัปโหลดสลิป',
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

        // Uploaded slips
        if (uploadedSlips.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สลิปที่อัปโหลดแล้ว (${uploadedSlips.length}/5)',
                style: AppTextStyles.body12Regular.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...uploadedSlips.asMap().entries.map((entry) {
                int index = entry.key;
                PlatformFile slip = entry.value;
                String fileName = slip.name;
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: AppTextStyles.body12Regular.copyWith(
                                color: AppColors.purpleText,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getFileSizeString(slip),
                              style: AppTextStyles.body12Regular.copyWith(
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
        ],

        const SizedBox(height: 16),

        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'วิธีการชำระเงิน:',
                style: AppTextStyles.body12Regular.copyWith(
                  color: AppColors.mainPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. เปิดแอปธนาคารหรือแอป PromptPay\n2. เลือกสแกน QR Code\n3. สแกน QR Code ที่แสดงบนหน้าจอ\n4. ยืนยันการชำระเงิน\n5. แนบสลิปการโอนเงิน',
                style: AppTextStyles.body12Regular.copyWith(
                  color: AppColors.mainPurple,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUploadOptions() {
    if (uploadedSlips.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สามารถอัปโหลดสลิปได้สูงสุด 5 ไฟล์เท่านั้น'),
          backgroundColor: AppColors.mainPink,
        ),
      );
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
    if (kIsWeb) {
      _showErrorMessage('การถ่ายรูปไม่รองรับบนเว็บเบราว์เซอร์');
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final platformFile = PlatformFile(
          name: image.name,
          size: bytes.length,
          bytes: bytes,
          path: !kIsWeb ? image.path : null,
        );
        await _uploadSlipFile(platformFile);
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
        final bytes = await image.readAsBytes();
        final platformFile = PlatformFile(
          name: image.name,
          size: bytes.length,
          bytes: bytes,
          path: !kIsWeb ? image.path : null,
        );
        await _uploadSlipFile(platformFile);
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
        withData: true, // Important for web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        await _uploadSlipFile(file);
      }
    } catch (e) {
      print('Error picking file: $e');
      _showErrorMessage('เกิดข้อผิดพลาดในการเลือกไฟล์');
    }
  }

  Future<void> _uploadSlipFile(PlatformFile file) async {
    if (uploadedSlips.length >= 5) {
      _showErrorMessage('สามารถอัปโหลดสลิปได้สูงสุด 5 ไฟล์เท่านั้น');
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // For now, just add to local list for UI purposes
      // Backend upload will be implemented when order is created
      setState(() {
        uploadedSlips.add(file);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มสลิปสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorMessage('เกิดข้อผิดพลาดในการอัปโหลด');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  // Method to upload slips after order is created
  Future<bool> uploadSlipsToServer(String orderId) async {
    if (uploadedSlips.isEmpty) return true;

    try {
      print(
          'Starting slip upload for order: $orderId with ${uploadedSlips.length} slips');

      final response = await ApiService.uploadPlatformFiles(
        '/payment-slips/upload',
        uploadedSlips,
        data: {'order_id': orderId},
        fileFieldName: 'files',
      );

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = ApiService.parseResponse(response);
        bool success = responseData['success'] == true;
        print('Upload success: $success');
        return success;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading slips: $e');
      return false;
    }
  }

  void _removeSlip(int index) {
    setState(() {
      uploadedSlips.removeAt(index);
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.mainPink,
      ),
    );
  }

  String _getFileSizeString(PlatformFile file) {
    try {
      final bytes = file.size;
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

  // Get uploaded slips for external access (e.g., from checkout screen)
  List<PlatformFile> getUploadedSlips() {
    return List.from(uploadedSlips);
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body12Regular.copyWith(
            color: AppColors.purpleText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.lightGray.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            keyboardType: keyboardType,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.purpleText,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.body12Regular.copyWith(
                color: AppColors.lightGray,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
