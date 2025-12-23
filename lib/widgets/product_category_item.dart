import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product_category.dart';

class ProductCategoryItem extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final Function(int)? onQuantityChanged; // เพิ่ม callback สำหรับกรอกจำนวนตรง

  const ProductCategoryItem({
    super.key,
    required this.category,
    required this.onIncrease,
    required this.onDecrease,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category badge
        Container(
          width: 84,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.mainPurple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              category.name,
              style: AppTextStyles.body12Regular.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Product image
        Container(
          width: 69,
          height: 125,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: category.imagePath.startsWith('http')
                  ? NetworkImage(category.imagePath) as ImageProvider
                  : AssetImage(category.imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quantity controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: category.quantity > 0 ? onDecrease : null,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: category.quantity > 0
                      ? AppColors.lightGray
                      : AppColors.lightGray.withValues(alpha:0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: onQuantityChanged != null
                  ? () => _showQuantityDialog(context)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: onQuantityChanged != null
                      ? Border.all(color: AppColors.lightGray.withValues(alpha: 0.5), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${category.quantity}',
                  style: AppTextStyles.body12Regular.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onIncrease,
              child: Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  color: AppColors.mainPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Separator line
        Container(
          width: 33,
          height: 1,
          color: AppColors.lightGray,
        ),
      ],
    );
  }

  void _showQuantityDialog(BuildContext context) {
    final controller = TextEditingController(text: '${category.quantity}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'กรอกจำนวน ${category.name}',
          style: AppTextStyles.heading16Medium.copyWith(
            color: AppColors.purpleText,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ใส่จำนวน',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.mainPink, width: 2),
            ),
          ),
          onSubmitted: (value) {
            final qty = int.tryParse(value) ?? 0;
            onQuantityChanged?.call(qty);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.body14Medium.copyWith(
                color: AppColors.lightGray,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              onQuantityChanged?.call(qty);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ยืนยัน',
              style: AppTextStyles.body14Medium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
