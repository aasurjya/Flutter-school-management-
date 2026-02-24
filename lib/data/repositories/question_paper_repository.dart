import '../models/question_paper.dart';
import 'base_repository.dart';

class QuestionPaperRepository extends BaseRepository {
  QuestionPaperRepository(super.client);

  // ==================== LIST ====================

  Future<List<QuestionPaper>> getQuestionPapers({
    String? subjectId,
    String? classId,
    PaperStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    // Build filters first (before order/range which returns a TransformBuilder)
    var filterQuery = client
        .from('question_papers')
        .select('*, subjects(name), classes(name)')
        .eq('tenant_id', requireTenantId);

    if (subjectId != null) {
      filterQuery = filterQuery.eq('subject_id', subjectId);
    }
    if (classId != null) {
      filterQuery = filterQuery.eq('class_id', classId);
    }
    if (status != null) {
      filterQuery = filterQuery.eq('status', status.dbValue);
    }

    final response = await filterQuery
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => QuestionPaper.fromJson(json))
        .toList();
  }

  // ==================== DETAIL ====================

  Future<QuestionPaper> getQuestionPaper(String paperId) async {
    final response = await client
        .from('question_papers')
        .select('''
          *,
          subjects(name),
          classes(name),
          question_paper_sections(
            *,
            question_paper_items(*)
          )
        ''')
        .eq('id', paperId)
        .eq('tenant_id', requireTenantId)
        .single();

    return QuestionPaper.fromJson(response);
  }

  // ==================== CREATE ====================

  Future<QuestionPaper> createQuestionPaper({
    required Map<String, dynamic> paperData,
    required List<Map<String, dynamic>> sectionsWithItems,
  }) async {
    // Insert paper
    final paperResponse = await client
        .from('question_papers')
        .insert({
          ...paperData,
          'tenant_id': requireTenantId,
          'created_by': client.auth.currentUser?.id,
        })
        .select()
        .single();

    final paperId = paperResponse['id'] as String;

    // Insert sections + items
    for (var i = 0; i < sectionsWithItems.length; i++) {
      final sectionData = Map<String, dynamic>.from(sectionsWithItems[i]);
      final items =
          (sectionData.remove('items') as List<dynamic>?) ?? [];

      sectionData['paper_id'] = paperId;
      sectionData['sequence_order'] = i + 1;

      final sectionResponse = await client
          .from('question_paper_sections')
          .insert(sectionData)
          .select()
          .single();

      final sectionId = sectionResponse['id'] as String;

      if (items.isNotEmpty) {
        final itemInserts = items.asMap().entries.map((entry) {
          final item = Map<String, dynamic>.from(entry.value);
          return {
            ...item,
            'paper_id': paperId,
            'section_id': sectionId,
            'sequence_order': entry.key + 1,
          };
        }).toList();

        await client.from('question_paper_items').insert(itemInserts);
      }
    }

    return getQuestionPaper(paperId);
  }

  // ==================== UPDATE STATUS ====================

  Future<void> updatePaperStatus(String paperId, PaperStatus status) async {
    await client
        .from('question_papers')
        .update({'status': status.dbValue})
        .eq('id', paperId)
        .eq('tenant_id', requireTenantId);
  }

  // ==================== DELETE ====================

  Future<void> deleteQuestionPaper(String paperId) async {
    await client
        .from('question_papers')
        .delete()
        .eq('id', paperId)
        .eq('tenant_id', requireTenantId);
  }
}
