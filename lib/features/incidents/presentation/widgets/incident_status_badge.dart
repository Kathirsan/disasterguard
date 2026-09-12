import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/incident_model.dart';

class IncidentStatusBadge extends StatelessWidget {
  final IncidentStatus status;

  const IncidentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayLabel,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
