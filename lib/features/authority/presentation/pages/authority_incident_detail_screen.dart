import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/network/api_client.dart';
import '../providers/authority_provider.dart';

class AuthorityIncidentDetailScreen extends StatefulWidget {
  final int incidentId;

  const AuthorityIncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<AuthorityIncidentDetailScreen> createState() => _AuthorityIncidentDetailScreenState();
}

class _AuthorityIncidentDetailScreenState extends State<AuthorityIncidentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AuthorityProvider>(context, listen: false);
      provider.loadIncidentDetail(widget.incidentId);
      provider.loadAvailableCrews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Incident #${widget.incidentId} Verification', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Provider.of<AuthorityProvider>(context, listen: false)
                  .loadIncidentDetail(widget.incidentId);
            },
          ),
        ],
      ),
      body: Consumer<AuthorityProvider>(
        builder: (context, provider, child) {
          if (provider.status == AuthorityStatus.loading && provider.selectedIncidentDetail == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.status == AuthorityStatus.error && provider.selectedIncidentDetail == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(provider.errorMessage ?? 'Failed to load details', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Retry',
                    onPressed: () => provider.loadIncidentDetail(widget.incidentId),
                  ),
                ],
              ),
            );
          }

          final detail = provider.selectedIncidentDetail;
          if (detail == null) return const SizedBox.shrink();

          final incident = detail['incident'] as Map<String, dynamic>;
          final reporter = detail['reporter'] as Map<String, dynamic>?;
          final verification = detail['verification'] as Map<String, dynamic>?;
          final weather = detail['weather'] as Map<String, dynamic>?;
          final ai = detail['ai_assessment'] as Map<String, dynamic>?;
          final history = detail['status_history'] as List<dynamic>? ?? [];
          final ticket = detail['council_ticket'] as Map<String, dynamic>?;
          final assignment = detail['crew_assignment'] as Map<String, dynamic>?;
          final alert = detail['alert'] as Map<String, dynamic>?;
          final primaryImgUrl = detail['primary_image_url'] as String?;

          final statusStr = incident['status'] ?? 'SUBMITTED';
          final hazardStr = incident['hazard_type'] ?? 'FLOOD';
          final riskLevel = verification?['risk_level'] ?? 'LOW';
          final riskScore = verification?['risk_score'] ?? 0;

          Color riskColor;
          if (riskLevel == 'CRITICAL' || riskLevel == 'HIGH') {
            riskColor = AppColors.primary;
          } else if (riskLevel == 'MODERATE') {
            riskColor = AppColors.warning;
          } else {
            riskColor = AppColors.accentCyan;
          }

          return SingleChildScrollView(
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // Top Status Header Banner
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: riskColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Text('INCIDENT STATUS', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(statusStr.replaceAll('_', ' '), style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.2),
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(color: riskColor),
                        ),
                        child: Text(
                          '$riskLevel RISK ($riskScore/100)',
                          style: AppTypography.labelMedium.copyWith(color: riskColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 1. ORIGINAL CITIZEN REPORT CARD
                _buildSectionHeader('1. Citizen Emergency Report', Icons.person_pin_circle_rounded),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(hazardStr.replaceAll('_', ' '), style: AppTypography.titleMedium),
                          Text('Reporter: ${reporter?['full_name'] ?? 'Citizen'}', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(incident['description'] ?? '', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.accentCyan),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Location: ${incident['address_text'] ?? "Lat: ${incident['latitude']}, Lon: ${incident['longitude']}"}',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      if (primaryImgUrl != null && primaryImgUrl.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: AppSpacing.borderRadiusSm,
                          child: Image.network(
                            primaryImgUrl.startsWith('http') ? primaryImgUrl : '${ApiClient().baseUrl.replaceAll('/api/v1', '')}$primaryImgUrl',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: AppColors.surfaceElevated,
                              child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2. SYSTEM VERIFICATION & WEATHER
                _buildSectionHeader('2. System Verification & Weather Evidence', Icons.cloud_done_rounded),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                (verification?['gps_valid'] ?? true) ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: (verification?['gps_valid'] ?? true) ? AppColors.success : AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text('GPS Validity: ${(verification?['gps_valid'] ?? true) ? "VALID COORDINATES" : "INVALID"}', style: AppTypography.labelMedium),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('SUPPORT: ${verification?['weather_support'] ?? "UNKNOWN"}', style: AppTypography.labelSmall.copyWith(color: AppColors.accentBlue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (weather != null) ...[
                        Text('Weather Observation: ${weather['condition']}', style: AppTypography.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Rainfall: ${weather['rainfall_mm']} mm  |  Wind: ${weather['wind_speed_kmh']} km/h  |  Temp: ${weather['temperature_c']}°C',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        Text('Provider: ${weather['provider']}', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      ],
                      const Divider(color: AppColors.border, height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nearby Reports (5km): ${verification?['nearby_report_count'] ?? 0}', style: AppTypography.bodyMedium),
                          if (verification?['is_possible_duplicate'] ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text('POSSIBLE DUPLICATE', style: AppTypography.labelSmall.copyWith(color: AppColors.warning)),
                            ),
                        ],
                      ),
                      if (verification?['cluster_id'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Assigned Cluster: ${verification!['cluster_id']}', style: AppTypography.bodySmall.copyWith(color: AppColors.roleAuthority)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 3. AI VISION ANALYSIS
                _buildSectionHeader('3. Multimodal AI Vision Analysis', Icons.psychology_rounded),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Detected: ${ai?['detected_hazard'] ?? hazardStr}', style: AppTypography.titleMedium),
                          Text(
                            'Confidence: ${((ai?['confidence'] ?? 0.0) * 100).toInt()}%',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.roleAuthority, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: (ai?['confidence'] ?? 0.0).toDouble(),
                        backgroundColor: AppColors.surfaceElevated,
                        color: AppColors.roleAuthority,
                        minHeight: 6,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Visible Evidence:', style: AppTypography.titleSmall),
                      Text(ai?['visible_evidence'] ?? 'Processing image pixels...', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text('AI Reasoning:', style: AppTypography.titleSmall),
                      Text(ai?['reasoning_summary'] ?? 'Analyzing hazard pattern against emergency classifier.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 4. COMBINED RISK ASSESSMENT
                _buildSectionHeader('4. Combined Risk Assessment & Evidence Summary', Icons.analytics_rounded),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calculated Risk Score:', style: AppTypography.titleMedium),
                          Text('$riskScore / 100', style: AppTypography.displayMedium.copyWith(fontSize: 22, color: riskColor)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(verification?['evidence_summary'] ?? 'System risk score evaluation completed.', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 5. AUTHORITY ACTION BAR (CONFIRM / REJECT)
                if (statusStr == 'VERIFICATION_REQUIRED' || statusStr == 'SUBMITTED') ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Reject Incident',
                          variant: AppButtonVariant.secondary,
                          icon: Icons.cancel_rounded,
                          isLoading: provider.isActionLoading,
                          onPressed: () => _showRejectDialog(context, provider),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          text: 'Confirm Incident',
                          icon: Icons.verified_user_rounded,
                          isLoading: provider.isActionLoading,
                          onPressed: () async {
                            final success = await provider.confirmIncident(widget.incidentId);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Incident confirmed as VERIFIED!')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 6. POST-CONFIRMATION OPERATIONS (ALERT / TICKET / DISPATCH)
                if (statusStr == 'VERIFIED' || statusStr == 'DISPATCHED') ...[
                  _buildSectionHeader('Operational Response & Dispatch Control', Icons.local_fire_department_rounded),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      children: [
                        if (alert != null) ...[
                          Container(
                            padding: AppSpacing.paddingMd,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: AppSpacing.borderRadiusSm, border: Border.all(color: AppColors.primary)),
                            child: Row(
                              children: [
                                const Icon(Icons.campaign_rounded, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAlignment.start,
                                    children: [
                                      Text('Active Broadcast Alert: ${alert['title']}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                                      Text(alert['message'] ?? '', style: AppTypography.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (ticket != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Council Ticket: ${ticket['ticket_number']}', style: AppTypography.titleSmall.copyWith(color: AppColors.accentCyan)),
                              Text('Priority: ${ticket['priority']}', style: AppTypography.labelSmall.copyWith(color: AppColors.warning)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (assignment != null) ...[
                          Container(
                            padding: AppSpacing.paddingMd,
                            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: AppSpacing.borderRadiusSm, border: Border.all(color: AppColors.success)),
                            child: Row(
                              children: [
                                const Icon(Icons.fire_truck_rounded, color: AppColors.success),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAlignment.start,
                                    children: [
                                      Text('Crew Dispatched!', style: AppTypography.titleSmall.copyWith(color: AppColors.success)),
                                      Text('Instructions: ${assignment['instructions'] ?? ""}', style: AppTypography.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Action Buttons for Operations
                        Column(
                          children: [
                            if (alert == null) ...[
                              AppButton(
                                text: '📢 Broadcast Area Emergency Alert',
                                variant: AppButtonVariant.secondary,
                                onPressed: () => _showAlertDialog(context, provider),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            if (ticket == null) ...[
                              AppButton(
                                text: '🎫 Generate Operational Council Ticket',
                                variant: AppButtonVariant.secondary,
                                onPressed: () async {
                                  final ok = await provider.createCouncilTicket(incidentId: widget.incidentId);
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Council Ticket Created!')));
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            if (statusStr == 'VERIFIED') ...[
                              AppButton(
                                text: '🚒 Dispatch Emergency Crew',
                                icon: Icons.local_fire_department_rounded,
                                onPressed: () => _showDispatchDialog(context, provider, ticket?['id']),
                              ),
                            ],
                            if (statusStr == 'RESOLVED' || statusStr == 'IN_PROGRESS') ...[
                              const SizedBox(height: AppSpacing.sm),
                              AppButton(
                                text: '✅ Officially Close Incident',
                                icon: Icons.check_circle_rounded,
                                onPressed: () async {
                                  final ok = await provider.closeIncident(widget.incidentId);
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident Officially Closed!')));
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 6.5 FIELD PROGRESS & RESOLUTION EVIDENCE
                if (detail['progress_updates'] != null && (detail['progress_updates'] as List).isNotEmpty || detail['resolution_image_url'] != null) ...[
                  _buildSectionHeader('Crew Field Activity & Resolution Evidence', Icons.engineering_rounded),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          if (detail['resolution_image_url'] != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                                const SizedBox(width: AppSpacing.xs),
                                Text('Final Resolution Photo Evidence', style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: AppSpacing.borderRadiusMd,
                              child: Image.network(
                                (detail['resolution_image_url'] as String).startsWith('http')
                                    ? detail['resolution_image_url']
                                    : 'http://localhost:8000${detail['resolution_image_url']}',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (detail['progress_updates'] != null) ...[
                            Text('Field Updates Log', style: AppTypography.titleSmall),
                            const SizedBox(height: AppSpacing.xs),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: (detail['progress_updates'] as List).length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                              itemBuilder: (context, idx) {
                                final u = (detail['progress_updates'] as List)[idx];
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: AppSpacing.borderRadiusSm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(u['update_type'] ?? 'PROGRESS', style: AppTypography.labelSmall.copyWith(color: AppColors.roleCrew)),
                                          Text(u['created_at'].toString().substring(11, 16), style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                                        ],
                                      ),
                                      if (u['note'] != null) Text(u['note'], style: AppTypography.bodySmall),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],


                // 7. AUDIT TIMELINE
                _buildSectionHeader('Audit History & Lifecycle Timeline', Icons.history_rounded),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                    itemBuilder: (context, idx) {
                      final h = history[idx] as Map<String, dynamic>;
                      return Row(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          const Icon(Icons.timeline_rounded, color: AppColors.roleAuthority, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Text('${h['prev_status']} → ${h['new_status']}', style: AppTypography.titleSmall),
                                if (h['reason'] != null) Text(h['reason'], style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                Text('Actor: ${h['actor_role']}  |  ${h['created_at']}', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.roleAuthority, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: AppTypography.titleMedium),
      ],
    );
  }

  void _showRejectDialog(BuildContext context, AuthorityProvider provider) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Reject Incident #${widget.incidentId}', style: AppTypography.titleLarge),
        content: TextField(
          controller: reasonCtrl,
          style: AppTypography.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection (e.g. False alarm, invalid photo)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Reject',
            variant: AppButtonVariant.primary,
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.rejectIncident(widget.incidentId, reasonCtrl.text);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident Rejected.')));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAlertDialog(BuildContext context, AuthorityProvider provider) {
    final titleCtrl = TextEditingController(text: 'EMERGENCY HAZARD ALERT');
    final msgCtrl = TextEditingController(text: 'Area warning: Confirmed emergency hazard. Follow safety instructions.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Broadcast Emergency Area Alert', style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Alert Title')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Emergency Message')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          AppButton(
            text: 'Broadcast',
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.createAlert(incidentId: widget.incidentId, title: titleCtrl.text, message: msgCtrl.text);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Alert Broadcasted to Area!')));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, AuthorityProvider provider, int? existingTicketId) async {
    if (existingTicketId == null) {
      // Auto-create council ticket first if missing
      await provider.createCouncilTicket(incidentId: widget.incidentId);
      final updatedDetail = provider.selectedIncidentDetail;
      existingTicketId = updatedDetail?['council_ticket']?['id'];
    }

    final crews = provider.availableCrews;
    if (crews.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active CREW users available.')));
      }
      return;
    }

    int selectedCrewId = crews.first['id'];
    final instrCtrl = TextEditingController(text: 'Immediate dispatch to incident location. Proceed with emergency equipment.');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Dispatch Emergency Crew', style: AppTypography.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text('Select Available Crew:', style: AppTypography.labelMedium),
              DropdownButton<int>(
                value: selectedCrewId,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                items: crews.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text('${c['full_name']} (${c['email']})', style: AppTypography.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCrewId = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: instrCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Crew Instructions'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            AppButton(
              text: 'Dispatch Crew',
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await provider.dispatchCrew(
                  incidentId: widget.incidentId,
                  ticketId: existingTicketId!,
                  assignedCrewId: selectedCrewId,
                  instructions: instrCtrl.text,
                );
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crew Dispatched Successfully!')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
