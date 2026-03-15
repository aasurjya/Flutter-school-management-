import 'package:flutter/material.dart';
import '../../../../data/models/admission.dart';

/// Color-coded status badge for application status
class ApplicationStatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  final bool large;

  const ApplicationStatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _statusColors(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(large ? 12 : 8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: large ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, Color) _statusColors(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return (const Color(0xFF64748B), const Color(0xFFF1F5F9));
      case ApplicationStatus.submitted:
        return (const Color(0xFF3B82F6), const Color(0xFFDBEAFE));
      case ApplicationStatus.underReview:
        return (const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
      case ApplicationStatus.interviewScheduled:
        return (const Color(0xFFF97316), const Color(0xFFEDE9FE));
      case ApplicationStatus.accepted:
        return (const Color(0xFF22C55E), const Color(0xFFDCFCE7));
      case ApplicationStatus.rejected:
        return (const Color(0xFFEF4444), const Color(0xFFFEE2E2));
      case ApplicationStatus.waitlisted:
        return (const Color(0xFFF97316), const Color(0xFFFED7AA));
      case ApplicationStatus.enrolled:
        return (const Color(0xFF059669), const Color(0xFFA7F3D0));
      case ApplicationStatus.withdrawn:
        return (const Color(0xFF6B7280), const Color(0xFFF3F4F6));
    }
  }
}

/// Color-coded status badge for inquiry status
class InquiryStatusBadge extends StatelessWidget {
  final InquiryStatus status;

  const InquiryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _statusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, Color) _statusColors(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.newInquiry:
        return (const Color(0xFF3B82F6), const Color(0xFFDBEAFE));
      case InquiryStatus.contacted:
        return (const Color(0xFFF97316), const Color(0xFFEDE9FE));
      case InquiryStatus.visitScheduled:
        return (const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
      case InquiryStatus.visitCompleted:
        return (const Color(0xFF06B6D4), const Color(0xFFCFFAFE));
      case InquiryStatus.applicationSent:
        return (const Color(0xFF22C55E), const Color(0xFFDCFCE7));
      case InquiryStatus.converted:
        return (const Color(0xFF059669), const Color(0xFFA7F3D0));
      case InquiryStatus.lost:
        return (const Color(0xFFEF4444), const Color(0xFFFEE2E2));
    }
  }
}

/// Color-coded status badge for interview status
class InterviewStatusBadge extends StatelessWidget {
  final InterviewStatus status;

  const InterviewStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _statusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, Color) _statusColors(InterviewStatus status) {
    switch (status) {
      case InterviewStatus.scheduled:
        return (const Color(0xFF3B82F6), const Color(0xFFDBEAFE));
      case InterviewStatus.completed:
        return (const Color(0xFF22C55E), const Color(0xFFDCFCE7));
      case InterviewStatus.cancelled:
        return (const Color(0xFFEF4444), const Color(0xFFFEE2E2));
      case InterviewStatus.rescheduled:
        return (const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
      case InterviewStatus.noShow:
        return (const Color(0xFF6B7280), const Color(0xFFF3F4F6));
    }
  }
}

/// Document status badge
class DocumentStatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const DocumentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon) = _statusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color, IconData) _statusInfo(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return (
          const Color(0xFF64748B),
          const Color(0xFFF1F5F9),
          Icons.schedule,
        );
      case DocumentStatus.uploaded:
        return (
          const Color(0xFF3B82F6),
          const Color(0xFFDBEAFE),
          Icons.cloud_upload,
        );
      case DocumentStatus.verified:
        return (
          const Color(0xFF22C55E),
          const Color(0xFFDCFCE7),
          Icons.check_circle,
        );
      case DocumentStatus.rejected:
        return (
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2),
          Icons.cancel,
        );
    }
  }
}
