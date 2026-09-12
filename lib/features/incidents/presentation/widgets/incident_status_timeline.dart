import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/incident_model.dart';

class IncidentStatusTimeline extends StatelessWidget {
  final IncidentStatus currentStatus;

  const IncidentStatusTimeline({super.key, required this.currentStatus});

  static const List<IncidentStatus> _timelineSteps = [
    IncidentStatus.SUBMITTED,
    IncidentStatus.VERIFIED,
    IncidentStatus.DISPATCHED,
    IncidentStatus.IN_PROGRESS,
    IncidentStatus.RESOLVED,
  ];

  int _getStepIndex(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.SUBMITTED:
      case IncidentStatus.SYSTEM_CHECKING:
      case IncidentStatus.AI_ANALYSIS:
      case IncidentStatus.VERIFICATION_REQUIRED:
        return 0;
      case IncidentStatus.VERIFIED:
        return 1;
      case IncidentStatus.DISPATCHED:
        return 2;
      case IncidentStatus.IN_PROGRESS:
        return 3;
      case IncidentStatus.RESOLVED:
      case IncidentStatus.CLOSED:
        return 4;
      case IncidentStatus.REJECTED:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == IncidentStatus.REJECTED) {
      return Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Incident Report Rejected by Authority Verification',
                style: AppTypography.titleMedium.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _getStepIndex(currentStatus);

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Text(
            'STATUS TRACKING TIMELINE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(_timelineSteps.length, (index) {
              final step = _timelineSteps[index];
              final isPassed = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.primary
                                : (isPassed ? AppColors.success : AppColors.surface),
                            border: Border.all(
                              color: isPassed ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isPassed ? Icons.check : Icons.circle,
                            size: 14,
                            color: isPassed ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.displayLabel,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: isCurrent
                                ? AppColors.textPrimary
                                : (isPassed ? AppColors.textSecondary : AppColors.textMuted),
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (index < _timelineSteps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex ? AppColors.success : AppColors.border,
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
