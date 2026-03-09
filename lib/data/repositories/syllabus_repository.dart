import '../models/syllabus_topic.dart';
import '../models/lesson_plan.dart';
import 'base_repository.dart';

class SyllabusRepository extends BaseRepository {
  SyllabusRepository(super.client);

  // ==================== TOPIC TREE ====================

  /// Loads ALL topics for a subject+class+year in one query,
  /// then builds the tree client-side.
  Future<List<SyllabusTopic>> getTopicTree({
    required String subjectId,
    required String classId,
    required String academicYearId,
    String? sectionId,
  }) async {
    final select = sectionId != null
        ? '''
          *,
          subjects(name),
          classes(name),
          terms(name),
          topic_coverage!left(id, topic_id, section_id, teacher_id, status, started_date, completed_date, periods_spent, notes)
        '''
        : '''
          *,
          subjects(name),
          classes(name),
          terms(name)
        ''';

    var query = client
        .from('syllabus_topics')
        .select(select)
        .eq('tenant_id', requireTenantId)
        .eq('subject_id', subjectId)
        .eq('class_id', classId)
        .eq('academic_year_id', academicYearId);

    if (sectionId != null) {
      query = query.or('topic_coverage.section_id.eq.$sectionId,topic_coverage.section_id.is.null');
    }

    final response =
        await query.order('sequence_order', ascending: true);

    final allTopics = (response as List)
        .map((json) => SyllabusTopic.fromJson(json))
        .toList();

    return _buildTree(allTopics);
  }

  /// Builds hierarchical tree from flat list.
  List<SyllabusTopic> _buildTree(List<SyllabusTopic> flat) {
    final Map<String, List<SyllabusTopic>> childrenMap = {};
    final List<SyllabusTopic> roots = [];

    for (final topic in flat) {
      final parentId = topic.parentTopicId;
      if (parentId == null) {
        roots.add(topic);
      } else {
        childrenMap.putIfAbsent(parentId, () => []).add(topic);
      }
    }

    SyllabusTopic attachChildren(SyllabusTopic node) {
      final kids = childrenMap[node.id] ?? [];
      final populatedKids = kids.map(attachChildren).toList();
      return node.copyWith(
        children: populatedKids,
        childCount: populatedKids.length,
      );
    }

    return roots.map(attachChildren).toList();
  }

  Future<SyllabusTopic?> getTopicById(String topicId,
      {String? sectionId}) async {
    final select = sectionId != null
        ? '''
          *,
          subjects(name),
          classes(name),
          terms(name),
          topic_coverage(id, topic_id, section_id, teacher_id, status, started_date, completed_date, periods_spent, notes)
        '''
        : '''
          *,
          subjects(name),
          classes(name),
          terms(name)
        ''';

    final query = client
        .from('syllabus_topics')
        .select(select)
        .eq('id', topicId);

    final response = await query.maybeSingle();
    if (response == null) return null;
    return SyllabusTopic.fromJson(response);
  }

  Future<SyllabusTopic> createTopic(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['created_by'] = currentUserId;

    final response = await client
        .from('syllabus_topics')
        .insert(data)
        .select()
        .single();

    return SyllabusTopic.fromJson(response);
  }

  Future<SyllabusTopic> updateTopic(
    String topicId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('syllabus_topics')
        .update(data)
        .eq('id', topicId)
        .select()
        .single();

    return SyllabusTopic.fromJson(response);
  }

  Future<void> deleteTopic(String topicId) async {
    await client.from('syllabus_topics').delete().eq('id', topicId);
  }

  Future<void> reorderTopics(List<String> topicIds) async {
    for (var i = 0; i < topicIds.length; i++) {
      await client
          .from('syllabus_topics')
          .update({'sequence_order': i})
          .eq('id', topicIds[i]);
    }
  }

  Future<void> bulkCreateTopics(List<Map<String, dynamic>> topics) async {
    for (final data in topics) {
      data['tenant_id'] = tenantId;
      data['created_by'] = currentUserId;
    }
    await client.from('syllabus_topics').insert(topics);
  }

  // ==================== COVERAGE ====================

  Future<TopicCoverage> updateCoverage({
    required String topicId,
    required String sectionId,
    required TopicStatus status,
    int? periodsSpent,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'tenant_id': tenantId,
      'topic_id': topicId,
      'section_id': sectionId,
      'teacher_id': currentUserId,
      'status': status.dbValue,
    };

    if (status == TopicStatus.inProgress && periodsSpent == null) {
      data['started_date'] = DateTime.now().toIso8601String().split('T')[0];
    }
    if (status == TopicStatus.completed) {
      data['completed_date'] = DateTime.now().toIso8601String().split('T')[0];
    }
    if (periodsSpent != null) {
      data['periods_spent'] = periodsSpent;
    }
    if (notes != null) {
      data['notes'] = notes;
    }

    final response = await client
        .from('topic_coverage')
        .upsert(data, onConflict: 'topic_id,section_id')
        .select()
        .single();

    return TopicCoverage.fromJson(response);
  }

