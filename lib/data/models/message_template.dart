import 'package:flutter/material.dart';

enum MessageType {
  attendanceWarning,
  feeReminder,
  achievementPraise,
  behavioralNotice,
  ptmInvitation,
  general;

  String get label {
    switch (this) {
      case MessageType.attendanceWarning:
        return 'Attendance Warning';
      case MessageType.feeReminder:
        return 'Fee Reminder';
      case MessageType.achievementPraise:
        return 'Achievement Praise';
      case MessageType.behavioralNotice:
        return 'Behavioral Notice';
      case MessageType.ptmInvitation:
        return 'PTM Invitation';
      case MessageType.general:
        return 'General Message';
    }
  }

  IconData get icon {
    switch (this) {
      case MessageType.attendanceWarning:
        return Icons.event_busy;
      case MessageType.feeReminder:
        return Icons.currency_rupee;
      case MessageType.achievementPraise:
        return Icons.emoji_events;
      case MessageType.behavioralNotice:
        return Icons.report;
      case MessageType.ptmInvitation:
        return Icons.group;
      case MessageType.general:
        return Icons.mail_outline;
    }
  }

  Color get color {
    switch (this) {
      case MessageType.attendanceWarning:
        return const Color(0xFFF97316);
      case MessageType.feeReminder:
        return const Color(0xFFEF4444);
      case MessageType.achievementPraise:
        return const Color(0xFF22C55E);
      case MessageType.behavioralNotice:
        return const Color(0xFFEAB308);
      case MessageType.ptmInvitation:
        return const Color(0xFF3B82F6);
      case MessageType.general:
        return const Color(0xFF8B5CF6);
    }
  }
}

class MessageDraft {
  final MessageType type;
  final String? studentId;
  final String studentName;
  final String parentName;
  final String subject;
  final String body;
  final bool isLLMGenerated;

  const MessageDraft({
    required this.type,
    this.studentId,
    required this.studentName,
    required this.parentName,
    required this.subject,
    required this.body,
    this.isLLMGenerated = false,
  });

  MessageDraft copyWith({
    String? subject,
    String? body,
  }) {
    return MessageDraft(
      type: type,
      studentId: studentId,
      studentName: studentName,
      parentName: parentName,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      isLLMGenerated: isLLMGenerated,
    );
  }
}

class MessageDraftRequest {
  final String studentId;
  final String studentName;
  final MessageType messageType;

  const MessageDraftRequest({
    required this.studentId,
    required this.studentName,
    required this.messageType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageDraftRequest &&
          studentId == other.studentId &&
          messageType == other.messageType;

  @override
  int get hashCode => Object.hash(studentId, messageType);
}
