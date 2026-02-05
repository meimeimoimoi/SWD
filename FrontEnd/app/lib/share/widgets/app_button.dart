import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    Widget button;
    if (variant == AppButtonVariant.ghost) {
      button = TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        child: child,
      );
    } else if (variant == AppButtonVariant.outlined) {
      button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      );
    } else {
      button = ElevatedButton(onPressed: onPressed, child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!expand) return button;

        if (constraints.hasBoundedWidth) {
          return SizedBox(width: double.infinity, child: button);
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minWidth: 0),
          child: button,
        );
      },
    );
  }
}

enum AppButtonVariant { primary, outlined, ghost }
