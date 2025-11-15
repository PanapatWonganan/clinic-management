import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/customer_address.dart';
import '../services/address_service.dart';
import '../widgets/custom_app_bar.dart';
import 'add_address_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<CustomerAddress> addresses = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedAddresses = await AddressService.fetchAddresses();
      setState(() {
        addresses = AddressService.sortAddresses(fetchedAddresses);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _setDefaultAddress(String id) async {
    try {
      await AddressService.setDefaultAddress(id);
      _loadAddresses(); // Reload to update UI
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ตั้งเป็นที่อยู่หลักสำเร็จ'),
            backgroundColor: AppColors.mainPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบที่อยู่นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AddressService.deleteAddress(id);
        _loadAddresses(); // Reload to update UI
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบที่อยู่สำเร็จ'),
              backgroundColor: AppColors.mainPurple,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'จัดการที่อยู่',
                  style: AppTextStyles.heading16Medium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleText,
                  ),
                ),
                if (addresses.length < 3)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadAddresses();
                      }
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('เพิ่มที่อยู่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainPurple),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: AppTextStyles.heading16Medium.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body14Medium.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.lightGray,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีที่อยู่',
              style: AppTextStyles.heading16Medium.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เพิ่มที่อยู่เพื่อความสะดวกในการสั่งซื้อ',
              textAlign: TextAlign.center,
              style: AppTextStyles.body14Medium.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAddressScreen(),
                  ),
                );
                if (result == true) {
                  _loadAddresses();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มที่อยู่แรก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(CustomerAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault 
              ? AppColors.mainPurple 
              : AppColors.lightGray.withValues(alpha: 0.2),
          width: address.isDefault ? 2 : 1,
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      address.name,
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mainPurple,
                          borderRadius: BorderRadius.circular(12),
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editAddress(address);
                      break;
                    case 'setDefault':
                      _setDefaultAddress(address.id);
                      break;
                    case 'delete':
                      _deleteAddress(address.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('แก้ไข'),
                      ],
                    ),
                  ),
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'setDefault',
                      child: Row(
                        children: [
                          Icon(Icons.home, size: 20),
                          SizedBox(width: 8),
                          Text('ตั้งเป็นหลัก'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('ลบ', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Recipient info
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
                color: AppColors.lightGray,
              ),
              const SizedBox(width: 8),
              Text(
                address.recipientName,
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Phone
          Row(
            children: [
              const Icon(
                Icons.phone,
                size: 16,
                color: AppColors.lightGray,
              ),
              const SizedBox(width: 8),
              Text(
                address.phone,
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.lightGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address.fullAddress,
                  style: AppTextStyles.body14Medium.copyWith(
                    color: AppColors.lightGray,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editAddress(CustomerAddress address) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(
          address: address,
          isEditing: true,
        ),
      ),
    );
    if (result == true) {
      _loadAddresses();
    }
  }
}