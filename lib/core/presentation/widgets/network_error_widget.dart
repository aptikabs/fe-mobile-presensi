import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// A reusable widget that displays a network error state with an icon,
/// user-friendly message, and a retry button.
///
/// Can be used as a full-page placeholder or inline card within a list/column.
class NetworkErrorWidget extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the "Coba Lagi" (retry) button is pressed.
  final VoidCallback onRetry;

  /// Whether to display as a compact card or full-page centered widget.
  final bool compact;

  const NetworkErrorWidget({
    super.key,
    this.message = 'Tidak ada koneksi internet.\nPeriksa jaringan Anda dan coba lagi.',
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon container with gradient background
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning100,
                AppColors.warning200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_off_rounded,
            size: compact ? 40 : 56,
            color: AppColors.warning600,
          ),
        ),
        SizedBox(height: compact ? 16 : 24),

        // Error message
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        SizedBox(height: compact ? 16 : 24),

        // Retry button
        SizedBox(
          width: compact ? null : 200,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 28,
                vertical: compact ? 10 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning200),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: content,
      ),
    );
  }
}
