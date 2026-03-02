import 'package:flutter/material.dart';
import 'package:superdriver_admin/shared/components/custom_text.dart';
import 'package:superdriver_admin/shared/themes/colors_custom.dart';

class ShowMessage {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: ColorsCustom.textOnPrimary, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextCustom(
                text: message,
                color: ColorsCustom.textOnPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? ColorsCustom.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.primary,
      icon: Icons.info_outline_rounded,
    );
  }
}
