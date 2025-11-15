import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/thai_address.dart';
import '../services/thai_address_service.dart';

class ThaiAddressDropdown extends StatefulWidget {
  final int? selectedProvinceId;
  final int? selectedDistrictId;
  final int? selectedSubDistrictId;
  final String? detailAddress;
  final Function(int?) onProvinceChanged;
  final Function(int?) onDistrictChanged;
  final Function(int?) onSubDistrictChanged;
  final Function(String) onDetailAddressChanged;
  final bool isRequired;

  const ThaiAddressDropdown({
    super.key,
    this.selectedProvinceId,
    this.selectedDistrictId,
    this.selectedSubDistrictId,
    this.detailAddress,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onSubDistrictChanged,
    required this.onDetailAddressChanged,
    this.isRequired = false,
  });

  @override
  State<ThaiAddressDropdown> createState() => _ThaiAddressDropdownState();
}

class _ThaiAddressDropdownState extends State<ThaiAddressDropdown> {
  final ThaiAddressService _addressService = ThaiAddressService.instance;

  List<Province> _provinces = [];
  List<District> _districts = [];
  List<SubDistrict> _subDistricts = [];

  bool _isLoadingProvinces = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingSubDistricts = false;

  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.detailAddress ?? '';
    _loadProvinces();

    if (widget.selectedProvinceId != null) {
      _loadDistricts(widget.selectedProvinceId!);
    }

