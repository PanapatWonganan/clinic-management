import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import 'redeem_free_items_screen.dart';

class MyFreeItemsScreen extends StatefulWidget {
  const MyFreeItemsScreen({super.key});

  @override
  State<MyFreeItemsScreen> createState() => _MyFreeItemsScreenState();
}

class _MyFreeItemsScreenState extends State<MyFreeItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> rewards = [];
  List<Map<String, dynamic>> redemptionHistory = [];
  Map<String, dynamic>? summary;
  bool isLoadingRewards = true;
  bool isLoadingHistory = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyRewards();
    _loadRedemptionHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRewards() async {
    try {
      setState(() {
        isLoadingRewards = true;
        errorMessage = null;
      });

      final response = await ApiService.get('/my-rewards');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            rewards = List<Map<String, dynamic>>.from(data['data']['rewards'] ?? []);
            summary = data['data']['summary'];
            isLoadingRewards = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load rewards';
            isLoadingRewards = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load rewards';
          isLoadingRewards = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoadingRewards = false;
      });
    }
  }

  Future<void> _loadRedemptionHistory() async {
    try {
      setState(() {
        isLoadingHistory = true;
      });

      final response = await ApiService.get('/redemption-history');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            redemptionHistory = List<Map<String, dynamic>>.from(data['data'] ?? []);
            isLoadingHistory = false;
          });
        }
      }
      setState(() {
        isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        isLoadingHistory = false;
      });
    }
  }

  void _navigateToRedeem() async {
    final totalRemaining = summary?['total_remaining'] ?? 0;
    if (totalRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสิทธิ์ของแถมคงเหลือ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final combinedReward = {
      'id': 'combined',
      'remaining_free_items': totalRemaining,
      'earned_free_items': summary?['total_earned'] ?? 0,
      'redeemed_free_items': summary?['total_redeemed'] ?? 0,
      'rewards': rewards,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedeemFreeItemsScreen(reward: combinedReward),
      ),
    );
    if (result == true) {
      _loadMyRewards();
      _loadRedemptionHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            // Clean Header
            _buildCleanHeader(),
            // Tab Bar & Content
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: Column(
                  children: [
                    // Minimal Tab bar
                    _buildMinimalTabBar(),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRewardsTab(),
                          _buildHistoryTab(),
                        ],
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
  }

  Widget _buildCleanHeader() {
    final totalRemaining = summary?['total_remaining'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Title
          const Text(
            'ของแถมของฉัน',
            style: TextStyle(
              color: AppColors.purpleText,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Main number display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalRemaining',
                style: const TextStyle(
                  color: AppColors.mainPurple,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'ชิ้น',
                  style: TextStyle(
                    color: AppColors.lightGray,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'สิทธิ์คงเหลือ',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // Stats row - minimal style
          if (summary != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('ได้รับ', '${summary!['total_earned'] ?? 0}'),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey[200],
                ),
                _buildStatItem('แลกแล้ว', '${summary!['total_redeemed'] ?? 0}'),
              ],
            ),
          const SizedBox(height: 24),
          // CTA Button - สีชมพู/แดงเพื่อให้โดดเด่น
          if (totalRemaining > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToRedeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.redeem, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'แลกของแถม',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.purpleText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.mainPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'สิทธิ์ของแถม'),
          Tab(text: 'ประวัติการแลก'),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    if (isLoadingRewards) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.mainPurple,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadMyRewards,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    final totalRemaining = summary?['total_remaining'] ?? 0;

    if (rewards.isEmpty || totalRemaining == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_giftcard_outlined,
                  size: 36,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ยังไม่มีสิทธิ์ของแถม',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'สะสมสินค้าเพื่อรับของแถมฟรี',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRewards,
      color: AppColors.mainPurple,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          // Level breakdown - clean cards
          _buildLevelBreakdown(),
        ],
      ),
    );
  }

  Widget _buildLevelBreakdown() {
    final Map<int, Map<String, int>> levelStats = {};

    for (final reward in rewards) {
      final level = reward['level'] ?? 1;
      final earned = reward['earned_free_items'] ?? 0;
      final redeemed = reward['redeemed_free_items'] ?? 0;
      final remaining = reward['remaining_free_items'] ?? 0;

      if (!levelStats.containsKey(level)) {
        levelStats[level] = {'earned': 0, 'redeemed': 0, 'remaining': 0};
      }
      levelStats[level]!['earned'] = (levelStats[level]!['earned'] ?? 0) + (earned as int);
      levelStats[level]!['redeemed'] = (levelStats[level]!['redeemed'] ?? 0) + (redeemed as int);
      levelStats[level]!['remaining'] = (levelStats[level]!['remaining'] ?? 0) + (remaining as int);
    }

    if (levelStats.isEmpty) return const SizedBox();

    final sortedLevels = levelStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'รายละเอียด',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...sortedLevels.map((entry) => _buildCleanLevelCard(
          entry.key,
          entry.value['earned'] ?? 0,
          entry.value['redeemed'] ?? 0,
          entry.value['remaining'] ?? 0,
        )),
      ],
    );
  }

  Widget _buildCleanLevelCard(int level, int earned, int redeemed, int remaining) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getLevelColor(level).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  color: _getLevelColor(level),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Stats
          Expanded(
            child: Row(
              children: [
                _buildCleanStat('ได้รับ', earned),
                _buildCleanStat('แลกแล้ว', redeemed),
                _buildCleanStat('คงเหลือ', remaining, isHighlight: remaining > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanStat(String label, int value, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: isHighlight ? AppColors.mainPurple : AppColors.purpleText,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    const colors = [
      Color(0xFF6B7280), // grey
      Color(0xFF3B82F6), // blue
      Color(0xFF10B981), // green
      Color(0xFFF59E0B), // amber
      Color(0xFF8B5CF6), // purple
      Color(0xFFEF4444), // red
    ];
    return colors[(level - 1) % colors.length];
  }

  Widget _buildHistoryTab() {
    if (isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.mainPurple,
        ),
      );
    }

    if (redemptionHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_outlined,
                  size: 36,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ยังไม่มีประวัติการแลก',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRedemptionHistory,
      color: AppColors.mainPurple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: redemptionHistory.length,
        itemBuilder: (context, index) {
          final item = redemptionHistory[index];
          return _buildCleanHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildCleanHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final statusLabel = item['status_label'] ?? _getStatusLabel(status);
    final product = item['product'] as Map<String, dynamic>?;
    final createdAt = item['created_at'] != null
        ? DateTime.tryParse(item['created_at'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: product?['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product!['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.card_giftcard_outlined,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    Icons.card_giftcard_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?['name'] ?? 'สินค้า',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.purpleText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item['quantity']} ชิ้น',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if (createdAt != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'รออนุมัติ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'preparing':
        return 'กำลังจัดเตรียม';
      case 'shipped':
        return 'จัดส่งแล้ว';
      case 'delivered':
        return 'ส่งถึงแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF3B82F6);
      case 'preparing':
        return const Color(0xFF8B5CF6);
      case 'shipped':
        return const Color(0xFF6366F1);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
