import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class RewardHistoryScreen extends StatefulWidget {
  const RewardHistoryScreen({super.key});

  @override
  State<RewardHistoryScreen> createState() => _RewardHistoryScreenState();
}

class _RewardHistoryScreenState extends State<RewardHistoryScreen> {
  final List<Map<String, dynamic>> rewardHistory = [
    {
      'id': 1,
      'name': 'แก้วน้ำสูญญากาศ Seagull',
      'date': '15 ธันวาคม 2024',
      'status': 'ส่งแล้ว',
      'statusColor': const Color(0xFF10B981),
      'statusBgColor': const Color(0xFFD1FAE5),
      'image': 'assets/images/product1.png',
      'points': 800,
    },
    {
      'id': 2,
      'name': 'เครื่องดูดฝุ่น 2 IN 1 แบบถังกลม',
      'date': '10 ธันวาคม 2024',
      'status': 'กำลังจัดส่ง',
      'statusColor': const Color(0xFF3B82F6),
      'statusBgColor': const Color(0xFFDBEAFE),
      'image': 'assets/images/product2.png',
      'points': 800,
    },
    {
      'id': 3,
      'name': 'แก้วน้ำสูญญากาศ Seagull',
      'date': '5 ธันวาคม 2024',
      'status': 'ส่งแล้ว',
      'statusColor': const Color(0xFF10B981),
      'statusBgColor': const Color(0xFFD1FAE5),
      'image': 'assets/images/product3.png',
      'points': 800,
    },
    {
      'id': 4,
      'name': 'เครื่องดูดฝุ่น 2 IN 1 แบบถังกลม',
      'date': '1 ธันวาคม 2024',
      'status': 'ส่งแล้ว',
      'statusColor': const Color(0xFF10B981),
      'statusBgColor': const Color(0xFFD1FAE5),
      'image': 'assets/images/product4.png',
      'points': 800,
    },
  ];

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

          // History list
          Expanded(
            child: rewardHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: rewardHistory.length,
                    itemBuilder: (context, index) {
                      final item = rewardHistory[index];
                      return _buildHistoryItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha:0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8F9FA),
              border: Border.all(
                color: AppColors.lightGray.withValues(alpha:0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item['image'].startsWith('http')
                  ? Image.network(
                      item['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.image,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      item['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.image,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          ),
                        );
                      },
                    ),
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
                  item['name'],
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
                  'ใช้คะแนน ${item['points']} คะแนน',
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),

                const SizedBox(height: 8),

                // Date and status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date
                    Text(
                      'แลกเมื่อ ${item['date']}',
                      style: const TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightGray,
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item['statusBgColor'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['status'],
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: item['statusColor'],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha:0.1),
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
            'ยังไม่มีประวัติการใช้รีวอร์ด',
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
