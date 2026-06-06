import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

enum RiskState { safe, warning, danger }

class SubjectAttendanceStats {
  final int attendedCount;
  final int absentCount;
  final int conductedCount;
  final double attendancePercentage;
  final int safeMinimumRequired;
  final int
  remainingMargin; // Classes you can miss (if >=75%), or consecutive classes to attend to recover (if <75%)
  final RiskState riskState;

  SubjectAttendanceStats({
    required this.attendedCount,
    required this.absentCount,
    required this.conductedCount,
    required this.attendancePercentage,
    required this.safeMinimumRequired,
    required this.remainingMargin,
    required this.riskState,
  });
}

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final _uuid = const Uuid();

  // Local state caches
  List<Subject> _subjects = [];
  List<ClassSession> _sessions = [];
  List<ProofImage> _proofs = [];
  List<AttendanceAuditLog> _logs = [];

  List<Subject> get subjects => _subjects;
  List<ClassSession> get sessions => _sessions;
  List<ProofImage> get proofs => _proofs;
  List<AttendanceAuditLog> get logs => _logs;

  /// Calculations based strictly on the formulas in Section 5 and 13 of spec
  SubjectAttendanceStats calculateStats(Subject subject, double targetStandard) {
    final subjectSessions = _sessions
        .where((s) => s.subjectId == subject.id)
        .toList();

    int attended = 0;
    int absent = 0;

    for (final session in subjectSessions) {
      if (session.status == 'conducted') {
        if (session.attendanceStatus == 'present') {
          attended++;
        } else if (session.attendanceStatus == 'absent') {
          absent++;
        }
      }
    }

    final conducted = attended + absent;
    final double pct = conducted == 0 ? 100.0 : (attended / conducted) * 100.0;
    final double targetRatio = targetStandard / 100.0;
    final int safeMin = (targetRatio * conducted).ceil();

    int margin = 0;
    RiskState state = RiskState.safe;

    if (pct >= targetStandard) {
      // Classes we can safely miss: floor(A / targetRatio) - C
      margin = conducted == 0
          ? subject.plannedTotalClasses
          : ((attended / targetRatio).floor() - conducted);
      if (margin < 0) margin = 0;
      state = margin <= 1 ? RiskState.warning : RiskState.safe;
    } else {
      // Consecutive classes we must attend to recover: ceil((targetRatio * C - A) / (1 - targetRatio))
      final double denominator = 1.0 - targetRatio;
      if (denominator > 0.0) {
        margin = ((targetRatio * conducted - attended) / denominator).ceil();
      } else {
        margin = 0;
      }
      if (margin < 0) margin = 0;
      state = RiskState.danger;
    }

    return SubjectAttendanceStats(
      attendedCount: attended,
      absentCount: absent,
      conductedCount: conducted,
      attendancePercentage: pct,
      safeMinimumRequired: safeMin,
      remainingMargin: margin,
      riskState: state,
    );
  }

  // --- PERSISTENCE ---

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final subjectsJson = prefs.getString('subjects_data');
    if (subjectsJson != null) {
      final List decoded = json.decode(subjectsJson);
      _subjects = decoded.map((item) => Subject.fromMap(item)).toList();
    } else {
      _subjects = [];
    }

    final sessionsJson = prefs.getString('sessions_data');
    if (sessionsJson != null) {
      final List decoded = json.decode(sessionsJson);
      _sessions = decoded.map((item) => ClassSession.fromMap(item)).toList();
    } else {
      _sessions = [];
    }

    final proofsJson = prefs.getString('proofs_data');
    if (proofsJson != null) {
      final List decoded = json.decode(proofsJson);
      _proofs = decoded.map((item) => ProofImage.fromMap(item)).toList();
    } else {
      _proofs = [];
    }

    final logsJson = prefs.getString('logs_data');
    if (logsJson != null) {
      final List decoded = json.decode(logsJson);
      _logs = decoded.map((item) => AttendanceAuditLog.fromMap(item)).toList();
    } else {
      _logs = [];
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'subjects_data',
      json.encode(_subjects.map((s) => s.toMap()).toList()),
    );
    await prefs.setString(
      'sessions_data',
      json.encode(_sessions.map((s) => s.toMap()).toList()),
    );
    await prefs.setString(
      'proofs_data',
      json.encode(_proofs.map((p) => p.toMap()).toList()),
    );
    await prefs.setString(
      'logs_data',
      json.encode(_logs.map((l) => l.toMap()).toList()),
    );
  }

  // --- SUBJECT OPERATIONS ---

  Future<Subject> createSubject({
    required String name,
    required String code,
    required String color,
    required String icon,
    int plannedTotalClasses = 30,
    String? teacherName,
    DateTime? semesterStart,
    DateTime? semesterEnd,
  }) async {
    final now = DateTime.now();
    final subject = Subject(
      id: _uuid.v4(),
      name: name,
      code: code,
      color: color,
      icon: icon,
      plannedTotalClasses: plannedTotalClasses,
      teacherName: teacherName,
      semesterStart: semesterStart,
      semesterEnd: semesterEnd,
      createdAt: now,
      updatedAt: now,
    );
    _subjects.add(subject);
    await saveData();
    return subject;
  }

  Future<void> updateSubject(Subject updated) async {
    final idx = _subjects.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _subjects[idx] = updated.copyWith(updatedAt: DateTime.now());
      await saveData();
    }
  }

  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    _sessions.removeWhere((s) => s.subjectId == id);
    _proofs.removeWhere((p) => p.subjectId == id);
    await saveData();
  }

  // --- SESSION OPERATIONS ---

  Future<ClassSession> createOrGetSession({
    required String subjectId,
    required DateTime date,
    String sessionType = 'lecture',
  }) async {
    // Truncate time parameters to match date only
    final dateOnly = DateTime(date.year, date.month, date.day);

    final existingIdx = _sessions.indexWhere(
      (s) =>
          s.subjectId == subjectId &&
          s.sessionDate.year == dateOnly.year &&
          s.sessionDate.month == dateOnly.month &&
          s.sessionDate.day == dateOnly.day &&
          s.sessionType == sessionType,
    );

    if (existingIdx != -1) {
      return _sessions[existingIdx];
    }

    final now = DateTime.now();
    final session = ClassSession(
      id: _uuid.v4(),
      subjectId: subjectId,
      sessionDate: dateOnly,
      sessionType: sessionType,
      status: 'conducted',
      attendanceStatus: 'unknown',
      createdAt: now,
      updatedAt: now,
    );
    _sessions.add(session);
    await saveData();
    return session;
  }

  Future<void> updateSessionAttendance({
    required String sessionId,
    required String newStatus,
    required String reason,
  }) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final oldSession = _sessions[idx];
      final now = DateTime.now();

      _sessions[idx] = oldSession.copyWith(
        attendanceStatus: newStatus,
        updatedAt: now,
      );

      // Log the change in audit log
      final log = AttendanceAuditLog(
        id: _uuid.v4(),
        sessionId: sessionId,
        actionType: 'updated',
        oldValue: oldSession.attendanceStatus,
        newValue: newStatus,
        reason: reason,
        timestamp: now,
      );
      _logs.add(log);

      await saveData();
    }
  }

  // --- PROOF HANDLING ---

  Future<ProofImage> addProofImage({
    required String filePathEncrypted,
    required String thumbnailPath,
    required int originalSize,
    required int compressedSize,
    required String hash,
    String? subjectId,
    String? sessionId,
    double? latitude,
    double? longitude,
    double? accuracy,
    required String source,
    DateTime? captureTimestamp,
  }) async {
    final now = DateTime.now();
    final actualCaptureTime = captureTimestamp ?? now;
    final dateOnly = DateTime(
      actualCaptureTime.year,
      actualCaptureTime.month,
      actualCaptureTime.day,
    );

    final proof = ProofImage(
      id: _uuid.v4(),
      sessionId: sessionId,
      subjectId: subjectId,
      captureTimestamp: actualCaptureTime,
      captureDate: dateOnly,
      filePathEncrypted: filePathEncrypted,
      thumbnailPath: thumbnailPath,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      source: source,
      compressionQuality: 75,
      originalSize: originalSize,
      compressedSize: compressedSize,
      hash: hash,
      createdAt: now,
    );

    _proofs.add(proof);

    // Apply auto-present rule (Section 13) if assigned to a session
    if (sessionId != null) {
      final sessIdx = _sessions.indexWhere((s) => s.id == sessionId);
      if (sessIdx != -1) {
        final session = _sessions[sessIdx];
        _sessions[sessIdx] = session.copyWith(
          proofCount: session.proofCount + 1,
          attendanceStatus: 'present', // Auto-present rule
        );

        final log = AttendanceAuditLog(
          id: _uuid.v4(),
          sessionId: sessionId,
          actionType: 'proof_attached',
          oldValue: session.attendanceStatus,
          newValue: 'present',
          reason: 'Auto-marked present due to proof attachment',
          timestamp: now,
        );
        _logs.add(log);
      }
    }

    await saveData();
    return proof;
  }

  /// Reassigns an anonymous proof image to a session
  Future<bool> assignProofToSession({
    required String proofId,
    required String subjectId,
    required String sessionId,
    required String reason,
  }) async {
    final proofIdx = _proofs.indexWhere((p) => p.id == proofId);
    final sessIdx = _sessions.indexWhere((s) => s.id == sessionId);

    if (proofIdx == -1 || sessIdx == -1) return false;

    final proof = _proofs[proofIdx];
    final session = _sessions[sessIdx];

    // Enforce max 3 proof limit (Section 9)
    if (session.proofCount >= 3) {
      throw Exception('Max limit of 3 proof images reached for this session.');
    }

    // Date-matching validation rule (Section 5)
    final proofDate = DateTime(
      proof.captureTimestamp.year,
      proof.captureTimestamp.month,
      proof.captureTimestamp.day,
    );
    final sessionDate = DateTime(
      session.sessionDate.year,
      session.sessionDate.month,
      session.sessionDate.day,
    );

    if (proofDate.compareTo(sessionDate) != 0) {
      // Reassignment is allowed but must be explicit and logged
      // Proceed with update but make sure it logs audit
    }

    final now = DateTime.now();
    _proofs[proofIdx] = proof.copyWith(
      sessionId: sessionId,
      subjectId: subjectId,
    );

    _sessions[sessIdx] = session.copyWith(
      proofCount: session.proofCount + 1,
      attendanceStatus: 'present', // Auto-present rule
    );

    final log = AttendanceAuditLog(
      id: _uuid.v4(),
      sessionId: sessionId,
      actionType: 'reassigned',
      oldValue: 'unassigned',
      newValue: 'assigned_proof_${proof.id}',
      reason: reason,
      timestamp: now,
    );
    _logs.add(log);

    await saveData();
    return true;
  }

  /// Removes a proof image from a session
  Future<void> removeProofFromSession({
    required String proofId,
    required String sessionId,
    required String
    userDecision, // 'keep_present', 'mark_absent', 'mark_unknown'
  }) async {
    final proofIdx = _proofs.indexWhere((p) => p.id == proofId);
    final sessIdx = _sessions.indexWhere((s) => s.id == sessionId);

    if (proofIdx != -1) {
      // Keep proof image in memory, but make it anonymous again
      final proof = _proofs[proofIdx];
      _proofs[proofIdx] = ProofImage(
        id: proof.id,
        sessionId: null,
        subjectId: null,
        captureTimestamp: proof.captureTimestamp,
        captureDate: proof.captureDate,
        filePathEncrypted: proof.filePathEncrypted,
        thumbnailPath: proof.thumbnailPath,
        latitude: proof.latitude,
        longitude: proof.longitude,
        accuracy: proof.accuracy,
        source: proof.source,
        compressionQuality: proof.compressionQuality,
        originalSize: proof.originalSize,
        compressedSize: proof.compressedSize,
        hash: proof.hash,
        createdAt: proof.createdAt,
      );
    }

    if (sessIdx != -1) {
      final session = _sessions[sessIdx];
      String newAttendance = session.attendanceStatus;

      if (userDecision == 'mark_present') {
        newAttendance = 'present';
      } else if (userDecision == 'mark_absent') {
        newAttendance = 'absent';
      } else if (userDecision == 'mark_unknown') {
        newAttendance = 'unknown';
      }

      _sessions[sessIdx] = session.copyWith(
        proofCount: (session.proofCount - 1).clamp(0, 3),
        attendanceStatus: newAttendance,
      );

      final log = AttendanceAuditLog(
        id: _uuid.v4(),
        sessionId: sessionId,
        actionType: 'proof_detached',
        oldValue: session.attendanceStatus,
        newValue: newAttendance,
        reason: 'Proof detached. User selected: $userDecision',
        timestamp: DateTime.now(),
      );
      _logs.add(log);
    }

    await saveData();
  }

  Future<void> deleteProofCompletely(String proofId) async {
    final idx = _proofs.indexWhere((p) => p.id == proofId);
    if (idx != -1) {
      final proof = _proofs[idx];
      _proofs.removeAt(idx);

      if (proof.sessionId != null) {
        final sessIdx = _sessions.indexWhere((s) => s.id == proof.sessionId);
        if (sessIdx != -1) {
          final session = _sessions[sessIdx];
          _sessions[sessIdx] = session.copyWith(
            proofCount: (session.proofCount - 1).clamp(0, 3),
          );
        }
      }
      await saveData();
    }
  }
}
