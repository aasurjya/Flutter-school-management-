import 'dart:developer' as developer;

import '../ai/ai_gateway_client.dart';
import '../ai/ai_router.dart';
import 'deepseek_service.dart';

class AITextResult {
  final String text;
  final bool isLLMGenerated;
  final bool isFromCache;

  const AITextResult({
    required this.text,
    this.isLLMGenerated = false,
    this.isFromCache = false,
  });
}

class AITextGenerator {
  final AiGatewayClient? _gateway;
  final DeepSeekService? _service;
  final AIRouter? _router;

  const AITextGenerator({
    AiGatewayClient? gateway,
    DeepSeekService? service,
    AIRouter? router,
  })  : _gateway = gateway,
        _service = service,
        _router = router;

  // ---------------------------------------------------------------------------
  // Generic orchestrator (preference order):
  //   1. AiGatewayClient — production path; server enforces quota/cost/keys
  //   2. AIRouter        — debug / local-dev path with direct adapters
  //   3. DeepSeekService — legacy direct path
  //   4. Fallback string — graceful degradation
  // featureType MUST match a key in the gateway's FEATURE_ROUTES table
  // (see supabase/functions/ai-gateway/index.ts).
  // ---------------------------------------------------------------------------

  Future<AITextResult> _generate({
    required String featureType,
    required String systemPrompt,
    required String userPrompt,
    required String fallback,
    double temperature = 0.7,
    int maxTokens = 300,
    bool skipCache = false,
    Duration? cacheTtl,
    String? responseFormat,
  }) async {
    // Primary: gateway. On any quota block or transport error, fall through.
    if (_gateway != null) {
      try {
        final res = await _gateway.complete(
          featureType: featureType,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
          responseFormat: responseFormat ?? 'text',
          skipCache: skipCache,
        );
        return AITextResult(
          text: res.text,
          isLLMGenerated: true,
          isFromCache: res.cached,
        );
      } on AiGatewayQuotaException catch (e) {
        // Quota blocked — surface fallback string; banner is already raised
        // via the QuotaController stream. Don't fall back to direct adapters
        // (that would defeat the purpose of the quota gate).
        developer.log(
          'ai-gateway blocked: ${e.reason}',
          name: 'AITextGenerator',
        );
        return AITextResult(text: fallback);
      } catch (e) {
        developer.log(
          'ai-gateway transport failed, trying local adapters',
          name: 'AITextGenerator',
          error: e,
        );
        // Fall through to debug paths.
      }
    }

    // Debug / local-dev fallback: direct AIRouter.
    if (_router != null) {
      try {
        final response = await _router.generateText(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
          skipCache: skipCache,
          cacheTtl: cacheTtl,
        );
        return AITextResult(
          text: response.text,
          isLLMGenerated: true,
          isFromCache: response.isFromCache,
        );
      } catch (e) {
        developer.log(
          'AIRouter failed, trying legacy service',
          name: 'AITextGenerator',
          error: e,
        );
      }
    }

    // Legacy path: direct DeepSeek service.
    if (_service == null) {
      return AITextResult(text: fallback);
    }

    try {
      final text = await _service.chatCompletion(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      return AITextResult(text: text, isLLMGenerated: true);
    } catch (e) {
      developer.log(
        'AI text generation failed, using fallback',
        name: 'AITextGenerator',
        error: e,
      );
      return AITextResult(text: fallback);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Parent Digest Summary
  // ---------------------------------------------------------------------------

  static const _digestSystemPrompt =
      'You are a warm, supportive school communication assistant writing weekly '
      'parent digest summaries. Write 3-5 sentences. Celebrate wins first, then '
      'gently flag any concerns. Use the parent\'s child\'s first name. '
      'Be encouraging but honest. Do not use markdown or bullet points.';

  Future<AITextResult> generateDigestSummary({
    required String studentName,
    required int presentDays,
    required int totalDays,
    required List<String> highlights,
    required String fallback,
  }) {
    final firstName = studentName.split(' ').first;
    final attPct =
        totalDays > 0 ? (presentDays / totalDays * 100).round() : 0;

    final userPrompt = StringBuffer()
      ..writeln('Student: $firstName')
      ..writeln('Attendance this week: $presentDays/$totalDays days ($attPct%)')
      ..writeln(
          'Academic highlights: ${highlights.isNotEmpty ? highlights.join("; ") : "None this week"}')
      ..writeln(
          'Write a warm 3-5 sentence parent digest summary for this week.');

    return _generate(
      featureType: 'parent_digest',
      systemPrompt: _digestSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.7,
      maxTokens: 300,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Risk Score Explanation
  // ---------------------------------------------------------------------------

  static const _riskSystemPrompt =
      'You are an empathetic school counselor AI assistant. Given a student\'s '
      'risk score breakdown, explain in 3-4 sentences why this student has been '
      'flagged. Be specific about which factors are concerning. End with 2 '
      'concrete, actionable suggestions. Do not use markdown or bullet points. '
      'Be supportive, not alarming.';

  Future<AITextResult> generateRiskExplanation({
    required String studentName,
    required String riskLevel,
    required double overallScore,
    required double attendanceScore,
    required double academicScore,
    required double feeScore,
    required double engagementScore,
    required List<String> flags,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Student: $studentName')
      ..writeln('Risk Level: $riskLevel (Score: ${overallScore.round()}/100)')
      ..writeln('Breakdown:')
      ..writeln('  - Attendance risk: ${attendanceScore.round()}/100')
      ..writeln('  - Academic risk: ${academicScore.round()}/100')
      ..writeln('  - Fee status risk: ${feeScore.round()}/100')
      ..writeln('  - Engagement risk: ${engagementScore.round()}/100')
      ..writeln('Flags: ${flags.isNotEmpty ? flags.join(", ") : "None"}')
      ..writeln('Explain why this student is flagged and suggest 2 actions.');

    return _generate(
      featureType: 'risk_explanation',
      systemPrompt: _riskSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 400,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Attendance Narrative
  // ---------------------------------------------------------------------------

  static const _attendanceSystemPrompt =
      'You are a data analyst assistant for school teachers. Given attendance '
      'pattern data for a class section, write a concise narrative summary '
      'under 100 words. Highlight key findings (worst days, chronic absentees, '
      'anomalies) and offer 1 actionable suggestion. Use plain language. '
      'Do not use markdown or bullet points.';

  Future<AITextResult> generateAttendanceNarrative({
    required List<String> problematicDays,
    required int chronicAbsenteeCount,
    required int anomalyCount,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln(
          'Problematic days (below 85% attendance): ${problematicDays.isNotEmpty ? problematicDays.join(", ") : "None"}')
      ..writeln('Chronic absentees (>20% absence rate): $chronicAbsenteeCount')
      ..writeln('Anomalies detected in last 30 days: $anomalyCount')
      ..writeln(
          'Summarize the key attendance patterns and suggest one improvement.');

    return _generate(
      featureType: 'attendance_narrative',
      systemPrompt: _attendanceSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.6,
      maxTokens: 350,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Early Warning Alert Explanation
  // ---------------------------------------------------------------------------

  static const _alertSystemPrompt =
      'You are a school counselor assistant. Given an early warning alert with '
      'its trigger conditions, explain in 3-4 sentences what is concerning and '
      'suggest 2 specific actions the school can take. Be supportive and '
      'action-oriented. Do not use markdown or bullet points.';

  Future<AITextResult> generateAlertExplanation({
    required String category,
    required String severity,
    required Map<String, dynamic> triggerConditions,
    required String studentName,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Student: $studentName')
      ..writeln('Alert Category: $category')
      ..writeln('Severity: $severity')
      ..writeln('Trigger Conditions:');
    for (final entry in triggerConditions.entries) {
      userPrompt.writeln('  - ${entry.key}: ${entry.value}');
    }
    userPrompt.writeln(
        'Explain what is concerning and suggest 2 specific actions.');

    return _generate(
      featureType: 'early_warning_alert',
      systemPrompt: _alertSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 350,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Study Plan Recommendations
  // ---------------------------------------------------------------------------

  static const _studyPlanSystemPrompt =
      'You are a friendly academic tutor for Indian school students. Given the '
      'student\'s subject performance and attendance pattern, create 3-4 specific '
      'study recommendations. Each recommendation should be on its own line. '
      'Be practical and encouraging. Do not use markdown or bullet points.';

  Future<AITextResult> generateStudyPlan({
    required String studentName,
    required Map<String, double> subjectPerformance,
    required double attendancePercent,
    required String fallback,
  }) {
    final firstName = studentName.split(' ').first;

    final userPrompt = StringBuffer()
      ..writeln('Student: $firstName')
      ..writeln('Attendance: ${attendancePercent.round()}%')
      ..writeln('Subject Performance:');
    for (final entry in subjectPerformance.entries) {
      userPrompt.writeln('  - ${entry.key}: ${entry.value.round()}%');
    }
    userPrompt.writeln(
        'Create 3-4 specific, actionable study recommendations.');

    return _generate(
      featureType: 'study_recommendation',
      systemPrompt: _studyPlanSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.7,
      maxTokens: 400,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Report Card Remark
  // ---------------------------------------------------------------------------

  static const _reportRemarkSystemPrompt =
      'You are an experienced class teacher in an Indian school writing report '
      'card remarks. Write a 3-5 sentence personalized remark. Start positive. '
      'Mention specific performance numbers. Reference attendance if relevant. '
      'End encouragingly. Do not use markdown or bullet points.';

  Future<AITextResult> generateReportRemark({
    required String studentName,
    required double attendancePercent,
    required double averagePercentage,
    required String fallback,
  }) {
    final firstName = studentName.split(' ').first;

    final userPrompt = StringBuffer()
      ..writeln('Student: $firstName')
      ..writeln('Average percentage: ${averagePercentage.round()}%')
      ..writeln('Attendance: ${attendancePercent.round()}%')
      ..writeln(
          'Write a personalized 3-5 sentence report card remark.');

    return _generate(
      featureType: 'report_card_remark',
      systemPrompt: _reportRemarkSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.7,
      maxTokens: 300,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Parent Message
  // ---------------------------------------------------------------------------

  static const _parentMessageSystemPrompt =
      'You are a professional school communication assistant helping teachers '
      'write messages to parents. Write a polite, warm, professional message '
      'in letter format. Include a greeting, 2-3 paragraphs, and a closing. '
      'Be respectful of Indian cultural norms. Do not use markdown.';

  Future<AITextResult> generateParentMessage({
    required String messageType,
    required String studentName,
    required String parentName,
    required Map<String, dynamic> contextData,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Message type: $messageType')
      ..writeln('Student: $studentName')
      ..writeln('Parent: $parentName');
    if (contextData.isNotEmpty) {
      userPrompt.writeln('Context:');
      for (final entry in contextData.entries) {
        userPrompt.writeln('  - ${entry.key}: ${entry.value}');
      }
    }
    userPrompt.writeln(
        'Write a professional parent message for this purpose.');

    return _generate(
      featureType: 'parent_message',
      systemPrompt: _parentMessageSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.6,
      maxTokens: 400,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Class Performance Narrative
  // ---------------------------------------------------------------------------

  static const _classNarrativeSystemPrompt =
      'You are a data analyst for a school principal. Given class performance '
      'data, write a 5-7 sentence analysis covering: overall class health, '
      'strongest and weakest subjects, attendance concerns, students needing '
      'attention, and one recommendation. Do not use markdown or bullet points.';

  Future<AITextResult> generateClassNarrative({
    required String className,
    required String sectionName,
    required double passRate,
    required double avgPercentage,
    required String bestSubject,
    required String worstSubject,
    required double attendancePct,
    required int riskCount,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Class: $className $sectionName')
      ..writeln('Pass rate: ${passRate.round()}%')
      ..writeln('Average percentage: ${avgPercentage.round()}%')
      ..writeln('Best subject: $bestSubject')
      ..writeln('Weakest subject: $worstSubject')
      ..writeln('Attendance: ${attendancePct.round()}%')
      ..writeln('High-risk students: $riskCount')
      ..writeln(
          'Write a 5-7 sentence class performance analysis with one recommendation.');

    return _generate(
      featureType: 'class_performance',
      systemPrompt: _classNarrativeSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 500,
    );
  }

  // ---------------------------------------------------------------------------
  // 9. Syllabus Structure Generation
  // ---------------------------------------------------------------------------

  static const _syllabusSystemPrompt =
      'You are an expert Indian school curriculum designer. Given a subject, '
      'class level, and optional board/textbook, generate a structured syllabus. '
      'Output ONLY valid JSON — no markdown, no explanation. '
      'Return a JSON array of units. Each unit has: '
      '"title" (string), "description" (string), "estimated_periods" (int), '
      '"learning_objectives" (string array), and "chapters" (array). '
      'Each chapter has the same fields plus a "topics" array. '
      'Each topic has the same fields (no sub-array). '
      'Aim for 4-6 units, 2-4 chapters per unit, 2-5 topics per chapter. '
      'Use Indian curriculum terminology and standards.';

  Future<AITextResult> generateSyllabusStructure({
    required String subjectName,
    required String className,
    String? board,
    String? textbookName,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Subject: $subjectName')
      ..writeln('Class: $className');
    if (board != null && board.isNotEmpty) {
      userPrompt.writeln('Board: $board');
    }
    if (textbookName != null && textbookName.isNotEmpty) {
      userPrompt.writeln('Textbook: $textbookName');
    }
    userPrompt.writeln(
        'Generate a complete syllabus structure as a JSON array of units.');

    return _generate(
      featureType: 'syllabus_structure',
      systemPrompt: _syllabusSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.3,
      maxTokens: 2000,
    );
  }

  // ---------------------------------------------------------------------------
  // 10. Lesson Plan Generation
  // ---------------------------------------------------------------------------

  static const _lessonPlanSystemPrompt =
      'You are an experienced Indian school teacher and lesson planner. '
      'Create a lesson plan as valid JSON with these exact keys: '
      '"objective" (string), "warm_up" (string, 5-min activity), '
      '"main_activity" (string, detailed teaching steps), '
      '"assessment_activity" (string, how to check understanding), '
      '"homework" (string), "materials_needed" (string), '
      '"differentiation_notes" (string, for mixed-ability classes). '
      'Output ONLY valid JSON — no markdown, no explanation. '
      'Be practical, engaging, and age-appropriate.';

  Future<AITextResult> generateLessonPlan({
    required String topicTitle,
    required String subjectName,
    required String className,
    int durationMinutes = 40,
    List<String>? learningObjectives,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Topic: $topicTitle')
      ..writeln('Subject: $subjectName')
      ..writeln('Class: $className')
      ..writeln('Duration: $durationMinutes minutes');
    if (learningObjectives != null && learningObjectives.isNotEmpty) {
      userPrompt.writeln(
          'Learning objectives: ${learningObjectives.join("; ")}');
    }
    userPrompt.writeln(
        'Create a detailed lesson plan as JSON.');

    return _generate(
      featureType: 'lesson_plan_json',
      systemPrompt: _lessonPlanSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 800,
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Question Paper Generation
  // ---------------------------------------------------------------------------

  static const _questionPaperSystemPrompt =
      'You are an expert Indian school examiner. Generate a question paper '
      'as valid JSON — no markdown, no explanation. '
      'Output a JSON object with key "sections" (array). '
      'Each section has: "title" (string), "instructions" (string), '
      '"questions" (array). '
      'Each question has: "question_text" (string), "question_type" '
      '("mcq"|"short_answer"|"long_answer"|"true_false"|"fill_blank"), '
      '"marks" (number), "difficulty" ("easy"|"medium"|"hard"), '
      '"options" (array of strings, only for mcq/true_false), '
      '"correct_answer" (string), "explanation" (string). '
      'Group questions by type into sections (Section A — Objective, '
      'Section B — Short Answer, Section C — Long Answer). '
      'Ensure total marks match the requested total. '
      'Use Indian curriculum standards and terminology. '
      'Output ONLY valid JSON.';

  Future<AITextResult> generateQuestionPaper({
    required String subjectName,
    required String className,
    required String examType,
    required int totalMarks,
    required int durationMinutes,
    required String difficulty,
    required List<String> topics,
    String? board,
    Map<String, int>? questionTypeCounts,
    String? extraInstructions,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Subject: $subjectName')
      ..writeln('Class: $className')
      ..writeln('Exam type: $examType')
      ..writeln('Total marks: $totalMarks')
      ..writeln('Duration: $durationMinutes minutes')
      ..writeln('Overall difficulty: $difficulty');

    if (board != null && board.isNotEmpty) {
      userPrompt.writeln('Board/Curriculum: $board');
    }

    if (topics.isNotEmpty) {
      userPrompt
          .writeln('Topics to cover: ${topics.take(10).join(", ")}');
    }

    if (questionTypeCounts != null && questionTypeCounts.isNotEmpty) {
      userPrompt.writeln('Question distribution:');
      for (final entry in questionTypeCounts.entries) {
        userPrompt.writeln('  - ${entry.key}: ${entry.value} questions');
      }
    } else {
      userPrompt.writeln(
          'Auto-distribute question types appropriately for $totalMarks marks.');
    }

    if (extraInstructions != null && extraInstructions.isNotEmpty) {
      userPrompt.writeln('Extra instructions: $extraInstructions');
    }

    userPrompt.writeln(
        'Generate a complete question paper as a JSON object with sections array.');

    return _generate(
      featureType: 'question_paper_json',
      systemPrompt: _questionPaperSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.4,
      maxTokens: 4000,
    );
  }

  // ---------------------------------------------------------------------------
  // 12. Fee Reminder Message
  // ---------------------------------------------------------------------------

  static const _feeReminderSystemPrompt =
      'You are a professional school fee collection assistant for an Indian school. '
      'Write a polite, firm, and empathetic fee reminder message. '
      'The tone should be respectful but clear about urgency. '
      'Keep it under 100 words. Write in plain English without markdown. '
      'End with the school name placeholder [School Name]. '
      'Do not include email headers or subject lines — just the message body.';

  Future<AITextResult> generateFeeReminderMessage({
    required String parentName,
    required String studentName,
    required String className,
    required double amountDue,
    required int daysOverdue,
    required int riskScore,
    required String recommendedAction,
    required List<String> riskFactors,
    required String fallback,
  }) {
    final overdueText = daysOverdue > 0
        ? 'The invoice is $daysOverdue day(s) overdue.'
        : 'The invoice is due soon.';

    final urgency = riskScore >= 71
        ? 'URGENT'
        : riskScore >= 41
            ? 'Important'
            : 'Friendly';

    final userPrompt = StringBuffer()
      ..writeln('Parent: $parentName')
      ..writeln('Student: $studentName, $className')
      ..writeln('Amount due: ₹${amountDue.toStringAsFixed(0)}')
      ..writeln(overdueText)
      ..writeln('Urgency level: $urgency')
      ..writeln('Recommended action: $recommendedAction');

    if (riskFactors.isNotEmpty) {
      userPrompt.writeln(
          'Context: ${riskFactors.take(2).join("; ")}');
    }

    userPrompt.writeln(
        'Write a $urgency fee reminder message (under 100 words) to this parent.');

    return _generate(
      featureType: 'fee_reminder',
      systemPrompt: _feeReminderSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.6,
      maxTokens: 200,
    );
  }

  // ---------------------------------------------------------------------------
  // 13. Trend Narrative
  // ---------------------------------------------------------------------------

  static const _trendSystemPrompt =
      'You are an analytics assistant for school administrators. Given trend '
      'prediction data (direction, confidence, data points), write a plain-language '
      'interpretation in 2-4 sentences. Mention the trend direction, confidence '
      'level, and what it means practically. Do not use markdown or bullet points.';

  Future<AITextResult> generateTrendNarrative({
    required String metricType,
    required String trendDirection,
    required double rSquared,
    required int dataPointCount,
    required double? latestValue,
    required double? predictedValue,
    required String fallback,
  }) {
    final confidence = rSquared >= 0.7
        ? 'high'
        : rSquared >= 0.4
            ? 'medium'
            : 'low';

    final userPrompt = StringBuffer()
      ..writeln('Metric: $metricType')
      ..writeln('Trend direction: $trendDirection')
      ..writeln(
          'Confidence: $confidence (R-squared: ${rSquared.toStringAsFixed(2)})')
      ..writeln('Data points: $dataPointCount')
      ..writeln(
          'Latest value: ${latestValue?.toStringAsFixed(1) ?? "N/A"}')
      ..writeln(
          'Predicted next value: ${predictedValue?.toStringAsFixed(1) ?? "N/A"}')
      ..writeln('Interpret this trend in 2-4 plain-language sentences.');

    return _generate(
      featureType: 'trend_narrative',
      systemPrompt: _trendSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 300,
    );
  }

  // ---------------------------------------------------------------------------
  // 14. School Health Narrative (Admin)
  // ---------------------------------------------------------------------------

  static const _schoolHealthSystemPrompt =
      'You are a data analyst for a school principal or administrator. Given '
      'key school health metrics, write a 3-5 sentence daily summary. Highlight '
      'the most notable metric (good or concerning), compare to expected norms, '
      'and end with one actionable suggestion. Do not use markdown or bullet '
      'points. Be concise and professional.';

  Future<AITextResult> generateSchoolHealthNarrative({
    required double attendancePercent,
    required double feeCollectionRate,
    required Map<String, int> riskDistribution,
    required int totalStudents,
    required String fallback,
  }) {
    final highRisk = (riskDistribution['high'] ?? 0) +
        (riskDistribution['critical'] ?? 0);

    final userPrompt = StringBuffer()
      ..writeln('Total students: $totalStudents')
      ..writeln('Today\'s attendance: ${attendancePercent.round()}%')
      ..writeln('Fee collection rate: ${feeCollectionRate.round()}%')
      ..writeln('High-risk students: $highRisk')
      ..writeln(
          'Risk distribution: ${riskDistribution.entries.map((e) => "${e.key}: ${e.value}").join(", ")}')
      ..writeln(
          'Write a 3-5 sentence school health summary with one suggestion.');

    return _generate(
      featureType: 'school_health',
      systemPrompt: _schoolHealthSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 350,
    );
  }

  // ---------------------------------------------------------------------------
  // 15. Platform Health Narrative (Super Admin)
  // ---------------------------------------------------------------------------

  static const _platformHealthSystemPrompt =
      'You are a platform analytics assistant for a multi-tenant school '
      'management SaaS. Given platform-wide metrics, write a 3-5 sentence '
      'summary covering tenant health, user activity, and revenue trends. '
      'Flag any concern and suggest one action. Do not use markdown or bullet '
      'points.';

  Future<AITextResult> generatePlatformHealthNarrative({
    required int tenantCount,
    required int totalStudents,
    required double activePercent,
    required double monthlyRevenue,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Active tenants: $tenantCount')
      ..writeln('Total students across platform: $totalStudents')
      ..writeln('Active user percentage: ${activePercent.round()}%')
      ..writeln(
          'Monthly revenue: \$${monthlyRevenue.toStringAsFixed(0)}')
      ..writeln(
          'Write a 3-5 sentence platform health summary with one suggestion.');

    return _generate(
      featureType: 'platform_health',
      systemPrompt: _platformHealthSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 350,
    );
  }

  // ---------------------------------------------------------------------------
  // 16. Pre-PTM Brief (Sprint 1.1)
  // ---------------------------------------------------------------------------
  // Teacher opens a scheduled appointment → AI produces 6 bullets so they
  // walk in prepared. Pulls structured context (attendance, recent marks,
  // risk score, behavior incidents, achievements) and asks for talking
  // points. Routes through gateway as feature_type = 'ptm_brief'.

  static const _ptmBriefSystemPrompt =
      'You are a teacher prep assistant. Given a student profile and recent '
      'history, produce a Parent-Teacher Meeting brief as EXACTLY SIX BULLETS '
      'in this order: '
      '(1) one-line academic summary, '
      '(2) one-line attendance & engagement summary, '
      '(3) one-line behavior summary, '
      '(4) the single biggest strength to praise, '
      '(5) the single most important concern to raise, '
      '(6) one concrete suggested action for the parent. '
      'Each bullet starts with "- " and is one sentence, no markdown bold, no '
      'preamble, no closing remarks. Use the student\'s first name. Be warm '
      'but specific. Never invent data — if a field is "n/a", reflect that.';

  Future<AITextResult> generatePtmBrief({
    required String studentName,
    required String className,
    int? attendancePercent,
    List<String> recentMarks = const [],
    String? riskLevel,
    int? recentIncidentCount,
    String? mostSevereRecentIncident,
    List<String> achievements = const [],
    required String fallback,
  }) {
    final firstName = studentName.split(' ').first;
    final att = attendancePercent != null ? '$attendancePercent%' : 'n/a';
    final marks =
        recentMarks.isNotEmpty ? recentMarks.join('; ') : 'n/a';
    final risk = riskLevel ?? 'n/a';
    final behavior = (recentIncidentCount ?? 0) > 0
        ? '${recentIncidentCount ?? 0} incident(s) in last 30 days'
            '${mostSevereRecentIncident != null ? " (most severe: $mostSevereRecentIncident)" : ""}'
        : 'No incidents in last 30 days';
    final wins =
        achievements.isNotEmpty ? achievements.join('; ') : 'n/a';

    final userPrompt = StringBuffer()
      ..writeln('Student: $firstName')
      ..writeln('Class: $className')
      ..writeln('Attendance this term: $att')
      ..writeln('Recent marks: $marks')
      ..writeln('Risk level: $risk')
      ..writeln('Behavior: $behavior')
      ..writeln('Achievements / recognitions: $wins')
      ..writeln('Produce the 6-bullet PTM brief now.');

    return _generate(
      featureType: 'ptm_brief',
      systemPrompt: _ptmBriefSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.6,
      maxTokens: 400,
    );
  }

  // ---------------------------------------------------------------------------
  // 17. Principal Weekly Digest (Sprint 1.2)
  // ---------------------------------------------------------------------------
  // Friday in-app card narrating the school week. Distinct from parent
  // digest — audience is the principal, tone is executive briefing.

  static const _principalDigestSystemPrompt =
      'You are an executive-briefing AI assistant for a school principal. '
      'Given week-level KPIs, write a concise 5-7 sentence digest. '
      'Lead with the most important data point. Quantify where possible. '
      'Surface ONE actionable recommendation at the end (start it with '
      '"Recommended action: "). No markdown, no bullets, plain prose. '
      'Avoid hype words. Be honest about declines.';

  Future<AITextResult> generatePrincipalDigest({
    required String schoolName,
    required String weekStartDate,
    required int attendancePercent,
    required int attendanceDeltaPct,
    required int feeCollectionPercent,
    required int feeCollectionDeltaPct,
    required int incidentsThisWeek,
    required int incidentsDeltaCount,
    required int escalatingStudents,
    required int atRiskStudents,
    required String fallback,
  }) {
    String sign(int v) =>
        v > 0 ? '+$v' : v < 0 ? '$v' : '±0';

    final userPrompt = StringBuffer()
      ..writeln('School: $schoolName')
      ..writeln('Week beginning: $weekStartDate')
      ..writeln(
          'Attendance: $attendancePercent% (${sign(attendanceDeltaPct)} pts vs prior week)')
      ..writeln(
          'Fee collection: $feeCollectionPercent% (${sign(feeCollectionDeltaPct)} pts vs prior week)')
      ..writeln(
          'Discipline incidents: $incidentsThisWeek (${sign(incidentsDeltaCount)} vs prior week)')
      ..writeln('Escalating students this fortnight: $escalatingStudents')
      ..writeln('Students flagged at-risk: $atRiskStudents')
      ..writeln('Write the digest now.');

    return _generate(
      featureType: 'principal_digest',
      systemPrompt: _principalDigestSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 400,
    );
  }
}
