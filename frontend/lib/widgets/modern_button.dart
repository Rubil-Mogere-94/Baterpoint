import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../constants/theme.dart';

enum ModernButtonType { primary, secondary, outlined, text }

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final double height;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ModernButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 56.0, // Modern larger tap target
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ModernButtonType.primary ? AppColors.textInverse : AppColors.primary,
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        
        if ((isLoading || icon != null) && text.isNotEmpty)
          const SizedBox(width: AppSpacing.sm),
          
        if (text.isNotEmpty && !isLoading)
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
      ],
    );

    final ButtonStyle style;
    switch (type) {
      case ModernButtonType.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusPill),
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        );
        return ElevatedButton(
          onPressed: isLoading ? null : () {
            Vibrate.feedback(FeedbackType.light);
            onPressed?.call();
          },
          style: style,
          child: buttonContent,
        );
      case ModernButtonType.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusPill),
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        );
        return ElevatedButton(
          onPressed: isLoading ? null : () {
            Vibrate.feedback(FeedbackType.light);
            onPressed?.call();
          },
          style: style,
          child: buttonContent,
        );
      case ModernButtonType.outlined:
        style = OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusPill),
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        );
        return OutlinedButton(
          onPressed: isLoading ? null : () {
            Vibrate.feedback(FeedbackType.light);
            onPressed?.call();
          },
          style: style,
          child: buttonContent,
        );
      case ModernButtonType.text:
        style = TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        );
        return TextButton(
          onPressed: isLoading ? null : () {
            Vibrate.feedback(FeedbackType.light);
            onPressed?.call();
          },
          style: style,
          child: buttonContent,
        );
    }
  }
}
