class DigestSection {
  final String title;
  final String icon;
  final String content;
  final String? urgency; // 'normal', 'attention', 'urgent'

  const DigestSection({
    required this.title,
    required this.icon,
    required this.content,
    this.urgency = 'normal',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'icon': icon,
        'content': content,
        'urgency': urgency,
      };

  factory DigestSection.fromJson(Map<String, dynamic> json) => DigestSection(
        title: json['title'] ?? '',
        icon: json['icon'] ?? 'info',
        content: json['content'] ?? '',
        urgency: json['urgency'] ?? 'normal',
      );
}

class DigestTemplateEngine {
  DigestTemplateEngine._();

  static String generateSummary({
    required String studentName,
    required int presentDays,
    required int totalDays,
    required List<String> highlights,
    double? riskScore,
  }) {
    final buffer = StringBuffer();
    final firstName = studentName.split(' ').first;

    // Attendance sentence
    if (totalDays > 0) {
      final pct = (presentDays / totalDays * 100).round();
      if (pct >= 90) {
        buffer.write('$firstName had an excellent week with $pct% attendance. ');
      } else if (pct >= 75) {
        buffer.write(
            '$firstName attended $presentDays of $totalDays days this week ($pct%). ');
      } else if (pct >= 50) {
        buffer.write(
            '$firstName\'s attendance needs attention — only $presentDays of $totalDays days ($pct%). ');
      } else {
        buffer.write(
            'Urgent: $firstName attended only $presentDays of $totalDays days this week. ');
      }
    }

    // Highlights
    if (highlights.isNotEmpty) {
      buffer.write(highlights.first);
      if (highlights.length > 1) {
        buffer.write(' Also, ${highlights[1].toLowerCase()}');
      }
    }

    // Risk note
    if (riskScore != null && riskScore > 50) {
      buffer.write(
          ' Our system has flagged some areas that may need attention.');
    }

    return buffer.toString().trim();
  }

  static List<DigestSection> generateSections({
    required int presentDays,
    required int absentDays,
    required int lateDays,
    required int totalDays,
    required List<String> highlights,
    required List<String> events,
    double? riskScore,
  }) {
    final sections = <DigestSection>[];

    // Attendance section
    final attPct =
        totalDays > 0 ? (presentDays / totalDays * 100).round() : 0;
    final attUrgency = attPct < 75 ? 'attention' : 'normal';
    sections.add(DigestSection(
      title: 'Attendance',
      icon: 'calendar_today',
      content:
          'Present: $presentDays | Absent: $absentDays | Late: $lateDays — $attPct% attendance rate',
      urgency: attUrgency,
    ));

    // Academic highlights
    if (highlights.isNotEmpty) {
      sections.add(DigestSection(
        title: 'Academic Highlights',
        icon: 'school',
        content: highlights.join('. '),
      ));
    }

    // Upcoming events
    if (events.isNotEmpty) {
      sections.add(DigestSection(
        title: 'Upcoming',
        icon: 'event',
        content: events.join('. '),
      ));
    }

    // Risk/tips section
    if (riskScore != null && riskScore > 30) {
      String tip;
      String urgency;
      if (riskScore > 70) {
        tip =
            'Your child may need additional support. Please consider scheduling a meeting with the class teacher.';
        urgency = 'urgent';
      } else if (riskScore > 50) {
        tip =
            'Some areas need attention. Encourage regular study habits and ensure homework is completed on time.';
        urgency = 'attention';
      } else {
        tip =
            'Keep up the good work! Consistent effort in all subjects will help maintain progress.';
        urgency = 'normal';
      }
      sections.add(DigestSection(
        title: 'Tips for Parents',
        icon: 'lightbulb',
        content: tip,
        urgency: urgency,
      ));
    }

    return sections;
  }

  static String generateTitle({
    required String studentName,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final startStr = '${weekStart.day} ${months[weekStart.month - 1]}';
    final endStr = '${weekEnd.day} ${months[weekEnd.month - 1]}';
    return 'Weekly Update for ${studentName.split(' ').first}: $startStr - $endStr';
  }
}
