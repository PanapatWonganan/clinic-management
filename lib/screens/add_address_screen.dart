import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/customer_address.dart';
import '../models/thai_address.dart';
import '../services/address_service.dart';
import '../services/thai_address_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/thai_address_dropdown.dart';

class AddAddressScreen extends StatefulWidget {
  final CustomerAddress? address;
  final bool isEditing;

  const AddAddressScreen({
    super.key,
    this.address,
    this.isEditing = false,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _postalCodeController = TextEditingController();

  Province? selectedProvince;
  District? selectedDistrict;
  SubDistrict? selectedSubDistrict;
  
  bool isLoading = false;
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.isEditing && widget.address != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final address = widget.address!;
    
    _nameController.text = address.name;
    _recipientNameController.text = address.recipientName;
    _phoneController.text = address.phone;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _postalCodeController.text = address.postalCode;
    isDefault = address.isDefault;
    
    // Load address data based on IDs
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    final address = widget.address!;
    
    try {
      // Load provinces
      final provinces = await ThaiAddressService.instance.getProvinces();
      selectedProvince = provinces.firstWhere(
        (p) => p.id == address.provinceId,
        orElse: () => provinces.first,
      );
      
      // Load districts
      final districts = await ThaiAddressService.instance.getDistrictsByProvinceId(selectedProvince!.id);
      selectedDistrict = districts.firstWhere(
        (d) => d.id == address.districtId,
        orElse: () => districts.first,
      );
      
      // Load sub-districts
      final subDistricts = await ThaiAddressService.instance.getSubDistrictsByDistrictId(selectedDistrict!.id);
      selectedSubDistrict = subDistricts.firstWhere(
        (s) => s.id == address.subDistrictId,
        orElse: () => subDistricts.first,
      );
      
      setState(() {});
    } catch (e) {
      debugPrint('Error loading address data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  widget.isEditing ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่ใหม่',
                  style: AppTextStyles.heading16Medium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleText,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 20),
                    
                    _buildRecipientNameField(),
                    const SizedBox(height: 20),
                    
                    _buildPhoneField(),
                    const SizedBox(height: 20),
                    
                    _buildAddressLine1Field(),
                    const SizedBox(height: 20),
                    
                    _buildAddressLine2Field(),
                    const SizedBox(height: 20),
                    
                    _buildAddressSelectionFields(),
                    const SizedBox(height: 20),
                    
                    _buildPostalCodeField(),
                    const SizedBox(height: 20),
                    
                    if (!widget.isEditing || !widget.address!.isDefault)
                      _buildDefaultAddressSwitch(),
                    
                    const SizedBox(height: 32),
                    
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ชื่อที่อยู่ *',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'เช่น บ้าน, ที่ทำงาน, คอนโด',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณาระบุชื่อที่อยู่';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRecipientNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ชื่อผู้รับ *',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _recipientNameController,
          decoration: InputDecoration(
            hintText: 'ชื่อ-นามสกุล ผู้รับพัสดุ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณาระบุชื่อผู้รับ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เบอร์โทรศัพท์ *',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '08x-xxx-xxxx',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณาระบุเบอร์โทรศัพท์';
            }
            if (!AddressService.isValidPhoneNumber(value.trim())) {
              return 'รูปแบบเบอร์โทรไม่ถูกต้อง';
            }
            return null;
          },
          onChanged: (value) {
            // Auto-format phone number
            if (value.length >= 10) {
              _phoneController.text = AddressService.formatPhoneNumber(value);
              _phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: _phoneController.text.length),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAddressLine1Field() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ที่อยู่ *',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressLine1Controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'เลขที่ ซอย ถนน',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณาระบุที่อยู่';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressLine2Field() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ที่อยู่เพิ่มเติม',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressLine2Controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSelectionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'จังหวัด/อำเภอ/ตำบล *',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        ThaiAddressDropdown(
          selectedProvinceId: selectedProvince?.id,
          selectedDistrictId: selectedDistrict?.id,
          selectedSubDistrictId: selectedSubDistrict?.id,
          detailAddress: _addressLine1Controller.text,
          onProvinceChanged: (provinceId) async {
            if (provinceId != null) {
              final provinces = await ThaiAddressService.instance.getProvinces();
              final province = provinces.firstWhere((p) => p.id == provinceId);
              setState(() {
                selectedProvince = province;
                selectedDistrict = null;
                selectedSubDistrict = null;
                _postalCodeController.clear();
              });
            } else {
              setState(() {
                selectedProvince = null;
                selectedDistrict = null;
                selectedSubDistrict = null;
                _postalCodeController.clear();
              });
            }
          },
          onDistrictChanged: (districtId) async {
            if (districtId != null && selectedProvince != null) {
              final districts = await ThaiAddressService.instance.getDistrictsByProvinceId(selectedProvince!.id);
              final district = districts.firstWhere((d) => d.id == districtId);
              setState(() {
                selectedDistrict = district;
                selectedSubDistrict = null;
                _postalCodeController.clear();
              });
            } else {
              setState(() {
                selectedDistrict = null;
                selectedSubDistrict = null;
                _postalCodeController.clear();
              });
            }
          },
          onSubDistrictChanged: (subDistrictId) async {
            if (subDistrictId != null && selectedDistrict != null) {
              final subDistricts = await ThaiAddressService.instance.getSubDistrictsByDistrictId(selectedDistrict!.id);
              final subDistrict = subDistricts.firstWhere((s) => s.id == subDistrictId);
              setState(() {
                selectedSubDistrict = subDistrict;
                _postalCodeController.text = subDistrict.postalCode;
              });
            } else {
              setState(() {
                selectedSubDistrict = null;
                _postalCodeController.clear();
              });
            }
          },
          onDetailAddressChanged: (address) {
            _addressLine1Controller.text = address;
          },
        ),
      ],
    );
  }

  Widget _buildPostalCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รหัสไปรษณีย์ *',
          style: AppTextStyles.body14Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _postalCodeController,
          keyboardType: TextInputType.number,
          maxLength: 5,
          decoration: InputDecoration(
            hintText: '10xxx',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณาระบุรหัสไปรษณีย์';
            }
            if (!AddressService.isValidPostalCode(value.trim())) {
              return 'รูปแบบรหัสไปรษณีย์ไม่ถูกต้อง';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDefaultAddressSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตั้งเป็นที่อยู่หลัก',
                  style: AppTextStyles.body14Medium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ใช้เป็นที่อยู่เริ่มต้นสำหรับการสั่งซื้อ',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDefault,
            onChanged: (value) {
              setState(() {
                isDefault = value;
              });
            },
            activeColor: AppColors.mainPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มที่อยู่',
                style: AppTextStyles.button16.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedProvince == null || selectedDistrict == null || selectedSubDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกจังหวัด อำเภอ และตำบล'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final addressData = {
        'name': _nameController.text.trim(),
        'recipient_name': _recipientNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address_line_1': _addressLine1Controller.text.trim(),
        'address_line_2': _addressLine2Controller.text.trim().isEmpty 
            ? null 
            : _addressLine2Controller.text.trim(),
        'district': selectedDistrict!.name,
        'province': selectedProvince!.name,
        'postal_code': _postalCodeController.text.trim(),
        'province_id': selectedProvince!.id,
        'district_id': selectedDistrict!.id,
        'sub_district_id': selectedSubDistrict!.id,
        'is_default': isDefault,
      };

      if (widget.isEditing) {
        await AddressService.updateAddress(widget.address!.id, addressData);
      } else {
        await AddressService.createAddress(addressData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'แก้ไขที่อยู่สำเร็จ' : 'เพิ่มที่อยู่สำเร็จ'),
            backgroundColor: AppColors.mainPurple,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}