import '../models/lms.dart';
import 'base_repository.dart';

class LmsRepository extends BaseRepository {
  LmsRepository(super.client);

  // ============================================
  // COURSES
  // ============================================

  static const _courseSelect = '''
    *,
    subjects:subject_id(id, name),
    classes:class_id(id, name),
    users:teacher_id(id, full_name)
  ''';

  static const _courseDetailSelect = '''
    *,
    subjects:subject_id(id, name),
    classes:class_id(id, name),
    users:teacher_id(id, full_name),
    course_modules(
      *,
      module_content(*)
    ),
    course_enrollments(id)
  ''';

  Future<List<Course>> getCourses({
    String? status,
    String? teacherId,
    String? classId,
    String? subjectId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('courses')
        .select(_courseSelect)
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Course.fromJson(json)).toList();
  }

  Future<List<Course>> getPublishedCourses({
    String? classId,
    String? subjectId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    return getCourses(
      status: 'published',
      classId: classId,
      subjectId: subjectId,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }

  Future<Course?> getCourseById(String courseId) async {
    final response = await client
        .from('courses')
        .select(_courseDetailSelect)
        .eq('id', courseId)
        .maybeSingle();

    if (response == null) return null;
    return Course.fromJson(response);
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['teacher_id'] ??= requireUserId;

    final response = await client
        .from('courses')
        .insert(data)
        .select(_courseSelect)
        .single();

    return Course.fromJson(response);
  }

  Future<Course> updateCourse(String courseId, Map<String, dynamic> data) async {
    final response = await client
        .from('courses')
        .update(data)
        .eq('id', courseId)
        .select(_courseSelect)
        .single();

    return Course.fromJson(response);
  }

  Future<void> deleteCourse(String courseId) async {
    await client.from('courses').delete().eq('id', courseId);
  }

  // ============================================
  // COURSE MODULES
  // ============================================

  Future<List<CourseModule>> getModules(String courseId) async {
    final response = await client
        .from('course_modules')
        .select('*, module_content(*)')
        .eq('course_id', courseId)
        .order('sequence_order');

    return (response as List)
        .map((json) => CourseModule.fromJson(json))
        .toList();
  }

  Future<CourseModule> createModule(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('course_modules')
        .insert(data)
        .select('*, module_content(*)')
        .single();

    return CourseModule.fromJson(response);
  }

  Future<CourseModule> updateModule(
      String moduleId, Map<String, dynamic> data) async {
    final response = await client
        .from('course_modules')
        .update(data)
        .eq('id', moduleId)
        .select('*, module_content(*)')
        .single();

    return CourseModule.fromJson(response);
  }

  Future<void> deleteModule(String moduleId) async {
    await client.from('course_modules').delete().eq('id', moduleId);
  }

  Future<void> reorderModules(List<Map<String, dynamic>> updates) async {
    for (final update in updates) {
      await client
          .from('course_modules')
          .update({'sequence_order': update['sequence_order']})
          .eq('id', update['id']);
    }
  }

  // ============================================
  // MODULE CONTENT
  // ============================================

  Future<List<ModuleContent>> getContents(String moduleId) async {
    final response = await client
        .from('module_content')
        .select('*')
        .eq('module_id', moduleId)
        .order('sequence_order');

    return (response as List)
        .map((json) => ModuleContent.fromJson(json))
        .toList();
  }

  Future<ModuleContent> createContent(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('module_content')
        .insert(data)
        .select()
        .single();

    return ModuleContent.fromJson(response);
  }

  Future<ModuleContent> updateContent(
      String contentId, Map<String, dynamic> data) async {
    final response = await client
        .from('module_content')
        .update(data)
        .eq('id', contentId)
        .select()
        .single();

    return ModuleContent.fromJson(response);
  }

  Future<void> deleteContent(String contentId) async {
    await client.from('module_content').delete().eq('id', contentId);
  }

  // ============================================
  // ENROLLMENTS
  // ============================================

  Future<List<CourseEnrollment>> getEnrollments({
    String? courseId,
    String? studentId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('course_enrollments')
        .select('''
          *,
          courses:course_id(
            *,
            subjects:subject_id(id, name),
            classes:class_id(id, name),
            users:teacher_id(id, full_name),
            course_modules(
              *,
              module_content(*)
            )
          ),
          users:student_id(id, full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('enrolled_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => CourseEnrollment.fromJson(json))
        .toList();
  }

  Future<CourseEnrollment?> getMyEnrollment(String courseId) async {
    final response = await client
        .from('course_enrollments')
        .select('''
          *,
          courses:course_id(
            *,
            subjects:subject_id(id, name),
            classes:class_id(id, name),
            users:teacher_id(id, full_name)
          )
        ''')
        .eq('course_id', courseId)
        .eq('student_id', requireUserId)
        .maybeSingle();

    if (response == null) return null;
    return CourseEnrollment.fromJson(response);
  }

  Future<CourseEnrollment> enrollInCourse(String courseId) async {
    final data = {
      'tenant_id': requireTenantId,
      'course_id': courseId,
      'student_id': requireUserId,
      'status': EnrollmentStatus.enrolled.value,
    };

    final response = await client
        .from('course_enrollments')
        .insert(data)
        .select('''
          *,
          courses:course_id(*, subjects:subject_id(id, name), classes:class_id(id, name), users:teacher_id(id, full_name))
        ''')
        .single();

    return CourseEnrollment.fromJson(response);
  }

  Future<CourseEnrollment> updateEnrollment(
      String enrollmentId, Map<String, dynamic> data) async {
    final response = await client
        .from('course_enrollments')
        .update(data)
        .eq('id', enrollmentId)
        .select()
        .single();

    return CourseEnrollment.fromJson(response);
  }

  Future<void> dropCourse(String enrollmentId) async {
    await client
        .from('course_enrollments')
        .update({'status': EnrollmentStatus.dropped.value})
        .eq('id', enrollmentId);
  }

  // ============================================
  // CONTENT PROGRESS
  // ============================================

  Future<List<ContentProgress>> getContentProgress(
      String enrollmentId) async {
    final response = await client
        .from('content_progress')
        .select('*')
        .eq('enrollment_id', enrollmentId)
        .order('created_at');

    return (response as List)
        .map((json) => ContentProgress.fromJson(json))
        .toList();
  }

  Future<ContentProgress> upsertContentProgress({
    required String enrollmentId,
    required String contentId,
    required ContentProgressStatus status,
    int? timeSpentSeconds,
    double? score,
  }) async {
    final data = {
      'tenant_id': requireTenantId,
      'enrollment_id': enrollmentId,
      'content_id': contentId,
      'status': status.value,
      if (status == ContentProgressStatus.inProgress &&
          timeSpentSeconds == null)
        'started_at': DateTime.now().toIso8601String(),
      if (status == ContentProgressStatus.completed)
        'completed_at': DateTime.now().toIso8601String(),
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (score != null) 'score': score,
    };

    final response = await client
        .from('content_progress')
        .upsert(data, onConflict: 'enrollment_id,content_id')
        .select()
        .single();

    return ContentProgress.fromJson(response);
  }

  /// Recalculate enrollment progress percentage based on content progress
  Future<double> recalculateProgress(String enrollmentId) async {
    final enrollment = await client
        .from('course_enrollments')
        .select('course_id')
        .eq('id', enrollmentId)
        .single();

    final courseId = enrollment['course_id'] as String;

    // Get total mandatory content count
    final contentResponse = await client
        .from('module_content')
        .select('id')
        .eq('is_mandatory', true)
        .inFilter(
            'module_id',
            (await client
                    .from('course_modules')
                    .select('id')
                    .eq('course_id', courseId))
                .map((e) => e['id'] as String)
                .toList());

    final totalContent = (contentResponse as List).length;
    if (totalContent == 0) return 100;

    // Get completed content count
    final completedResponse = await client
        .from('content_progress')
        .select('id')
        .eq('enrollment_id', enrollmentId)
        .eq('status', 'completed');

    final completedCount = (completedResponse as List).length;
    final progress = (completedCount / totalContent * 100).clamp(0, 100).toDouble();

    // Update the enrollment
    await client
        .from('course_enrollments')
        .update({
          'progress_percentage': progress,
          if (progress >= 100) 'status': EnrollmentStatus.completed.value,
          if (progress >= 100)
            'completed_at': DateTime.now().toIso8601String(),
          if (progress > 0 && progress < 100)
            'status': EnrollmentStatus.inProgress.value,
        })
        .eq('id', enrollmentId);

    return progress;
  }

  // ============================================
  // DISCUSSION FORUMS
  // ============================================

  Future<List<DiscussionForum>> getForums(String courseId) async {
    final response = await client
        .from('discussion_forums')
        .select('''
          *,
          users:created_by(id, full_name),
          forum_posts(id)
        ''')
        .eq('course_id', courseId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DiscussionForum.fromJson(json))
        .toList();
  }

  Future<DiscussionForum> createForum(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;

    final response = await client
        .from('discussion_forums')
        .insert(data)
        .select('''
          *,
          users:created_by(id, full_name)
        ''')
        .single();

    return DiscussionForum.fromJson(response);
  }

  Future<DiscussionForum> updateForum(
      String forumId, Map<String, dynamic> data) async {
    final response = await client
        .from('discussion_forums')
        .update(data)
        .eq('id', forumId)
        .select('''
          *,
          users:created_by(id, full_name)
        ''')
        .single();

    return DiscussionForum.fromJson(response);
  }

  Future<void> deleteForum(String forumId) async {
    await client.from('discussion_forums').delete().eq('id', forumId);
  }

  // ============================================
  // FORUM POSTS
  // ============================================

  Future<List<ForumPost>> getForumPosts(String forumId) async {
    final response = await client
        .from('forum_posts')
        .select('''
          *,
          users:author_id(id, full_name)
        ''')
        .eq('forum_id', forumId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => ForumPost.fromJson(json))
        .toList();
  }

  Future<ForumPost> createPost(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['author_id'] = requireUserId;

    final response = await client
        .from('forum_posts')
        .insert(data)
        .select('''
          *,
          users:author_id(id, full_name)
        ''')
        .single();

    return ForumPost.fromJson(response);
  }

  Future<ForumPost> updatePost(
      String postId, Map<String, dynamic> data) async {
    final response = await client
        .from('forum_posts')
        .update(data)
        .eq('id', postId)
        .select('''
          *,
          users:author_id(id, full_name)
        ''')
        .single();

    return ForumPost.fromJson(response);
  }

  Future<void> deletePost(String postId) async {
    await client.from('forum_posts').delete().eq('id', postId);
  }

  Future<ForumPost> upvotePost(String postId) async {
    // Using rpc would be better, but for now increment manually
    final current = await client
        .from('forum_posts')
        .select('upvotes')
        .eq('id', postId)
        .single();

    final newCount = ((current['upvotes'] as int?) ?? 0) + 1;
    return updatePost(postId, {'upvotes': newCount});
  }

  // ============================================
  // CERTIFICATES
  // ============================================

  Future<CourseCertificate?> getCertificate(String enrollmentId) async {
    final response = await client
        .from('course_certificates')
        .select('''
          *,
          course_enrollments:enrollment_id(
            *,
            courses:course_id(id, title),
            users:student_id(id, full_name)
          )
        ''')
        .eq('enrollment_id', enrollmentId)
        .maybeSingle();

    if (response == null) return null;
    return CourseCertificate.fromJson(response);
  }

  Future<List<CourseCertificate>> getMyCertificates() async {
    // Get all enrollments for current user, then their certificates
    final enrollments = await client
        .from('course_enrollments')
        .select('id')
        .eq('student_id', requireUserId)
        .eq('tenant_id', requireTenantId);

    final enrollmentIds =
        (enrollments as List).map((e) => e['id'] as String).toList();
    if (enrollmentIds.isEmpty) return [];

    final response = await client
        .from('course_certificates')
        .select('''
          *,
          course_enrollments:enrollment_id(
            *,
            courses:course_id(id, title),
            users:student_id(id, full_name)
          )
        ''')
        .inFilter('enrollment_id', enrollmentIds)
        .order('issued_at', ascending: false);

    return (response as List)
        .map((json) => CourseCertificate.fromJson(json))
        .toList();
  }

  Future<CourseCertificate> issueCertificate({
    required String enrollmentId,
    required String certificateNumber,
    Map<String, dynamic>? templateData,
  }) async {
    final data = {
      'tenant_id': requireTenantId,
      'enrollment_id': enrollmentId,
      'certificate_number': certificateNumber,
      'issued_at': DateTime.now().toIso8601String(),
      'template_data': templateData ?? {},
    };

    final response = await client
        .from('course_certificates')
        .insert(data)
        .select('''
          *,
          course_enrollments:enrollment_id(
            *,
            courses:course_id(id, title),
            users:student_id(id, full_name)
          )
        ''')
        .single();

    return CourseCertificate.fromJson(response);
  }

  // ============================================
  // STATS
  // ============================================

  Future<LmsStats> getStats() async {
    final tid = requireTenantId;

    final coursesResponse = await client
        .from('courses')
        .select('status')
        .eq('tenant_id', tid);

    final courses = coursesResponse as List;
    final publishedCourses =
        courses.where((c) => c['status'] == 'published').length;

    final enrollmentsResponse = await client
        .from('course_enrollments')
        .select('status, progress_percentage')
        .eq('tenant_id', tid);

    final enrollments = enrollmentsResponse as List;
    final completedEnrollments =
        enrollments.where((e) => e['status'] == 'completed').length;
    final inProgressEnrollments =
        enrollments.where((e) => e['status'] == 'in_progress').length;

    double avgProgress = 0;
    if (enrollments.isNotEmpty) {
      avgProgress = enrollments.fold<double>(
              0,
              (sum, e) =>
                  sum + ((e['progress_percentage'] as num?)?.toDouble() ?? 0)) /
          enrollments.length;
    }

    final certsResponse = await client
        .from('course_certificates')
        .select('id')
        .eq('tenant_id', tid);

    return LmsStats(
      totalCourses: courses.length,
      publishedCourses: publishedCourses,
      totalEnrollments: enrollments.length,
      completedEnrollments: completedEnrollments,
      inProgressEnrollments: inProgressEnrollments,
      avgProgress: avgProgress,
      totalCertificates: (certsResponse as List).length,
    );
  }
}
