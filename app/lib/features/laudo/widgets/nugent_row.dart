import 'package:flutter/material.dart';
import 'package:microlaudo/core/theme/app_theme.dart';

class NugentRow extends StatelessWidget {
  final String label;
  final String description;
  final List<String> options;
  final String value;
  final int pts;
  final ValueChanged<String?> onChanged;

  const NugentRow({
    super.key,
    required this.label,
    required this.description,
    required this.options,
    required this.value,
    required this.pts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge A/B/C
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Descrição (flex)
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Dropdown
          DropdownButton<String>(
            value: value,
            isDense: true,
            underline: Container(height: 1, color: AppColors.border),
            items: options
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
          const SizedBox(width: 12),
          // Pontos
          SizedBox(
            width: 28,
            child: Text(
              '$pts',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
