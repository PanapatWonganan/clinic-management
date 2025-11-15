import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/thai_address_dropdown.dart';
import '../services/profile_service.dart';
import '../services/thai_address_service.dart';
import '../models/user_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Thai address fields
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  int? _selectedSubDistrictId;
  String _detailAddress = '';

  bool _isLoading = true;
  final ThaiAddressService _addressService = ThaiAddressService.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await ProfileService.instance.loadProfile();

    setState(() {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _detailAddress = profile.address;
      _selectedProvinceId = profile.provinceId;
      _selectedDistrictId = profile.districtId;
      _selectedSubDistrictId = profile.subDistrictId;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Get address names from IDs for backward compatibility
    final province = _selectedProvinceId != null
        ? await _addressService.getProvinceById(_selectedProvinceId!)
        : null;
    final district = _selectedDistrictId != null
        ? await _addressService.getDistrictById(_selectedDistrictId!)
        : null;
    final subDistrict = _selectedSubDistrictId != null
        ? await _addressService.getSubDistrictById(_selectedSubDistrictId!)
        : null;

    // สร้าง UserProfile ใหม่จากข้อมูลในฟอร์ม
    final updatedProfile = UserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _detailAddress.trim(),
      district: subDistrict?.nameTh ?? '',
      province: province?.nameTh ?? '',
      postalCode: subDistrict?.postalCode ?? '',
      provinceId: _selectedProvinceId,
      districtId: _selectedDistrictId,
      subDistrictId: _selectedSubDistrictId,
    );

    // บันทึกข้อมูล
    final success = await ProfileService.instance.saveProfile(updatedProfile);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // ส่ง result กลับไปเพื่อให้หน้าอื่นอัปเดต
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'เลือกรูปภาพ',
              style: AppTextStyles.heading16Medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.purpleText,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'ถ่ายรูป',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement camera
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'เลือกจากแกลเลอรี่',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement gallery
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.lightPurple.withValues(alpha:0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: AppColors.mainPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.purpleText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
                      'แก้ไขข้อมูลคลีนิค',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Profile image section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.lightGray.withValues(alpha:0.3),
                                  border: Border.all(
                                    color: AppColors.lightGray.withValues(alpha:0.5),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.lightGray,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImagePicker,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.mainPink,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'แตะเพื่อเปลี่ยนรูปภาพ',
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form fields
                    _buildInputField(
                      label: 'ชื่อ-นามสกุล',
                      controller: _nameController,
                      hintText: 'กรุณากรอกชื่อ-นามสกุล',
                    ),

                    const SizedBox(height: 20),

                    _buildInputField(
                      label: 'อีเมล',
                      controller: _emailController,
                      hintText: 'กรุณากรอกอีเมล',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    _buildInputField(
                      label: 'เบอร์โทรศัพท์',
                      controller: _phoneController,
                      hintText: 'กรุณากรอกเบอร์โทรศัพท์',
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 32),

                    // Thai Address Dropdown
                    ThaiAddressDropdown(
                      selectedProvinceId: _selectedProvinceId,
                      selectedDistrictId: _selectedDistrictId,
                      selectedSubDistrictId: _selectedSubDistrictId,
                      detailAddress: _detailAddress,
                      onProvinceChanged: (provinceId) {
                        setState(() {
                          _selectedProvinceId = provinceId;
                          // Reset dependent selections when province changes
                          _selectedDistrictId = null;
                          _selectedSubDistrictId = null;
                        });
                      },
                      onDistrictChanged: (districtId) {
                        setState(() {
                          _selectedDistrictId = districtId;
                          // Reset sub-district when district changes
                          _selectedSubDistrictId = null;
                        });
                      },
                      onSubDistrictChanged: (subDistrictId) {
                        setState(() {
                          _selectedSubDistrictId = subDistrictId;
                        });
                      },
                      onDetailAddressChanged: (address) {
                        setState(() {
                          _detailAddress = address;
                        });
                      },
                      isRequired: true,
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
}