  Future<SyllabusCoverageSummary?> getCoverageSummary({
    required String subjectId,
    required String classId,
    required String academicYearId,
    required String sectionId,
  }) async {
    final response = await client
        .from('v_syllabus_coverage_summary')
        .select()
        .eq('tenant_id', requireTenantId)
        .eq('subject_id', subjectId)
        .eq('class_id', classId)
        .eq('academic_year_id', academicYearId)
        .eq('section_id', sectionId)
        .maybeSingle();

    if (response == null) return null;
    return SyllabusCoverageSummary.fromJson(response);
  }

  Future<List<SyllabusCoverageSummary>> getTeacherCoverageSummaries({
    required String teacherId,
    required String academicYearId,
  }) async {
    // Get teacher's assignments first
    final assignments = await client
        .from('teacher_assignments')
        .select('''
          subject_id,
          section_id,
          subjects(name),
          sections(id, name, class_id, classes(id, name))
        ''')
        .eq('teacher_id', teacherId)
        .eq('academic_year_id', academicYearId);

    final summaries = <SyllabusCoverageSummary>[];

    for (final assignment in (assignments as List)) {
      final subjectId = assignment['subject_id'] as String;
      final section = assignment['sections'];
      if (section == null) continue;

      final sectionId = section['id'] as String;
      final classId = section['class_id'] as String;

      final summary = await getCoverageSummary(
        subjectId: subjectId,
        classId: classId,
        academicYearId: academicYearId,
        sectionId: sectionId,
      );

      if (summary != null) {
        summaries.add(SyllabusCoverageSummary(
          subjectId: subjectId,
          classId: classId,
          academicYearId: academicYearId,
          sectionId: sectionId,
          totalTopics: summary.totalTopics,
          completedTopics: summary.completedTopics,
          inProgressTopics: summary.inProgressTopics,
          skippedTopics: summary.skippedTopics,
          coveragePercentage: summary.coveragePercentage,
          totalEstimatedPeriods: summary.totalEstimatedPeriods,
          totalPeriodsSpent: summary.totalPeriodsSpent,
          subjectName: assignment['subjects']?['name'],
          className: section['classes']?['name'],
          sectionName: section['name'],
        ));
      } else {
        // No topics yet — show zero coverage
        summaries.add(SyllabusCoverageSummary(
          subjectId: subjectId,
          classId: classId,
          academicYearId: academicYearId,
          sectionId: sectionId,
          subjectName: assignment['subjects']?['name'],
          className: section['classes']?['name'],
          sectionName: section['name'],
        ));
      }
    }

    return summaries;
  }

  // ==================== TOPIC RESOURCE LINKS ====================

  Future<List<TopicResourceLink>> getTopicLinks(String topicId) async {
    final response = await client
        .from('topic_resource_links')
        .select()
        .eq('topic_id', topicId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TopicResourceLink.fromJson(json))
        .toList();
  }

  Future<TopicResourceLink> linkEntity({
    required String topicId,
    required String entityType,
    required String entityId,
  }) async {
    final response = await client
        .from('topic_resource_links')
        .insert({
          'tenant_id': tenantId,
          'topic_id': topicId,
          'entity_type': entityType,
          'entity_id': entityId,
        })
        .select()
        .single();

    return TopicResourceLink.fromJson(response);
  }

  Future<void> unlinkEntity(String linkId) async {
    await client.from('topic_resource_links').delete().eq('id', linkId);
  }

  // ==================== SEARCH ====================

  Future<List<SyllabusTopic>> searchTopics({
    required String query,
    String? subjectId,
    String? classId,
  }) async {
    var dbQuery = client
        .from('syllabus_topics')
        .select('*, subjects(name), classes(name)')
        .eq('tenant_id', requireTenantId)
        .ilike('title', '%$query%');

    if (subjectId != null) {
      dbQuery = dbQuery.eq('subject_id', subjectId);
    }
    if (classId != null) {
      dbQuery = dbQuery.eq('class_id', classId);
    }

    final response = await dbQuery.order('title').limit(20);

    return (response as List)
        .map((json) => SyllabusTopic.fromJson(json))
        .toList();
  }

  // ==================== LESSON PLANS ====================

  Future<List<LessonPlan>> getLessonPlans({
    String? topicId,
    String? teacherId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('lesson_plans')
        .select('''
          *,
          syllabus_topics(title),
          sections(name),
          users!teacher_id(full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (topicId != null) {
      query = query.eq('topic_id', topicId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => LessonPlan.fromJson(json))
        .toList();
  }

  Future<LessonPlan?> getLessonPlanById(String id) async {
    final response = await client
        .from('lesson_plans')
        .select('''
          *,
          syllabus_topics(title),
          sections(name),
          users!teacher_id(full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return LessonPlan.fromJson(response);
  }

  Future<LessonPlan> createLessonPlan(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['teacher_id'] = currentUserId;

    final response = await client
        .from('lesson_plans')
        .insert(data)
        .select()
        .single();

    return LessonPlan.fromJson(response);
  }

  Future<LessonPlan> updateLessonPlan(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('lesson_plans')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return LessonPlan.fromJson(response);
  }

  Future<void> deleteLessonPlan(String id) async {
    await client.from('lesson_plans').delete().eq('id', id);
  }
}
