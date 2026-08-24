import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/item_status.dart';

class StatusBadge extends StatelessWidget {
  final ItemStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;
    String text = status.displayName;

    switch (status) {
      case ItemStatus.active:
        bg = AppColors.success.withOpacity(0.12);
        border = AppColors.success.withOpacity(0.3);
        textColor = AppColors.success;
        break;
      case ItemStatus.claimed:
        bg = AppColors.warning.withOpacity(0.12);
        border = AppColors.warning.withOpacity(0.3);
        textColor = AppColors.warning;
        break;
      case ItemStatus.returned:
        bg = AppColors.info.withOpacity(0.12);
        border = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        break;
      case ItemStatus.closed:
      case ItemStatus.expired:
        bg = AppColors.textMuted.withOpacity(0.12);
        border = AppColors.textMuted.withOpacity(0.3);
        textColor = AppColors.textMuted;
        break;
      case ItemStatus.disputed:
        bg = AppColors.error.withOpacity(0.12);
        border = AppColors.error.withOpacity(0.3);
        textColor = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
