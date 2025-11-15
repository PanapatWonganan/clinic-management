import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_menu_item.dart';
import 'profile_edit_screen.dart';
import 'change_password_screen.dart';
import 'tax_address_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile userProfile = UserProfile();
  bool isLoadingProfile = true;

  /*final List<MembershipLevel> membershipLevels = [
    MembershipLevel(
      id: 1,
      name: 'Level 1',
      boxes: '5 กล่อง',
      free: 'ฟรี 3',
      progress: 37.5,
    ),
    MembershipLevel(
      id: 2,
      name: 'Level 2',
      boxes: '10 กล่อง',
      free: 'ฟรี 10',
      progress: 0,
    ),
    MembershipLevel(
      id: 3,
      name: 'Level 3',
      boxes: '50 กล่อง',
      free: 'ฟรี 75',
      progress: 0,
    ),
  ];*/

  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.home_outlined,
      'title': 'หน้าแรก',
      'onTap': 'home',
    },
    {
      'icon': Icons.person_outline,
      'title': 'ข้อมูลคลีนิค',
      'onTap': 'profile',
    },
    {
      'icon': Icons.lock_outline,
      'title': 'เปลี่ยนรหัสผ่าน',
      'onTap': 'change_password',
    },
    {
      'icon': Icons.receipt_long_outlined,
      'title': 'เพิ่มที่อยู่สำหรับออกใบกำกับภาษี',
      'onTap': 'tax_address',
    },
    {
      'icon': Icons.history_outlined,
      'title': 'ประวัติการซื้อ',
      'onTap': 'history',
    },
    {
      'icon': Icons.logout_outlined,
      'title': 'ออกจากระบบ',
      'onTap': 'logout',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await ProfileService.instance.loadProfile();
    setState(() {
      userProfile = profile;
      isLoadingProfile = false;
    });
  }

  Future<void> _handleMenuTap(String action) async {
    switch (action) {
      case 'home':
        Navigator.pop(context);
        break;
      case 'profile':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
        );

        // ถ้ามีการแก้ไขข้อมูล ให้โหลดข้อมูลใหม่และส่ง result กลับ
        if (result == true) {
          await _loadUserProfile();
          Navigator.pop(context, true); // ส่ง result กลับไปยัง Home Screen
        }
        break;
      case 'change_password':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
        break;
      case 'tax_address':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaxAddressScreen()),
        );
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
        );
        break;
      case 'logout':
        _showLogoutDialog();
        break;
      default:
        // Handle other menu items
        break;
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainPink),
          ),
        ),
      );

      // Call logout service
      await AuthService.instance.logout();

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to login screen and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ออกจากระบบสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.mainPink,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'ออกจากระบบ',
            style: AppTextStyles.heading16Medium,
          ),
          content: Text(
            'คุณต้องการออกจากระบบหรือไม่?',
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.lightGray,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ออกจากระบบ',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Profile Section
            Column(
              children: [
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightGray.withValues(alpha: 0.3),
                    border: Border.all(
                      color: AppColors.lightGray.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.lightGray,
                  ),
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  isLoadingProfile
                      ? 'กำลังโหลด...'
                      : (userProfile.name.isEmpty
                          ? 'ชื่อคลีนิค'
                          : userProfile.name),
                  style: AppTextStyles.heading16Medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // Email
                Text(
                  isLoadingProfile
                      ? 'กำลังโหลด...'
                      : (userProfile.email.isEmpty
                          ? 'อีเมล'
                          : userProfile.email),
                  style: AppTextStyles.body12Regular.copyWith(
                    fontSize: 14,
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Membership Progress Card
            /*MembershipProgressCard(
              levels: membershipLevels,
              membershipType: 'exMember', // Default for profile screen
            ),*/

            const SizedBox(height: 40),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: menuItems
                    .map((item) => ProfileMenuItem(
                          icon: item['icon'] as IconData,
                          title: item['title'] as String,
                          onTap: () => _handleMenuTap(item['onTap'] as String),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
