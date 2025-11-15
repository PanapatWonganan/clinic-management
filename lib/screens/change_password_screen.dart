import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Validate passwords
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านใหม่และยืนยันรหัสผ่านไม่ตรงกัน'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    // TODO: Implement change password functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เปลี่ยนรหัสผ่านสำเร็จ'),
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
                      'เปลี่ยนรหัสผ่าน',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'กรุณากรอกรหัสผ่านปัจจุบันและรหัสผ่านใหม่',
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.lightGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Current password field
                    _buildPasswordField(
                      label: 'รหัสผ่านปัจจุบัน',
                      controller: _currentPasswordController,
                      hintText: 'กรุณากรอกรหัสผ่านปัจจุบัน',
                      isVisible: _isCurrentPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isCurrentPasswordVisible =
                              !_isCurrentPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // New password field
                    _buildPasswordField(
                      label: 'รหัสผ่านใหม่',
                      controller: _newPasswordController,
                      hintText: 'กรุณากรอกรหัสผ่านใหม่',
                      isVisible: _isNewPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // Password requirements
                    Text(
                      'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
                      style: AppTextStyles.body12Regular.copyWith(
                        color: AppColors.lightGray,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Confirm password field
                    _buildPasswordField(
                      label: 'ยืนยันรหัสผ่านใหม่',
                      controller: _confirmPasswordController,
                      hintText: 'กรุณายืนยันรหัสผ่านใหม่',
                      isVisible: _isConfirmPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 40),

                    // Security tips
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
                                Icons.security,
                                color: AppColors.mainPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'เคล็ดลับความปลอดภัย',
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.mainPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• ใช้รหัสผ่านที่มีความยาวอย่างน้อย 8 ตัวอักษร\n'
                            '• ผสมผสานตัวอักษรพิมพ์ใหญ่ พิมพ์เล็ก ตัวเลข และสัญลักษณ์\n'
                            '• หลีกเลี่ยงการใช้ข้อมูลส่วนตัว เช่น ชื่อ วันเกิด\n'
                            '• เปลี่ยนรหัสผ่านเป็นประจำทุก 3-6 เดือน',
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
                    'บันทึกการเปลี่ยนแปลง',
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body14Medium.copyWith(
            color: AppColors.purpleText,
            fontWeight: FontWeight.w500,
          ),
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
            obscureText: !isVisible,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.purpleText,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.body14Medium.copyWith(
                color: AppColors.lightGray,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.lightGray,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
