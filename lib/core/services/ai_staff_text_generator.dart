import 'ai_text_generator.dart';
import 'deepseek_service.dart';

/// AI text generation methods for operational staff roles.
///
/// Extracted from [AITextGenerator] to keep the main file under 800 lines.
/// Uses the same [DeepSeekService] backend and fallback pattern.
class AIStaffTextGenerator {
  final DeepSeekService? _service;

  const AIStaffTextGenerator({DeepSeekService? service}) : _service = service;

  // ---------------------------------------------------------------------------
  // Generic orchestrator (mirrors AITextGenerator._generate)
  // ---------------------------------------------------------------------------

  Future<AITextResult> _generate({
    required String systemPrompt,
    required String userPrompt,
    required String fallback,
    double temperature = 0.7,
    int maxTokens = 300,
  }) async {
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
    } catch (_) {
      return AITextResult(text: fallback);
    }
  }

  // ---------------------------------------------------------------------------
  // 16. Fee Collection Insight (Accountant)
  // ---------------------------------------------------------------------------

  static const _feeInsightSystemPrompt =
      'You are a financial analyst for a school. Given fee collection metrics, '
      'write a 2-3 sentence insight highlighting the collection rate, overdue '
      'trends, and one suggestion to improve collections. Be professional and '
      'concise. Do not use markdown or bullet points.';

  Future<AITextResult> generateFeeCollectionInsight({
    required int overdueCount,
    required double collectionRate,
    required double totalBilled,
    required double totalCollected,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Overdue invoices: $overdueCount')
      ..writeln('Collection rate: ${collectionRate.round()}%')
      ..writeln(
          'Total billed: \u20B9${totalBilled.toStringAsFixed(0)}')
      ..writeln(
          'Total collected: \u20B9${totalCollected.toStringAsFixed(0)}')
      ..writeln('Write a 2-3 sentence fee collection insight.');

    return _generate(
      systemPrompt: _feeInsightSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 250,
    );
  }

  // ---------------------------------------------------------------------------
  // 17. Book Recommendation (Librarian)
  // ---------------------------------------------------------------------------

  static const _bookRecommendationSystemPrompt =
      'You are a school librarian assistant. Given borrowing statistics and '
      'popular genres, write a 2-3 sentence recommendation about which books '
      'to promote or acquire next. Be encouraging and student-focused. '
      'Do not use markdown or bullet points.';

  Future<AITextResult> generateBookRecommendation({
    required List<String> popularGenres,
    required int totalIssued,
    required int overdueReturns,
    required int catalogSize,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln(
          'Popular genres: ${popularGenres.isNotEmpty ? popularGenres.join(", ") : "N/A"}')
      ..writeln('Books issued today: $totalIssued')
      ..writeln('Overdue returns: $overdueReturns')
      ..writeln('Total catalog size: $catalogSize')
      ..writeln('Write a 2-3 sentence library recommendation.');

    return _generate(
      systemPrompt: _bookRecommendationSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.6,
      maxTokens: 250,
    );
  }

  // ---------------------------------------------------------------------------
  // 18. Route Insight (Transport Manager)
  // ---------------------------------------------------------------------------

  static const _routeInsightSystemPrompt =
      'You are a transport coordinator for a school. Given route and vehicle '
      'metrics, write a 2-3 sentence insight about fleet utilization, capacity, '
      'and any concerns. End with one suggestion. Do not use markdown or '
      'bullet points.';

  Future<AITextResult> generateRouteInsight({
    required int activeRoutes,
    required double capacityPercent,
    required int totalVehicles,
    required int activeTrips,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Active routes: $activeRoutes')
      ..writeln('Fleet capacity utilization: ${capacityPercent.round()}%')
      ..writeln('Total vehicles: $totalVehicles')
      ..writeln('Active trips today: $activeTrips')
      ..writeln('Write a 2-3 sentence transport insight.');

    return _generate(
      systemPrompt: _routeInsightSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 250,
    );
  }

  // ---------------------------------------------------------------------------
  // 19. Hostel Insight (Hostel Warden)
  // ---------------------------------------------------------------------------

  static const _hostelInsightSystemPrompt =
      'You are a hostel management assistant for a school. Given occupancy '
      'and complaint data, write a 2-3 sentence insight covering room '
      'utilization and any maintenance concerns. End with one suggestion. '
      'Do not use markdown or bullet points.';

  Future<AITextResult> generateHostelInsight({
    required double occupancyPercent,
    required int availableBeds,
    required int maintenanceRequests,
    required int totalHostels,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Occupancy rate: ${occupancyPercent.round()}%')
      ..writeln('Available beds: $availableBeds')
      ..writeln('Pending maintenance requests: $maintenanceRequests')
      ..writeln('Total hostels: $totalHostels')
      ..writeln('Write a 2-3 sentence hostel insight.');

    return _generate(
      systemPrompt: _hostelInsightSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 250,
    );
  }

  // ---------------------------------------------------------------------------
  // 20. Visitor Insight (Receptionist)
  // ---------------------------------------------------------------------------

  static const _visitorInsightSystemPrompt =
      'You are a front-desk assistant for a school. Given visitor statistics, '
      'write a 2-3 sentence insight about visitor traffic patterns and '
      'pre-registration trends. End with one suggestion. Do not use markdown '
      'or bullet points.';

  Future<AITextResult> generateVisitorInsight({
    required int dailyVisitorCount,
    required int onPremises,
    required int preRegistrations,
    required int checkedOut,
    required String fallback,
  }) {
    final userPrompt = StringBuffer()
      ..writeln('Visitors today: $dailyVisitorCount')
      ..writeln('Currently on premises: $onPremises')
      ..writeln('Pre-registered: $preRegistrations')
      ..writeln('Checked out: $checkedOut')
      ..writeln('Write a 2-3 sentence visitor insight.');

    return _generate(
      systemPrompt: _visitorInsightSystemPrompt,
      userPrompt: userPrompt.toString(),
      fallback: fallback,
      temperature: 0.5,
      maxTokens: 250,
    );
  }
}
