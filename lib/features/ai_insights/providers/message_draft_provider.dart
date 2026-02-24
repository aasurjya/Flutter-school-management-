import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../data/models/message_template.dart';

final messageDraftProvider =
    FutureProvider.family<MessageDraft, MessageDraftRequest>(
  (ref, request) async {
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);
    final parentName =
        'Parent'; // In production, fetch from student's parent record

    // Generate subject line based on type
    final subject = _getSubject(request.messageType, request.studentName);

    // Build fallback
    final fallback =
        _getFallback(request.messageType, request.studentName, parentName);

    try {
      final result = await aiTextGenerator.generateParentMessage(
        messageType: request.messageType.label,
        studentName: request.studentName,
        parentName: parentName,
        contextData: {},
        fallback: fallback,
      );

      return MessageDraft(
        type: request.messageType,
        studentId: request.studentId,
        studentName: request.studentName,
        parentName: parentName,
        subject: subject,
        body: result.text,
        isLLMGenerated: result.isLLMGenerated,
      );
    } catch (_) {
      return MessageDraft(
        type: request.messageType,
        studentId: request.studentId,
        studentName: request.studentName,
        parentName: parentName,
        subject: subject,
        body: fallback,
      );
    }
  },
);

String _getSubject(MessageType type, String studentName) {
  switch (type) {
    case MessageType.attendanceWarning:
      return 'Attendance Concern - $studentName';
    case MessageType.feeReminder:
      return 'Fee Payment Reminder - $studentName';
    case MessageType.achievementPraise:
      return 'Academic Achievement - $studentName';
    case MessageType.behavioralNotice:
      return 'Behavioral Notice - $studentName';
    case MessageType.ptmInvitation:
      return 'Parent-Teacher Meeting Invitation';
    case MessageType.general:
      return 'Regarding $studentName';
  }
}

String _getFallback(MessageType type, String studentName, String parentName) {
  switch (type) {
    case MessageType.attendanceWarning:
      return 'Dear $parentName,\n\nWe have noticed that $studentName\'s attendance has dropped below acceptable levels this term. Regular attendance is crucial for academic success. We kindly request your support in ensuring $studentName attends school regularly.\n\nPlease feel free to reach out if there are any concerns we can help address.\n\nWarm regards,\nClass Teacher';
    case MessageType.feeReminder:
      return 'Dear $parentName,\n\nThis is a gentle reminder regarding the pending fee payment for $studentName. Kindly arrange for the payment at your earliest convenience to avoid any late fee charges.\n\nIf you have already made the payment, please disregard this message.\n\nThank you,\nAccounts Department';
    case MessageType.achievementPraise:
      return 'Dear $parentName,\n\nWe are delighted to inform you that $studentName has demonstrated excellent academic performance recently. This achievement reflects dedication and hard work.\n\nWe encourage $studentName to continue this wonderful progress.\n\nWith warm regards,\nClass Teacher';
    case MessageType.behavioralNotice:
      return 'Dear $parentName,\n\nWe would like to bring to your attention some behavioral concerns regarding $studentName that have been observed recently. We believe in working together with parents to support our students.\n\nWe would appreciate the opportunity to discuss this matter with you at your convenience.\n\nRegards,\nClass Teacher';
    case MessageType.ptmInvitation:
      return 'Dear $parentName,\n\nYou are cordially invited to attend the upcoming Parent-Teacher Meeting. This will be an excellent opportunity to discuss $studentName\'s progress and development.\n\nPlease confirm your availability at your earliest convenience.\n\nWarm regards,\nSchool Administration';
    case MessageType.general:
      return 'Dear $parentName,\n\nWe hope this message finds you well. We are writing to you regarding $studentName.\n\nPlease feel free to reach out if you have any questions.\n\nWarm regards,\nClass Teacher';
  }
}
