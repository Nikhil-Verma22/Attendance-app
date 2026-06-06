import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../theme.dart';
import '../../services/attendance_service.dart';

class AnonymousInboxScreen extends StatelessWidget {
  const AnonymousInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final anonymousProofs = appState.anonymousProofs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Console
          Text(
            'Anonymous Proof Inbox',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4.0),
          Text(
            'Unsorted photo captures awaiting subject assignment and date mapping.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32.0),

          // Render Grid or Empty state
          if (anonymousProofs.isEmpty)
            _buildEmptyInbox(context)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                mainAxisExtent: 220.0,
              ),
              itemCount: anonymousProofs.length,
              itemBuilder: (context, index) {
                final proof = anonymousProofs[index];
                return _buildAnonymousProofCard(context, appState, proof);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyInbox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.mark_as_unread_rounded,
            size: 64.0,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Your Inbox is Clean!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8.0),
          Text(
            'All photo proofs have been assigned to their respective class sessions.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousProofCard(
    BuildContext context, 
    AppState appState, 
    ProofImage proof
  ) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Proof Preview Header
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => _viewFullProofImage(context, appState, proof),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Decompressed Image Memory Decoder
                    FutureBuilder<Uint8List?>(
                      future: appState.loadProofImage(proof.filePathEncrypted),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return Image.memory(snapshot.data!, fit: BoxFit.cover);
                        }
                        return Container(
                          color: AppTheme.neutralBorder,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Metrics & Timestamps
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(proof.captureTimestamp),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showAssignWizard(context, appState, proof),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                          child: const Text('Assign', style: TextStyle(fontSize: 12.0)),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20.0),
                        onPressed: () => appState.deleteProofCompletely(proof),
                        tooltip: 'Delete Proof Permanently',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ASSIGNMENT WIZARD ---

  void _showAssignWizard(BuildContext context, AppState appState, ProofImage proof) {
    if (appState.subjects.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text('No Subjects Registered', style: TextStyle(color: AppTheme.textPrimary)),
          content: Text('You must register at least one subject in the dashboard before assigning proof images.', style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: AppTheme.primary))),
          ],
        ),
      );
      return;
    }

    Subject? selectedSubject = appState.subjects.first;
    DateTime selectedDate = proof.captureTimestamp;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              surfaceTintColor: AppTheme.transparent,
              title: Text('Assign Proof Image', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select target subject:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<Subject>(
                    initialValue: selectedSubject,
                    items: appState.subjects.map((sub) {
                      return DropdownMenuItem<Subject>(
                        value: sub,
                        child: Text('${sub.name} (${sub.code})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedSubject = val),
                  ),
                  const SizedBox(height: 16.0),
                  Text('Confirm session date:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8.0),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.neutralBorder),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: TextStyle(color: AppTheme.textPrimary)),
                          Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedSubject != null) {
                      // 1. Create or load session on the selected date
                      final session = await AttendanceService().createOrGetSession(
                        subjectId: selectedSubject!.id,
                        date: selectedDate,
                      );

                      // 2. Assign proof to session
                      await appState.assignProofToSession(
                        proofId: proof.id,
                        subjectId: selectedSubject!.id,
                        sessionId: session.id,
                        reason: 'Assigned anonymous proof from inbox',
                      );

                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Proof image successfully assigned to session!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewFullProofImage(BuildContext context, AppState appState, ProofImage proof) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.transparent,
          insetPadding: const EdgeInsets.all(16.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Large Image Viewer Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header metadata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                           child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proof Image',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.white,
                                    ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                DateFormat('MMMM d, yyyy • h:mm a').format(proof.captureTimestamp),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppTheme.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Image Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        color: AppTheme.neutralBorder.withOpacity(0.3),
                        child: FutureBuilder<Uint8List?>(
                          future: appState.loadProofImage(proof.filePathEncrypted),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return SizedBox(
                                height: 200.0,
                                child: Center(
                                  child: CircularProgressIndicator(color: AppTheme.primary),
                                ),
                              );
                            }
                            if (snapshot.hasError || snapshot.data == null) {
                              return SizedBox(
                                height: 200.0,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_rounded, color: AppTheme.error, size: 48.0),
                                      SizedBox(height: 8.0),
                                      Text('Failed to load decrypted proof image', style: TextStyle(color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Footer details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailBadge(Icons.source_rounded, 'Source: ${proof.source.toUpperCase()}'),
                        if (proof.latitude != null && proof.longitude != null)
                          _buildDetailBadge(Icons.location_on_rounded, 'GPS Active'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: AppTheme.primary),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget to place overlays inside Stack
class PositionPoint extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final Widget child;

  const PositionPoint({
    super.key,
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: child,
    );
  }
}