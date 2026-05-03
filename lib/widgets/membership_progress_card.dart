import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/membership_level.dart';

class MembershipProgressCard extends StatelessWidget {
  final List<MembershipLevel> levels;
  final String membershipType;
  final double? previewQuantity; // จำนวนชิ้นในตะกร้า (preview)
  final double? currentQuantity; // จำนวนชิ้นปัจจุบัน
  final List<int>? requiredQuantities; // จำนวนชิ้นที่ต้องการแต่ละ level

  const MembershipProgressCard({
    super.key,
    required this.levels,
    required this.membershipType,
    this.previewQuantity,
    this.currentQuantity,
    this.requiredQuantities,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Membership header with badge
          _buildMembershipHeader(),
          const SizedBox(height: 16),

          // Dynamic progress layout
          _buildProgressLayout(),
        ],
      ),
    );
  }

  Widget _buildMembershipHeader() {
    final previewBoxes = previewQuantity?.toInt() ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getMembershipDisplayName(),
          style: AppTextStyles.heading16Medium.copyWith(
            color: _getMembershipColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (previewBoxes > 0)
          Text(
            '$previewBoxes กล่อง',
            style: TextStyle(
              color: _getMembershipColor(),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getMembershipColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getMembershipColor()),
          ),
          child: Text(
            _getMembershipBadge(),
            style: TextStyle(
              color: _getMembershipColor(),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getMembershipDisplayName() {
    switch (membershipType) {
      case 'exMember': return 'Member';
      case 'exVip': return 'VIP Member';
      case 'exSuperVip': return 'Super VIP';
      case 'exDoctor': return 'Doctor';
      default: return 'Member';
    }
  }

  String _getMembershipBadge() {
    switch (membershipType) {
      case 'exMember': return 'BASIC';
      case 'exVip': return 'VIP';
      case 'exSuperVip': return 'SUPER VIP';
      case 'exDoctor': return 'DOCTOR';
      default: return 'BASIC';
    }
  }

  Color _getMembershipColor() {
    switch (membershipType) {
      case 'exMember': return AppColors.mainPink;
      case 'exVip': return AppColors.mainPink; // ใช้สีชมพูเหมือน exMember
      case 'exSuperVip': return const Color(0xFFFFD700); // Gold
      case 'exDoctor': return Colors.green;
      default: return AppColors.mainPink;
    }
  }

  Widget _buildProgressLayout() {
    switch (membershipType) {
      case 'exMember':
        return _buildHorizontal3Levels();
      case 'exVip':
      case 'exSuperVip':
      case 'exDoctor':
        return _buildVertical6Levels();
      default:
        return _buildHorizontal3Levels();
    }
  }

  // สร้าง progress section พร้อม preview
  Widget _buildProgressSection({
    required int levelIndex,
    required double progress,
    required bool isFirst,
    required bool isLast,
    required bool canProgress,
  }) {
    final previewProgress = _calculatePreviewProgress(levelIndex, progress);
    // _calculatePreviewProgress already checks if previous levels would be filled
    // so we don't need canProgress check here for preview
    final hasPreview = previewProgress > 0;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: progress >= 100 && canProgress
            ? _getMembershipColor()
            : AppColors.progressBackground,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(4) : Radius.zero,
          bottomLeft: isFirst ? const Radius.circular(4) : Radius.zero,
          topRight: isLast ? const Radius.circular(4) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(4) : Radius.zero,
        ),
      ),
      // Show preview even if canProgress is false (preview handles its own validation)
      child: (progress < 100 && canProgress) || hasPreview
          ? Stack(
              children: [
                // Preview progress (สีจาง)
                if (hasPreview)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ((progress + previewProgress) / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getMembershipColor().withValues(alpha: 0.6),
                        borderRadius: BorderRadius.only(
                          topLeft: isFirst ? const Radius.circular(4) : Radius.zero,
                          bottomLeft: isFirst ? const Radius.circular(4) : Radius.zero,
                          topRight: isLast && progress + previewProgress >= 100
                              ? const Radius.circular(4) : Radius.zero,
                          bottomRight: isLast && progress + previewProgress >= 100
                              ? const Radius.circular(4) : Radius.zero,
                        ),
                      ),
                    ),
                  ),
                // Current progress (สีเข้ม)
                if (progress > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progress / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getMembershipColor(),
                        borderRadius: BorderRadius.only(
                          topLeft: isFirst ? const Radius.circular(4) : Radius.zero,
                          bottomLeft: isFirst ? const Radius.circular(4) : Radius.zero,
                          topRight: isLast && progress >= 100
                              ? const Radius.circular(4) : Radius.zero,
                          bottomRight: isLast && progress >= 100
                              ? const Radius.circular(4) : Radius.zero,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  // คำนวณ preview progress สำหรับแต่ละ level (ใช้จำนวนชิ้น + รองรับข้าม level)
  double _calculatePreviewProgress(int levelIndex, double currentProgress) {
    if (previewQuantity == null || previewQuantity == 0) {
      return 0;
    }

    if (currentQuantity == null || requiredQuantities == null ||
        levelIndex >= requiredQuantities!.length) {
      return 0;
    }

    // ถ้า current progress เต็ม 100% แล้ว ไม่ต้องแสดง preview
    if (currentProgress >= 100) return 0;

    final requiredQty = requiredQuantities![levelIndex];
    final totalQty = currentQuantity! + previewQuantity!;

    // Check ว่า level ก่อนหน้าทั้งหมดเต็มหรือยัง (รวม preview)
    // ถ้า totalQty ไม่พอจะเต็ม level ก่อนหน้า → ไม่แสดง preview สำหรับ level นี้
    for (int i = 0; i < levelIndex; i++) {
      final prevRequiredQty = requiredQuantities![i];
      if (totalQty < prevRequiredQty) {
        return 0;
      }
    }

    // คำนวณ preview progress % สำหรับ level นี้
    final previewProgressPercent = (totalQty / requiredQty * 100).clamp(0, 100);

    // ส่งคืนเฉพาะส่วนที่เกิน current progress
    final additionalProgress = (previewProgressPercent - currentProgress).clamp(0.0, 100.0 - currentProgress);

    // Debug log
    debugPrint('Level $levelIndex: totalQty=$totalQty, required=$requiredQty, preview%=${previewProgressPercent.toStringAsFixed(1)}, additional=${additionalProgress.toStringAsFixed(1)}');

    return additionalProgress.toDouble();
  }

  Widget _buildHorizontal3Levels() {
    final displayLevels = levels.take(3).toList();

    return Column(
      children: [
        // Level labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayLevels.map((level) =>
            Text(
              level.name,
              style: AppTextStyles.caption10.copyWith(
                color: AppColors.purpleText,
              ),
            ),
          ).toList(),
        ),
        const SizedBox(height: 8),

        // Progress bar - 3 separate sections with preview
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.progressBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Level 1 section
              Expanded(
                flex: 1,
                child: _buildProgressSection(
                  levelIndex: 0,
                  progress: displayLevels.isNotEmpty ? displayLevels[0].progress : 0,
                  isFirst: true,
                  isLast: false,
                  canProgress: true,
                ),
              ),
              // Level 2 section
              Expanded(
                flex: 1,
                child: _buildProgressSection(
                  levelIndex: 1,
                  progress: displayLevels.length > 1 ? displayLevels[1].progress : 0,
                  isFirst: false,
                  isLast: false,
                  canProgress: displayLevels.isNotEmpty && displayLevels[0].progress >= 100,
                ),
              ),
              // Level 3 section
              Expanded(
                flex: 1,
                child: _buildProgressSection(
                  levelIndex: 2,
                  progress: displayLevels.length > 2 ? displayLevels[2].progress : 0,
                  isFirst: false,
                  isLast: true,
                  canProgress: displayLevels.length > 1 && displayLevels[0].progress >= 100 && displayLevels[1].progress >= 100,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Level icons and details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayLevels.asMap().entries.map((entry) {
            MembershipLevel level = entry.value;
            bool isActive = level.progress >= 100;

            return Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.mainPink : AppColors.progressBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  level.boxes,
                  style: AppTextStyles.caption7.copyWith(
                    color: AppColors.purpleText,
                  ),
                ),
                Text(
                  level.free,
                  style: AppTextStyles.caption10.copyWith(
                    color: AppColors.mainPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVertical6Levels() {
    final displayLevels = levels.take(6).toList();

    return Column(
      children: [
        // Level labels (scrollable horizontally)
        SizedBox(
          height: 20,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: displayLevels.map((level) =>
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  child: Text(
                    level.name,
                    style: AppTextStyles.caption10.copyWith(
                      color: AppColors.purpleText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Progress bar - แบบเดิมแต่ scrollable พร้อม preview
        SizedBox(
          height: 8,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: displayLevels.length * 68.0, // 60 width + 8 margin
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: displayLevels.asMap().entries.map((entry) {
                  int index = entry.key;
                  var level = entry.value;
                  bool isFirst = index == 0;
                  bool isLast = index == displayLevels.length - 1;

                  // Check if previous level is completed for cascading logic
                  bool canProgress = true;
                  if (index > 0) {
                    canProgress = displayLevels[index - 1].progress >= 100;
                  }

                  return Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      child: _buildProgressSection(
                        levelIndex: index,
                        progress: level.progress,
                        isFirst: isFirst,
                        isLast: isLast,
                        canProgress: canProgress,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Level icons and details (scrollable horizontally) - แบบเดิม
        SizedBox(
          height: 80,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: displayLevels.asMap().entries.map((entry) {
                int index = entry.key;
                var level = entry.value;

                // Check if previous level is completed for cascading logic
                bool canProgress = true;
                if (index > 0) {
                  canProgress = displayLevels[index - 1].progress >= 100;
                }

                bool isActive = level.progress >= 100 && canProgress;

                return Container(
                  width: 60,
                  margin: EdgeInsets.only(right: index < displayLevels.length - 1 ? 8 : 0),
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isActive ? _getMembershipColor() : AppColors.progressBackground,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level.boxes,
                        style: AppTextStyles.caption7.copyWith(
                          color: AppColors.purpleText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        level.free,
                        style: AppTextStyles.caption10.copyWith(
                          color: _getMembershipColor(),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}