/// Academic Year model
class AcademicYear {
  final String id;
  final String tenantId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final DateTime createdAt;

  const AcademicYear({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    required this.createdAt,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isCurrent: json['is_current'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_current': isCurrent,
    };
  }
}

/// Term model
class Term {
  final String id;
  final String tenantId;
  final String academicYearId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int sequenceOrder;
  final DateTime createdAt;

  const Term({
    required this.id,
    required this.tenantId,
    required this.academicYearId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.sequenceOrder,
    required this.createdAt,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id'],
      tenantId: json['tenant_id'],
      academicYearId: json['academic_year_id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      sequenceOrder: json['sequence_order'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'academic_year_id': academicYearId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'sequence_order': sequenceOrder,
    };
  }
}

/// Class model
class SchoolClass {
  final String id;
  final String tenantId;
  final String name;
  final int? numericName;
  final String? description;
  final int sequenceOrder;
  final DateTime createdAt;

  // Related data
  final List<Section>? sections;

  const SchoolClass({
    required this.id,
    required this.tenantId,
    required this.name,
    this.numericName,
    this.description,
    required this.sequenceOrder,
    required this.createdAt,
    this.sections,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    List<Section>? sections;
    if (json['sections'] != null) {
      sections = (json['sections'] as List)
          .map((s) => Section.fromJson(s))
          .toList();
    }

    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    }

    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return SchoolClass(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      numericName: _parseInt(json['numeric_name']),
      description: json['description'],
      sequenceOrder: _parseInt(json['sequence_order']) ?? 0,
      createdAt: _parseDate(json['created_at']),
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'numeric_name': numericName,
      'description': description,
      'sequence_order': sequenceOrder,
    };
  }
}

/// Section model
class Section {
  final String id;
  final String tenantId;
  final String classId;
  final String academicYearId;
  final String name;
  final int capacity;
  final String? classTeacherId;
  final String? roomNumber;
  final DateTime createdAt;

  // Related data
  final String? className;
  final String? classTeacherName;
  final int? studentCount;

  const Section({
    required this.id,
    required this.tenantId,
    required this.classId,
    required this.academicYearId,
    required this.name,
    this.capacity = 40,
    this.classTeacherId,
    this.roomNumber,
    required this.createdAt,
    this.className,
    this.classTeacherName,
    this.studentCount,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    }

    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return Section(
      id: json['id'],
      tenantId: json['tenant_id'],
      classId: json['class_id'],
      academicYearId: json['academic_year_id'],
      name: json['name'],
      capacity: _parseInt(json['capacity']) ?? 40,
      classTeacherId: json['class_teacher_id'],
      roomNumber: json['room_number'],
      createdAt: _parseDate(json['created_at']),
      className: json['class']?['name'],
      classTeacherName: json['class_teacher']?['full_name'],
      studentCount: _parseInt(json['student_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'class_id': classId,
      'academic_year_id': academicYearId,
      'name': name,
      'capacity': capacity,
      'class_teacher_id': classTeacherId,
      'room_number': roomNumber,
    };
  }

  /// Display name (Class - Section)
  String get displayName => '$className - $name';
}

/// Subject model
class Subject {
  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String subjectType;
  final String? description;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.tenantId,
    required this.name,
    this.code,
    this.subjectType = 'mandatory',
    this.description,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      code: json['code'],
      subjectType: json['subject_type'] ?? 'mandatory',
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'subject_type': subjectType,
      'description': description,
    };
  }
}

/// Teacher Assignment model
class TeacherAssignment {
  final String id;
  final String tenantId;
  final String teacherId;
  final String sectionId;
  final String subjectId;
  final String academicYearId;
  final DateTime createdAt;

  // Related data
  final String? teacherName;
  final String? sectionName;
  final String? className;
  final String? subjectName;

  const TeacherAssignment({
    required this.id,
    required this.tenantId,
    required this.teacherId,
    required this.sectionId,
    required this.subjectId,
    required this.academicYearId,
    required this.createdAt,
    this.teacherName,
    this.sectionName,
    this.className,
    this.subjectName,
  });

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherAssignment(
      id: json['id'],
      tenantId: json['tenant_id'],
      teacherId: json['teacher_id'],
      sectionId: json['section_id'],
      subjectId: json['subject_id'],
      academicYearId: json['academic_year_id'],
      createdAt: DateTime.parse(json['created_at']),
      teacherName: json['teacher']?['full_name'],
      sectionName: json['section']?['name'],
      className: json['section']?['class']?['name'],
      subjectName: json['subject']?['name'],
    );
  }
}
