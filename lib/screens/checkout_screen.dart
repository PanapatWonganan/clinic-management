import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/checkout_item.dart';
import '../models/user_profile.dart';
import '../models/delivery_option.dart';
import '../models/customer_address.dart';
import '../models/membership_level.dart';
import '../services/profile_service.dart';
import '../services/api_service.dart';
import '../services/delivery_service.dart';
import '../services/address_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/checkout_item_card.dart';
import '../widgets/address_selection_card.dart';
import '../widgets/vehicle_type_selector.dart';
import '../widgets/delivery_company_selector.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/membership_progress_card.dart';
import 'payment_pending_screen.dart';
import 'payment_webview_screen.dart';
import 'profile_edit_screen.dart';
import 'redeem_free_items_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CheckoutItem> cartItems;
  final Map<String, dynamic>? appliedReward; // reward ที่แลกมาใช้เป็นส่วนลด
  final Map<String, dynamic>? membershipData; // ข้อมูล membership progress
  final bool isFreeItemOnly; // เป็น order ของแถมฟรีอย่างเดียว (ไม่ต้องชำระเงิน)
  final VoidCallback? onOrderCreated; // callback เมื่อสร้าง order สำเร็จ
  final Map<String, dynamic>? freeItemRedemption; // ข้อมูล reward สำหรับแลกของแถม

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    this.appliedReward,
    this.membershipData,
    this.isFreeItemOnly = false,
    this.onOrderCreated,
    this.freeItemRedemption,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  VehicleType? selectedVehicleType;
  DeliveryOption? selectedDeliveryOption;
  late String selectedPaymentMethod;
  UserProfile userProfile = UserProfile();
  bool isLoadingProfile = true;
  List<DeliveryOption> availableDeliveryOptions = [];
  bool isLoadingDeliveryOptions = false;

  // Address selection state
  CustomerAddress? selectedAddress;
  List<CustomerAddress> addresses = [];
  bool isLoadingAddresses = false;

  // Membership state
  List<MembershipLevel> membershipLevels = [];
  Map<String, dynamic>? membershipData;
  bool isLoadingMembership = true;

  // Reward selection state - ผู้ใช้เลือก reward ในหน้า checkout
  Map<String, dynamic>? selectedReward;

  // สิทธิ์ของแถมที่มีอยู่แล้ว (จาก user_claimed_rewards)
  List<Map<String, dynamic>> existingRewards = [];
  Map<String, dynamic>? existingRewardsSummary;
  bool isLoadingExistingRewards = true;

  // ของแถมที่เลือกเพิ่มในออเดอร์นี้
  List<Map<String, dynamic>> selectedFreeItems = [];

  // Global keys to access payment method card state
  final GlobalKey<State<PaymentMethodCard>> _creditCardKey =
      GlobalKey<State<PaymentMethodCard>>();
  final GlobalKey<State<PaymentMethodCard>> _promptPayKey =
      GlobalKey<State<PaymentMethodCard>>();

  List<CheckoutItem> get checkoutItems => widget.cartItems;

  // Reward ที่แลกมาใช้เป็นส่วนลด (ใช้ selectedReward ก่อน ถ้าไม่มีใช้ widget.appliedReward)
  Map<String, dynamic>? get appliedReward => selectedReward ?? widget.appliedReward;

  double get subtotal {
    return checkoutItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get discount {
    // No automatic discount - discounts should be applied at product level
    return 0.0;
  }

  // ของแถมจาก promotion (ไม่หักราคา - เป็นของฟรีที่จะได้รับหลังชำระเงิน)
  int get freeItemsCount {
    if (appliedReward == null) return 0;
    return (appliedReward!['earned_free_items'] ?? 0) as int;
  }

  double get deliveryFee {
    return selectedDeliveryOption?.price ?? 0;
  }

  double get total {
    // ของแถมไม่หักราคา - ลูกค้าจ่ายเต็มราคา แล้วได้ของฟรีเพิ่ม
    return subtotal - discount + deliveryFee;
  }

  // คำนวณจำนวนชิ้นในตะกร้า (สำหรับ preview progress)
  int get cartItemCount {
    return checkoutItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // คำนวณ preview progress (จำนวนในตะกร้าใหม่เท่านั้น - widget จะรวมกับ currentQuantity เอง)
  double get previewQuantity {
    // ส่งแค่ cartItemCount เพราะ widget จะเอาไปรวมกับ currentQuantity เอง
    return cartItemCount.toDouble();
  }

  @override
  void initState() {
    super.initState();
    // For free item orders, default to promptpay (slip upload)
    // For regular orders, default to credit_card
    selectedPaymentMethod = widget.isFreeItemOnly ? 'promptpay' : 'credit_card';
    _loadUserProfile();
    _loadAddresses();
    _loadMembershipData();
    _loadExistingRewards();
  }

  // โหลดสิทธิ์ของแถมที่มีอยู่แล้ว
  Future<void> _loadExistingRewards() async {
    setState(() {
      isLoadingExistingRewards = true;
    });

    try {
      final response = await ApiService.get('/my-rewards');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            existingRewards = List<Map<String, dynamic>>.from(data['data']['rewards'] ?? []);
            existingRewardsSummary = data['data']['summary'];
            isLoadingExistingRewards = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading existing rewards: $e');
    }

    setState(() {
      isLoadingExistingRewards = false;
    });
  }

  // จำนวนสิทธิ์ของแถมที่มีอยู่
  int get totalExistingRewards {
    return existingRewardsSummary?['total_remaining'] ?? 0;
  }

  Future<void> _loadMembershipData() async {
    setState(() {
      isLoadingMembership = true;
    });

    try {
      // ใช้ membership data ที่ส่งมาจาก HomeScreen ถ้ามี
      if (widget.membershipData != null) {
        membershipData = widget.membershipData;
        _parseMembershipLevels(widget.membershipData!);
      } else {
        // โหลดจาก API ถ้าไม่มี
        final progressData = await ProfileService.instance.getMembershipProgress();
        if (progressData != null) {
          membershipData = progressData;
          _parseMembershipLevels(progressData);
        }
      }
    } catch (e) {
      debugPrint('Error loading membership data: $e');
    }

    setState(() {
      isLoadingMembership = false;
    });
  }

  void _parseMembershipLevels(Map<String, dynamic> data) {
    if (data['level_progress'] != null) {
      membershipLevels = (data['level_progress'] as List).map((levelData) {
        // ใช้ progress_percentage จาก API (รองรับ null)
        final progress = levelData['progress_percentage'] ?? levelData['progress'] ?? 0;
        return MembershipLevel(
          id: levelData['level'] ?? 0,
          name: 'Level ${levelData['level'] ?? 0}',
          boxes: '${levelData['required_quantity'] ?? 0} ชิ้น',
          free: 'ฟรี ${levelData['free_quantity'] ?? levelData['earned_free_items'] ?? 0} ชิ้น',
          progress: (progress is num) ? progress.toDouble() : 0.0,
        );
      }).toList();
    }
  }

  // ดึง effective_quantity จาก membership data (จำนวนสะสมที่ยังไม่ได้แลก)
  double _getEffectiveQuantityFromMembership() {
    if (membershipData == null) return 0;

    // ใช้ effective_quantity จาก root level ของ API response
    // นี่คือจำนวนที่สะสมไว้หลังจาก claim ครั้งล่าสุด (หรือทั้งหมดถ้ายังไม่เคย claim)
    final effectiveQty = membershipData!['effective_quantity'];
    if (effectiveQty != null) {
      // Handle both num and String types
      if (effectiveQty is num) {
        return effectiveQty.toDouble();
      }
      return double.tryParse(effectiveQty.toString()) ?? 0;
    }
    return 0;
  }

  // ดึง required_quantity ของแต่ละ level
  List<int> _getRequiredQuantitiesFromMembership() {
    if (membershipData == null) return [];

    final levelProgress = membershipData!['level_progress'] as List?;
    if (levelProgress == null) return [];

    return levelProgress.map((level) {
      final val = level['required_quantity'] ?? 0;
      // Handle both num and String types
      if (val is num) {
        return val.toInt();
      }
      return int.tryParse(val.toString()) ?? 0;
    }).toList();
  }

  Future<void> _loadUserProfile() async {
    print('Loading user profile...');
    final profile = await ProfileService.instance.loadProfile();
    print('Profile loaded: ${profile.district} ${profile.province}');
    setState(() {
      userProfile = profile;
      isLoadingProfile = false;
    });
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoadingAddresses = true;
    });

    try {
      final fetchedAddresses = await AddressService.fetchAddresses();
      setState(() {
        addresses = AddressService.sortAddresses(fetchedAddresses);
        isLoadingAddresses = false;

        // Auto-select default address
        final defaultAddress = AddressService.getDefaultAddress(addresses);
        if (defaultAddress != null) {
          selectedAddress = defaultAddress;
          // Load delivery options based on selected address
          _loadDeliveryOptionsForAddress(defaultAddress);
        } else if (addresses.isNotEmpty) {
          selectedAddress = addresses.first;
          _loadDeliveryOptionsForAddress(addresses.first);
        }
      });
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        isLoadingAddresses = false;
      });
    }
  }

  Future<void> _loadDeliveryOptions() async {
    setState(() {
      isLoadingDeliveryOptions = true;
    });

    try {
      // Try to get delivery options based on user's district and province
      final userDistrict = _getUserDistrict();
      final userProvince = _getUserProvince();

      final options = await DeliveryService.getDeliveryOptionsForAddress(
          userDistrict, userProvince);

      setState(() {
        availableDeliveryOptions = options;
        isLoadingDeliveryOptions = false;
      });
    } catch (e) {
      print('Error loading delivery options: $e');
      // Fallback to sample options
      setState(() {
        availableDeliveryOptions = DeliveryOption.getSampleOptions();
        isLoadingDeliveryOptions = false;
      });
    }
  }

  Future<void> _loadDeliveryOptionsForAddress(CustomerAddress address) async {
    setState(() {
      isLoadingDeliveryOptions = true;
    });

    // Store current selection to try to maintain it
    final previousSelection = selectedDeliveryOption;
    final previousVehicleType = selectedVehicleType;

    try {
      final options = await DeliveryService.getDeliveryOptionsForAddress(
          address.district, address.province);

      setState(() {
        availableDeliveryOptions = options;
        isLoadingDeliveryOptions = false;

        // Try to maintain the previous selection if it's still available
        if (previousSelection != null && previousVehicleType != null) {
          // Find matching option by vehicle type and company
          DeliveryOption? matchingOption;

          try {
            // Try to find exact match by vehicle type and company
            matchingOption = options.firstWhere(
              (option) =>
                  option.vehicleType == previousVehicleType &&
                  option.company == previousSelection.company,
            );
          } catch (e) {
            try {
              // Try to find match by vehicle type only
              matchingOption = options.firstWhere(
                (option) => option.vehicleType == previousVehicleType,
              );
            } catch (e) {
              // No match found
              matchingOption = null;
            }
          }

          if (matchingOption != null) {
            selectedDeliveryOption = matchingOption;
          } else {
            selectedDeliveryOption = null;
          }
        }
      });
    } catch (e) {
      print('Error loading delivery options: $e');
      // Fallback to sample options
      setState(() {
        availableDeliveryOptions = DeliveryOption.getSampleOptions();
        isLoadingDeliveryOptions = false;

        // Try to maintain selection with fallback options
        if (previousSelection != null && previousVehicleType != null) {
          DeliveryOption? matchingOption;

          try {
            // Try to find exact match by vehicle type and company
            matchingOption = availableDeliveryOptions.firstWhere(
              (option) =>
                  option.vehicleType == previousVehicleType &&
                  option.company == previousSelection.company,
            );
          } catch (e) {
            try {
              // Try to find match by vehicle type only
              matchingOption = availableDeliveryOptions.firstWhere(
                (option) => option.vehicleType == previousVehicleType,
              );
            } catch (e) {
              // No match found
              matchingOption = null;
            }
          }

          selectedDeliveryOption = matchingOption;
        }
      });
    }
  }

  String? _extractDistrictFromAddress(String address) {
    // Simple district extraction - you might want to make this more sophisticated
    // This is a placeholder - adjust based on your address format
    final parts = address.split(' ');
    for (final part in parts) {
      if (part.startsWith('แขวง')) {
        return part;
      }
    }
    return null;
  }

  String? _getUserDistrict() {
    // First try to get district from the district field
    if (userProfile.district.isNotEmpty) {
      // For Bangkok districts, make sure name starts with 'แขวง'
      if (userProfile.province == 'กรุงเทพมหานคร' ||
          userProfile.province.isEmpty) {
        if (userProfile.district.startsWith('แขวง')) {
          return userProfile.district;
        } else {
          return 'แขวง${userProfile.district}';
        }
      } else {
        // For other provinces, use district name as is (อำเภอ)
        if (userProfile.district.startsWith('อำเภอ')) {
          return userProfile.district;
        } else {
          return 'อำเภอ${userProfile.district}';
        }
      }
    }

    // Fallback to extracting from address
    if (userProfile.address.isNotEmpty) {
      return _extractDistrictFromAddress(userProfile.address);
    }

    return null;
  }

  String? _getUserProvince() {
    if (userProfile.province.isNotEmpty) {
      return userProfile.province;
    }
    return null;
  }

  bool _canProceedWithCheckout() {
    // Check if cart is not empty
    if (checkoutItems.isEmpty) return false;

    // For delivery orders, check if address is selected
    if (selectedDeliveryOption != null && selectedAddress == null) {
      return false;
    }

    // Check if loading states prevent checkout
    if (isLoadingAddresses || isLoadingDeliveryOptions) return false;

    return true;
  }

  Future<void> _handleEditAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    );

    // ถ้าผู้ใช้บันทึกข้อมูลแล้ว ให้โหลดข้อมูลใหม่และ delivery options ใหม่
    if (result == true) {
      print('Profile updated, reloading data...');
      await ProfileService.instance.forceReloadProfile();
      await _loadUserProfile();
      // Delivery options will be reloaded automatically in _loadUserProfile
    }
  }

  // Handle free item redemption - separate flow from normal checkout
  Future<void> _handleFreeItemRedemption() async {
    debugPrint('=== _handleFreeItemRedemption called ===');

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('กำลังดำเนินการแลกของแถม...'),
            ],
          ),
        ),
      );

      // Build request body from freeItemRedemption data
      final requestBody = Map<String, dynamic>.from(widget.freeItemRedemption!);

      // Add shipping address if selected
      if (selectedAddress != null) {
        requestBody['shipping_address_id'] = selectedAddress!.id;
      }

      // Add delivery fee if applicable
      if (selectedDeliveryOption != null) {
        requestBody['delivery_fee'] = deliveryFee;
        requestBody['delivery_method'] = selectedDeliveryOption!.companyCode;
      }

      debugPrint('Free item redemption request: $requestBody');

      final response = await ApiService.post('/redeem-free-items', requestBody);
      final data = json.decode(response.body);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 201 && data['success'] == true) {
        final orderId = data['data']['order_id']?.toString();
        final orderNumber = data['data']['order_number'];
        final requiresPayment = data['data']['requires_payment'] ?? false;

        // ถ้ามีค่าขนส่ง ให้ upload slip
        if (requiresPayment && orderId != null) {
          // Upload slip if user selected promptpay
          bool slipUploadSuccess = true;
          try {
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('กำลังอัพโหลดสลิปการชำระเงิน...'),
                    ],
                  ),
                ),
              );
            }

            // Get uploaded slips from PromptPay card
            slipUploadSuccess = await PaymentMethodCard.uploadSlipsFromCard(
                _promptPayKey, orderId);
            debugPrint('Slip upload result: $slipUploadSuccess');
          } catch (e) {
            debugPrint('Error uploading slips: $e');
            slipUploadSuccess = false;
          }

          // Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          if (mounted) {
            if (!slipUploadSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('แลกของแถมสำเร็จ แต่ไม่สามารถอัพโหลดสลิปได้ กรุณาอัพโหลดใหม่ในหน้าคำสั่งซื้อ'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('แลกของแถมและอัพโหลดสลิปสำเร็จ! รอการตรวจสอบ'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            // Navigate to payment pending screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPendingScreen(
                  orderNumber: orderNumber ?? '',
                  orderId: orderId,
                  totalAmount: deliveryFee,
                  paymentMethod: 'promptpay',
                  orderStatus: 'pending_payment',
                ),
              ),
            );
          }
        } else {
          // ไม่มีค่าขนส่ง - สำเร็จทันที
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('แลกของแถมสำเร็จ! รอการจัดส่ง'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'เกิดข้อผิดพลาดในการแลกของแถม'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCheckout() async {
    debugPrint('=== _handleCheckout called ===');

    // Validate address selection for delivery orders
    if (selectedDeliveryOption != null && selectedAddress == null) {
      debugPrint('Error: No address selected for delivery');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกที่อยู่จัดส่ง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle free item redemption separately
    if (widget.isFreeItemOnly && widget.freeItemRedemption != null) {
      await _handleFreeItemRedemption();
      return;
    }

    try {
      debugPrint('Starting checkout process...');
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('กำลังประมวลผลคำสั่งซื้อ...'),
            ],
          ),
        ),
      );

      // Prepare order data
      final orderData = {
        'items': checkoutItems
            .map((item) => {
                  'product_id': item.id,
                  'quantity': item.quantity,
                })
            .toList(),
        'delivery_method':
            selectedDeliveryOption != null ? 'delivery' : 'pickup',
        'payment_method':
            selectedPaymentMethod == 'credit_card' ? 'credit_card' : 'qr_code',
        'delivery_fee': deliveryFee,
        'discount': discount, // ส่วนลดปกติ (ไม่รวมของแถม เพราะของแถมไม่หักราคา)
        'notes':
            'Order from Flutter app - ${selectedDeliveryOption?.fullDisplayName ?? 'Pickup'} - Total: ฿${total.toStringAsFixed(0)}${freeItemsCount > 0 ? ' + ของแถม $freeItemsCount ชิ้น' : ''}',
        if (selectedAddress != null && selectedDeliveryOption != null)
          'shipping_address_id': selectedAddress!.id,
        // ส่ง reward ที่ใช้ไปกับ order (ถ้ามี) - ของแถมจะได้รับหลังชำระเงิน
        if (appliedReward != null) ...{
          'reward_level': appliedReward!['level'],
          'reward_discount': 0, // ของแถมไม่หักราคา (เป็นของฟรีที่ได้รับเพิ่ม)
          'reward_free_items': appliedReward!['earned_free_items'],
          'reward_required_quantity': appliedReward!['required_quantity'] ?? appliedReward!['total_quantity'],
        },
        // ส่งของแถมที่เลือกจากสิทธิ์ที่มีอยู่แล้วไปกับ order
        if (selectedFreeItems.isNotEmpty)
          'selected_free_items': selectedFreeItems
              .map((item) => {
                    'product_id': item['product_id'],
                    'quantity': item['quantity'],
                  })
              .toList(),
      };

      debugPrint('Order data prepared: $orderData');

      // Create order via API
      debugPrint('Sending POST request to /orders...');
      final response = await ApiService.post('/orders', orderData);
      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 201) {
        // Success - now handle payment based on method
        final responseData = json.decode(response.body);
        final orderId = responseData['data']['id'].toString();
        final orderNumber = responseData['data']['order_number'];

        // เรียก callback เพื่อ clear cart เมื่อ order สร้างสำเร็จ
        widget.onOrderCreated?.call();

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        // Handle payment based on selected method
        if (selectedPaymentMethod == 'credit_card') {
          // Credit Card - Open Payment Gateway WebView
          try {
            // Show loading for payment creation
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('กำลังเตรียมหน้าชำระเงิน...'),
                    ],
                  ),
                ),
              );
            }

            // Create payment transaction
            final paymentResponse = await ApiService.post('/payment/create', {
              'order_id': int.parse(orderId),
            });

            debugPrint('Payment creation response: ${paymentResponse.body}');

            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog
            }

            if (paymentResponse.statusCode == 200) {
              final paymentData = json.decode(paymentResponse.body);

              if (paymentData['success'] == true) {
                final paymentUrl = paymentData['data']['payment_url'];
                final paymentId = paymentData['data']['payment_id'];

                // Open WebView for payment
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentWebViewScreen(
                        paymentUrl: paymentUrl,
                        paymentId: paymentId,
                        orderId: int.parse(orderId),
                        orderNumber: orderNumber,
                        totalAmount: total,
                      ),
                    ),
                  );
                }
              } else {
                // Error creating payment
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'เกิดข้อผิดพลาดในการสร้าง Payment: ${paymentData['message']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              // HTTP error
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ไม่สามารถเชื่อมต่อ Payment Gateway ได้'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error creating payment: $e');
            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog if open
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เกิดข้อผิดพลาด: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else if (selectedPaymentMethod == 'promptpay') {
          // PromptPay - Upload slip
          bool slipUploadSuccess = true;
          try {
            // Update loading dialog message
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('กำลังอัพโหลดสลิปการชำระเงิน...'),
                    ],
                  ),
                ),
              );
            }

            // Get uploaded slips from PromptPay card
            slipUploadSuccess = await PaymentMethodCard.uploadSlipsFromCard(
                _promptPayKey, orderId);
            print('Slip upload result: $slipUploadSuccess');
          } catch (e) {
            print('Error uploading slips: $e');
            slipUploadSuccess = false;
          }

          // Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          if (context.mounted) {
            // Show appropriate message
            if (!slipUploadSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'สร้างคำสั่งซื้อสำเร็จ แต่ไม่สามารถอัพโหลดสลิปได้ กรุณาอัพโหลดใหม่'),
                  backgroundColor: Colors.orange,
                ),
              );
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPendingScreen(
                  orderNumber: orderNumber,
                  orderId: orderId,
                  totalAmount: total,
                  paymentMethod: selectedPaymentMethod,
                  orderStatus:
                      responseData['data']['status'] ?? 'pending_payment',
                ),
              ),
            );
          }
        }
      } else {
        // Error - show error message
        final errorData = json.decode(response.body);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${errorData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('=== ERROR in _handleCheckout ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('===========================');

      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Page title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'ตะกร้าสินค้า',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Membership Progress Card with preview - ซ่อนเมื่อเป็น free item redemption
                  if (membershipLevels.isNotEmpty && !widget.isFreeItemOnly)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: MembershipProgressCard(
                        levels: membershipLevels,
                        membershipType: membershipData?['membership_type'] ?? 'exMember',
                        previewQuantity: previewQuantity,
                        currentQuantity: _getEffectiveQuantityFromMembership(),
                        requiredQuantities: _getRequiredQuantitiesFromMembership(),
                      ),
                    ),

                  // Reward Selection Section - ให้ผู้ใช้เลือกแลกรางวัล (ซ่อนเมื่อเป็น free item redemption)
                  if (_getClaimableLevels().isNotEmpty && !widget.isFreeItemOnly) ...[
                    _buildRewardSelectionSection(),
                    const SizedBox(height: 20),
                  ],

                  // Applied Reward Info (ถ้ามี)
                  if (appliedReward != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mainPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.mainPink.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: AppColors.mainPink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ใช้สิทธิ์ของแถม Level ${appliedReward!['level']}',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: AppColors.mainPink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ได้รับของแถม ${appliedReward!['earned_free_items']} ชิ้น หลังชำระเงิน',
                                  style: AppTextStyles.caption10.copyWith(
                                    color: AppColors.mainPink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Free Items Display Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade50,
                            Colors.green.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.redeem,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'สินค้าฟรี',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'คุณได้รับสินค้าฟรี ${appliedReward!['earned_free_items']} ชิ้น',
                                  style: AppTextStyles.body12Regular.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${appliedReward!['earned_free_items']} ชิ้น',
                              style: AppTextStyles.body14Medium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Checkout items
                  ...checkoutItems
                      .map((item) => CheckoutItemCard(
                            item: item,
                            onQuantityChanged: (newQuantity) {
                              setState(() {
                                item.quantity = newQuantity;
                              });
                            },
                            onRemove: () {
                              setState(() {
                                checkoutItems.remove(item);
                              });
                            },
                          ))
                      .toList(),

                  const SizedBox(height: 20),

                  // ของแถมที่เลือกเพิ่มในออเดอร์
                  if (selectedFreeItems.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'ของแถมในออเดอร์นี้',
                        style: AppTextStyles.heading16Medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedFreeItems.map((item) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: item['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(item['image'], fit: BoxFit.cover),
                                  )
                                : Icon(Icons.card_giftcard, color: Colors.green.shade400),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'ของแถม',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'จำนวน: ${item['quantity']} ชิ้น (ฟรี)',
                                  style: AppTextStyles.caption10.copyWith(
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedFreeItems.remove(item);
                              });
                            },
                            icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // สิทธิ์ของแถมที่มีอยู่แล้ว (ซ่อนเมื่อเป็น free item redemption)
                  if (totalExistingRewards > 0 && !widget.isFreeItemOnly) ...[
                    _buildExistingRewardsSection(),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 10),

                  // Address section
                  isLoadingAddresses
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: AddressSelectionCard(
                            selectedAddress: selectedAddress,
                            addresses: addresses,
                            onAddressSelected: (address) {
                              setState(() {
                                selectedAddress = address;
                              });
                              if (address != null) {
                                _loadDeliveryOptionsForAddress(address);
                              }
                            },
                          ),
                        ),

                  const SizedBox(height: 30),

                  // Delivery options section - Step 1: Vehicle Type
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: VehicleTypeSelector(
                      selectedVehicleType: selectedVehicleType,
                      onVehicleTypeChanged: (vehicleType) {
                        setState(() {
                          selectedVehicleType = vehicleType;
                          // Reset delivery option when vehicle type changes
                          selectedDeliveryOption = null;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Step 2: Company Selection (only show if vehicle type selected)
                  if (selectedVehicleType != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: isLoadingDeliveryOptions
                          ? const Center(child: CircularProgressIndicator())
                          : DeliveryCompanySelector(
                              vehicleType: selectedVehicleType!,
                              selectedOption: selectedDeliveryOption,
                              availableOptions: availableDeliveryOptions,
                              onOptionChanged: (option) {
                                setState(() {
                                  selectedDeliveryOption = option;
                                });
                              },
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  const SizedBox(height: 30),

                  // Payment method section - Show if not free item only OR if free item has delivery fee
                  if (!widget.isFreeItemOnly || (widget.isFreeItemOnly && deliveryFee > 0)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.isFreeItemOnly ? 'ชำระค่าจัดส่ง' : 'วิธีการชำระเงิน',
                        style: AppTextStyles.heading16Medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purpleText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment methods - For free item with delivery, only show PromptPay
                    if (!widget.isFreeItemOnly) ...[
                      PaymentMethodCard(
                        key: _creditCardKey,
                        title: 'บัตรเครดิต/เดบิต',
                        subtitle: 'Visa, Mastercard, JCB',
                        icon: Icons.credit_card,
                        value: 'credit_card',
                        groupValue: selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod = value!;
                          });
                        },
                      ),
                    ],

                    PaymentMethodCard(
                      key: _promptPayKey,
                      title: 'พร้อมเพย์',
                      subtitle: widget.isFreeItemOnly ? 'ชำระค่าส่งผ่าน QR Code และอัปโหลดสลิป' : 'ชำระผ่าน QR Code',
                      icon: Icons.qr_code,
                      value: 'promptpay',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 30),
                  ],

                  // Order summary
                  _buildOrderSummary(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom checkout button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  onPressed: _canProceedWithCheckout() ? _handleCheckout : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceedWithCheckout()
                        ? AppColors.mainPurple
                        : AppColors.lightGray,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isFreeItemOnly ? 'ยืนยันการแลก ' : 'ชำระเงิน ',
                        style: AppTextStyles.button16.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.isFreeItemOnly
                            ? '(ค่าส่ง ฿${deliveryFee.toStringAsFixed(0)})'
                            : '฿${total.toStringAsFixed(0)}',
                        style: AppTextStyles.button16.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปคำสั่งซื้อ',
            style: AppTextStyles.heading16Medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleText,
            ),
          ),

          const SizedBox(height: 16),

          // Subtotal
          _buildSummaryRow(
            'ราคาสินค้า',
            '฿${subtotal.toStringAsFixed(0)}',
            false,
          ),

          const SizedBox(height: 12),

          // Delivery fee
          _buildSummaryRow(
            'ค่าจัดส่ง',
            '฿${deliveryFee.toStringAsFixed(0)}',
            false,
          ),

          const SizedBox(height: 12),

          // Only show discount row if there's an actual discount
          if (discount > 0) ...[
            _buildSummaryRow(
              'ส่วนลด',
              '-฿${discount.toStringAsFixed(0)}',
              false,
              valueColor: AppColors.mainPink,
            ),
            const SizedBox(height: 12),
          ],

          // ของแถมที่จะได้รับ (แสดงเป็น info ไม่หักราคา)
          if (freeItemsCount > 0) ...[
            _buildSummaryRow(
              'ของแถม (Level ${appliedReward?['level']})',
              '+$freeItemsCount ชิ้น',
              false,
              valueColor: Colors.green,
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: AppColors.lightGray.withOpacity(0.3),
          ),

          const SizedBox(height: 16),

          // Total
          _buildSummaryRow(
            'ยอดรวมทั้งหมด',
            '฿${total.toStringAsFixed(0)}',
            true,
          ),

          const SizedBox(height: 16),

          // Reward info - removed hardcoded text
        ],
      ),
    );
  }

  // UI แสดงสิทธิ์ของแถมที่มีอยู่และเลือกเพิ่มในออเดอร์
  Widget _buildExistingRewardsSection() {
    if (isLoadingExistingRewards) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'สิทธิ์ของแถมที่มีอยู่',
                style: AppTextStyles.heading16Medium.copyWith(
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'คุณมีสิทธิ์ของแถมคงเหลือ $totalExistingRewards ชิ้น',
            style: AppTextStyles.body14Medium.copyWith(
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'สามารถเลือกรับของแถมพร้อมออเดอร์นี้ได้เลย (ประหยัดค่าจัดส่ง)',
            style: AppTextStyles.body12Regular.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          // แสดงของแถมที่เลือกแล้ว
          if (selectedFreeItems.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'ของแถมที่เลือก (${selectedFreeItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] ?? 1) as int))} ชิ้น):',
              style: AppTextStyles.body14Medium.copyWith(
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedFreeItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.card_giftcard,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.card_giftcard,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['name']} x${item['quantity']}',
                      style: AppTextStyles.body14Medium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        selectedFreeItems.removeWhere((i) => i['product_id'] == item['product_id']);
                      });
                    },
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
          // ปุ่มเลือกของแถม
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFreeItemSelectionBottomSheet(),
              icon: Icon(
                selectedFreeItems.isEmpty ? Icons.add : Icons.edit,
                size: 18,
              ),
              label: Text(
                selectedFreeItems.isEmpty ? 'เลือกของแถม' : 'แก้ไขของแถม',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
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

  // Bottom sheet สำหรับเลือกของแถม
  void _showFreeItemSelectionBottomSheet() async {
    // โหลดรายการสินค้าที่แลกได้
    List<Map<String, dynamic>> availableProducts = [];
    bool isLoading = true;

    // State สำหรับเลือกสินค้า - ต้องอยู่นอก builder เพื่อให้ persist
    Map<int, int> tempSelectedProducts = {};
    for (var item in selectedFreeItems) {
      tempSelectedProducts[item['product_id'] as int] = item['quantity'] as int;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // โหลดสินค้า
          if (isLoading) {
            ApiService.get('/redeemable-products').then((response) {
              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                if (data['success'] == true) {
                  setModalState(() {
                    availableProducts = List<Map<String, dynamic>>.from(data['data'] ?? []);
                    isLoading = false;
                  });
                }
              }
            }).catchError((e) {
              setModalState(() {
                isLoading = false;
              });
            });
          }

          int tempTotalSelected = tempSelectedProducts.values.fold(0, (sum, qty) => sum + qty);
          int remainingToSelect = totalExistingRewards - tempTotalSelected;

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'เลือกของแถม',
                            style: AppTextStyles.heading16Medium.copyWith(
                              color: Colors.green.shade800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'เหลือ $remainingToSelect / $totalExistingRewards',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Product List
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : availableProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'ไม่มีสินค้าให้เลือก',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: availableProducts.length,
                              itemBuilder: (context, index) {
                                final product = availableProducts[index];
                                final productId = product['id'] as int;
                                final quantity = tempSelectedProducts[productId] ?? 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: quantity > 0 ? Colors.green.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: quantity > 0 ? Colors.green.shade300 : Colors.grey.shade200,
                                      width: quantity > 0 ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Product image
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: product['image'] != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  product['image'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Icon(
                                                    Icons.card_giftcard,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              )
                                            : Icon(Icons.card_giftcard, color: Colors.grey.shade400),
                                      ),
                                      const SizedBox(width: 12),
                                      // Product info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (product['description'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                product['description'],
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Quantity selector
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: quantity > 0
                                                  ? () {
                                                      setModalState(() {
                                                        if (quantity <= 1) {
                                                          tempSelectedProducts.remove(productId);
                                                        } else {
                                                          tempSelectedProducts[productId] = quantity - 1;
                                                        }
                                                      });
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.remove),
                                              iconSize: 18,
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              color: quantity > 0 ? Colors.green : Colors.grey.shade400,
                                            ),
                                            // Editable quantity field
                                            GestureDetector(
                                              onTap: () {
                                                final controller = TextEditingController(text: quantity.toString());
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogContext) => AlertDialog(
                                                    title: Text('ระบุจำนวน ${product['name']}'),
                                                    content: TextField(
                                                      controller: controller,
                                                      keyboardType: TextInputType.number,
                                                      autofocus: true,
                                                      decoration: InputDecoration(
                                                        hintText: 'จำนวน (สูงสุด ${remainingToSelect + quantity})',
                                                        border: const OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(dialogContext),
                                                        child: const Text('ยกเลิก'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          final newQty = int.tryParse(controller.text) ?? 0;
                                                          final maxAllowed = remainingToSelect + quantity;
                                                          final validQty = newQty.clamp(0, maxAllowed);
                                                          setModalState(() {
                                                            if (validQty <= 0) {
                                                              tempSelectedProducts.remove(productId);
                                                            } else {
                                                              tempSelectedProducts[productId] = validQty;
                                                            }
                                                          });
                                                          Navigator.pop(dialogContext);
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                        ),
                                                        child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                constraints: const BoxConstraints(minWidth: 36),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.green.shade300),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$quantity',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: quantity > 0 ? Colors.green : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: remainingToSelect > 0
                                                  ? () {
                                                      setModalState(() {
                                                        tempSelectedProducts[productId] = quantity + 1;
                                                      });
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.add),
                                              iconSize: 18,
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              color: remainingToSelect > 0 ? Colors.green : Colors.grey.shade400,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Bottom button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // บันทึกของแถมที่เลือก
                          final newSelectedItems = <Map<String, dynamic>>[];
                          for (var entry in tempSelectedProducts.entries) {
                            if (entry.value > 0) {
                              final product = availableProducts.firstWhere(
                                (p) => p['id'] == entry.key,
                                orElse: () => {},
                              );
                              if (product.isNotEmpty) {
                                newSelectedItems.add({
                                  'product_id': entry.key,
                                  'name': product['name'],
                                  'image': product['image'],
                                  'quantity': entry.value,
                                });
                              }
                            }
                          }
                          setState(() {
                            selectedFreeItems = newSelectedItems;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tempTotalSelected > 0
                              ? 'ยืนยันของแถม ($tempTotalSelected ชิ้น)'
                              : 'ยืนยัน',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ดึง levels ที่สามารถแลกรางวัลได้ (รวมสินค้าในตะกร้าปัจจุบัน)
  List<Map<String, dynamic>> _getClaimableLevels() {
    if (membershipData == null) return [];

    // คำนวณจำนวนรวม = effective_quantity + สินค้าในตะกร้า
    final effectiveQtyRaw = membershipData!['effective_quantity'];
    final effectiveQty = effectiveQtyRaw is num
        ? effectiveQtyRaw.toDouble()
        : double.tryParse(effectiveQtyRaw?.toString() ?? '0') ?? 0;
    final cartQty = widget.cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalQty = effectiveQty + cartQty;

    // ดึง level_progress และหา levels ที่ totalQty >= required_quantity
    final levelProgress = membershipData!['level_progress'] as List?;
    if (levelProgress == null || levelProgress.isEmpty) return [];

    List<Map<String, dynamic>> claimableLevels = [];

    for (var level in levelProgress) {
      final requiredQty = double.tryParse(level['required_quantity']?.toString() ?? '')?.toInt() ?? 0;
      final freeQty = double.tryParse(level['free_quantity']?.toString() ?? '')?.toInt() ?? 0;
      final levelNum = int.tryParse(level['level']?.toString() ?? '') ?? 0;

      // ถ้าจำนวนรวมถึง required_quantity ของ level นี้
      if (totalQty >= requiredQty && requiredQty > 0) {
        claimableLevels.add({
          'level': levelNum,
          'required_quantity': requiredQty,
          'earned_free_items': freeQty,
          'unit_price': double.tryParse(level['unit_price']?.toString() ?? '') ?? 2500,
          'total_quantity': requiredQty,
          'display_name': level['display_name'] ?? 'Level $levelNum',
          'is_projected': true, // บอกว่าเป็นการ preview รวมกับ cart
        });
      }
    }

    return claimableLevels;
  }

  // UI สำหรับเลือกแลกรางวัล
  Widget _buildRewardSelectionSection() {
    // ถ้าเลือกรางวัลจาก Home มาแล้ว (widget.appliedReward != null) → ไม่แสดงกล่องนี้
    // เพราะเลือกไปแล้ว ไม่ต้องเลือกซ้ำ
    if (widget.appliedReward != null) {
      return const SizedBox.shrink();
    }

    final claimableLevels = _getClaimableLevels();

    // ถ้าไม่มี rewards ให้เลือก → ไม่แสดง
    if (claimableLevels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'แลกรางวัลสะสม',
                style: AppTextStyles.heading16Medium.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'คุณมีสิทธิ์แลกรางวัลได้ ${claimableLevels.length} รายการ',
            style: AppTextStyles.body12Regular.copyWith(
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Option: ไม่แลกรางวัล
          _buildRewardOption(
            null,
            'ไม่แลกรางวัลตอนนี้',
            'สะสมต่อเพื่อรางวัลที่ดีกว่า',
            selectedReward == null && widget.appliedReward == null,
          ),

          const SizedBox(height: 8),

          // Options: แลกรางวัลแต่ละ level
          ...claimableLevels.map((level) {
            final freeItems = int.tryParse(level['earned_free_items']?.toString() ?? '0') ?? 0;
            final unitPrice = double.tryParse(level['unit_price']?.toString() ?? '0')?.toInt() ?? 0;
            final discount = freeItems * unitPrice;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRewardOption(
                level,
                'แลก Level ${level['level']} - ฟรี $freeItems ชิ้น',
                'ส่วนลด ฿${discount.toStringAsFixed(0)}',
                appliedReward != null && appliedReward!['level'] == level['level'],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRewardOption(
    Map<String, dynamic>? reward,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedReward = reward;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainPink.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.mainPink : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.mainPink : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body14Medium.copyWith(
                      color: isSelected ? AppColors.mainPink : AppColors.purpleText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption10.copyWith(
                      color: isSelected ? AppColors.mainPink : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isTotal, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.body14Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w600,
                )
              : AppTextStyles.body14Medium.copyWith(
                  color: AppColors.lightGray,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.heading16Medium.copyWith(
                  color: AppColors.purpleText,
                  fontWeight: FontWeight.w700,
                )
              : AppTextStyles.body14Medium.copyWith(
                  color: valueColor ?? AppColors.purpleText,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
