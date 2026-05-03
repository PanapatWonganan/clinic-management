import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/api_service.dart';
import '../models/product_category.dart';
import '../models/checkout_item.dart';
import '../models/membership_level.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/membership_progress_card.dart';
import '../widgets/product_category_item.dart';
import '../widgets/reward_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/membership_benefits_dialog.dart';
import 'profile_screen.dart';
import 'checkout_screen.dart';
import 'rewards_screen.dart';
import 'order_history_screen.dart';
import 'my_free_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  UserProfile userProfile = UserProfile();
  bool isLoadingProfile = true;
  bool isLoadingProducts = true;
  bool isLoadingMembership = true;

  List<ProductCategory> productCategories = [];
  List<MembershipLevel> membershipLevels = [];
  Map<String, dynamic>? membershipProgressData;

  // ── Reward selection for the current (unsaved) order ───────────────────────
  // _pendingReward is a snapshot from level_progress for the highest level that
  // (currentQty + previewQty) has unlocked; null when no reward is available.
  // _pendingFreeItems holds the user's in-memory picks from the home popup —
  // nothing is persisted until checkout POSTs the order.
  Map<String, dynamic>? _pendingReward;
  List<Map<String, dynamic>> _pendingFreeItems = [];
  int? _lastPendingRewardLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _loadMembershipProgress().then((_) {
      // Load products after membership data is loaded
      _loadProducts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload membership data เมื่อ app กลับมาจาก background
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - reloading membership data');
      _loadMembershipProgress();
    }
  }

  String _getMembershipLogoPath(String? membershipType) {
    switch (membershipType) {
      case 'exMember':
        return 'assets/images/exmember-pink-1.png';
      case 'exVip':
        return 'assets/images/exvip-pink-1.png';
      case 'exSuperVip':
        return 'assets/images/exsupervip-gold-1.png';
      case 'exDoctor':
        return 'assets/images/exdoctor-green-1.png';
      default:
        return 'assets/images/exmember-pink-1.png'; // fallback
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await ProfileService.instance.loadProfile();
    setState(() {
      userProfile = profile;
      isLoadingProfile = false;
    });
  }

  Future<void> _loadProducts() async {
    try {
      // Get membership type from membership progress data if available
      String? membershipType = membershipProgressData?['membership_type'];
      final products = await ProductService.instance.getMainProducts(membershipType: membershipType);
      setState(() {
        productCategories = products;
        isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadMembershipProgress() async {
    try {
      final progressData = await ProfileService.instance.getMembershipProgress();
      setState(() {
        membershipProgressData = progressData;
        if (progressData != null && progressData['level_progress'] != null) {
          // สร้าง MembershipLevel objects จากข้อมูล API
          membershipLevels = (progressData['level_progress'] as List).map((levelData) {
            return MembershipLevel(
              id: levelData['level'],
              name: 'Level ${levelData['level']}',
              boxes: '${levelData['required_quantity']} กล่อง',
              free: 'ฟรี ${levelData['free_quantity']}',
              progress: levelData['progress_percentage'].toDouble(),
            );
          }).toList();
        } else {
          // ถ้าไม่มีข้อมูลจาก API ให้ใช้ข้อมูล default
          membershipLevels = [
            MembershipLevel(
              id: 1,
              name: 'Level 1',
              boxes: '5 กล่อง',
              free: 'ฟรี 3',
              progress: 0,
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
          ];
        }
        isLoadingMembership = false;
        _recomputePendingReward();
      });
    } catch (e) {
      debugPrint('Error loading membership progress: $e');
      setState(() {
        // ใช้ข้อมูล fallback ถ้าเกิดข้อผิดพลาด
        membershipLevels = [
          MembershipLevel(
            id: 1,
            name: 'Level 1',
            boxes: '5 กล่อง',
            free: 'ฟรี 3',
            progress: 0,
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
        ];
        isLoadingMembership = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyFreeItemsScreen()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 2:
        final cartItems = _getCartItems();
        if (cartItems.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutScreen(
                cartItems: cartItems,
                appliedReward: _pendingReward,
                membershipData: membershipProgressData,
                preselectedNewOrderFreeItems: _pendingFreeItems,
                onOrderCreated: _clearCart,
              ),
            ),
          ).then((_) async {
            // Reset selected index เมื่อกลับมาจากหน้า Checkout
            setState(() {
              _selectedIndex = 0;
            });
            // Reload membership progress หลังจากสั่งซื้อสินค้า
            await _loadMembershipProgress();
          });
        }
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
        ).then((_) {
          // Reset selected index เมื่อกลับมาจากหน้า Order History
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RewardsScreen()),
        ).then((_) {
          // Reset selected index เมื่อกลับมาจากหน้า Rewards
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );

    // ถ้ามีการแก้ไขข้อมูลในหน้าโปรไฟล์ ให้โหลดข้อมูลใหม่
    if (result == true) {
      await _loadUserProfile();
    }
  }

  void _showMembershipBenefits() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return MembershipBenefitsDialog(
          membershipType: membershipProgressData?['membership_type'] ?? 'exMember',
          levels: membershipLevels,
        );
      },
    );
  }

  void _increaseQuantity(int categoryId) {
    setState(() {
      final index = productCategories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        productCategories[index].quantity++;
      }
      _recomputePendingReward();
    });
  }

  void _decreaseQuantity(int categoryId) {
    setState(() {
      final index = productCategories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1 && productCategories[index].quantity > 0) {
        productCategories[index].quantity--;
      }
      _recomputePendingReward();
    });
  }

  void _setQuantity(int categoryId, int quantity) {
    setState(() {
      final index = productCategories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        productCategories[index].quantity = quantity < 0 ? 0 : quantity;
      }
      _recomputePendingReward();
    });
  }

  // Clear cart after successful order
  void _clearCart() {
    setState(() {
      for (var category in productCategories) {
        category.quantity = 0;
      }
      _pendingReward = null;
      _pendingFreeItems = [];
      _lastPendingRewardLevel = null;
    });
    // Reload membership data to reflect new order
    _loadMembershipProgress();
  }

  // Recompute which reward level is unlocked by (current + preview) quantity.
  // Why: backend's available_rewards is based on effective_quantity only —
  // it doesn't know about items still sitting in the cart. We mirror the
  // same threshold logic on the client so the popup can fire as soon as the
  // user crosses a level on the cart, before an order is placed.
  void _recomputePendingReward() {
    final levelProgress = membershipProgressData?['level_progress'] as List?;
    if (levelProgress == null || levelProgress.isEmpty) {
      _pendingReward = null;
      _pendingFreeItems = [];
      _lastPendingRewardLevel = null;
      return;
    }

    final currentQty = _getCurrentQuantityFromMembership();
    final previewQty = _getTotalItems().toDouble();
    final totalQty = currentQty + previewQty;

    // Pick the highest level whose required_quantity is met and which the
    // user has not already claimed.
    Map<String, dynamic>? best;
    int bestLevel = 0;
    for (final entry in levelProgress) {
      final m = entry as Map<String, dynamic>;
      final required = _parseNum(m['required_quantity']);
      final level = (m['level'] is num) ? (m['level'] as num).toInt() : 0;
      final alreadyCompleted = m['is_completed'] == true;
      if (alreadyCompleted) continue;
      if (totalQty >= required && level > bestLevel) {
        best = m;
        bestLevel = level;
      }
    }

    if (best == null) {
      _pendingReward = null;
      _pendingFreeItems = [];
      _lastPendingRewardLevel = null;
      return;
    }

    final newLevel = bestLevel;
    final oldLevel = _lastPendingRewardLevel;
    final newQuota = _parseNum(best['free_quantity']).toInt();

    if (oldLevel == null || newLevel > oldLevel) {
      // Level unlocked or raised — keep prior picks but truncate to new quota.
      _pendingFreeItems = _truncateFreeItems(_pendingFreeItems, newQuota);
    } else if (newLevel < oldLevel) {
      // Level dropped (user removed boxes) — clear selections; they'd likely
      // exceed the new (smaller) quota anyway.
      _pendingFreeItems = [];
    }

    _pendingReward = best;
    _lastPendingRewardLevel = newLevel;
  }

  double _parseNum(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _truncateFreeItems(
      List<Map<String, dynamic>> items, int quota) {
    int taken = 0;
    final out = <Map<String, dynamic>>[];
    for (final item in items) {
      final q = (item['quantity'] ?? 0) as int;
      if (taken + q <= quota) {
        out.add(Map<String, dynamic>.from(item));
        taken += q;
      } else {
        final room = quota - taken;
        if (room > 0) {
          out.add({...item, 'quantity': room});
          taken = quota;
        }
        break;
      }
    }
    return out;
  }

  int get _pendingFreeItemQuota =>
      _pendingReward == null ? 0 : _parseNum(_pendingReward!['free_quantity']).toInt();

  int get _pendingFreeItemPicked =>
      _pendingFreeItems.fold<int>(0, (s, it) => s + ((it['quantity'] ?? 0) as int));

  double _calculateTotalPrice() {
    return productCategories.fold(0.0, (total, category) {
      return total + (category.quantity * category.price);
    });
  }

  int _getTotalItems() {
    return productCategories.fold(0, (total, category) {
      return total + category.quantity;
    });
  }

  // ดึง effective_quantity จาก membership data (ยอดสะสมทั้งหมดหลังแลกรางวัลครั้งล่าสุด)
  double _getCurrentQuantityFromMembership() {
    if (membershipProgressData == null) return 0;

    // ใช้ effective_quantity จาก root level ของ API response
    // effective_quantity = ยอดรวมจาก orders หลังการแลกรางวัลครั้งล่าสุด
    final effectiveQty = membershipProgressData!['effective_quantity'];
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
    if (membershipProgressData == null) return [];
    final levelProgress = membershipProgressData!['level_progress'] as List?;
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

  List<CheckoutItem> _getCartItems() {
    return productCategories
        .where((category) => category.quantity > 0)
        .map((category) => CheckoutItem(
              id: category.id,
              name: category.name,
              quantity: category.quantity,
              price: category.price,
              imagePath: category.imagePath,
            ))
        .toList();
  }

  Map<String, dynamic>? _getAvailableReward() {
    debugPrint('_getAvailableReward called');
    debugPrint('membershipProgressData: ${membershipProgressData?.keys}');
    debugPrint('available_rewards raw: ${membershipProgressData?['available_rewards']}');
    debugPrint('available_rewards type: ${membershipProgressData?['available_rewards'].runtimeType}');

    if (membershipProgressData == null || membershipProgressData!['available_rewards'] == null) {
      debugPrint('No available_rewards in API response');
      return null;
    }

    final availableRewards = membershipProgressData!['available_rewards'] as List;
    debugPrint('Found ${availableRewards.length} available rewards');

    if (availableRewards.isEmpty) {
      return null;
    }

    // เลือก reward ที่สูงสุดที่สามารถแลกได้ (Level สูงสุด)
    Map<String, dynamic>? bestReward;
    int highestLevel = 0;

    for (var reward in availableRewards) {
      final rewardMap = reward as Map<String, dynamic>;
      final level = rewardMap['level'] as int;

      if (level > highestLevel) {
        highestLevel = level;
        bestReward = rewardMap;
      }
    }

    debugPrint('Best available reward (Level $highestLevel): $bestReward');
    return bestReward;
  }

  void _onClaimReward(Map<String, dynamic> reward) async {
    debugPrint('Claiming reward: $reward');

    try {
      // เรียก API เพื่อแลกรางวัล
      final result = await ProfileService.instance.claimReward(reward['level']);
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        // แสดง dialog สำเร็จ
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('แลกของแถมสำเร็จ'),
              content: Text('คุณได้แลกสิทธิ์ ${reward['required_quantity']} ชิ้น ฟรี ${reward['earned_free_items']} ชิ้น เรียบร้อยแล้ว'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Reload membership progress to update the reward status
                    _loadMembershipProgress();
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      } else {
        // แสดง dialog ข้อผิดพลาด
        final errorMessage = result?['message'] ?? 'เกิดข้อผิดพลาดในการแลกรางวัล';
        final errorCode = result?['error'] ?? '';

        String dialogTitle = 'ไม่สามารถแลกของแถมได้';
        String buttonText = 'ตกลง';

        // ปรับข้อความสำหรับกรณีที่แลกแล้ว
        if (errorCode == 'ALREADY_CLAIMED') {
          dialogTitle = 'แลกรางวัลแล้ว';
          buttonText = 'รับทราบ';
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // รีเฟรชข้อมูลเมื่อแลกรางวัลแล้ว
                    if (errorCode == 'ALREADY_CLAIMED') {
                      _loadMembershipProgress();
                    }
                  },
                  child: Text(buttonText),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error in _onClaimReward: $e');
      if (!mounted) return;
      // แสดง dialog ข้อผิดพลาดการเชื่อมต่อ
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
            content: const Text('กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    }
  }


  // นำ reward ไปใช้เป็นส่วนลดในตะกร้า (ไม่ต้อง approve จาก API)
  void _onApplyRewardToCart(Map<String, dynamic> reward) {
    debugPrint('Applying reward to cart: $reward');

    final cartItems = _getCartItems();

    if (cartItems.isEmpty) {
      // ถ้าไม่มีสินค้าในตะกร้า แสดงข้อความแจ้งเตือน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกสินค้าก่อนใช้สิทธิ์ส่วนลด'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate ไป checkout พร้อม reward
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartItems,
          appliedReward: reward,
          membershipData: membershipProgressData,
          onOrderCreated: _clearCart,
        ),
      ),
    ).then((_) async {
      // Reload membership progress หลังจากสั่งซื้อสินค้า
      await _loadMembershipProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onMenuTap: _navigateToProfile,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Welcome section
            _buildWelcomeSection(),
            const SizedBox(height: 40),

            // Membership progress
            isLoadingMembership
                ? Container(
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.2)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mainPurple,
                      ),
                    ),
                  )
                : MembershipProgressCard(
                    levels: membershipLevels,
                    membershipType: membershipProgressData?['membership_type'] ?? 'exMember',
                    previewQuantity: _getTotalItems().toDouble(),
                    currentQuantity: _getCurrentQuantityFromMembership(),
                    requiredQuantities: _getRequiredQuantitiesFromMembership(),
                  ),
            const SizedBox(height: 24),

            // Member benefits button
            _buildMemberBenefitsButton(),
            const SizedBox(height: 40),

            // Product categories
            _buildProductCategories(),
            const SizedBox(height: 40),

            // Reward card
            RewardCard(
              availableReward: _getAvailableReward(),
              onClaim: _onClaimReward,
              onApplyToCart: _onApplyRewardToCart,
              onRewardClaimed: _loadMembershipProgress, // reload data หลังแลกรางวัล
              onRedeemCheckboxChanged: _onRedeemCheckboxChanged,
              cartQuantity: _getTotalItems(),
              currentQuantity: _getCurrentQuantityFromMembership(),
              levelProgress: membershipProgressData?['level_progress'],
            ),
            const SizedBox(height: 40),

            // Payment button
            _buildPaymentButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLoadingProfile
                  ? 'ยินดีต้อนรับ...'
                  : 'ยินดีต้อนรับ , ${userProfile.name.isEmpty ? "คลีนิค" : userProfile.name}',
              style: AppTextStyles.heading16Medium,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _navigateToProfile,
              child: const Icon(
                Icons.edit,
                size: 12,
                color: AppColors.lightGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: 400,
          height: 120,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_getMembershipLogoPath(membershipProgressData?['membership_type'])),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ราคากล่องละ 2,500.-',
          style: AppTextStyles.body12Regular.copyWith(
            color: AppColors.lightGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberBenefitsButton() {
    return GestureDetector(
      onTap: _showMembershipBenefits,
      child: Container(
        width: 110,
        height: 35,
        decoration: BoxDecoration(
          color: AppColors.lightPurple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ดูสิทธิ์สมาชิก',
              style: AppTextStyles.body12Regular.copyWith(
                color: AppColors.purpleText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppColors.purpleText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isLoadingProducts
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(
                  color: AppColors.mainPurple,
                ),
              ),
            )
          : productCategories.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'ไม่สามารถโหลดสินค้าได้',
                      style: TextStyle(
                        color: AppColors.greyText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: productCategories
                      .map((category) => ProductCategoryItem(
                            category: category,
                            onIncrease: () => _increaseQuantity(category.id),
                            onDecrease: () => _decreaseQuantity(category.id),
                            onQuantityChanged: (qty) => _setQuantity(category.id, qty),
                          ))
                      .toList(),
                ),
    );
  }

  // Fires when the RewardCard checkbox is toggled.
  // Returns the checkbox state the card should settle on.
  Future<bool> _onRedeemCheckboxChanged(bool checked) async {
    if (!checked) {
      // Unchecking always clears in-memory selections.
      setState(() {
        _pendingFreeItems = [];
      });
      return false;
    }

    // RewardCard computes its own "available reward" from level_progress,
    // which can include levels the cart alone hasn't reached yet (it's
    // based on effective_quantity from the server). The picker, though,
    // needs a quota — if the cart hasn't crossed any level, there's
    // nothing to pick, so warn and keep the box unchecked.
    if (_pendingReward == null || _pendingFreeItemQuota <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกสินค้าในตะกร้าให้ถึง level ก่อน'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    // Checking opens the picker. If the user confirms, we keep the box
    // checked; if they cancel or pick zero items, revert it so the UI
    // reflects that no selection was made.
    final confirmed = await _showFreeItemRedeemSheet();
    return confirmed;
  }

  // Bottom sheet: pick free items up to the unlocked quota.
  // Selections are kept in home-screen state only (no API writes) and then
  // passed to CheckoutScreen via preselectedNewOrderFreeItems on navigation.
  // Returns true if the user confirmed at least one pick.
  Future<bool> _showFreeItemRedeemSheet() async {
    final quota = _pendingFreeItemQuota;
    if (quota <= 0) return false;

    // snapshot current picks into the sheet
    final Map<int, Map<String, dynamic>> picked = {
      for (final item in _pendingFreeItems)
        item['product_id'] as int: Map<String, dynamic>.from(item),
    };

    List<Map<String, dynamic>> products = [];
    bool loading = true;
    String? loadError;
    bool confirmed = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            if (loading && loadError == null) {
              ApiService.get('/redeemable-products').then((response) {
                if (!sheetCtx.mounted) return;
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['success'] == true) {
                    setSheetState(() {
                      products =
                          List<Map<String, dynamic>>.from(data['data'] ?? []);
                      loading = false;
                    });
                    return;
                  }
                }
                setSheetState(() {
                  loadError = 'ไม่สามารถโหลดรายการของแถมได้';
                  loading = false;
                });
              }).catchError((e) {
                if (!sheetCtx.mounted) return;
                setSheetState(() {
                  loadError = 'เกิดข้อผิดพลาด: $e';
                  loading = false;
                });
              });
            }

            final pickedTotal = picked.values
                .fold<int>(0, (s, it) => s + ((it['quantity'] ?? 0) as int));
            final remaining = quota - pickedTotal;

            return Container(
              height: MediaQuery.of(sheetCtx).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.redeem, color: AppColors.mainPink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เลือกของแถม $quota ชิ้น',
                                style:
                                    AppTextStyles.heading16Medium.copyWith(
                                  color: AppColors.mainPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'เลือกแล้ว $pickedTotal/$quota ชิ้น',
                                style: AppTextStyles.caption10.copyWith(
                                  color: AppColors.purpleText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : loadError != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    loadError!,
                                    style: AppTextStyles.body14Medium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : products.isEmpty
                                ? const Center(
                                    child: Text('ไม่มีสินค้าให้เลือก'))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: products.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (ctx, i) {
                                      final p = products[i];
                                      final pid = p['id'] as int;
                                      final qty =
                                          (picked[pid]?['quantity'] ?? 0)
                                              as int;
                                      final stock = (p['stock'] ?? 0) as int;

                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: qty > 0
                                              ? AppColors.mainPink
                                                  .withValues(alpha: 0.05)
                                              : Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: qty > 0
                                                ? AppColors.mainPink
                                                : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: p['image_url'] != null
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(8),
                                                      child: Image.network(
                                                        p['image_url'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                Icon(
                                                          Icons.card_giftcard,
                                                          color: Colors
                                                              .grey.shade400,
                                                        ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.card_giftcard,
                                                      color: Colors
                                                          .grey.shade400,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['name'] ?? '-',
                                                    style: AppTextStyles
                                                        .body14Medium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'คงเหลือ $stock ชิ้น',
                                                    style: AppTextStyles
                                                        .caption10
                                                        .copyWith(
                                                      color: Colors
                                                          .grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed: qty <= 0
                                                      ? null
                                                      : () {
                                                          setSheetState(() {
                                                            final next =
                                                                qty - 1;
                                                            if (next <= 0) {
                                                              picked
                                                                  .remove(pid);
                                                            } else {
                                                              picked[pid] = {
                                                                'product_id':
                                                                    pid,
                                                                'name':
                                                                    p['name'],
                                                                'image': p[
                                                                    'image_url'],
                                                                'quantity':
                                                                    next,
                                                              };
                                                            }
                                                          });
                                                        },
                                                  icon: Icon(
                                                    Icons
                                                        .remove_circle_outline,
                                                    color: qty <= 0
                                                        ? Colors
                                                            .grey.shade300
                                                        : AppColors.mainPink,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 24,
                                                  child: Text(
                                                    '$qty',
                                                    style: AppTextStyles
                                                        .body14Medium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    textAlign:
                                                        TextAlign.center,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      remaining <= 0 ||
                                                              qty >= stock
                                                          ? null
                                                          : () {
                                                              setSheetState(
                                                                  () {
                                                                picked[pid] =
                                                                    {
                                                                  'product_id':
                                                                      pid,
                                                                  'name': p[
                                                                      'name'],
                                                                  'image': p[
                                                                      'image_url'],
                                                                  'quantity':
                                                                      qty + 1,
                                                                };
                                                              });
                                                            },
                                                  icon: Icon(
                                                    Icons.add_circle_outline,
                                                    color: (remaining <= 0 ||
                                                            qty >= stock)
                                                        ? Colors
                                                            .grey.shade300
                                                        : AppColors.mainPink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: pickedTotal == 0
                                  ? null
                                  : () {
                                      setState(() {
                                        _pendingFreeItems = picked.values
                                            .map((it) =>
                                                Map<String, dynamic>.from(it))
                                            .toList();
                                      });
                                      confirmed = true;
                                      Navigator.pop(sheetCtx);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainPink,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.mainPink.withValues(alpha: 0.4),
                                disabledForegroundColor:
                                    Colors.white.withValues(alpha: 0.8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                pickedTotal == 0
                                    ? 'เลือกของแถมก่อน'
                                    : 'ยืนยัน ($pickedTotal ชิ้น)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return confirmed;
  }

  Widget _buildPaymentButton() {
    final totalPrice = _calculateTotalPrice();
    final totalItems = _getTotalItems();

    return Container(
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: totalItems > 0
            ? () {
                final cartItems = _getCartItems();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      cartItems: cartItems,
                      appliedReward: _pendingReward,
                      membershipData: membershipProgressData,
                      preselectedNewOrderFreeItems: _pendingFreeItems,
                      onOrderCreated: _clearCart,
                    ),
                  ),
                ).then((_) async {
                  // Reload membership progress หลังจากสั่งซื้อสินค้า
                  await _loadMembershipProgress();
                });
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: totalItems > 0
              ? const Color(0xFF8386CB)
              : AppColors.lightGray.withValues(alpha:0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: totalItems > 0
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ชำระเงิน ($totalItems ชิ้น)',
                    style: AppTextStyles.button16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '฿${NumberFormat('#,##0').format(totalPrice)}',
                    style: AppTextStyles.button16.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : const Text(
                'เลือกสินค้าเพื่อชำระเงิน',
                style: AppTextStyles.button16,
              ),
      ),
    );
  }
}
