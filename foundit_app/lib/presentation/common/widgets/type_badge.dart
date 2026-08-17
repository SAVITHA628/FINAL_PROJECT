import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/item_type.dart';

class TypeBadge extends StatelessWidget {
  final ItemType type;

  const TypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isLost = type == ItemType.lost;
    final color = isLost ? AppColors.error : AppColors.success;
    final text = isLost ? 'LOST' : 'FOUND';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
