import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Simple validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: AppColors.mainPink,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        // Login successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Login failed - แสดงข้อความที่ชัดเจนขึ้น
        String errorMessage = 'เข้าสู่ระบบไม่สำเร็จ';

        // ตรวจสอบข้อความ error และแปลเป็นภาษาไทย
        if (result['message'] != null) {
          String msg = result['message'].toString().toLowerCase();
          if (msg.contains('password') || msg.contains('credentials')) {
            errorMessage = 'รหัสผ่านไม่ถูกต้อง';
          } else if (msg.contains('user') || msg.contains('email')) {
            errorMessage = 'ไม่พบผู้ใช้นี้ในระบบ';
          } else if (msg.contains('unauthorized')) {
            errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.mainPink,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.mainPink,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainPurple,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 100),

                // Logo
                Container(
                  width: 180,
                  height: 60,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/white-1.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // Welcome text
                Text(
                  'ยินดีต้อนรับ',
                  style: AppTextStyles.heading16Medium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'เข้าสู่ระบบเพื่อเริ่มใช้งาน',
                  style: AppTextStyles.body14Medium.copyWith(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha:0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 40),

                // Email field
                _buildInputField(
                  controller: _emailController,
                  label: 'อีเมล',
                  hintText: 'กรุณากรอกอีเมล',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password field
                _buildPasswordField(),

                const SizedBox(height: 40),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                      shadowColor: Colors.black.withValues(alpha:0.2),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.mainPurple),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'เข้าสู่ระบบ',
                            style: AppTextStyles.button16.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainPurple,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body14Medium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha:0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รหัสผ่าน',
          style: AppTextStyles.body14Medium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha:0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.purpleText,
            ),
            decoration: InputDecoration(
              hintText: 'กรุณากรอกรหัสผ่าน',
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
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.lightGray,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
