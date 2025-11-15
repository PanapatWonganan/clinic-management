import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onMenuTap;
  
  const CustomAppBar({
    super.key,
    this.showBackButton = false,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.mainPurple,
      elevation: 4,
      shadowColor: Colors.black26,
      centerTitle: true,
      leading: showBackButton 
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          )
        : null,
      title: Container(
        width: 120,
        height: 42,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/white-1.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
      actions: showBackButton ? null : [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 28,
            ),
            onPressed: onMenuTap,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}