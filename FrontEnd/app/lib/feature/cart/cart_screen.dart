import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../share/theme/app_colors.dart';
import '../../share/services/cart_api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartApiService _api = CartApiService();
  bool _loading = true;
  List<CartItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    final items = await _api.getCartItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _removeItem(int cartItemId) async {
    final ok = await _api.removeCartItem(cartItemId);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa khỏi giỏ hàng')));
      await _loadCart();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa không thành công')));
    }
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
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
                          'assets/cart_illustration.png',
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
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl ?? '',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            size: 36,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.solutionName ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Số lượng: ${item.quantity}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _removeItem(item.cartItemId),
                            icon: Icon(
                              Icons.delete,
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.brandAccent,
                            ),
                            onPressed: () async {
                              final url = item.shopeeUrl;
                              if (url == null || url.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Link mua hàng không có'),
                                  ),
                                );
                                return;
                              }
                              final uri = Uri.tryParse(url);
                              if (uri == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Link mua hàng không hợp lệ'),
                                  ),
                                );
                                return;
                              }
                              try {
                                final launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!launched) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Không thể mở link'),
                                    ),
                                  );
                                }
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lỗi khi mở link'),
                                  ),
                                );
                              }
                            },
                            tooltip: 'Mua',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
