import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';

enum AlertType { stock, sync, billing, system }

class InAppNotificationToast extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final VoidCallback onClose;

  const InAppNotificationToast({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    IconData icon;

    switch (type.toUpperCase()) {
      case 'STOCK':
        indicatorColor = AppColors.error;
        icon = Icons.warning_amber_rounded;
        break;
      case 'SYNC':
        indicatorColor = AppColors.secondary;
        icon = Icons.sync_lock_rounded;
        break;
      case 'BILLING':
        indicatorColor = AppColors.primary;
        icon = Icons.receipt_long_rounded;
        break;
      default:
        indicatorColor = AppColors.accent;
        icon = Icons.info_outline;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: indicatorColor),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Icon(icon, color: indicatorColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InAppNotificationManager {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: InAppNotificationToast(
              title: title,
              message: message,
              type: type,
              onClose: () {
                entry.remove();
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}
