// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssignmentImpl _$$AssignmentImplFromJson(Map<String, dynamic> json) =>
    _$AssignmentImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      sectionId: json['sectionId'] as String,
      subjectId: json['subjectId'] as String,
      teacherId: json['teacherId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      dueDate: DateTime.parse(json['dueDate'] as String),
      maxMarks: (json['maxMarks'] as num?)?.toDouble(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'draft',
      allowLateSubmission: json['allowLateSubmission'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      sectionName: json['sectionName'] as String?,
      className: json['className'] as String?,
      subjectName: json['subjectName'] as String?,
      subjectCode: json['subjectCode'] as String?,
      teacherName: json['teacherName'] as String?,
      totalStudents: (json['totalStudents'] as num?)?.toInt(),
      submittedCount: (json['submittedCount'] as num?)?.toInt(),
      gradedCount: (json['gradedCount'] as num?)?.toInt(),
      lateCount: (json['lateCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$AssignmentImplToJson(_$AssignmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'sectionId': instance.sectionId,
      'subjectId': instance.subjectId,
      'teacherId': instance.teacherId,
      'title': instance.title,
      'description': instance.description,
      'instructions': instance.instructions,
      'dueDate': instance.dueDate.toIso8601String(),
      'maxMarks': instance.maxMarks,
      'attachments': instance.attachments,
      'status': instance.status,
      'allowLateSubmission': instance.allowLateSubmission,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'sectionName': instance.sectionName,
      'className': instance.className,
      'subjectName': instance.subjectName,
      'subjectCode': instance.subjectCode,
      'teacherName': instance.teacherName,
      'totalStudents': instance.totalStudents,
      'submittedCount': instance.submittedCount,
      'gradedCount': instance.gradedCount,
      'lateCount': instance.lateCount,
    };

_$SubmissionImpl _$$SubmissionImplFromJson(Map<String, dynamic> json) =>
    _$SubmissionImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      content: json['content'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
      status: json['status'] as String? ?? 'pending',
      marksObtained: (json['marksObtained'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedBy: json['gradedBy'] as String?,
      gradedAt: json['gradedAt'] == null
          ? null
          : DateTime.parse(json['gradedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      studentName: json['studentName'] as String?,
      admissionNumber: json['admissionNumber'] as String?,
      assignmentTitle: json['assignmentTitle'] as String?,
      maxMarks: (json['maxMarks'] as num?)?.toDouble(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      gradedByName: json['gradedByName'] as String?,
    );

Map<String, dynamic> _$$SubmissionImplToJson(_$SubmissionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'assignmentId': instance.assignmentId,
      'studentId': instance.studentId,
      'content': instance.content,
      'attachments': instance.attachments,
      'submittedAt': instance.submittedAt?.toIso8601String(),
      'status': instance.status,
      'marksObtained': instance.marksObtained,
      'feedback': instance.feedback,
      'gradedBy': instance.gradedBy,
      'gradedAt': instance.gradedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'assignmentTitle': instance.assignmentTitle,
      'maxMarks': instance.maxMarks,
      'dueDate': instance.dueDate?.toIso8601String(),
      'gradedByName': instance.gradedByName,
    };

_$AssignmentSummaryImpl _$$AssignmentSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$AssignmentSummaryImpl(
      tenantId: json['tenantId'] as String,
      assignmentId: json['assignmentId'] as String,
      title: json['title'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      className: json['className'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      maxMarks: (json['maxMarks'] as num?)?.toDouble(),
      status: json['status'] as String,
      totalStudents: (json['totalStudents'] as num).toInt(),
      submittedCount: (json['submittedCount'] as num).toInt(),
      gradedCount: (json['gradedCount'] as num).toInt(),
      lateCount: (json['lateCount'] as num).toInt(),
      isPastDue: json['isPastDue'] as bool,
    );

Map<String, dynamic> _$$AssignmentSummaryImplToJson(
        _$AssignmentSummaryImpl instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'assignmentId': instance.assignmentId,
      'title': instance.title,
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'className': instance.className,
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'teacherId': instance.teacherId,
      'teacherName': instance.teacherName,
      'dueDate': instance.dueDate.toIso8601String(),
      'maxMarks': instance.maxMarks,
      'status': instance.status,
      'totalStudents': instance.totalStudents,
      'submittedCount': instance.submittedCount,
      'gradedCount': instance.gradedCount,
      'lateCount': instance.lateCount,
      'isPastDue': instance.isPastDue,
    };
