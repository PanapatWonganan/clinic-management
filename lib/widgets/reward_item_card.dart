import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class RewardItemCard extends StatelessWidget {
  final int id;
  final String name;
  final int quantity;
  final String imagePath;
  final String level;
  final bool isSelected;
  final VoidCallback onToggle;

  const RewardItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.quantity,
    required this.imagePath,
    required this.level,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mainPink : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.mainPink : AppColors.lightGray,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Product Image
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: imagePath.startsWith('http')
                          ? NetworkImage(imagePath) as ImageProvider
                          : AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.body14Medium.copyWith(
                              color: AppColors.purpleText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.badgeBackground,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              level,
                              style: AppTextStyles.body12Regular.copyWith(
                                color: AppColors.lightGray,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'จำนวน $quantity ชิ้น',
                            style: AppTextStyles.body12Regular.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                          Text(
                            'ฟรี',
                            style: AppTextStyles.body14Medium.copyWith(
                              color: AppColors.mainPink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}