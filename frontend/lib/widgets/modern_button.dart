import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

enum ModernButtonType { primary, secondary, outlined, text, glass }

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
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                type == ModernButtonType.primary ? Colors.white : theme.colorScheme.primary,
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
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13),
          ),
      ],
    );

    if (type == ModernButtonType.glass) {
      return Container(
        height: height,
        width: isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: AppRadius.roundedPill,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.roundedPill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ElevatedButton(
              onPressed: isLoading ? null : () {
                Vibrate.feedback(FeedbackType.light);
                onPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
              ),
              child: buttonContent,
            ),
          ),
        ),
      );
    }

    final ButtonStyle style;
    switch (type) {
      case ModernButtonType.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        );
        return ElevatedButton(
          onPressed: isLoading ? null : () {
            Vibrate.feedback(FeedbackType.light);
            onPressed?.call();
          },
          style: style,
          child: buttonContent,
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .shimmer(duration: 3.seconds, color: Colors.white24);
      case ModernButtonType.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceVariant,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        ) ;
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
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
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
          foregroundColor: theme.colorScheme.primary,
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
      case ModernButtonType.glass:
        // Already handled above
        return const SizedBox.shrink();
    }
  }
}
