import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/delivery_option.dart';

class VehicleTypeSelector extends StatelessWidget {
  final VehicleType? selectedVehicleType;
  final Function(VehicleType) onVehicleTypeChanged;

  const VehicleTypeSelector({
    super.key,
    required this.selectedVehicleType,
    required this.onVehicleTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลือกประเภทยานพาหนะ',
          style: AppTextStyles.heading16Medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 16),
        
        // Motorcycle option
        _buildVehicleTypeCard(
          VehicleType.motorcycle,
          'มอเตอร์ไซค์',
          'เหมาะสำหรับส่งด่วน',
          Icons.two_wheeler,
          AppColors.mainPink,
        ),
        
        const SizedBox(height: 12),
        
        // Car option
        _buildVehicleTypeCard(
          VehicleType.car,
          'รถยนต์',
          'เหมาะสำหรับของใหญ่',
          Icons.directions_car,
          AppColors.mainPurple,
        ),
      ],
    );
  }

  Widget _buildVehicleTypeCard(
    VehicleType vehicleType,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = selectedVehicleType == vehicleType;
    
    return GestureDetector(
      onTap: () => onVehicleTypeChanged(vehicleType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.lightGray.withValues(alpha:0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.lightGray,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body14Medium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body12Regular.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}