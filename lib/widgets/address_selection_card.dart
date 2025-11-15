import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/customer_address.dart';
import '../services/address_service.dart';
import '../screens/address_management_screen.dart';
import '../screens/add_address_screen.dart';

class AddressSelectionCard extends StatefulWidget {
  final CustomerAddress? selectedAddress;
  final List<CustomerAddress>? addresses;
  final ValueChanged<CustomerAddress?> onAddressSelected;
  final bool showManageButton;

  const AddressSelectionCard({
    super.key,
    required this.selectedAddress,
    this.addresses,
    required this.onAddressSelected,
    this.showManageButton = true,
  });

  @override
  State<AddressSelectionCard> createState() => _AddressSelectionCardState();
}

class _AddressSelectionCardState extends State<AddressSelectionCard> {
  List<CustomerAddress> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.addresses != null) {
      _addresses = widget.addresses!;
    } else {
      _loadAddresses();
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedAddresses = await AddressService.fetchAddresses();
      setState(() {
        _addresses = AddressService.sortAddresses(fetchedAddresses);
        _isLoading = false;
        
        // Auto-select default address if no address is selected
        if (widget.selectedAddress == null && _addresses.isNotEmpty) {
          final defaultAddress = AddressService.getDefaultAddress(_addresses);
          if (defaultAddress != null) {
            widget.onAddressSelected(defaultAddress);
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ที่อยู่จัดส่ง',
                style: AppTextStyles.heading16Medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleText,
                ),
              ),
              if (widget.showManageButton)
                TextButton(
                  onPressed: () => _navigateToAddressManagement(),
                  child: Text(
                    'จัดการ',
                    style: AppTextStyles.body14Medium.copyWith(
                      color: AppColors.mainPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainPurple),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: AppTextStyles.body12Regular.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadAddresses,
              child: const Text('ลองใหม่', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return _buildEmptyAddressState();
    }

    if (widget.selectedAddress != null) {
      return _buildSelectedAddressView();
    }

    return _buildAddressSelectionView();
  }

  Widget _buildEmptyAddressState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off,
            size: 48,
            color: AppColors.lightGray,
          ),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีที่อยู่จัดส่ง',
            style: AppTextStyles.body14Medium.copyWith(
              color: AppColors.lightGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เพิ่มที่อยู่เพื่อดำเนินการสั่งซื้อ',
            textAlign: TextAlign.center,
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToAddAddress(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('เพิ่มที่อยู่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAddressView() {
    final address = widget.selectedAddress!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address header
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      address.name,
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.purpleText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mainPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'หลัก',
                          style: AppTextStyles.caption10.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showAddressSelectionDialog(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'เปลี่ยน',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.mainPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Recipient info
          Text(
            address.recipientName,
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.purpleText,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Phone
          Text(
            address.phone,
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Address
          Text(
            address.fullAddress,
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.lightGray,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelectionView() {
    return Column(
      children: [
        ...List.generate(_addresses.length, (index) {
          final address = _addresses[index];
          final isSelected = widget.selectedAddress?.id == address.id;
          
          return Container(
            margin: EdgeInsets.only(bottom: index < _addresses.length - 1 ? 12 : 0),
            child: InkWell(
              onTap: () => widget.onAddressSelected(address),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.mainPurple.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.mainPurple 
                        : AppColors.lightGray.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Radio<CustomerAddress>(
                      value: address,
                      groupValue: widget.selectedAddress,
                      onChanged: widget.onAddressSelected,
                      activeColor: AppColors.mainPurple,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.name,
                                style: AppTextStyles.body14Medium.copyWith(
                                  color: AppColors.purpleText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mainPurple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'หลัก',
                                    style: AppTextStyles.caption10.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            '${address.recipientName} • ${address.phone}',
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            address.shortAddress,
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        // Add new address button
        if (_addresses.length < 3) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToAddAddress(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('เพิ่มที่อยู่ใหม่'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mainPurple,
                side: const BorderSide(color: AppColors.mainPurple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddressSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกที่อยู่จัดส่ง'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _addresses.map((address) {
                return RadioListTile<CustomerAddress>(
                  value: address,
                  groupValue: widget.selectedAddress,
                  onChanged: (selectedAddress) {
                    widget.onAddressSelected(selectedAddress);
                    Navigator.of(context).pop();
                  },
                  activeColor: AppColors.mainPurple,
                  title: Text(
                    address.name,
                    style: AppTextStyles.body14Medium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${address.recipientName}\n${address.shortAddress}',
                    style: AppTextStyles.body12Regular.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
                  isThreeLine: true,
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddressManagement() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressManagementScreen(),
      ),
    );
    
    if (result == true) {
      _loadAddresses();
    }
  }

  void _navigateToAddAddress() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAddressScreen(),
      ),
    );
    
    if (result == true) {
      _loadAddresses();
    }
  }
}