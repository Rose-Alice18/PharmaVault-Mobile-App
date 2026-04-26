import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = color ?? theme.colorScheme.primary;
    final foreground = theme.colorScheme.onPrimary;
    final disabledColor = theme.colorScheme.onSurface.withOpacity(0.12);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: foreground,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style:
                        theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ) ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
