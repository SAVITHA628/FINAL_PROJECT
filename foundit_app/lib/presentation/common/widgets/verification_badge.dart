import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/verification_status.dart';

class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;

  const VerificationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label = status.displayName;

    switch (status) {
      case VerificationStatus.verified:
        color = AppColors.success;
        icon = Icons.verified_user_rounded;
        break;
      case VerificationStatus.rejected:
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      case VerificationStatus.pending:
        color = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
