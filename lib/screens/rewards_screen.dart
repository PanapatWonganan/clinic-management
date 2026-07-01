import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/reward_product.dart';
import '../services/profile_service.dart';
import '../services/reward_service.dart';
import '../widgets/custom_app_bar.dart';
import 'reward_detail_screen.dart';
import 'reward_history_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<RewardProduct> rewardItems = [];
  bool isLoadingRewards = true;
  bool hasRewardError = false;

  Map<String, dynamic>? membershipData;
  bool isLoadingMembership = true;

  int? pointsBalance;
  bool isLoadingPoints = true;

  @override
  void initState() {
    super.initState();
    _loadRewardProducts();
    _loadMembershipProgress();
    _loadPointsBalance();
  }

  Future<void> _loadRewardProducts() async {
    try {
      final products = await RewardService.instance.getRewardCatalog();
      setState(() {
        rewardItems = products;
        isLoadingRewards = false;
        hasRewardError = false;
      });
    } catch (e) {
      debugPrint('Error loading reward catalog: $e');
      setState(() {
        isLoadingRewards = false;
        hasRewardError = true;
      });
    }
  }

  Future<void> _loadMembershipProgress() async {
    try {
      final progressData = await ProfileService.instance.getMembershipProgress();
      setState(() {
        membershipData = progressData;
        isLoadingMembership = false;
      });
    } catch (e) {
      debugPrint('Error loading membership progress: $e');
      setState(() {
        isLoadingMembership = false;
      });
    }
  }

  Future<void> _loadPointsBalance() async {
    try {
      final balance = await RewardService.instance.getPointsBalance();
      setState(() {
        pointsBalance = balance;
        isLoadingPoints = false;
      });
    } catch (e) {
      debugPrint('Error loading points balance: $e');
      setState(() {
        isLoadingPoints = false;
      });
    }
  }

  void _navigateToRewardDetail(RewardProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardDetailScreen(product: product),
      ),
    );
  }

  void _navigateToRewardHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainPurple,
      appBar: const CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          // Purple header section
          _buildPurpleHeaderSection(),

          // White content section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Section title
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'แลก Reward สะสม',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Reward items grid
                          _buildRewardItemsGrid(),

                          const SizedBox(height: 40),
                        ],
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
  }

  Widget _buildPurpleHeaderSection() {
    // Points display: use real balance from getPointsBalance(); fall back to
    // getMembershipProgress current_points only if balance hasn't loaded yet.
    final String pointsText;
    if (isLoadingPoints) {
      pointsText = 'กำลังโหลด...';
    } else if (pointsBalance != null) {
      pointsText = 'คะแนนปัจจุบัน $pointsBalance คะแนน';
    } else {
      // getPointsBalance() failed; fall back to membership data if available
      final fallback = membershipData?['current_points'] ?? 0;
      pointsText = 'คะแนนปัจจุบัน $fallback คะแนน';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Title
          const Text(
            'รีวอร์ด',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // Membership card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ExMember logo
                SizedBox(
                  height: 40,
                  child: Image.asset(
                    'assets/images/exmember-purple-1.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                // Points info
                const Text(
                  'ยอดการซื้อ 10,000 บาท ได้รับ 1 คะแนนสะสม',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 12),

                // Shopping cart icon and amount
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLoadingMembership
                        ? 'กำลังโหลด...'
                        : 'ยอดสั่งซื้อสำหรับ ${membershipData?['total_spent']?.toStringAsFixed(0) ?? '0'} บาท',
                      style: const TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Discount amount
                Text(
                  isLoadingMembership
                    ? 'กำลังโหลด...'
                    : 'ยอดส่วนลดสะสม ${membershipData?['total_savings']?.toStringAsFixed(0) ?? '0'} บาท',
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainPink,
                  ),
                ),

                // Points balance — real, deducted balance from RewardService
                Text(
                  pointsText,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 20),

                // Exchange button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _navigateToRewardHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ดูประวัติการใช้รีวอร์ด',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItemsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isLoadingRewards
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(
                  color: AppColors.mainPurple,
                ),
              ),
            )
          : hasRewardError || rewardItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      hasRewardError
                          ? 'ไม่สามารถโหลดสินค้ารางวัลได้'
                          : 'ยังไม่มีสินค้ารางวัลในขณะนี้',
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: rewardItems.length,
                  itemBuilder: (context, index) {
                    final product = rewardItems[index];

                    return GestureDetector(
                      onTap: () => _navigateToRewardDetail(product),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF000000).withValues(alpha:0.04),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  color: Color(0xFFF8F9FA),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: _buildProductImage(product),
                                ),
                              ),
                            ),

                            // Product info
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product name
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontFamily: 'Prompt',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const Spacer(),

                                    // Points badge
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
                                        'ใช้คะแนน : ${product.points}',
                                        style: const TextStyle(
                                          fontFamily: 'Prompt',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildProductImage(RewardProduct product) {
    final imageUrl = product.image;
    if (imageUrl == null) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            product.fallbackIcon,
            size: 48,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    final isNetwork = imageUrl.startsWith('http');
    if (isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF3F4F6),
            child: Center(
              child: Icon(
                product.fallbackIcon,
                size: 48,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF3F4F6),
          child: Center(
            child: Icon(
              product.fallbackIcon,
              size: 48,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        );
      },
    );
  }
}
