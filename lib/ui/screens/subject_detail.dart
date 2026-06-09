import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../services/attendance_service.dart';
import '../theme.dart';
import '../widgets/three_number_bar.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  DateTime _currentMonth = DateTime.now();
  late TextEditingController _noteController;
  bool _isEditingNote = false;
  DateTime? _lastSelectedDate;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Smart fallback subject selection
    final subject =
        appState.selectedSubject ??
        appState.lastSelectedSubject ??
        (appState.subjects.isNotEmpty ? appState.subjects.first : null);

    if (subject == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64.0,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No subjects registered yet!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Please register a subject from the Dashboard to begin tracking attendance.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final stats = appState.getStatsForSubject(subject);
    final isSafe = stats.attendancePercentage >= appState.globalTargetStandard;

    // Filter sessions for currently selected subject & date
    final sessions = appState.sessions
        .where((s) => s.subjectId == subject.id)
        .toList();
    final selectedDateOnly = DateTime(
      appState.selectedDate.year,
      appState.selectedDate.month,
      appState.selectedDate.day,
    );

    ClassSession? activeSession;
    for (final s in sessions) {
      if (s.sessionDate.year == selectedDateOnly.year &&
          s.sessionDate.month == selectedDateOnly.month &&
          s.sessionDate.day == selectedDateOnly.day) {
        activeSession = s;
        break;
      }
    }

    final List<ProofImage> activeProofs = activeSession != null
        ? appState.getProofsForSession(activeSession.id)
        : [];

    if (_lastSelectedDate != selectedDateOnly) {
      _lastSelectedDate = selectedDateOnly;
      _isEditingNote = false;
      _noteController.text = activeSession?.notes ?? '';
    }


    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek top row with back button (if selected explicitly), subject info and premium percentage badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (appState.selectedSubject != null) ...[
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 18.0,
                        ),
                        onPressed: () => appState.setSelectedSubject(null),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${subject.code} • Target: ${appState.globalTargetStandard.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              // Beautiful Premium Attendance Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: isSafe
                      ? AppTheme.success.withOpacity(0.08)
                      : AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSafe
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.error.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.attendancePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isSafe ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.w900,
                        fontSize: 18.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isSafe ? 'SECURE' : 'AT RISK',
                      style: TextStyle(
                        color: isSafe ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // 2. Beautiful Attendance Progress Overview Card (Spans 100% full width)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 14.0,
            ),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Attendance Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                ThreeNumberBar(
                  totalPlanned: subject.plannedTotalClasses,
                  conducted: stats.conductedCount,
                  attended: stats.attendedCount,
                  isSafe: isSafe,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // 3. Main Responsive Spacing Grid Layout (Calendar and Controls)
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isLargeLayout = constraints.maxWidth > 700;

              final calendarWidget = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    _buildCalendarHeader(),
                    const SizedBox(height: 10.0),
                    _buildCalendarGrid(appState, sessions),
                  ],
                ),
              );

              final rightPanelWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSessionControlCard(
                    context,
                    appState,
                    subject,
                    activeSession,
                  ),
                  const SizedBox(height: 8.0),
                  _buildProofsCard(
                    context,
                    appState,
                    subject,
                    activeSession,
                    activeProofs,
                  ),
                  const SizedBox(height: 8.0),
                  _buildNotesCard(
                    context,
                    appState,
                    subject,
                    activeSession,
                  ),
                ],
              );


              if (isLargeLayout) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: calendarWidget),
                    const SizedBox(width: 24.0),
                    Expanded(flex: 2, child: rightPanelWidget),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    calendarWidget,
                    const SizedBox(height: 8.0),
                    rightPanelWidget,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 8.0),
          // 4. Historical Audit logs list
          _buildAuditLogsSection(context, appState, activeSession),
        ],
      ),
    );
  }

  // --- INTERACTIVE CALENDAR BUILDING ROUTINES ---

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: AppTheme.textPrimary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
              }),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(AppState appState, List<ClassSession> sessions) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    // Week headers
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map(
                (d) => SizedBox(
                  width: 36.0,
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),
          itemCount: daysInMonth + firstDayOffset,
          itemBuilder: (context, index) {
            if (index < firstDayOffset) {
              return const SizedBox();
            }

            final day = index - firstDayOffset + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final bool isSelected = DateUtils.isSameDay(
              date,
              appState.selectedDate,
            );
            final bool isToday = DateUtils.isSameDay(date, DateTime.now());

            // Search for attendance log on this day
            String attendanceState = 'none';
            for (final s in sessions) {
              if (s.sessionDate.year == date.year &&
                  s.sessionDate.month == date.month &&
                  s.sessionDate.day == date.day) {
                if (s.status == 'conducted') {
                  attendanceState = s.attendanceStatus;
                }
                break;
              }
            }

            Color tileBg = AppTheme.transparent;
            Color textColor = AppTheme.textPrimary;
            Border? tileBorder;

            if (attendanceState == 'present') {
              tileBg = AppTheme.successLight;
              textColor = AppTheme.success;
            } else if (attendanceState == 'absent') {
              tileBg = AppTheme.errorLight;
              textColor = AppTheme.error;
            }

            if (isSelected) {
              tileBorder = Border.all(color: AppTheme.white, width: 1.5);
              if (attendanceState == 'none') {
                tileBg = AppTheme.primary;
                textColor = AppTheme.white;
              }
            } else if (isToday) {
              tileBorder = Border.all(color: AppTheme.primary, width: 1.5);
            }

            return GestureDetector(
              onTap: () => appState.setSelectedDate(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(12.0),
                  border: tileBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: (isSelected || isToday)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14.0,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- CONTROLS CARD AND UPLOAD ENGINE ---

  void _showAttendanceOptionsDialog(
    BuildContext context,
    AppState appState,
    Subject subject,
    String currentStatus,
  ) {
    final String oppositeStatus = currentStatus == 'Present'
        ? 'Absent'
        : 'Present';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          surfaceTintColor: AppTheme.transparent,
          title: Text(
            'Update Attendance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Would you like to mark this session as $oppositeStatus or unmark it completely?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                await appState.markAttendance(
                  subjectId: subject.id,
                  date: appState.selectedDate,
                  status: 'unknown',
                  sessionType: 'lecture',
                  reason: 'Manually unmarked attendance status',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Unmark',
                style: TextStyle(color: AppTheme.warning),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await appState.markAttendance(
                  subjectId: subject.id,
                  date: appState.selectedDate,
                  status: oppositeStatus.toLowerCase(),
                  sessionType: 'lecture',
                  reason:
                      'Changed attendance status from $currentStatus to $oppositeStatus',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: oppositeStatus == 'Present'
                    ? AppTheme.success
                    : AppTheme.error,
                foregroundColor: AppTheme.white,
              ),
              child: Text('Mark $oppositeStatus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionControlCard(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? activeSession,
  ) {
    final status = activeSession?.attendanceStatus ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(appState.selectedDate),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Mark attendance state for this session:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16.0),
          if (status == 'unknown')
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceButton(
                    context,
                    isActive: false,
                    activeColor: AppTheme.success,
                    icon: Icons.check_circle_rounded,
                    label: 'Present',
                    onTap: () => appState.markAttendance(
                      subjectId: subject.id,
                      date: appState.selectedDate,
                      status: 'present',
                      sessionType: 'lecture',
                      reason: 'Manually logged Present',
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildAttendanceButton(
                    context,
                    isActive: false,
                    activeColor: AppTheme.error,
                    icon: Icons.cancel_rounded,
                    label: 'Absent',
                    onTap: () => appState.markAttendance(
                      subjectId: subject.id,
                      date: appState.selectedDate,
                      status: 'absent',
                      sessionType: 'lecture',
                      reason: 'Manually logged Absent',
                    ),
                  ),
                ),
              ],
            )
          else if (status == 'present')
            _buildAttendanceButton(
              context,
              isActive: true,
              activeColor: AppTheme.success,
              icon: Icons.check_circle_rounded,
              label: 'Present',
              onTap: () => _showAttendanceOptionsDialog(
                context,
                appState,
                subject,
                'Present',
              ),
            )
          else
            _buildAttendanceButton(
              context,
              isActive: true,
              activeColor: AppTheme.error,
              icon: Icons.cancel_rounded,
              label: 'Absent',
              onTap: () => _showAttendanceOptionsDialog(
                context,
                appState,
                subject,
                'Absent',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(
    BuildContext context, {
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        height: 50.0,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : AppTheme.transparent,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.neutralBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : AppTheme.textSecondary,
              size: 18.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofsCard(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? activeSession,
    List<ProofImage> proofs,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Photo Proofs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${proofs.length}/3 Limit',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          if (proofs.isEmpty)
            _buildEmptyProofs(context)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: proofs.length,
              itemBuilder: (context, index) {
                final proof = proofs[index];
                return _buildProofTile(context, appState, activeSession, proof);
              },
            ),

          if (proofs.length < 3) ...[
            const SizedBox(height: 16.0),
            TextButton.icon(
              onPressed: () => _uploadProofForSession(
                context,
                appState,
                subject,
                activeSession,
              ),
              icon: Icon(Icons.add_a_photo_rounded, size: 18.0, color: AppTheme.primary),
              label: Text('Add Session Proof Image', style: TextStyle(color: AppTheme.primary)),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 44.0),
                backgroundColor: AppTheme.primaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showClearConfirmationDialog(
    BuildContext context,
    AppState appState,
    Subject subject,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          surfaceTintColor: AppTheme.transparent,
          title: Text(
            'Clear Lecture Note?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this lecture note? This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await appState.updateSessionNotes(
                  subjectId: subject.id,
                  date: appState.selectedDate,
                  notes: null,
                );
                setState(() {
                  _isEditingNote = false;
                  _noteController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotesCard(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? activeSession,
  ) {
    final noteText = activeSession?.notes;
    final hasNote = noteText != null && noteText.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lecture Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!_isEditingNote && hasNote)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18.0, color: AppTheme.primary),
                  onPressed: () {
                    setState(() {
                      _isEditingNote = true;
                      _noteController.text = noteText;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          if (_isEditingNote) ...[
            TextField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 4,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.0),
              decoration: InputDecoration(
                hintText: 'Add notes for this class (e.g. topics covered, homework, exam syllabus)...',
                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.backgroundEnd,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppTheme.neutralBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.all(12.0),
                counterStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 10.0),
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasNote) ...[
                  TextButton(
                    onPressed: () => _showClearConfirmationDialog(context, appState, subject),
                    child: Text('Clear', style: TextStyle(color: AppTheme.error)),
                  ),
                  const SizedBox(width: 8.0),
                ],
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingNote = false;
                      _noteController.text = noteText ?? '';
                    });
                  },
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () async {
                    await appState.updateSessionNotes(
                      subjectId: subject.id,
                      date: appState.selectedDate,
                      notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                    );
                    setState(() {
                      _isEditingNote = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    minimumSize: const Size(60, 36),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            if (hasNote)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundEnd,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppTheme.neutralBorder.withOpacity(0.5)),
                ),
                child: Text(
                  noteText,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.0,
                    height: 1.4,
                  ),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.neutralBorder.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      color: AppTheme.textSecondary,
                      size: 36.0,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'No lecture notes added',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditingNote = true;
                    _noteController.clear();
                  });
                },
                icon: Icon(Icons.add_rounded, size: 18.0, color: AppTheme.primary),
                label: Text('Add Lecture Note', style: TextStyle(color: AppTheme.primary)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44.0),
                  backgroundColor: AppTheme.primaryLight,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyProofs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.neutralBorder.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: AppTheme.textSecondary,
            size: 36.0,
          ),
          SizedBox(height: 8.0),
          Text(
            'No proof images attached',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofTile(
    BuildContext context,
    AppState appState,
    ClassSession? session,
    ProofImage proof,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundEnd,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.neutralBorder.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Material(
          color: AppTheme.transparent,
          child: InkWell(
            onTap: () => _viewFullProofImage(context, appState, proof),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Thumbnail loader
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 50.0,
                      height: 50.0,
                      color: AppTheme.neutralBorder,
                      child: FutureBuilder<Uint8List?>(
                        future: appState.loadProofThumbnail(
                          proof.thumbnailPath,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return Icon(
                            Icons.image,
                            color: AppTheme.textSecondary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'MMM d, yyyy • h:mm a',
                          ).format(proof.captureTimestamp),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Source: ${proof.source[0].toUpperCase()}${proof.source.substring(1)}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 11.0,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Delete proof trigger (triggers warning prompt)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error,
                      size: 20.0,
                    ),
                    onPressed: () => _confirmProofDeletion(
                      context,
                      appState,
                      session,
                      proof,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _viewFullProofImage(
    BuildContext context,
    AppState appState,
    ProofImage proof,
  ) {
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.white,
                                    ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                DateFormat(
                                  'MMMM d, yyyy • h:mm a',
                                ).format(proof.captureTimestamp),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppTheme.white,
                          ),
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
                          future: appState.loadProofImage(
                            proof.filePathEncrypted,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                height: 200.0,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
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
                                      Icon(
                                        Icons.broken_image_rounded,
                                        color: AppTheme.error,
                                        size: 48.0,
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        'Failed to load decrypted proof image',
                                      ),
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
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              ),
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
                        _buildDetailBadge(
                          Icons.source_rounded,
                          'Source: ${proof.source.toUpperCase()}',
                        ),
                        if (proof.latitude != null && proof.longitude != null)
                          _buildDetailBadge(
                            Icons.location_on_rounded,
                            'GPS Active',
                          ),
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

  // --- LOGS LIST ---

  Widget _buildAuditLogsSection(
    BuildContext context,
    AppState appState,
    ClassSession? session,
  ) {
    if (session == null) return const SizedBox();

    final auditLogs = appState.logs
        .where((l) => l.sessionId == session.id)
        .toList();

    // Sort logs descending so the latest events appear on top
    auditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Group logs by formatted date string
    final List<MapEntry<String, List<AttendanceAuditLog>>> groupedLogs = [];
    for (final log in auditLogs) {
      final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(log.timestamp);
      final existingIndex = groupedLogs.indexWhere((e) => e.key == dateStr);
      if (existingIndex == -1) {
        groupedLogs.add(MapEntry(dateStr, [log]));
      } else {
        groupedLogs[existingIndex].value.add(log);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Session Edit History (Audit Trail) ↓',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          if (groupedLogs.isEmpty)
            Text(
              'No modifications logged for this session yet.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.0),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedLogs.length,
              itemBuilder: (context, dateIndex) {
                final entry = groupedLogs[dateIndex];
                final dateStr = entry.key;
                final logs = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateIndex > 0) const SizedBox(height: 14.0),
                    // Date Header showing date performed
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.primary.withOpacity(0.7),
                          size: 13.0,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    // Indented messages under a date just like code
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: logs.map((log) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: AppTheme.primary.withOpacity(0.5),
                                  size: 5.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    '[${DateFormat('HH:mm').format(log.timestamp)}] ${log.reason} (${log.oldValue} → ${log.newValue})',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- ACTIONS EXECUTIONS ---

  void _uploadProofForSession(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? session,
  ) async {
    if (kIsWeb) {
      // Web: use file_picker
      await _pickProofFromGallery(context, appState, subject, session);
    } else {
      // Mobile: show camera/gallery bottom sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Session Proof',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.primary,
                    ),
                    title: Text(
                      'Take Photo',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _captureProofFromCamera(
                        context,
                        appState,
                        subject,
                        session,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.primary,
                    ),
                    title: Text(
                      'Choose from Gallery',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickProofFromGallery(
                        context,
                        appState,
                        subject,
                        session,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _captureProofFromCamera(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? session,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _saveProofBytes(
          context,
          appState,
          subject,
          session,
          bytes,
          'camera',
        );
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

  Future<void> _pickProofFromGallery(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? session,
  ) async {
    try {
      Uint8List? bytes;
      DateTime? captureDate;

      if (kIsWeb) {
        // Fallback for Web using file_picker
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );

        if (result != null && result.files.first.bytes != null) {
          bytes = result.files.first.bytes!;
          captureDate = null;
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
          bytes = await asset.originBytes;
          captureDate = asset.createDateTime;
        } else {
          return; // User cancelled
        }
      }

      if (bytes != null) {
        await _saveProofBytes(
          context,
          appState,
          subject,
          session,
          bytes,
          'gallery',
          captureDate: captureDate,
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

  Future<void> _saveProofBytes(
    BuildContext context,
    AppState appState,
    Subject subject,
    ClassSession? session,
    Uint8List bytes,
    String source, {
    DateTime? captureDate,
  }) async {
    final activeSess =
        session ??
        await AttendanceService().createOrGetSession(
          subjectId: subject.id,
          date: appState.selectedDate,
        );
    await appState.captureAndSaveProof(
      rawBytes: bytes,
      source: source,
      subjectId: subject.id,
      sessionId: activeSess.id,
      captureDate: captureDate,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session proof attached and auto-marked Present!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _confirmProofDeletion(
    BuildContext context,
    AppState appState,
    ClassSession? session,
    ProofImage proof,
  ) {
    if (session == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          surfaceTintColor: AppTheme.transparent,
          title: Text(
            'Delete Proof Image?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Deleting this image will detach it from the class session. '
            'How would you like to update the attendance status for this class?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await appState.removeProofFromSession(
                  proofId: proof.id,
                  sessionId: session.id,
                  userDecision: 'mark_present', // Mark Present override
                );
                Navigator.pop(context);
              },
              child: Text(
                'Mark Present',
                style: TextStyle(color: AppTheme.success),
              ),
            ),
            TextButton(
              onPressed: () async {
                await appState.removeProofFromSession(
                  proofId: proof.id,
                  sessionId: session.id,
                  userDecision: 'mark_absent', // Mark Absent
                );
                Navigator.pop(context);
              },
              child: Text(
                'Mark Absent',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                await appState.removeProofFromSession(
                  proofId: proof.id,
                  sessionId: session.id,
                  userDecision: 'mark_unknown', // Mark Unknown
                );
                Navigator.pop(context);
              },
              child: Text(
                'Unmark',
                style: TextStyle(color: AppTheme.warning),
              ),
            ),
          ],
        );
      },
    );
  }
}