import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/services/attendance_service.dart';

void main() {
  setUp(() {
    // Inject clean empty Mock values for SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('Attendance Calculation Engine Tests', () {
    final service = AttendanceService();

    test('Formula & Threshold Percentage Calculations', () async {
      // Initialize fresh service data
      await service.loadData();

      final subject = await service.createSubject(
        name: 'Calculus',
        code: 'MATH-201',
        color: '#3B3EAC',
        icon: 'book',
        plannedTotalClasses: 30,
      );

      // 1. Conducted is 0, percentage should default to 100%
      var stats = service.calculateStats(subject, 75.0);
      expect(stats.attendancePercentage, equals(100.0));
      expect(stats.conductedCount, equals(0));
      expect(stats.attendedCount, equals(0));

      // 2. Add conducted present classes
      final sess1 = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, 1));
      await service.updateSessionAttendance(sessionId: sess1.id, newStatus: 'present', reason: 'Attended');

      stats = service.calculateStats(subject, 75.0);
      expect(stats.attendancePercentage, equals(100.0));
      expect(stats.conductedCount, equals(1));
      expect(stats.attendedCount, equals(1));

      // 3. Add absent class (Conducted = 2, Attended = 1, Pct = 50%)
      final sess2 = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, 2));
      await service.updateSessionAttendance(sessionId: sess2.id, newStatus: 'absent', reason: 'Missed');

      stats = service.calculateStats(subject, 75.0);
      expect(stats.attendancePercentage, equals(50.0));
      expect(stats.conductedCount, equals(2));
      expect(stats.attendedCount, equals(1));
    });

    test('Ceil Minimum Safe Count & Risk State Threshold Rules', () async {
      await service.loadData();
      final subject = await service.createSubject(
        name: 'Physics',
        code: 'PHYS-101',
        color: '#FF9800',
        icon: 'atom',
        plannedTotalClasses: 20,
      );

      // Create 5 classes: 4 present, 1 absent (Conducted=5, Attended=4 => 80% (Safe))
      for (int i = 1; i <= 4; i++) {
        final s = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, i));
        await service.updateSessionAttendance(sessionId: s.id, newStatus: 'present', reason: 'Present');
      }
      final s5 = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, 5));
      await service.updateSessionAttendance(sessionId: s5.id, newStatus: 'absent', reason: 'Absent');

      final stats = service.calculateStats(subject, 75.0);
      // ceil(0.75 * 5) = 4
      expect(stats.safeMinimumRequired, equals(4));
      expect(stats.attendancePercentage, equals(80.0));
      expect(stats.riskState, equals(RiskState.warning)); // Margin 1 class remaining makes it warning
    });

    test('Consecutive Attendance Forecast Recovery Formulas', () async {
      await service.loadData();
      final subject = await service.createSubject(
        name: 'Chemistry',
        code: 'CHEM-102',
        color: '#4CAF50',
        icon: 'test_tube',
      );

      // Conducted = 12, Attended = 8 (66.7% - Risk)
      for (int i = 1; i <= 8; i++) {
        final s = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, i));
        await service.updateSessionAttendance(sessionId: s.id, newStatus: 'present', reason: 'Present');
      }
      for (int i = 9; i <= 12; i++) {
        final s = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, i));
        await service.updateSessionAttendance(sessionId: s.id, newStatus: 'absent', reason: 'Absent');
      }

      final stats = service.calculateStats(subject, 75.0);
      expect(stats.attendancePercentage, lessThan(75.0));
      // Formula: 3 * C - 4 * A = 3 * 12 - 4 * 8 = 36 - 32 = 4 consecutive classes to recover
      expect(stats.remainingMargin, equals(4));
      expect(stats.riskState, equals(RiskState.danger));
    });

    test('Safe Classes to Miss Forecast Formulas', () async {
      await service.loadData();
      final subject = await service.createSubject(
        name: 'Biology',
        code: 'BIOL-101',
        color: '#9C27B0',
        icon: 'leaf',
      );

      // Conducted = 12, Attended = 10 (83.3% - Safe)
      for (int i = 1; i <= 10; i++) {
        final s = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, i));
        await service.updateSessionAttendance(sessionId: s.id, newStatus: 'present', reason: 'Present');
      }
      for (int i = 11; i <= 12; i++) {
        final s = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, i));
        await service.updateSessionAttendance(sessionId: s.id, newStatus: 'absent', reason: 'Absent');
      }

      final stats = service.calculateStats(subject, 75.0);
      expect(stats.attendancePercentage, greaterThanOrEqualTo(75.0));
      // Formula: floor(A / 0.75) - C = floor(10 / 0.75) - 12 = 13 - 12 = 1 class can be safely missed
      expect(stats.remainingMargin, equals(1));
    });
  });

  group('Proof Image Security & Business Constraints Tests', () {
    final service = AttendanceService();

    test('Auto-Present Proof Rule', () async {
      await service.loadData();
      final subject = await service.createSubject(
        name: 'Literature',
        code: 'LIT-101',
        color: '#00BCD4',
        icon: 'book',
      );

      final session = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, 20));
      // Attendance starts as unknown
      expect(session.attendanceStatus, equals('unknown'));

      // Attach a proof image
      await service.addProofImage(
        filePathEncrypted: 'mock/path.bin',
        thumbnailPath: 'mock/thumb.bin',
        originalSize: 1000,
        compressedSize: 400,
        hash: 'mockhash',
        source: 'camera',
        subjectId: subject.id,
        sessionId: session.id,
      );

      final updatedSession = service.sessions.firstWhere((s) => s.id == session.id);
      // Auto-present rule should toggle attendance to present
      expect(updatedSession.attendanceStatus, equals('present'));
      expect(updatedSession.proofCount, equals(1));
    });

    test('Max 3 Proofs Cap Limits Rule', () async {
      await service.loadData();
      final subject = await service.createSubject(
        name: 'History',
        code: 'HIST-101',
        color: '#FF9800',
        icon: 'scroll',
      );

      final session = await service.createOrGetSession(subjectId: subject.id, date: DateTime(2026, 5, 21));

      // Attach 3 proofs successfully
      for (int i = 0; i < 3; i++) {
        await service.addProofImage(
          filePathEncrypted: 'mock/path_$i.bin',
          thumbnailPath: 'mock/thumb_$i.bin',
          originalSize: 1000,
          compressedSize: 400,
          hash: 'mockhash_$i',
          source: 'camera',
          subjectId: subject.id,
          sessionId: session.id,
        );
      }

      final updatedSession = service.sessions.firstWhere((s) => s.id == session.id);
      expect(updatedSession.proofCount, equals(3));

      // Attempting to assign a 4th anonymous proof to the session should throw an exception
      final anonProof = await service.addProofImage(
        filePathEncrypted: 'mock/path_anon.bin',
        thumbnailPath: 'mock/thumb_anon.bin',
        originalSize: 1000,
        compressedSize: 400,
        hash: 'mockhash_anon',
        source: 'camera',
      );

      expect(
        () => service.assignProofToSession(
          proofId: anonProof.id,
          subjectId: subject.id,
          sessionId: session.id,
          reason: 'Try 4th proof',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