    if (widget.selectedDistrictId != null) {
      _loadSubDistricts(widget.selectedDistrictId!);
    }
  }

  @override
  void didUpdateWidget(ThaiAddressDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update text controller if address changed
    if (widget.detailAddress != oldWidget.detailAddress) {
      _addressController.text = widget.detailAddress ?? '';
    }
    
    // Reload districts if province changed
    if (widget.selectedProvinceId != oldWidget.selectedProvinceId) {
      if (widget.selectedProvinceId != null) {
        _loadDistricts(widget.selectedProvinceId!);
      } else {
        setState(() {
          _districts = [];
          _subDistricts = [];
        });
      }
    }
    
    // Reload sub-districts if district changed
    if (widget.selectedDistrictId != oldWidget.selectedDistrictId) {
      if (widget.selectedDistrictId != null && _districts.isNotEmpty) {
        _loadSubDistricts(widget.selectedDistrictId!);
      } else {
        setState(() {
          _subDistricts = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final provinces = await _addressService.getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _loadDistricts(int provinceId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _subDistricts = [];
    });

    try {
      final districts =
          await _addressService.getDistrictsByProvinceId(provinceId);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      debugPrint('Error loading districts: $e');
      setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _loadSubDistricts(int districtId) async {
    setState(() {
      _isLoadingSubDistricts = true;
      _subDistricts = [];
    });

    try {
      final subDistricts =
          await _addressService.getSubDistrictsByDistrictId(districtId);
      setState(() {
        _subDistricts = subDistricts;
        _isLoadingSubDistricts = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubDistricts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Text(
              'ที่อยู่',
              style: AppTextStyles.heading16Medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.purpleText,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: AppTextStyles.heading16Medium.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Detail Address Input
        _buildTextFormField(
          label: 'ที่อยู่โดยละเอียด',
          hint: 'เลขที่ ซอย ถนน',
          controller: _addressController,
          onChanged: widget.onDetailAddressChanged,
        ),

        const SizedBox(height: 16),

        // Province Dropdown
        _buildDropdownField<Province>(
          label: 'จังหวัด',
          items: _provinces,
          selectedValue: _provinces
                      .firstWhere(
                        (province) => province.id == widget.selectedProvinceId,
                        orElse: () => Province(id: 0, nameTh: '', nameEn: ''),
                      )
                      .id ==
                  0
              ? null
              : _provinces.firstWhere(
                  (province) => province.id == widget.selectedProvinceId,
                ),
          isLoading: _isLoadingProvinces,
          onChanged: (province) {
            widget.onProvinceChanged(province?.id);
            widget.onDistrictChanged(null);
            widget.onSubDistrictChanged(null);
            if (province != null) {
              _loadDistricts(province.id);
            } else {
              setState(() {
                _districts = [];
                _subDistricts = [];
              });
            }
          },
          itemBuilder: (province) => Text(
            province.nameTh,
            style: AppTextStyles.body14Medium,
          ),
          hintText: 'เลือกจังหวัด',
        ),

        const SizedBox(height: 16),

        // District Dropdown
        _buildDropdownField<District>(
          label: 'อำเภอ/เขต',
          items: _districts,
          selectedValue: widget.selectedDistrictId != null &&
                  _districts.isNotEmpty
              ? _districts
                      .where((district) =>
                          district.id == widget.selectedDistrictId)
                      .isNotEmpty
                  ? _districts.firstWhere(
                      (district) => district.id == widget.selectedDistrictId)
                  : null
              : null,
          isLoading: _isLoadingDistricts,
          enabled: _districts.isNotEmpty,
          onChanged: (district) {
            widget.onDistrictChanged(district?.id);
            widget.onSubDistrictChanged(null);
            if (district != null) {
              _loadSubDistricts(district.id);
            } else {
              setState(() {
                _subDistricts = [];
              });
            }
          },
          itemBuilder: (district) => Text(
            district.nameTh,
            style: AppTextStyles.body14Medium,
          ),
          hintText: widget.selectedProvinceId == null
              ? 'เลือกจังหวัดก่อน'
              : 'เลือกอำเภอ/เขต',
        ),

        const SizedBox(height: 16),

        // Sub-district Dropdown with Postal Code
        _buildDropdownField<SubDistrict>(
          label: 'ตำบล/แขวง',
          items: _subDistricts,
          selectedValue:
              widget.selectedSubDistrictId != null && _subDistricts.isNotEmpty
                  ? _subDistricts
                          .where((subDistrict) =>
                              subDistrict.id == widget.selectedSubDistrictId)
                          .isNotEmpty
                      ? _subDistricts.firstWhere((subDistrict) =>
                          subDistrict.id == widget.selectedSubDistrictId)
                      : null
                  : null,
          isLoading: _isLoadingSubDistricts,
          enabled: _subDistricts.isNotEmpty,
          onChanged: (subDistrict) {
            widget.onSubDistrictChanged(subDistrict?.id);
          },
          itemBuilder: (subDistrict) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subDistrict.nameTh,
                  style: AppTextStyles.body14Medium,
                ),
              ),
              Text(
                subDistrict.postalCode,
                style: AppTextStyles.body12Regular.copyWith(
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
          hintText: widget.selectedDistrictId == null
              ? 'เลือกอำเภอก่อน'
              : 'เลือกตำบล/แขวง',
        ),

        // Show selected postal code
        if (widget.selectedSubDistrictId != null) ...[
          const SizedBox(height: 16),
          _buildPostalCodeDisplay(),
        ],
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
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
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.body14Medium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body14Medium.copyWith(
              color: AppColors.lightGray,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightGray.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightGray.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.mainPurple,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required bool isLoading,
    required Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
    required String hintText,
    bool enabled = true,
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
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha:0.3),
              width: 1,
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.mainPurple),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: selectedValue,
                    isExpanded: true,
                    hint: Text(
                      hintText,
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.lightGray,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color:
                          enabled ? AppColors.lightGray : Colors.grey.shade400,
                    ),
                    onChanged: enabled ? onChanged : null,
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: itemBuilder(item),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPostalCodeDisplay() {
    final subDistrict = _subDistricts.firstWhere(
      (sub) => sub.id == widget.selectedSubDistrictId,
      orElse: () => SubDistrict(
          id: 0, districtId: 0, nameTh: '', nameEn: '', postalCode: ''),
    );

    if (subDistrict.id == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPurple.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainPurple.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.mainPurple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'รหัสไปรษณีย์: ',
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.purpleText,
            ),
          ),
          Text(
            subDistrict.postalCode,
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.mainPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
