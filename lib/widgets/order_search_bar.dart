import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class OrderSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;

  const OrderSearchBar({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<OrderSearchBar> createState() => _OrderSearchBarState();
}

class _OrderSearchBarState extends State<OrderSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        style: AppTextStyles.body14Medium.copyWith(
          color: AppColors.purpleText,
        ),
        decoration: InputDecoration(
          hintText: 'ค้นหาหมายเลขคำสั่งซื้อหรือสินค้า',
          hintStyle: AppTextStyles.body14Medium.copyWith(
            color: AppColors.lightGray,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.lightGray,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.lightGray,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
