import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/item_type.dart';

class FilterChipsRow extends StatelessWidget {
  final ItemType? selectedType;
  final ValueChanged<ItemType?> onChanged;

  const FilterChipsRow({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(null, 'All', Icons.list_rounded),
        const SizedBox(width: 8),
        _buildChip(ItemType.lost, 'Lost', Icons.warning_amber_rounded),
        const SizedBox(width: 8),
        _buildChip(ItemType.found, 'Found', Icons.check_circle_outline_rounded),
      ],
    );
  }

  Widget _buildChip(ItemType? type, String label, IconData icon) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
