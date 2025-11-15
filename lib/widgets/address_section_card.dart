import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/user_profile.dart';

class AddressSectionCard extends StatelessWidget {
  final VoidCallback onEditAddress;
  final UserProfile profile;

  const AddressSectionCard({
    super.key,
    required this.onEditAddress,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and edit link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ที่อยู่จัดส่ง',
                style: AppTextStyles.heading16Medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleText,
                ),
              ),
              GestureDetector(
                onTap: onEditAddress,
                child: Text(
                  'แก้ไขที่อยู่',
                  style: AppTextStyles.body14Medium.copyWith(
                    color: AppColors.mainPink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Address content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location icon
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.mainPink,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Address details
              Expanded(
                child: profile.hasCompleteAddress
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and phone
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name
                                      : 'ชื่อไม่ระบุ',
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: AppColors.purpleText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (profile.phone.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 12,
                                  color: AppColors.lightGray.withValues(alpha:0.5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  profile.phone,
                                  style: AppTextStyles.body14Medium.copyWith(
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Full address
                          Text(
                            profile.fullAddress,
                            style: AppTextStyles.body14Medium.copyWith(
                              color: AppColors.purpleText,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Address label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightPurple.withValues(alpha:0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.mainPurple.withValues(alpha:0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'คลีนิค',
                              style: AppTextStyles.body12Regular.copyWith(
                                color: AppColors.mainPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ยังไม่ได้เพิ่มที่อยู่',
                            style: AppTextStyles.body14Medium.copyWith(
                              color: AppColors.lightGray,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'กดแก้ไขที่อยู่เพื่อเพิ่มข้อมูลที่อยู่จัดส่ง',
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
