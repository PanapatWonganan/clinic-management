import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/delivery_option.dart';

class DeliveryCompanySelector extends StatelessWidget {
  final VehicleType vehicleType;
  final DeliveryOption? selectedOption;
  final Function(DeliveryOption) onOptionChanged;
  final List<DeliveryOption> availableOptions;

  const DeliveryCompanySelector({
    super.key,
    required this.vehicleType,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.availableOptions,
  });

  @override
  Widget build(BuildContext context) {
    final options = availableOptions
        .where((option) => option.vehicleType == vehicleType)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลือกบริษัทขนส่ง (${vehicleType == VehicleType.motorcycle ? 'มอเตอร์ไซค์' : 'รถยนต์'})',
          style: AppTextStyles.heading16Medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.purpleText,
          ),
        ),
        const SizedBox(height: 16),
        
        ...options.map((option) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCompanyCard(option),
        )).toList(),
      ],
    );
  }

  Widget _buildCompanyCard(DeliveryOption option) {
    final bool isSelected = selectedOption?.company == option.company && 
                           selectedOption?.vehicleType == option.vehicleType;
    
    return GestureDetector(
      onTap: () => onOptionChanged(option),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.mainPurple : AppColors.lightGray.withValues(alpha:0.3),
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
                  color: isSelected ? AppColors.mainPurple : AppColors.lightGray,
                  width: 2,
                ),
                color: isSelected ? AppColors.mainPurple : Colors.transparent,
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
            
            // Company logo/icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCompanyColor(option.company).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCompanyIcon(option.company),
                color: _getCompanyColor(option.company),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Company info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.companyName,
                    style: AppTextStyles.body14Medium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.estimatedTime,
                    style: AppTextStyles.body12Regular.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price (placeholder for now)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${option.price.toInt()}',
                  style: AppTextStyles.body14Medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainPink,
                  ),
                ),
                Text(
                  'ประมาณ',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompanyColor(DeliveryCompany company) {
    switch (company) {
      case DeliveryCompany.grab:
        return const Color(0xFF00BF63); // Grab green
      case DeliveryCompany.lalamove:
        return const Color(0xFFFF6B35); // Lalamove orange
    }
  }

  IconData _getCompanyIcon(DeliveryCompany company) {
    switch (company) {
      case DeliveryCompany.grab:
        return Icons.local_taxi;
      case DeliveryCompany.lalamove:
        return Icons.delivery_dining;
    }
  }
}