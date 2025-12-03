import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserProfile userProfile = UserProfile();
  bool isLoadingProfile = true;
  bool isLoadingProducts = true;
  bool isLoadingMembership = true;

  List<ProductCategory> productCategories = [];
  List<MembershipLevel> membershipLevels = [];
  Map<String, dynamic>? membershipProgressData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadMembershipProgress().then((_) {
      // Load products after membership data is loaded
      _loadProducts();
    });
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
        final cartItems = _getCartItems();
        if (cartItems.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutScreen(cartItems: cartItems),
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
      case 2:
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
      case 3:
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
    });
  }

  void _decreaseQuantity(int categoryId) {
    setState(() {
      final index = productCategories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1 && productCategories[index].quantity > 0) {
        productCategories[index].quantity--;
      }
    });
  }

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
                          ))
                      .toList(),
                ),
    );
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
                    builder: (context) => CheckoutScreen(cartItems: cartItems),
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
