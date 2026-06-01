import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../theme.dart';
import '../widgets/three_number_bar.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _sortByWorst = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final anonymousCount = appState.anonymousProofs.length;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 380;

    // Derived dashboard calculations
    int warningSubjects = 0;
    for (final s in appState.subjects) {
      if (appState.getStatsForSubject(s).attendancePercentage <
          s.thresholdPercent) {
        warningSubjects++;
      }
    }

    // Sort subjects worst first if sorting enabled
    List<Subject> subjects = List.from(appState.subjects);
    if (_sortByWorst) {
      subjects.sort((a, b) {
        final pctA = appState.getStatsForSubject(a).attendancePercentage;
        final pctB = appState.getStatsForSubject(b).attendancePercentage;
        return pctA.compareTo(pctB);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Matching the mock UI layout)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showDeveloperConsole(context, appState),
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: AppTheme.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: AppTheme.primary,
                    size: 28.0,
                  ),
                  onPressed: () => _showAddSubjectDialog(context, appState),
                  tooltip: 'Add New Subject',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8.0),
                ),
              ],
            ),
            const SizedBox(height: 32.0),

            // 2. Summary Metric Cards — always 2x2 grid with dynamic aspect ratio
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              mainAxisExtent: 95.0,
              children: [
                _buildMetricCard(
                  context,
                  'Total Subjects',
                  '${appState.subjects.length}',
                  'Active Term',
                  Icons.school_rounded,
                  AppTheme.primary,
                ),
                _buildMetricCard(
                  context,
                  'At Risk (<${appState.globalTargetStandard.toStringAsFixed(0)}%)',
                  '$warningSubjects',
                  _sortByWorst
                      ? 'Sorted by Worst First'
                      : (warningSubjects > 0
                            ? 'Urgent attention'
                            : 'All clear'),
                  Icons.warning_amber_rounded,
                  warningSubjects > 0 ? AppTheme.error : AppTheme.success,
                  onTap: () {
                    setState(() {
                      _sortByWorst = !_sortByWorst;
                    });
                  },
                  isActive: _sortByWorst,
                ),
                _buildMetricCard(
                  context,
                  'Anonymous Proofs',
                  '$anonymousCount',
                  'Awaiting assignment',
                  Icons.mark_as_unread_rounded,
                  AppTheme.warning,
                  onTap: () {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!(2);
                    }
                  },
                ),
                _buildMetricCard(
                  context,
                  'Target Standard',
                  '${appState.globalTargetStandard.toStringAsFixed(0)}%',
                  'Minimum safe limit',
                  Icons.check_circle_outline_rounded,
                  AppTheme.success,
                  onLongPress: () =>
                      _showTargetStandardDialog(context, appState),
                ),
              ],
            ),
            const SizedBox(height: 32.0),

            // 3. Subjects list header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Subjects',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_sortByWorst) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                color: AppTheme.error,
                                size: 10.0,
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                'Worst First',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  '${subjects.length} Total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 4. Grid of Subject Cards with dynamic mainAxisExtent to avoid overflow
            if (subjects.isEmpty)
              _buildEmptyState(context, appState)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400.0,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  mainAxisExtent: screenWidth < 360
                      ? 210.0
                      : (screenWidth < 400 ? 200.0 : 190.0),
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _buildSubjectCard(context, appState, subject);
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _triggerQuickCapture(context, appState),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4.0,
        child: const Icon(Icons.photo_camera_rounded, size: 22.0),
      ),
      floatingActionButtonLocation: const _CustomRightFabLocation(),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isActive = false,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: AppTheme.cardDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(16.0),
          border: isActive
              ? Border.all(color: accentColor, width: 2.0)
              : Border.all(
                  color: AppTheme.neutralBorder.withOpacity(0.5),
                  width: 1.0,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: screenWidth < 380 ? 10.0 : 12.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 16.0),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth < 380 ? 20.0 : 24.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                    letterSpacing: -1,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Container(
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    AppState appState,
    Subject subject,
  ) {
    final stats = appState.getStatsForSubject(subject);
    final isSafe = stats.attendancePercentage >= subject.thresholdPercent;

    final parsedColor = Color(
      int.parse(subject.color.replaceFirst('#', 'FF'), radix: 16),
    );

    return InkWell(
      onTap: () {
        appState.setSelectedSubject(subject);
        // Quick callback redirection to index 1 (calendar screen)
      },
      onLongPress: () => _showEditSubjectDialog(context, appState, subject),
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: parsedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          subject.code,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
                // Attendance percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSafe ? AppTheme.successLight : AppTheme.errorLight,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '${stats.attendancePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isSafe ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Summary indicators
            Text(
              '${stats.attendedCount}/${stats.conductedCount} Conducted Present',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            // Custom Three-Number Bar Widget
            ThreeNumberBar(
              totalPlanned: subject.plannedTotalClasses,
              conducted: stats.conductedCount,
              attended: stats.attendedCount,
              isSafe: isSafe,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 64.0,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No subjects registered yet!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Begin tracking your academic attendance by setting up your primary subjects first.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            onPressed: () => _showAddSubjectDialog(context, appState),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Your First Subject'),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS INTERFACES ---

  void _triggerQuickCapture(BuildContext context, AppState appState) async {
    if (kIsWeb) {
      // Web: use file_picker since camera API is not available
      await _pickImageFromGallery(context, appState);
    } else {
      // Mobile: launch camera directly for zero-click Quick Capture
      await _captureFromCamera(context, appState);
    }
  }

  Future<void> _captureFromCamera(
    BuildContext context,
    AppState appState,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await appState.captureAndSaveProof(rawBytes: bytes, source: 'camera');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured and added to Anonymous Inbox!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery(
    BuildContext context,
    AppState appState,
  ) async {
    try {
      if (kIsWeb) {
        // Fallback for Web using file_picker
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );

        if (result != null && result.files.first.bytes != null) {
          final bytes = result.files.first.bytes!;
          await appState.captureAndSaveProof(
            rawBytes: bytes,
            source: 'gallery',
            captureDate: null,
          );
        }
      } else {
        // wechat_assets_picker for mobile queries the OS directly (MediaStore/PhotoKit)
        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: const AssetPickerConfig(
            maxAssets: 1,
            requestType: RequestType.image,
          ),
        );

        if (result != null && result.isNotEmpty) {
          final AssetEntity asset = result.first;
          final bytes = await asset.originBytes;

          if (bytes != null) {
            await appState.captureAndSaveProof(
              rawBytes: bytes,
              source: 'gallery',
              captureDate: asset.createDateTime,
            );
          }
        } else {
          // User cancelled
          return;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo proof added to Anonymous Inbox!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAddSubjectDialog(BuildContext context, AppState appState) {
    final formKey = GlobalKey<FormState>();
    final FocusNode nameFocus = FocusNode();
    final FocusNode codeFocus = FocusNode();
    final FocusNode plannedFocus = FocusNode();
    String name = '';
    String code = '';
    int planned = 30;
    String selectedHexColor = '#3B3EAC';
    String selectedIcon = 'book';

    final List<String> availableColors = [
      '#3B3EAC', // Deep Indigo
      '#F44336', // Bright Red
      '#4CAF50', // Emerald Green
      '#FF9800', // Orange
      '#9C27B0', // Purple
      '#00BCD4', // Cyan
    ];

    Future<void> submit() async {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        await appState.addSubject(
          name: name,
          code: code,
          color: selectedHexColor,
          icon: selectedIcon,
          plannedTotalClasses: planned,
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              surfaceTintColor: AppTheme.transparent,
              title: const Text(
                'Register New Subject',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        focusNode: nameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Mathematics',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(codeFocus),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Name required' : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        focusNode: codeFocus,
                        decoration: const InputDecoration(
                          labelText: 'Subject Code',
                          hintText: 'e.g. MATH-101',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(plannedFocus),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Code required' : null,
                        onSaved: (v) => code = v!,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        focusNode: plannedFocus,
                        decoration: const InputDecoration(
                          labelText: 'Planned Classes (Term)',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: '30',
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => submit(),
                        validator: (v) => int.tryParse(v ?? '') == null
                            ? 'Enter valid number'
                            : null,
                        onSaved: (v) => planned = int.parse(v!),
                      ),
                      const SizedBox(height: 16.0),
                      // Colors grid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subject Color',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: availableColors.map((hex) {
                              final isSel = selectedHexColor == hex;
                              final col = Color(
                                int.parse(
                                  hex.replaceFirst('#', 'FF'),
                                  radix: 16,
                                ),
                              );
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedHexColor = hex),
                                child: Container(
                                  width: 32.0,
                                  height: 32.0,
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                    border: isSel
                                        ? Border.all(
                                            color: AppTheme.textPrimary,
                                            width: 2.0,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: const Text('Register'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameFocus.dispose();
      codeFocus.dispose();
      plannedFocus.dispose();
    });
  }

  void _showEditSubjectDialog(
    BuildContext context,
    AppState appState,
    Subject subject,
  ) {
    final formKey = GlobalKey<FormState>();
    final FocusNode nameFocus = FocusNode();
    final FocusNode codeFocus = FocusNode();
    final FocusNode plannedFocus = FocusNode();
    String name = subject.name;
    String code = subject.code;
    int planned = subject.plannedTotalClasses;
    String selectedHexColor = subject.color;
    String selectedIcon = subject.icon;

    final List<String> availableColors = [
      '#3B3EAC', // Deep Indigo
      '#F44336', // Bright Red
      '#4CAF50', // Emerald Green
      '#FF9800', // Orange
      '#9C27B0', // Purple
      '#00BCD4', // Cyan
    ];

    Future<void> submit() async {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        final updated = subject.copyWith(
          name: name,
          code: code,
          color: selectedHexColor,
          icon: selectedIcon,
          plannedTotalClasses: planned,
        );
        await appState.updateSubject(updated);
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              surfaceTintColor: AppTheme.transparent,
              title: const Text(
                'Edit Subject Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        focusNode: nameFocus,
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(codeFocus),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Name required' : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        focusNode: codeFocus,
                        initialValue: code,
                        decoration: const InputDecoration(
                          labelText: 'Subject Code',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(plannedFocus),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Code required' : null,
                        onSaved: (v) => code = v!,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        focusNode: plannedFocus,
                        initialValue: planned.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Planned Classes (Term)',
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => submit(),
                        validator: (v) => int.tryParse(v ?? '') == null
                            ? 'Enter valid number'
                            : null,
                        onSaved: (v) => planned = int.parse(v!),
                      ),
                      const SizedBox(height: 16.0),
                      // Colors grid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subject Color',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: availableColors.map((hex) {
                              final isSel = selectedHexColor == hex;
                              final col = Color(
                                int.parse(
                                  hex.replaceFirst('#', 'FF'),
                                  radix: 16,
                                ),
                              );
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedHexColor = hex),
                                child: Container(
                                  width: 32.0,
                                  height: 32.0,
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                    border: isSel
                                        ? Border.all(
                                            color: AppTheme.textPrimary,
                                            width: 2.0,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (childContext) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        surfaceTintColor: AppTheme.transparent,
                        title: const Text(
                          'Delete Subject?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete "$name"? All its attendance history and proofs will be detached/deleted permanently.',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(childContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            onPressed: () async {
                              await appState.deleteSubject(subject.id);
                              Navigator.pop(childContext); // Close confirmation
                              Navigator.pop(context); // Close edit dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Subject successfully deleted.',
                                  ),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(onPressed: submit, child: const Text('Save')),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameFocus.dispose();
      codeFocus.dispose();
      plannedFocus.dispose();
    });
  }

  void _showDeveloperConsole(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final String allLogsText = appState.devLogs.join('\n');

            return Dialog(
              backgroundColor: AppTheme.transparent,
              insetPadding: const EdgeInsets.all(16.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark, // Dark VS Code terminal color
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: AppTheme.greyDark, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor.withOpacity(0.5),
                      blurRadius: 24.0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Terminal Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarker,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20.0),
                        ),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.greyDark),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Terminal Window controls mockup (Mac OS style)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppTheme.windowButtonRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppTheme.windowButtonYellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppTheme.windowButtonGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.terminal_rounded,
                                color: AppTheme.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Developer Console Logs',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.grey,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Console Toolbar Tab Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      color: AppTheme.surfaceSidebar,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Active Tab Mockup
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: AppTheme.greyDark),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.analytics_rounded,
                                  color: AppTheme.snippetKeyword,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'dev_activity.log',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 12.0,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Toolbar buttons
                          Row(
                            children: [
                              // Copy Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: allLogsText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'All logs copied to clipboard!',
                                      ),
                                      backgroundColor: AppTheme.success,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.copy_all_rounded,
                                  size: 14.0,
                                ),
                                label: const Text('Copy Logs'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF0E639C,
                                  ), // VS Code Blue
                                  foregroundColor: AppTheme.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              // Clear Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  appState.clearDevLogs();
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Console logs cleared.'),
                                      backgroundColor: AppTheme.textSecondary,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  size: 14.0,
                                ),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: BorderSide(color: AppTheme.grey),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Code block
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        color: AppTheme.surfaceDark,
                        child: appState.devLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  '// No events logged yet. Perform some actions in the app!',
                                  style: TextStyle(
                                    color: AppTheme.grey,
                                    fontFamily: 'monospace',
                                    fontSize: 13.0,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: SelectableText(
                                  allLogsText,
                                  style: const TextStyle(
                                    color: Color(
                                      0xFFD4D4D4,
                                    ), // Soft light grey code color
                                    fontFamily: 'monospace',
                                    fontSize: 12.0,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTargetStandardDialog(BuildContext context, AppState appState) {
    double localStandard = appState.globalTargetStandard;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              surfaceTintColor: AppTheme.transparent,
              title: const Text(
                'Change Target Standard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Adjust the default target attendance percentage. This will automatically update all existing subjects to use this threshold as their minimum safe limit.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    '${localStandard.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 48.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Slider(
                        value: localStandard,
                        min: 50.0,
                        max: 100.0,
                        divisions: 50,
                        activeColor: AppTheme.primary,
                        inactiveColor: AppTheme.primaryLight,
                        label: '${localStandard.toStringAsFixed(0)}%',
                        onChanged: (val) {
                          setState(() {
                            localStandard = val;
                          });
                        },
                      ),
                      // Dynamic visual dot on the track at exactly 75% (center of 50-100 range)
                      IgnorePointer(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              color: AppTheme.white.withOpacity(
                                localStandard == 75.0 ? 0.0 : 0.8,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowColor.withOpacity(
                                    localStandard == 75.0 ? 0.0 : 0.3,
                                  ),
                                  blurRadius: 2.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '50%',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              localStandard = 75.0;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5.0),
                              const Text(
                                '75% (Default)',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '100%',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await appState.updateGlobalTargetStandard(localStandard);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Target Standard updated to ${localStandard.toStringAsFixed(0)}%!',
                          ),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Standard'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CustomRightFabLocation extends FloatingActionButtonLocation {
  const _CustomRightFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Position on the right side (16.0 pixels padding from the right edge)
    final double x =
        scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.minInsets.right -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;
    // Position exactly 10.0 pixels above the bottom edge of the scaffold
    final double y =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.minInsets.bottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        10.0;
    return Offset(x, y);
  }
}
