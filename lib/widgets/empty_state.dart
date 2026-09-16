import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'custom_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    Key? key,
    this.icon = Icons.event_busy_rounded,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryLightColor.withOpacity(0.12)
                    : AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: actionText!,
                onPressed: onAction!,
                width: 180,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
