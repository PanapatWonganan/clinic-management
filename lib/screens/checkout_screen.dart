import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/checkout_item.dart';
import '../models/user_profile.dart';
import '../models/delivery_option.dart';
import '../models/customer_address.dart';
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
import 'payment_pending_screen.dart';
import 'payment_webview_screen.dart';
import 'profile_edit_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CheckoutItem> cartItems;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  VehicleType? selectedVehicleType;
  DeliveryOption? selectedDeliveryOption;
  String selectedPaymentMethod = 'credit_card';
  UserProfile userProfile = UserProfile();
  bool isLoadingProfile = true;
  List<DeliveryOption> availableDeliveryOptions = [];
  bool isLoadingDeliveryOptions = false;

  // Address selection state
  CustomerAddress? selectedAddress;
  List<CustomerAddress> addresses = [];
  bool isLoadingAddresses = false;

  // Global keys to access payment method card state
  final GlobalKey<State<PaymentMethodCard>> _creditCardKey =
      GlobalKey<State<PaymentMethodCard>>();
  final GlobalKey<State<PaymentMethodCard>> _promptPayKey =
      GlobalKey<State<PaymentMethodCard>>();

  List<CheckoutItem> get checkoutItems => widget.cartItems;

  double get subtotal {
    return checkoutItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get discount {
    // No automatic discount - discounts should be applied at product level
    return 0.0;
  }

  double get deliveryFee {
    return selectedDeliveryOption?.price ?? 0;
  }

  double get total {
    final calculatedTotal = subtotal - discount + deliveryFee;
    // ป้องกันยอดรวมติดลบ - ค่าจัดส่งขั้นต่ำ
    return calculatedTotal < deliveryFee ? deliveryFee : calculatedTotal;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAddresses();
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
        'discount': discount,
        'notes':
            'Order from Flutter app - ${selectedDeliveryOption?.fullDisplayName ?? 'Pickup'} - Total: ฿${total.toStringAsFixed(0)}',
        if (selectedAddress != null && selectedDeliveryOption != null)
          'shipping_address_id': selectedAddress!.id,
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

                  const SizedBox(height: 30),

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

                  // Payment method section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'วิธีการชำระเงิน',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment methods - ตัดโอนผ่านธนาคารออก
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

                  PaymentMethodCard(
                    key: _promptPayKey,
                    title: 'พร้อมเพย์',
                    subtitle: 'ชำระผ่าน QR Code',
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
                        'ชำระเงิน ',
                        style: AppTextStyles.button16.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '฿${total.toStringAsFixed(0)}',
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
