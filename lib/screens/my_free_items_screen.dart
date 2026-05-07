import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import 'redeem_free_items_screen.dart';

class MyFreeItemsScreen extends StatefulWidget {
  const MyFreeItemsScreen({super.key});

  @override
  State<MyFreeItemsScreen> createState() => _MyFreeItemsScreenState();
}

class _MyFreeItemsScreenState extends State<MyFreeItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Approved rewards with remaining > 0 (พร้อมใช้)
  List<Map<String, dynamic>> rewards = [];
  // Pending rewards (รออนุมัติ admin)
  List<Map<String, dynamic>> pendingRewards = [];
  // Levels unlocked but not claimed yet (ยังไม่ได้ claim)
  List<Map<String, dynamic>> availableRewards = [];
  // Redemption history
  List<Map<String, dynamic>> redemptionHistory = [];

  Map<String, dynamic>? summary;
  bool isLoadingRewards = true;
  bool isLoadingHistory = true;
  String? errorMessage;
  // Per-level claim-in-progress flag เพื่อกัน double-tap
  final Set<int> _claimingLevels = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
    _loadRedemptionHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      isLoadingRewards = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/my-rewards?include_pending=1'),
        ProfileService.instance.getMembershipProgress(),
      ]);

      // /my-rewards
      final rewardsResponse = results[0] as dynamic;
      if (rewardsResponse.statusCode == 200) {
        final data = json.decode(rewardsResponse.body);
        if (data['success'] == true) {
          rewards = List<Map<String, dynamic>>.from(
              data['data']['rewards'] ?? []);
          pendingRewards = List<Map<String, dynamic>>.from(
              data['data']['pending_rewards'] ?? []);
          summary = Map<String, dynamic>.from(data['data']['summary'] ?? {});
        }
      }

      // /membership/progress → available_rewards
      final progressData = results[1] as Map<String, dynamic>?;
      if (progressData != null) {
        availableRewards = List<Map<String, dynamic>>.from(
            progressData['available_rewards'] ?? []);
      }

      setState(() {
        isLoadingRewards = false;
      });
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
            redemptionHistory =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
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

  // levels ที่ user ได้ claim แล้ว (approved + pending) — ใช้กรอง available
  // ไม่ให้ซ้ำกับที่ pending/approved อยู่
  Set<int> get _alreadyClaimedLevels {
    final s = <int>{};
    for (final r in rewards) {
      s.add(r['level'] as int);
    }
    for (final r in pendingRewards) {
      s.add(r['level'] as int);
    }
    return s;
  }

  // available levels หลังตัดที่ claim แล้วออก (กัน double-claim)
  List<Map<String, dynamic>> get _unclaimedAvailable {
    final claimed = _alreadyClaimedLevels;
    return availableRewards
        .where((r) => !claimed.contains(r['level'] as int))
        .toList();
  }

  int get _totalRemaining => (summary?['total_remaining'] ?? 0) as int;

  int get _totalPending => pendingRewards.fold<int>(
      0, (s, r) => s + ((r['earned_free_items'] ?? 0) as int));

  int get _totalAvailableUnclaimed => _unclaimedAvailable.fold<int>(
      0, (s, r) => s + ((r['earned_free_items'] ?? 0) as int));

  int get _grandTotal =>
      _totalRemaining + _totalPending + _totalAvailableUnclaimed;

  Future<void> _claimLevel(Map<String, dynamic> level) async {
    final lvl = level['level'] as int;
    if (_claimingLevels.contains(lvl)) return;

    setState(() {
      _claimingLevels.add(lvl);
    });

    try {
      final result = await ProfileService.instance.claimReward(lvl);

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('ส่งคำขอแลกของแถม Level $lvl แล้ว รอแอดมินอนุมัติ'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'แลกของแถมไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _claimingLevels.remove(lvl);
        });
      }
    }
  }

  void _navigateToRedeem() async {
    if (_totalRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสิทธิ์ของแถมที่พร้อมใช้ — รอแอดมินอนุมัติก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final combinedReward = {
      'id': 'combined',
      'remaining_free_items': _totalRemaining,
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
      _loadAll();
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
            _buildCleanHeader(),
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: Column(
                  children: [
                    _buildMinimalTabBar(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_grandTotal',
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
            'ของแถมรวมทั้งหมด',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          // 3-stat row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('พร้อมใช้', _totalRemaining,
                  color: const Color(0xFF10B981)),
              Container(width: 1, height: 32, color: Colors.grey[200]),
              _buildStatItem('รออนุมัติ', _totalPending,
                  color: const Color(0xFFF59E0B)),
              Container(width: 1, height: 32, color: Colors.grey[200]),
              _buildStatItem('ยังไม่แลก', _totalAvailableUnclaimed,
                  color: AppColors.mainPurple),
            ],
          ),
          const SizedBox(height: 24),
          if (_totalRemaining > 0)
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

  Widget _buildStatItem(String label, int value, {Color? color}) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color ?? AppColors.purpleText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                onPressed: _loadAll,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (_grandTotal == 0 && rewards.isEmpty) {
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
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.mainPurple,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          if (rewards.any((r) => (r['remaining_free_items'] ?? 0) > 0))
            _buildSectionTitle('พร้อมใช้'),
          ..._buildApprovedCards(),
          if (pendingRewards.isNotEmpty) _buildSectionTitle('รออนุมัติ'),
          ...pendingRewards.map(_buildPendingCard),
          if (_unclaimedAvailable.isNotEmpty)
            _buildSectionTitle('ยังไม่ได้แลก (กดเพื่อขอแลก)'),
          ..._unclaimedAvailable.map(_buildAvailableCard),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Approved cards: rolled-up per level
  List<Widget> _buildApprovedCards() {
    final Map<int, Map<String, int>> levelStats = {};

    for (final reward in rewards) {
      final level = (reward['level'] ?? 1) as int;
      final earned = (reward['earned_free_items'] ?? 0) as int;
      final redeemed = (reward['redeemed_free_items'] ?? 0) as int;
      final remaining = (reward['remaining_free_items'] ?? 0) as int;

      levelStats.putIfAbsent(
          level, () => {'earned': 0, 'redeemed': 0, 'remaining': 0});
      levelStats[level]!['earned'] = (levelStats[level]!['earned']!) + earned;
      levelStats[level]!['redeemed'] =
          (levelStats[level]!['redeemed']!) + redeemed;
      levelStats[level]!['remaining'] =
          (levelStats[level]!['remaining']!) + remaining;
    }

    final sorted = levelStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) {
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
            _levelBadge(e.key),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  _miniStat('ได้รับ', e.value['earned']!),
                  _miniStat('แลกแล้ว', e.value['redeemed']!),
                  _miniStat('คงเหลือ', e.value['remaining']!,
                      isHighlight: e.value['remaining']! > 0),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPendingCard(Map<String, dynamic> r) {
    final level = (r['level'] ?? 1) as int;
    final earned = (r['earned_free_items'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _levelBadge(level),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $level — $earned ชิ้น',
                  style: const TextStyle(
                    color: AppColors.purpleText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'รอแอดมินอนุมัติ',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 14, color: Color(0xFFF59E0B)),
                SizedBox(width: 4),
                Text(
                  'รออนุมัติ',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> r) {
    final level = (r['level'] ?? 1) as int;
    final earned = (r['earned_free_items'] ?? 0) as int;
    final required = (r['required_quantity'] ?? 0) as int;
    final isClaiming = _claimingLevels.contains(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _levelBadge(level),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $level — $earned ชิ้น',
                  style: const TextStyle(
                    color: AppColors.purpleText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ปลดล็อกที่ $required ชิ้น',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isClaiming ? null : () => _claimLevel(r),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPurple,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: isClaiming
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'ขอแลก',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(int level) {
    return Container(
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
    );
  }

  Widget _miniStat(String label, int value, {bool isHighlight = false}) {
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
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    const colors = [
      Color(0xFF6B7280),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
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
                          color: Colors.grey[600], fontSize: 13),
                    ),
                    if (createdAt != null) ...[
                      Text(' • ',
                          style: TextStyle(color: Colors.grey[400])),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
