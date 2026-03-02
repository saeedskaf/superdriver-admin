import 'package:flutter/material.dart';
import 'package:superdriver_admin/shared/components/custom_text.dart';
import 'package:superdriver_admin/shared/themes/colors_custom.dart';

class LoadingModal {
  static bool _isShowing = false;

  static void show(BuildContext context, {String? message}) {
    if (_isShowing) return;

    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: ColorsCustom.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: ColorsCustom.primary,
                    strokeWidth: 3,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  TextCustom(
                    text: message,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ColorsCustom.textPrimary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).then((_) => _isShowing = false);
  }

  static void dismiss(BuildContext context) {
    if (_isShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowing = false;
    }
  }

  static bool get isShowing => _isShowing;
}
