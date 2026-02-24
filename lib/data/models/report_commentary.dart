class ReportCommentary {
  final String studentId;
  final String studentName;
  final String remark;
  final bool isEdited;
  final bool isApproved;
  final bool isLLMGenerated;

  const ReportCommentary({
    required this.studentId,
    required this.studentName,
    required this.remark,
    this.isEdited = false,
    this.isApproved = false,
    this.isLLMGenerated = false,
  });

  ReportCommentary copyWith({
    String? remark,
    bool? isEdited,
    bool? isApproved,
  }) {
    return ReportCommentary(
      studentId: studentId,
      studentName: studentName,
      remark: remark ?? this.remark,
      isEdited: isEdited ?? this.isEdited,
      isApproved: isApproved ?? this.isApproved,
      isLLMGenerated: isLLMGenerated,
    );
  }
}
