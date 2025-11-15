import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';

class TaxAddressScreen extends StatefulWidget {
  const TaxAddressScreen({super.key});

  @override
  State<TaxAddressScreen> createState() => _TaxAddressScreenState();
}

class _TaxAddressScreenState extends State<TaxAddressScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Validate required fields
    if (_companyNameController.text.isEmpty ||
        _taxIdController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกข้อมูลสำเร็จ'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page title
                    Text(
                      'เพิ่มที่อยู่สำหรับออกใบกำกับภาษี',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'กรุณากรอกข้อมูลสำหรับออกใบกำกับภาษี',
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.lightGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Company information section
                    Text(
                      'ข้อมูลบริษัท',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Company name field
                    _buildInputField(
                      label: 'ชื่อบริษัท/ร้าน',
                      controller: _companyNameController,
                      hintText: 'กรุณากรอกชื่อบริษัทหรือร้าน',
                      isRequired: true,
                    ),

                    const SizedBox(height: 20),

                    // Tax ID field
                    _buildInputField(
                      label: 'เลขประจำตัวผู้เสียภาษี',
                      controller: _taxIdController,
                      hintText: 'กรุณากรอกเลขประจำตัวผู้เสียภาษี 13 หลัก',
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),

                    const SizedBox(height: 32),

                    // Address section
                    Text(
                      'ที่อยู่',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Address field
                    _buildInputField(
                      label: 'ที่อยู่',
                      controller: _addressController,
                      hintText: 'กรุณากรอกที่อยู่',
                      maxLines: 3,
                      isRequired: true,
                    ),

                    const SizedBox(height: 20),

                    // District and Province row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'แขวง/ตำบล',
                            controller: _districtController,
                            hintText: 'กรุณากรอกแขวง/ตำบล',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: 'จังหวัด',
                            controller: _provinceController,
                            hintText: 'กรุณากรอกจังหวัด',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Postal code field
                    _buildInputField(
                      label: 'รหัสไปรษณีย์',
                      controller: _postalCodeController,
                      hintText: 'กรุณากรอกรหัสไปรษณีย์',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 32),

                    // Contact information section
                    Text(
                      'ข้อมูลติดต่อ',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phone field
                    _buildInputField(
                      label: 'เบอร์โทรศัพท์',
                      controller: _phoneController,
                      hintText: 'กรุณากรอกเบอร์โทรศัพท์',
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // Email field
                    _buildInputField(
                      label: 'อีเมล',
                      controller: _emailController,
                      hintText: 'กรุณากรอกอีเมล',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 32),

                    // Note section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.mainPurple.withValues(alpha:0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.mainPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'หมายเหตุ',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.mainPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• ข้อมูลที่มีเครื่องหมาย * จำเป็นต้องกรอก\n'
                            '• ข้อมูลนี้จะใช้สำหรับออกใบกำกับภาษีเท่านั้น\n'
                            '• กรุณาตรวจสอบความถูกต้องของข้อมูลก่อนบันทึก\n'
                            '• สามารถแก้ไขข้อมูลได้ในภายหลัง',
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.mainPurple,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Bottom save button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'บันทึกข้อมูล',
                    style: AppTextStyles.button16.copyWith(
                      fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.body14Medium.copyWith(
                color: AppColors.purpleText,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.mainPink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha:0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.purpleText,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.body14Medium.copyWith(
                color: AppColors.lightGray,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
