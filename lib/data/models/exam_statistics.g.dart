// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExamImpl _$$ExamImplFromJson(Map<String, dynamic> json) => _$ExamImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      academicYearId: json['academicYearId'] as String,
      termId: json['termId'] as String?,
      name: json['name'] as String,
      examType: json['examType'] as String,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      description: json['description'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      termName: json['termName'] as String?,
      academicYearName: json['academicYearName'] as String?,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => ExamSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ExamImplToJson(_$ExamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'academicYearId': instance.academicYearId,
      'termId': instance.termId,
      'name': instance.name,
      'examType': instance.examType,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'description': instance.description,
      'isPublished': instance.isPublished,
      'createdAt': instance.createdAt?.toIso8601String(),
      'termName': instance.termName,
      'academicYearName': instance.academicYearName,
      'subjects': instance.subjects,
    };

_$ExamSubjectImpl _$$ExamSubjectImplFromJson(Map<String, dynamic> json) =>
    _$ExamSubjectImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      examId: json['examId'] as String,
      subjectId: json['subjectId'] as String,
      classId: json['classId'] as String,
      examDate: json['examDate'] == null
          ? null
          : DateTime.parse(json['examDate'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      maxMarks: (json['maxMarks'] as num).toDouble(),
      passingMarks: (json['passingMarks'] as num).toDouble(),
      weightage: (json['weightage'] as num?)?.toDouble() ?? 1.0,
      syllabus: json['syllabus'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      subjectName: json['subjectName'] as String?,
      subjectCode: json['subjectCode'] as String?,
      className: json['className'] as String?,
    );

Map<String, dynamic> _$$ExamSubjectImplToJson(_$ExamSubjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'examId': instance.examId,
      'subjectId': instance.subjectId,
      'classId': instance.classId,
      'examDate': instance.examDate?.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'maxMarks': instance.maxMarks,
      'passingMarks': instance.passingMarks,
      'weightage': instance.weightage,
      'syllabus': instance.syllabus,
      'createdAt': instance.createdAt?.toIso8601String(),
      'subjectName': instance.subjectName,
      'subjectCode': instance.subjectCode,
      'className': instance.className,
    };

_$MarkImpl _$$MarkImplFromJson(Map<String, dynamic> json) => _$MarkImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      examSubjectId: json['examSubjectId'] as String,
      studentId: json['studentId'] as String,
      marksObtained: (json['marksObtained'] as num?)?.toDouble(),
      isAbsent: json['isAbsent'] as bool? ?? false,
      remarks: json['remarks'] as String?,
      enteredBy: json['enteredBy'] as String?,
      enteredAt: json['enteredAt'] == null
          ? null
          : DateTime.parse(json['enteredAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      studentName: json['studentName'] as String?,
      admissionNumber: json['admissionNumber'] as String?,
      subjectName: json['subjectName'] as String?,
      maxMarks: (json['maxMarks'] as num?)?.toDouble(),
      passingMarks: (json['passingMarks'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$MarkImplToJson(_$MarkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'examSubjectId': instance.examSubjectId,
      'studentId': instance.studentId,
      'marksObtained': instance.marksObtained,
      'isAbsent': instance.isAbsent,
      'remarks': instance.remarks,
      'enteredBy': instance.enteredBy,
      'enteredAt': instance.enteredAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'subjectName': instance.subjectName,
      'maxMarks': instance.maxMarks,
      'passingMarks': instance.passingMarks,
    };

_$StudentPerformanceImpl _$$StudentPerformanceImplFromJson(
        Map<String, dynamic> json) =>
    _$StudentPerformanceImpl(
      tenantId: json['tenantId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      admissionNumber: json['admissionNumber'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      examType: json['examType'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      subjectCode: json['subjectCode'] as String?,
      marksObtained: (json['marksObtained'] as num).toDouble(),
      maxMarks: (json['maxMarks'] as num).toDouble(),
      passingMarks: (json['passingMarks'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      isPassed: json['isPassed'] as bool,
      isAbsent: json['isAbsent'] as bool? ?? false,
      academicYearId: json['academicYearId'] as String,
      termId: json['termId'] as String?,
    );

Map<String, dynamic> _$$StudentPerformanceImplToJson(
        _$StudentPerformanceImpl instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'classId': instance.classId,
      'className': instance.className,
      'examId': instance.examId,
      'examName': instance.examName,
      'examType': instance.examType,
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'subjectCode': instance.subjectCode,
      'marksObtained': instance.marksObtained,
      'maxMarks': instance.maxMarks,
      'passingMarks': instance.passingMarks,
      'percentage': instance.percentage,
      'isPassed': instance.isPassed,
      'isAbsent': instance.isAbsent,
      'academicYearId': instance.academicYearId,
      'termId': instance.termId,
    };

_$StudentRankImpl _$$StudentRankImplFromJson(Map<String, dynamic> json) =>
    _$StudentRankImpl(
      tenantId: json['tenantId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      admissionNumber: json['admissionNumber'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      examType: json['examType'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      marksObtained: (json['marksObtained'] as num).toDouble(),
      maxMarks: (json['maxMarks'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      subjectRank: (json['subjectRank'] as num).toInt(),
      totalInSubject: (json['totalInSubject'] as num).toInt(),
      academicYearId: json['academicYearId'] as String,
    );

Map<String, dynamic> _$$StudentRankImplToJson(_$StudentRankImpl instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'classId': instance.classId,
      'className': instance.className,
      'examId': instance.examId,
      'examName': instance.examName,
      'examType': instance.examType,
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'marksObtained': instance.marksObtained,
      'maxMarks': instance.maxMarks,
      'percentage': instance.percentage,
      'subjectRank': instance.subjectRank,
      'totalInSubject': instance.totalInSubject,
      'academicYearId': instance.academicYearId,
    };

_$StudentOverallRankImpl _$$StudentOverallRankImplFromJson(
        Map<String, dynamic> json) =>
    _$StudentOverallRankImpl(
      tenantId: json['tenantId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      admissionNumber: json['admissionNumber'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      examType: json['examType'] as String,
      academicYearId: json['academicYearId'] as String,
      totalObtained: (json['totalObtained'] as num).toDouble(),
      totalMaxMarks: (json['totalMaxMarks'] as num).toDouble(),
      overallPercentage: (json['overallPercentage'] as num).toDouble(),
      subjectsCount: (json['subjectsCount'] as num).toInt(),
      subjectsPassed: (json['subjectsPassed'] as num).toInt(),
      classRank: (json['classRank'] as num).toInt(),
    );

Map<String, dynamic> _$$StudentOverallRankImplToJson(
        _$StudentOverallRankImpl instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'classId': instance.classId,
      'className': instance.className,
      'examId': instance.examId,
      'examName': instance.examName,
      'examType': instance.examType,
      'academicYearId': instance.academicYearId,
      'totalObtained': instance.totalObtained,
      'totalMaxMarks': instance.totalMaxMarks,
      'overallPercentage': instance.overallPercentage,
      'subjectsCount': instance.subjectsCount,
      'subjectsPassed': instance.subjectsPassed,
      'classRank': instance.classRank,
    };

_$ClassExamStatsImpl _$$ClassExamStatsImplFromJson(Map<String, dynamic> json) =>
    _$ClassExamStatsImpl(
      tenantId: json['tenantId'] as String,
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      examType: json['examType'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      academicYearId: json['academicYearId'] as String,
      totalStudents: (json['totalStudents'] as num).toInt(),
      studentsAppeared: (json['studentsAppeared'] as num).toInt(),
      classAverage: (json['classAverage'] as num).toDouble(),
      highestPercentage: (json['highestPercentage'] as num).toDouble(),
      lowestPercentage: (json['lowestPercentage'] as num).toDouble(),
      passedCount: (json['passedCount'] as num).toInt(),
      failedCount: (json['failedCount'] as num).toInt(),
      absentCount: (json['absentCount'] as num).toInt(),
      passPercentage: (json['passPercentage'] as num).toDouble(),
    );

Map<String, dynamic> _$$ClassExamStatsImplToJson(
        _$ClassExamStatsImpl instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'examId': instance.examId,
      'examName': instance.examName,
      'examType': instance.examType,
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'classId': instance.classId,
      'className': instance.className,
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'academicYearId': instance.academicYearId,
      'totalStudents': instance.totalStudents,
      'studentsAppeared': instance.studentsAppeared,
      'classAverage': instance.classAverage,
      'highestPercentage': instance.highestPercentage,
      'lowestPercentage': instance.lowestPercentage,
      'passedCount': instance.passedCount,
      'failedCount': instance.failedCount,
      'absentCount': instance.absentCount,
      'passPercentage': instance.passPercentage,
    };

_$GradeScaleImpl _$$GradeScaleImplFromJson(Map<String, dynamic> json) =>
    _$GradeScaleImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => GradeScaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$GradeScaleImplToJson(_$GradeScaleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt?.toIso8601String(),
      'items': instance.items,
    };

_$GradeScaleItemImpl _$$GradeScaleItemImplFromJson(Map<String, dynamic> json) =>
    _$GradeScaleItemImpl(
      id: json['id'] as String,
      gradeScaleId: json['gradeScaleId'] as String,
      grade: json['grade'] as String,
      minPercentage: (json['minPercentage'] as num).toDouble(),
      maxPercentage: (json['maxPercentage'] as num).toDouble(),
      gradePoint: (json['gradePoint'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$GradeScaleItemImplToJson(
        _$GradeScaleItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gradeScaleId': instance.gradeScaleId,
      'grade': instance.grade,
      'minPercentage': instance.minPercentage,
      'maxPercentage': instance.maxPercentage,
      'gradePoint': instance.gradePoint,
      'description': instance.description,
    };
