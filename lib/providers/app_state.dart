import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/attendance_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final StorageService _storageService = StorageService();

  double _globalTargetStandard = 75.0;
  double get globalTargetStandard => _globalTargetStandard;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Subject? _selectedSubject;
  Subject? _lastSelectedSubject;
  Subject? get selectedSubject => _selectedSubject;
  Subject? get lastSelectedSubject => _lastSelectedSubject;

  final List<String> _devLogs = [];
  List<String> get devLogs => List.unmodifiable(_devLogs);

  void logDevEvent(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logLine = '[$timestamp] $message';
    _devLogs.add(logLine);
    if (_devLogs.length > 1000) {
      _devLogs.removeAt(0);
    }
    notifyListeners();
  }

  void clearDevLogs() {
    _devLogs.clear();
    notifyListeners();
  }

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<Subject> get subjects => _attendanceService.subjects;
  List<ClassSession> get sessions => _attendanceService.sessions;
  List<ProofImage> get proofs => _attendanceService.proofs;
  List<AttendanceAuditLog> get logs => _attendanceService.logs;

  /// Retrieves only unassigned proofs for display in the Anonymous Inbox console
  List<ProofImage> get anonymousProofs {
    return _attendanceService.proofs.where((p) => p.sessionId == null).toList();
  }

  /// Load and sync all saved preferences and historical data
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _attendanceService.loadData();

    // Default to the last open subject or the first available
    final prefs = await SharedPreferences.getInstance();
    _globalTargetStandard = prefs.getDouble('global_target_standard') ?? 75.0;
    final lastId = prefs.getString('last_selected_subject_id');
    if (lastId != null) {
      final found = _attendanceService.subjects.firstWhere(
        (s) => s.id == lastId,
        orElse: () => _attendanceService.subjects.first,
      );
      _selectedSubject = null;
      _lastSelectedSubject = found;
    } else if (_attendanceService.subjects.isNotEmpty) {
      _selectedSubject = null;
      _lastSelectedSubject = _attendanceService.subjects.first;
    }

    _isLoading = false;
    logDevEvent(
      'System Initialized: loaded ${_attendanceService.subjects.length} subjects, ${_attendanceService.sessions.length} sessions, and ${_attendanceService.proofs.length} proof images.',
    );
    notifyListeners();
  }

  void setSelectedSubject(Subject? subject) {
    _selectedSubject = subject;
    if (subject != null) {
      _lastSelectedSubject = subject;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('last_selected_subject_id', subject.id);
      });
    }
    logDevEvent(
      'Subject Selection Changed: ${subject?.name ?? "None"} (${subject?.code ?? "N/A"})',
    );
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    logDevEvent(
      'Date Selection Changed: ${date.toIso8601String().substring(0, 10)}',
    );
    notifyListeners();
  }

  // --- BUSINESS STATS PASSTHROUGH ---

  SubjectAttendanceStats getStatsForSubject(Subject subject) {
    return _attendanceService.calculateStats(subject);
  }

  List<ClassSession> getSessionsForSelectedSubject() {
    if (_selectedSubject == null) return [];
    return _attendanceService.sessions
        .where((s) => s.subjectId == _selectedSubject!.id)
        .toList();
  }

  List<ProofImage> getProofsForSession(String sessionId) {
    return _attendanceService.proofs
        .where((p) => p.sessionId == sessionId)
        .toList();
  }

  // --- ACTIONS ---

  Future<void> updateGlobalTargetStandard(double newThreshold) async {
    _globalTargetStandard = newThreshold;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('global_target_standard', newThreshold);

    // Update all existing subjects to use this new threshold
    for (int i = 0; i < _attendanceService.subjects.length; i++) {
      final subject = _attendanceService.subjects[i];
      final updated = subject.copyWith(thresholdPercent: newThreshold);
      await _attendanceService.updateSubject(updated);
    }

    logDevEvent(
      'Global Target Standard Updated to ${newThreshold.toStringAsFixed(0)}%',
    );
    notifyListeners();
  }

  Future<void> addSubject({
    required String name,
    required String code,
    required String color,
    required String icon,
    int plannedTotalClasses = 30,
    double? thresholdPercent,
    String? teacherName,
    DateTime? semesterStart,
    DateTime? semesterEnd,
  }) async {
    final threshold = thresholdPercent ?? _globalTargetStandard;
    final sub = await _attendanceService.createSubject(
      name: name,
      code: code,
      color: color,
      icon: icon,
      plannedTotalClasses: plannedTotalClasses,
      thresholdPercent: threshold,
      teacherName: teacherName,
      semesterStart: semesterStart,
      semesterEnd: semesterEnd,
    );

    _selectedSubject ??= sub;
    logDevEvent(
      'Subject Created: "$name" ($code), Color: $color, Total Planned: $plannedTotalClasses, Threshold: $thresholdPercent%',
    );
    notifyListeners();
  }

  Future<void> updateSubject(Subject updated) async {
    await _attendanceService.updateSubject(updated);
    final subjectInService = _attendanceService.subjects.firstWhere(
      (s) => s.id == updated.id,
      orElse: () => updated,
    );
    if (_selectedSubject?.id == updated.id) {
      _selectedSubject = subjectInService;
    }
    if (_lastSelectedSubject?.id == updated.id) {
      _lastSelectedSubject = subjectInService;
    }
    logDevEvent(
      'Subject Updated: "${updated.name}" (${updated.code}), threshold: ${updated.thresholdPercent}%',
    );
    notifyListeners();
  }

  Future<void> deleteSubject(String id) async {
    await _attendanceService.deleteSubject(id);
    if (_selectedSubject?.id == id) {
      _selectedSubject = _attendanceService.subjects.isNotEmpty
          ? _attendanceService.subjects.first
          : null;
    }
    if (_lastSelectedSubject?.id == id) {
      _lastSelectedSubject = _attendanceService.subjects.isNotEmpty
          ? _attendanceService.subjects.first
          : null;
      final prefs = await SharedPreferences.getInstance();
      if (_lastSelectedSubject != null) {
        await prefs.setString(
          'last_selected_subject_id',
          _lastSelectedSubject!.id,
        );
      } else {
        await prefs.remove('last_selected_subject_id');
      }
    }
    logDevEvent('Subject Deleted: ID $id');
    notifyListeners();
  }

  Future<void> markAttendance({
    required String subjectId,
    required DateTime date,
    required String status, // 'present', 'absent', 'unknown'
    required String sessionType, // 'lecture', 'lab'
    required String reason,
  }) async {
    final session = await _attendanceService.createOrGetSession(
      subjectId: subjectId,
      date: date,
      sessionType: sessionType,
    );

    await _attendanceService.updateSessionAttendance(
      sessionId: session.id,
      newStatus: status,
      reason: reason,
    );
    logDevEvent(
      'Attendance Logged: Subject ID $subjectId, Date ${date.toIso8601String().substring(0, 10)}, Status: ${status.toUpperCase()} ($sessionType)',
    );
    notifyListeners();
  }

  /// Compresses, encrypts and saves an captured image proof
  Future<void> captureAndSaveProof({
    required Uint8List rawBytes,
    required String source, // 'camera', 'gallery'
    String? subjectId,
    String? sessionId,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? captureDate,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Call storage engine to compress, encrypt and write raw data
    final storageResults = await _storageService.saveProof(
      id: id,
      rawBytes: rawBytes,
      source: source,
    );

    // Call database manager to persist metadata
    await _attendanceService.addProofImage(
      filePathEncrypted: storageResults['filePathEncrypted'] as String,
      thumbnailPath: storageResults['thumbnailPath'] as String,
      originalSize: storageResults['originalSize'] as int,
      compressedSize: storageResults['compressedSize'] as int,
      hash: storageResults['hash'] as String,
      source: source,
      subjectId: subjectId,
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      captureTimestamp: captureDate,
    );

    logDevEvent(
      'Proof Captured & Encrypted: ID: $id, Source: $source, Size: ${rawBytes.length} bytes (Compressed: ${storageResults['compressedSize']} bytes)',
    );
    notifyListeners();
  }

  /// Reassigns an unassigned proof image to a session
  Future<void> assignProofToSession({
    required String proofId,
    required String subjectId,
    required String sessionId,
    required String reason,
  }) async {
    await _attendanceService.assignProofToSession(
      proofId: proofId,
      subjectId: subjectId,
      sessionId: sessionId,
      reason: reason,
    );
    logDevEvent(
      'Proof Assigned: Proof $proofId assigned to Session $sessionId',
    );
    notifyListeners();
  }

  /// Removes proof from a session and lets user choose what to do with attendance
  Future<void> removeProofFromSession({
    required String proofId,
    required String sessionId,
    required String
    userDecision, // 'mark_present', 'mark_absent', 'mark_unknown'
  }) async {
    await _attendanceService.removeProofFromSession(
      proofId: proofId,
      sessionId: sessionId,
      userDecision: userDecision,
    );
    logDevEvent(
      'Proof Detached: Proof $proofId removed from Session $sessionId. User decision: $userDecision',
    );
    notifyListeners();
  }

  /// Removes a proof image completely from database and local app sandbox
  Future<void> deleteProofCompletely(ProofImage proof) async {
    await _storageService.deleteProof(
      proof.filePathEncrypted,
      proof.thumbnailPath,
    );
    await _attendanceService.deleteProofCompletely(proof.id);
    logDevEvent('Proof Deleted Permanently: ID ${proof.id}');
    notifyListeners();
  }

  /// Load decompressed image data dynamically in UI components
  Future<Uint8List?> loadProofImage(String filePath) async {
    return await _storageService.loadProof(filePath);
  }

  /// Quick load of thumbnails in UI views
  Future<Uint8List?> loadProofThumbnail(String thumbPath) async {
    return await _storageService.loadThumbnail(thumbPath);
  }
}
