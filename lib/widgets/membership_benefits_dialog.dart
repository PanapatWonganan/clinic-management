import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/membership_level.dart';

class MembershipBenefitsDialog extends StatelessWidget {
  final String membershipType;
  final List<MembershipLevel> levels;

  const MembershipBenefitsDialog({
    super.key,
    required this.membershipType,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.15),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            _buildHeader(context),

            // Content
            _buildContent(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 24), // For balance
          Text(
            _getMembershipTitle(),
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _getMembershipColor(),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Logo section
          _buildLogoSection(),

          const SizedBox(height: 32),

          // Dynamic level cards based on membership type
          _buildLevelCards(),
        ],
      ),
    );
  }

  String _getMembershipTitle() {
    switch (membershipType) {
      case 'exMember': return 'สิทธิ์สมาชิก Member';
      case 'exVip': return 'สิทธิ์สมาชิก VIP';
      case 'exSuperVip': return 'สิทธิ์สมาชิก Super VIP';
      case 'exDoctor': return 'สิทธิ์สมาชิก Doctor';
      default: return 'สิทธิ์สมาชิก';
    }
  }

  Color _getMembershipColor() {
    switch (membershipType) {
      case 'exMember': return AppColors.mainPink;
      case 'exVip': return AppColors.mainPink;
      case 'exSuperVip': return const Color(0xFFFFD700);
      case 'exDoctor': return Colors.green;
      default: return AppColors.mainPink;
    }
  }

  String _getMembershipLogoPath() {
    switch (membershipType) {
      case 'exMember': return 'assets/images/exmember-pink-1.png';
      case 'exVip': return 'assets/images/exvip-pink-1.png';
      case 'exSuperVip': return 'assets/images/exsupervip-gold-1.png';
      case 'exDoctor': return 'assets/images/exdoctor-green-1.png';
      default: return 'assets/images/exmember-pink-1.png';
    }
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

  String _getMembershipDescription() {
    switch (membershipType) {
      case 'exMember': return 'สิทธิพิเศษเป็นสมาชิกเพื่อรับส่วนลดในโปรโมชั่นแลกของแถมได้';
      case 'exVip': return 'สิทธิพิเศษ VIP รับประโยชน์มากขึ้น สิทธิ์พิเศษและสะสมแต้มเร็วขึ้น';
      case 'exSuperVip': return 'สิทธิ์สูงสุดสำหรับ Super VIP สิทธิ์พิเศษระดับพรีเมียม';
      case 'exDoctor': return 'สิทธิพิเศษสำหรับหมอ รับสิทธิ์เฉพาะวิชาชีพ';
      default: return 'สิทธิพิเศษเป็นสมาชิกเพื่อรับส่วนลดในโปรโมชั่นแลกของแถมได้';
    }
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Dynamic membership logo
        Container(
          height: 128,
          alignment: Alignment.center,
          child: Image.asset(
            _getMembershipLogoPath(),
            width: 640,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 48,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getMembershipColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getMembershipDisplayName(),
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Dynamic description
        Text(
          _getMembershipDescription(),
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLevelCards() {
    // Use the appropriate number of levels based on membership type
    final displayLevels = membershipType == 'exMember'
        ? levels.take(3).toList()
        : levels.take(6).toList();

    if (membershipType == 'exMember') {
      // Original 3-level horizontal layout for exMember
      return _buildThreeLevelLayout(displayLevels);
    } else {
      // 6-level scrollable layout for VIP, SuperVIP, Doctor
      return _buildSixLevelLayout(displayLevels);
    }
  }

  Widget _buildThreeLevelLayout(List<MembershipLevel> displayLevels) {
    return Column(
      children: displayLevels.asMap().entries.map((entry) {
        int index = entry.key;
        MembershipLevel level = entry.value;
        bool isActive = level.progress >= 100;

        return Column(
          children: [
            _buildLevelCard(
              level: 'Level ${index + 1}',
              requirement: '${level.boxes} ${level.free}',
              backgroundColor: _getLevelBackgroundColor(index),
              borderColor: _getLevelBorderColor(index),
              iconPath: _getLevelIconPath(index),
              isActive: isActive,
            ),
            if (index < displayLevels.length - 1) const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSixLevelLayout(List<MembershipLevel> displayLevels) {
    return SizedBox(
      height: 400, // Fixed height for scrollable content
      child: SingleChildScrollView(
        child: Column(
          children: displayLevels.asMap().entries.map((entry) {
            int index = entry.key;
            MembershipLevel level = entry.value;
            bool isActive = level.progress >= 100;

            return Column(
              children: [
                _buildLevelCard(
                  level: 'Level ${index + 1}',
                  requirement: '${level.boxes} ${level.free}',
                  backgroundColor: _getLevelBackgroundColor(index),
                  borderColor: _getLevelBorderColor(index),
                  iconPath: _getLevelIconPath(index),
                  isActive: isActive,
                ),
                if (index < displayLevels.length - 1) const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getLevelBackgroundColor(int index) {
    final colors = [
      const Color(0xFFF3F4FF), // Purple
      const Color(0xFFF0FDF4), // Green
      const Color(0xFFFDF2F8), // Pink
      const Color(0xFFFFF7ED), // Orange
      const Color(0xFFF0F9FF), // Blue
      const Color(0xFFFAFAF9), // Gray
    ];
    return colors[index % colors.length];
  }

  Color _getLevelBorderColor(int index) {
    final colors = [
      const Color(0xFFE0E7FF), // Purple
      const Color(0xFFDCFCE7), // Green
      const Color(0xFFFCE7F3), // Pink
      const Color(0xFFFED7AA), // Orange
      const Color(0xFFE0F2FE), // Blue
      const Color(0xFFE5E7EB), // Gray
    ];
    return colors[index % colors.length];
  }

  String _getLevelIconPath(int index) {
    final icons = [
      'assets/images/purple.png',
      'assets/images/green.png',
      'assets/images/pink.png',
      'assets/images/purple.png',
      'assets/images/green.png',
      'assets/images/pink.png',
    ];
    return icons[index % icons.length];
  }

  Widget _buildLevelCard({
    required String level,
    required String requirement,
    required Color backgroundColor,
    required Color borderColor,
    required String iconPath,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Level icon using uploaded image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to colored circle if image fails to load
                    Color fallbackColor = AppColors.mainPurple;
                    if (iconPath.contains('green')) {
                      fallbackColor = const Color(0xFF22C55E);
                    }
                    if (iconPath.contains('pink')) {
                      fallbackColor = const Color(0xFFEC4899);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: fallbackColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          level.replaceAll('Level ', ''),
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Level content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level header with badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      level,
                      style: const TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mainPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ปัจจุบัน',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Requirement only
                Text(
                  requirement,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
