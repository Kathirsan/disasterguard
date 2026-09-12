import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../data/models/incident_model.dart';
import '../providers/incident_provider.dart';

class ReportDisasterPage extends StatefulWidget {
  final VoidCallback onReportSubmitted;

  const ReportDisasterPage({super.key, required this.onReportSubmitted});

  @override
  State<ReportDisasterPage> createState() => _ReportDisasterPageState();
}

class _ReportDisasterPageState extends State<ReportDisasterPage> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  HazardType _selectedHazard = HazardType.FLOOD;
  double _latitude = 6.9271; // Default coordinates (Colombo/City Center)
  double _longitude = 79.8612;
  bool _isGettingLocation = false;

  File? _selectedFile;
  Uint8List? _selectedBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _getGpsLocation() {
    setState(() {
      _isGettingLocation = true;
    });

    // Simulate GPS positioning or acquire device location
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _latitude = 6.9271 + (DateTime.now().second % 10) * 0.005;
        _longitude = 79.8612 + (DateTime.now().second % 10) * 0.005;
        _locationController.text =
            'City Sector Center (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})';
        _isGettingLocation = false;
      });
    });
  }

  void _selectMockPhoto() {
    setState(() {
      // Simulate photo evidence capture
      _selectedFileName = 'disaster_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _selectedBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);
    });
  }

  void _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final provider = Provider.of<IncidentProvider>(context, listen: false);
    provider.clearError();

    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the hazard/disaster.')),
      );
      return;
    }

    final success = await provider.submitReport(
      hazardType: _selectedHazard,
      description: desc,
      latitude: _latitude,
      longitude: _longitude,
      addressText: _locationController.text.isNotEmpty ? _locationController.text : 'Disaster Area',
      imageFile: _selectedFile,
      imageBytes: _selectedBytes,
      filename: _selectedFileName,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disaster report submitted successfully! Status: SUBMITTED'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onReportSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Report a Disaster', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onReportSubmitted,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAlignment.stretch,
              children: [
                if (provider.errorMessage != null) ...[
                  AppBanner(message: provider.errorMessage!, type: AppBannerType.error),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 1. Photo Capture Box
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text('1. EVIDENCE PHOTOGRAPH', style: AppTypography.labelSmall.copyWith(letterSpacing: 1)),
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: _selectMockPhoto,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppSpacing.borderRadiusMd,
                            border: Border.all(
                              color: _selectedFileName != null ? AppColors.success : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: _selectedFileName != null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 42),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Evidence Photo Attached', style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
                                    Text(_selectedFileName!, style: AppTypography.labelSmall),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 38),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Tap to Capture / Attach Photo', style: AppTypography.titleMedium),
                                    Text('Supports JPEG, PNG up to 10MB', style: AppTypography.labelSmall),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Hazard Type Selector
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text('2. HAZARD TYPE', style: AppTypography.labelSmall.copyWith(letterSpacing: 1)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: HazardType.values.map((type) {
                          final isSelected = _selectedHazard == type;
                          return ChoiceChip(
                            avatar: Icon(type.icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
                            label: Text(type.displayLabel),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceElevated,
                            labelStyle: AppTypography.labelSmall.copyWith(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedHazard = type;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Location Acquisition
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text('3. GPS LOCATION', style: AppTypography.labelSmall.copyWith(letterSpacing: 1)),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Coordinates / Area',
                              hint: 'Tap Acquire Location...',
                              controller: _locationController,
                              prefixIcon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceElevated,
                                  foregroundColor: AppColors.accentCyan,
                                  side: const BorderSide(color: AppColors.accentCyan),
                                ),
                                icon: _isGettingLocation
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.my_location_rounded, size: 18),
                                label: const Text('GPS'),
                                onPressed: _isGettingLocation ? null : _getGpsLocation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Description Input
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text('4. HAZARD DESCRIPTION', style: AppTypography.labelSmall.copyWith(letterSpacing: 1)),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: 'Details of the Incident',
                        hint: 'Describe severity, water depth, blocked lanes, or immediate risks...',
                        controller: _descriptionController,
                        prefixIcon: Icons.description_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                AppButton(
                  text: 'Submit Disaster Report',
                  isLoading: provider.isSubmitting,
                  icon: Icons.send_rounded,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
