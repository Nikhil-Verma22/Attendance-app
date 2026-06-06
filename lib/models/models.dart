import 'dart:convert';

class Subject {
  final String id;
  final String name;
  final String code;
  final String color;
  final String icon;
  final int plannedTotalClasses;
  final bool activeStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? teacherName;
  final DateTime? semesterStart;
  final DateTime? semesterEnd;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.icon,
    required this.plannedTotalClasses,
    this.activeStatus = true,
    required this.createdAt,
    required this.updatedAt,
    this.teacherName,
    this.semesterStart,
    this.semesterEnd,
  });

  Subject copyWith({
    String? name,
    String? code,
    String? color,
    String? icon,
    int? plannedTotalClasses,
    bool? activeStatus,
    DateTime? updatedAt,
    String? teacherName,
    DateTime? semesterStart,
    DateTime? semesterEnd,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      plannedTotalClasses: plannedTotalClasses ?? this.plannedTotalClasses,
      activeStatus: activeStatus ?? this.activeStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      teacherName: teacherName ?? this.teacherName,
      semesterStart: semesterStart ?? this.semesterStart,
      semesterEnd: semesterEnd ?? this.semesterEnd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'color': color,
      'icon': icon,
      'plannedTotalClasses': plannedTotalClasses,
      'activeStatus': activeStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'teacherName': teacherName,
      'semesterStart': semesterStart?.toIso8601String(),
      'semesterEnd': semesterEnd?.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      color: map['color'] as String,
      icon: map['icon'] as String,
      plannedTotalClasses: map['plannedTotalClasses'] as int,
      activeStatus: map['activeStatus'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      teacherName: map['teacherName'] as String?,
      semesterStart: map['semesterStart'] != null ? DateTime.parse(map['semesterStart'] as String) : null,
      semesterEnd: map['semesterEnd'] != null ? DateTime.parse(map['semesterEnd'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Subject.fromJson(String source) => Subject.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ClassSession {
  final String id;
  final String subjectId;
  final DateTime sessionDate;
  final String sessionType; // 'lecture' or 'lab'
  final String status; // 'scheduled', 'conducted', 'cancelled'
  final String attendanceStatus; // 'present', 'absent', 'unknown'
  final int proofCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassSession({
    required this.id,
    required this.subjectId,
    required this.sessionDate,
    required this.sessionType,
    required this.status,
    required this.attendanceStatus,
    this.proofCount = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  ClassSession copyWith({
    String? status,
    String? attendanceStatus,
    int? proofCount,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ClassSession(
      id: id,
      subjectId: subjectId,
      sessionDate: sessionDate,
      sessionType: sessionType,
      status: status ?? this.status,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      proofCount: proofCount ?? this.proofCount,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'sessionDate': sessionDate.toIso8601String(),
      'sessionType': sessionType,
      'status': status,
      'attendanceStatus': attendanceStatus,
      'proofCount': proofCount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClassSession.fromMap(Map<String, dynamic> map) {
    return ClassSession(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      sessionDate: DateTime.parse(map['sessionDate'] as String),
      sessionType: map['sessionType'] as String,
      status: map['status'] as String,
      attendanceStatus: map['attendanceStatus'] as String,
      proofCount: map['proofCount'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ClassSession.fromJson(String source) => ClassSession.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ProofImage {
  final String id;
  final String? sessionId;
  final String? subjectId;
  final DateTime captureTimestamp;
  final DateTime captureDate;
  final String filePathEncrypted;
  final String thumbnailPath;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String source; // 'camera', 'gallery', 'anonymous'
  final int compressionQuality;
  final int originalSize;
  final int compressedSize;
  final String hash;
  final DateTime createdAt;

  ProofImage({
    required this.id,
    this.sessionId,
    this.subjectId,
    required this.captureTimestamp,
    required this.captureDate,
    required this.filePathEncrypted,
    required this.thumbnailPath,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.source,
    required this.compressionQuality,
    required this.originalSize,
    required this.compressedSize,
    required this.hash,
    required this.createdAt,
  });

  ProofImage copyWith({
    String? sessionId,
    String? subjectId,
  }) {
    return ProofImage(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      subjectId: subjectId ?? this.subjectId,
      captureTimestamp: captureTimestamp,
      captureDate: captureDate,
      filePathEncrypted: filePathEncrypted,
      thumbnailPath: thumbnailPath,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      source: source,
      compressionQuality: compressionQuality,
      originalSize: originalSize,
      compressedSize: compressedSize,
      hash: hash,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'subjectId': subjectId,
      'captureTimestamp': captureTimestamp.toIso8601String(),
      'captureDate': captureDate.toIso8601String(),
      'filePathEncrypted': filePathEncrypted,
      'thumbnailPath': thumbnailPath,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'source': source,
      'compressionQuality': compressionQuality,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'hash': hash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProofImage.fromMap(Map<String, dynamic> map) {
    return ProofImage(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String?,
      subjectId: map['subjectId'] as String?,
      captureTimestamp: DateTime.parse(map['captureTimestamp'] as String),
      captureDate: DateTime.parse(map['captureDate'] as String),
      filePathEncrypted: map['filePathEncrypted'] as String,
      thumbnailPath: map['thumbnailPath'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      source: map['source'] as String,
      compressionQuality: map['compressionQuality'] as int,
      originalSize: map['originalSize'] as int,
      compressedSize: map['compressedSize'] as int,
      hash: map['hash'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProofImage.fromJson(String source) => ProofImage.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AttendanceAuditLog {
  final String id;
  final String sessionId;
  final String actionType; // 'created', 'updated', 'deleted', 'reassigned'
  final String oldValue;
  final String newValue;
  final String reason;
  final DateTime timestamp;

  AttendanceAuditLog({
    required this.id,
    required this.sessionId,
    required this.actionType,
    required this.oldValue,
    required this.newValue,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'actionType': actionType,
      'oldValue': oldValue,
      'newValue': newValue,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttendanceAuditLog.fromMap(Map<String, dynamic> map) {
    return AttendanceAuditLog(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      actionType: map['actionType'] as String,
      oldValue: map['oldValue'] as String,
      newValue: map['newValue'] as String,
      reason: map['reason'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceAuditLog.fromJson(String source) => AttendanceAuditLog.fromMap(json.decode(source) as Map<String, dynamic>);
}
