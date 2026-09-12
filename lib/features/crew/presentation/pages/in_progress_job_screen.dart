import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/crew_provider.dart';

class InProgressJobScreen extends StatefulWidget {
  final int assignmentId;

  const InProgressJobScreen({super.key, required this.assignmentId});

  @override
  State<InProgressJobScreen> createState() => _InProgressJobScreenState();
}

class _InProgressJobScreenState extends State<InProgressJobScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CrewProvider>(context, listen: false)
          .fetchAssignmentDetail(widget.assignmentId);
    });
  }

  void _showAddProgressDialog() {
    final noteController = TextEditingController();
    XFile? selectedFile;
    Uint8List? webBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text('Submit Progress Update', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter progress update note (e.g. Cleared 50% debris...)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Image Selection
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_a_photo_rounded),
                        label: const Text('Add Progress Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: () async {
                          final file = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (file != null) {
                            if (kIsWeb) {
                              final bytes = await file.readAsBytes();
                              setModalState(() {
                                selectedFile = file;
                                webBytes = bytes;
                              });
                            } else {
                              setModalState(() {
                                selectedFile = file;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (selectedFile != null)
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                            SizedBox(width: 4),
                            Text('Photo Selected', style: TextStyle(color: AppColors.success)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppButton(
                    text: 'SUBMIT PROGRESS UPDATE',
                    onPressed: () async {
                      final noteText = noteController.text.trim();
                      File? fileToUpload;
                      List<int>? bytesToUpload;
                      String? filename;

                      if (selectedFile != null) {
                        filename = selectedFile!.name;
                        if (!kIsWeb) {
                          fileToUpload = File(selectedFile!.path);
                        } else {
                          bytesToUpload = webBytes;
                        }
                      }

                      Navigator.pop(ctx);

                      final provider = Provider.of<CrewProvider>(context, listen: false);
                      final ok = await provider.addProgressUpdate(
                        widget.assignmentId,
                        note: noteText,
                        imageFile: fileToUpload,
                        imageBytes: bytesToUpload,
                        filename: filename,
                      );

                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Progress update posted successfully!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCompleteJobDialog() {
    final noteController = TextEditingController();
    XFile? selectedFile;
    Uint8List? webBytes;
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Complete Job & Resolve Incident', style: AppTypography.titleLarge.copyWith(color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Resolution photo evidence is required by authorities.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter completion summary (e.g., Road reopened, hazard fully removed)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Resolution Photo Section
                  InkWell(
                    onTap: () async {
                      final file = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (file != null) {
                        if (kIsWeb) {
                          final bytes = await file.readAsBytes();
                          setModalState(() {
                            selectedFile = file;
                            webBytes = bytes;
                            validationError = null;
                          });
                        } else {
                          setModalState(() {
                            selectedFile = file;
                            validationError = null;
                          });
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: selectedFile != null
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.surfaceElevated,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: selectedFile != null ? AppColors.success : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedFile != null ? Icons.verified_rounded : Icons.camera_alt_rounded,
                            size: 36,
                            color: selectedFile != null ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            selectedFile != null
                                ? 'Resolution Evidence Photo Attached'
                                : 'TAKE RESOLUTION PHOTO (MANDATORY)',
                            style: AppTypography.titleSmall.copyWith(
                              color: selectedFile != null ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (validationError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(validationError!, style: const TextStyle(color: AppColors.error)),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  AppButton(
                    text: 'COMPLETE JOB & RESOLVE',
                    onPressed: () async {
                      if (selectedFile == null) {
                        setModalState(() {
                          validationError = 'Resolution photo is required to complete this job!';
                        });
                        return;
                      }

                      final noteText = noteController.text.trim();
                      File? fileToUpload;
                      List<int>? bytesToUpload;
                      final filename = selectedFile!.name;

                      if (!kIsWeb) {
                        fileToUpload = File(selectedFile!.path);
                      } else {
                        bytesToUpload = webBytes;
                      }

                      Navigator.pop(ctx);

                      final provider = Provider.of<CrewProvider>(context, listen: false);
                      final ok = await provider.completeJob(
                        widget.assignmentId,
                        note: noteText.isNotEmpty ? noteText : 'Hazard resolved on-site.',
                        imageFile: fileToUpload,
                        imageBytes: bytesToUpload,
                        filename: filename,
                      );

                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job Completed & Incident Marked as RESOLVED!')),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Active Job #${widget.assignmentId}', style: AppTypography.titleLarge),
      ),
      body: Consumer<CrewProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedAssignment == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = provider.selectedAssignment;
          if (job == null) {
            return const Center(child: Text('Job details unavailable'));
          }

          final inc = job.incident;

          return SingleChildScrollView(
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // In-Progress Banner
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.engineering_rounded, color: AppColors.warning, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(
                              'WORK IN PROGRESS',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.warning),
                            ),
                            Text(
                              'Started At: ${job.startedAt?.toLocal().toString().substring(0, 16) ?? "Recently"}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Operational Summary
                AppCard(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(inc?.hazardType.replaceAll('_', ' ') ?? 'HAZARD', style: AppTypography.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Text(inc?.description ?? '', style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(inc?.addressText ?? '${inc?.latitude}, ${inc?.longitude}', style: AppTypography.bodySmall)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Field Progress Updates Feed
                Text('Field Progress Feed', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.sm),

                if (job.progressUpdates.isEmpty)
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Center(
                        child: Text('No progress updates uploaded yet.', style: AppTypography.bodyMedium),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: job.progressUpdates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final update = job.progressUpdates[index];
                      return AppCard(
                        child: Padding(
                          padding: AppSpacing.paddingMd,
                          child: Column(
                            crossAxisAlignment: CrossAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    update.updateType,
                                    style: AppTypography.titleSmall.copyWith(
                                      color: update.updateType == 'RESOLUTION' ? AppColors.success : AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    update.createdAt.toLocal().toString().substring(11, 16),
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                              if (update.note != null && update.note!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(update.note!, style: AppTypography.bodyMedium),
                              ],
                              if (update.evidencePath != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                ClipRRect(
                                  borderRadius: AppSpacing.borderRadiusSm,
                                  child: Image.network(
                                    update.evidencePath!.startsWith('http')
                                        ? update.evidencePath!
                                        : 'http://localhost:8000${update.evidencePath}',
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: AppSpacing.xl),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'POST PROGRESS',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.add_a_photo_rounded,
                        onPressed: _showAddProgressDialog,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        text: 'COMPLETE JOB',
                        icon: Icons.check_circle_rounded,
                        onPressed: _showCompleteJobDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
