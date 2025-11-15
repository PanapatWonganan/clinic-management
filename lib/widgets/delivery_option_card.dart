import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class DeliveryOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final Function(String?) onChanged;

  const DeliveryOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppColors.mainPurple 
                    : AppColors.lightGray.withValues(alpha:0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                  ? AppColors.mainPurple.withValues(alpha:0.05) 
                  : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.mainPurple.withValues(alpha:0.1) 
                        : AppColors.lightGray.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? AppColors.mainPurple 
                        : AppColors.lightGray,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.body12Regular.copyWith(
                          color: AppColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: AppColors.mainPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}