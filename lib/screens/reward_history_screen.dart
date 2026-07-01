import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/reward_redemption.dart';
import '../services/reward_service.dart';
import '../widgets/custom_app_bar.dart';

class RewardHistoryScreen extends StatefulWidget {
  const RewardHistoryScreen({super.key});

  @override
  State<RewardHistoryScreen> createState() => _RewardHistoryScreenState();
}

class _RewardHistoryScreenState extends State<RewardHistoryScreen> {
  List<RewardRedemption> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history = await RewardService.instance.getRedemptionHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } on RewardException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'โหลดประวัติไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // Page title
                Text(
                  'ประวัติการใช้รีวอร์ด',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleText,
                  ),
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  'รายการรีวอร์ดที่คุณได้แลกไปแล้ว',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),

          // History list / loading / error / empty
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_history.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(_history[index]);
      },
    );
  }

  Widget _buildHistoryItem(RewardRedemption item) {
    final statusColors = _statusColors(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Product icon placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8F9FA),
              border: Border.all(
                color: AppColors.lightGray.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 28,
              color: Color(0xFF9CA3AF),
            ),
          ),

          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  item.productName ?? 'ของรางวัล',
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Points used
                Text(
                  'ใช้ ${item.pointsTotal} คะแนน'
                  '${item.quantity > 1 ? ' · ${item.quantity} ชิ้น' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),

                if (item.trackingNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'เลขพัสดุ: ${item.trackingNumber}',
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightGray,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Date and status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Created date (raw ISO string — show as-is or trim)
                    Flexible(
                      child: Text(
                        'แลกเมื่อ ${_formatDate(item.createdAt)}',
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.statusLabel.isNotEmpty
                            ? item.statusLabel
                            : item.status,
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: statusColors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusColor _statusColors(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return const _StatusColor(
          foreground: Color(0xFF10B981),
          background: Color(0xFFD1FAE5),
        );
      case 'shipped':
      case 'shipping':
        return const _StatusColor(
          foreground: Color(0xFF3B82F6),
          background: Color(0xFFDBEAFE),
        );
      case 'cancelled':
      case 'rejected':
        return const _StatusColor(
          foreground: Color(0xFFEF4444),
          background: Color(0xFFFEE2E2),
        );
      default:
        // pending / processing / anything else
        return const _StatusColor(
          foreground: Color(0xFFF59E0B),
          background: Color(0xFFFEF3C7),
        );
    }
  }

  String _formatDate(String rawDate) {
    // rawDate may be an ISO 8601 string like "2024-12-15T10:30:00.000000Z"
    // Show only the date portion if possible; otherwise return as-is.
    if (rawDate.length >= 10) {
      return rawDate.substring(0, 10);
    }
    return rawDate;
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.lightGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.lightGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'ลองใหม่',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_outlined,
              size: 40,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ยังไม่มีประวัติการแลกรีวอร์ด',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'เมื่อคุณแลกรีวอร์ดแล้ว ประวัติจะแสดงที่นี่',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusColor {
  final Color foreground;
  final Color background;
  const _StatusColor({required this.foreground, required this.background});
}
