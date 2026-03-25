import 'package:flutter/material.dart';
import '../../share/theme/app_colors.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandAccent.withValues(alpha: 0.1),
                      AppColors.brandAccent.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/cart_illustration.png', // Assuming we'll have it or use a placeholder
                    width: 180,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shopping_cart_outlined,
                      size: 100,
                      color: AppColors.brandAccent.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Giỏ hàng trống',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Có vẻ như bạn chưa thêm sản phẩm nào vào giỏ hàng của mình.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
