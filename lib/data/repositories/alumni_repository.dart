import '../models/alumni.dart';
import 'base_repository.dart';

class AlumniRepository extends BaseRepository {
  AlumniRepository(super.client);

  // ============================================
  // PROFILES
  // ============================================

  Future<List<AlumniProfile>> getProfiles({
    String? search,
    int? graduationYear,
    String? industry,
    String? locationCity,
    bool? isMentor,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('alumni_profiles')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (search != null && search.isNotEmpty) {
      query = query.or(
          'first_name.ilike.%$search%,last_name.ilike.%$search%,current_company.ilike.%$search%');
    }
    if (graduationYear != null) {
      query = query.eq('graduation_year', graduationYear);
    }
    if (industry != null) {
      query = query.eq('industry', industry);
    }
    if (locationCity != null) {
      query = query.ilike('location_city', '%$locationCity%');
    }
    if (isMentor != null) {
      query = query.eq('is_mentor', isMentor);
    }

    final response = await query
        .order('graduation_year', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AlumniProfile.fromJson(json))
        .toList();
  }

  Future<AlumniProfile?> getProfileById(String profileId) async {
    final response = await client
        .from('alumni_profiles')
        .select('*')
        .eq('id', profileId)
        .maybeSingle();

    if (response == null) return null;
    return AlumniProfile.fromJson(response);
  }

  Future<AlumniProfile?> getProfileByUserId(String userId) async {
    final response = await client
        .from('alumni_profiles')
        .select('*')
        .eq('user_id', userId)
        .eq('tenant_id', requireTenantId)
        .maybeSingle();

    if (response == null) return null;
    return AlumniProfile.fromJson(response);
  }

  Future<AlumniProfile> createProfile(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('alumni_profiles')
        .insert(data)
        .select()
        .single();

    return AlumniProfile.fromJson(response);
  }

  Future<AlumniProfile> updateProfile(
      String profileId, Map<String, dynamic> data) async {
    final response = await client
        .from('alumni_profiles')
        .update(data)
        .eq('id', profileId)
        .select()
        .single();

    return AlumniProfile.fromJson(response);
  }

  Future<void> deleteProfile(String profileId) async {
    await client.from('alumni_profiles').delete().eq('id', profileId);
  }

  Future<List<String>> getDistinctIndustries() async {
    final response = await client
        .from('alumni_profiles')
        .select('industry')
        .eq('tenant_id', requireTenantId)
        .not('industry', 'is', null)
        .order('industry');

    final industries = <String>{};
    for (final row in response as List) {
      if (row['industry'] != null && (row['industry'] as String).isNotEmpty) {
        industries.add(row['industry'] as String);
      }
    }
    return industries.toList();
  }

  Future<List<int>> getDistinctGraduationYears() async {
    final response = await client
        .from('alumni_profiles')
        .select('graduation_year')
        .eq('tenant_id', requireTenantId)
        .order('graduation_year', ascending: false);

    final years = <int>{};
    for (final row in response as List) {
      if (row['graduation_year'] != null) {
        years.add(row['graduation_year'] as int);
      }
    }
    return years.toList();
  }

  // ============================================
  // EVENTS
  // ============================================

  Future<List<AlumniEvent>> getEvents({
    String? status,
    AlumniEventType? eventType,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('alumni_events')
        .select('''
          *,
          alumni_profiles:organizer_id(*),
          alumni_event_registrations(id)
        ''')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (eventType != null) {
      query = query.eq('event_type', eventType.value);
    }

    final response = await query
        .order('date', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AlumniEvent.fromJson(json))
        .toList();
  }

  Future<AlumniEvent?> getEventById(String eventId) async {
    final response = await client
        .from('alumni_events')
        .select('''
          *,
          alumni_profiles:organizer_id(*),
          alumni_event_registrations(id)
        ''')
        .eq('id', eventId)
        .maybeSingle();

    if (response == null) return null;
    return AlumniEvent.fromJson(response);
  }

  Future<AlumniEvent> createEvent(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('alumni_events')
        .insert(data)
        .select('''
          *,
          alumni_profiles:organizer_id(*),
          alumni_event_registrations(id)
        ''')
        .single();

    return AlumniEvent.fromJson(response);
  }

  Future<AlumniEvent> updateEvent(
      String eventId, Map<String, dynamic> data) async {
    final response = await client
        .from('alumni_events')
        .update(data)
        .eq('id', eventId)
        .select('''
          *,
          alumni_profiles:organizer_id(*),
          alumni_event_registrations(id)
        ''')
        .single();

    return AlumniEvent.fromJson(response);
  }

  Future<void> deleteEvent(String eventId) async {
    await client.from('alumni_events').delete().eq('id', eventId);
  }

  // ============================================
  // EVENT REGISTRATIONS
  // ============================================

  Future<List<AlumniEventRegistration>> getEventRegistrations(
      String eventId) async {
    final response = await client
        .from('alumni_event_registrations')
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .eq('event_id', eventId)
        .order('registered_at', ascending: false);

    return (response as List)
        .map((json) => AlumniEventRegistration.fromJson(json))
        .toList();
  }

  Future<AlumniEventRegistration?> getMyRegistration(
      String eventId, String alumniId) async {
    final response = await client
        .from('alumni_event_registrations')
        .select('*')
        .eq('event_id', eventId)
        .eq('alumni_id', alumniId)
        .maybeSingle();

    if (response == null) return null;
    return AlumniEventRegistration.fromJson(response);
  }

  Future<AlumniEventRegistration> registerForEvent(
      Map<String, dynamic> data) async {
    final response = await client
        .from('alumni_event_registrations')
        .insert(data)
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .single();

    return AlumniEventRegistration.fromJson(response);
  }

  Future<void> cancelRegistration(String registrationId) async {
    await client
        .from('alumni_event_registrations')
        .update({'status': 'cancelled'})
        .eq('id', registrationId);
  }

  Future<void> deleteRegistration(String registrationId) async {
    await client
        .from('alumni_event_registrations')
        .delete()
        .eq('id', registrationId);
  }

  // ============================================
  // DONATIONS
  // ============================================

  Future<List<AlumniDonation>> getDonations({
    String? alumniId,
    String? purpose,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('alumni_donations')
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .eq('tenant_id', requireTenantId);

    if (alumniId != null) {
      query = query.eq('alumni_id', alumniId);
    }
    if (purpose != null) {
      query = query.eq('purpose', purpose);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('donated_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AlumniDonation.fromJson(json))
        .toList();
  }

  Future<AlumniDonation> createDonation(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('alumni_donations')
        .insert(data)
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .single();

    return AlumniDonation.fromJson(response);
  }

  Future<AlumniDonation> updateDonation(
      String donationId, Map<String, dynamic> data) async {
    final response = await client
        .from('alumni_donations')
        .update(data)
        .eq('id', donationId)
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .single();

    return AlumniDonation.fromJson(response);
  }

  Future<Map<String, double>> getDonationSummary() async {
    final response = await client
        .from('alumni_donations')
        .select('purpose, amount')
        .eq('tenant_id', requireTenantId)
        .eq('status', 'completed');

    final summary = <String, double>{};
    double total = 0;
    for (final row in response as List) {
      final purpose = row['purpose'] as String? ?? 'general';
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      summary[purpose] = (summary[purpose] ?? 0) + amount;
      total += amount;
    }
    summary['total'] = total;
    return summary;
  }

  // ============================================
  // MENTORSHIP PROGRAMS
  // ============================================

  Future<List<MentorshipProgram>> getMentorshipPrograms({
    String? status,
    String? mentorId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('mentorship_programs')
        .select('''
          *,
          alumni_profiles:mentor_id(*),
          mentorship_requests(id)
        ''')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (mentorId != null) {
      query = query.eq('mentor_id', mentorId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MentorshipProgram.fromJson(json))
        .toList();
  }

  Future<MentorshipProgram?> getMentorshipProgramById(
      String programId) async {
    final response = await client
        .from('mentorship_programs')
        .select('''
          *,
          alumni_profiles:mentor_id(*),
          mentorship_requests(id)
        ''')
        .eq('id', programId)
        .maybeSingle();

    if (response == null) return null;
    return MentorshipProgram.fromJson(response);
  }

  Future<MentorshipProgram> createMentorshipProgram(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('mentorship_programs')
        .insert(data)
        .select('''
          *,
          alumni_profiles:mentor_id(*),
          mentorship_requests(id)
        ''')
        .single();

    return MentorshipProgram.fromJson(response);
  }

  Future<MentorshipProgram> updateMentorshipProgram(
      String programId, Map<String, dynamic> data) async {
    final response = await client
        .from('mentorship_programs')
        .update(data)
        .eq('id', programId)
        .select('''
          *,
          alumni_profiles:mentor_id(*),
          mentorship_requests(id)
        ''')
        .single();

    return MentorshipProgram.fromJson(response);
  }

  Future<void> deleteMentorshipProgram(String programId) async {
    await client
        .from('mentorship_programs')
        .delete()
        .eq('id', programId);
  }

  // ============================================
  // MENTORSHIP REQUESTS
  // ============================================

  Future<List<MentorshipRequest>> getMentorshipRequests({
    String? programId,
    String? studentId,
    String? status,
  }) async {
    var query = client
        .from('mentorship_requests')
        .select('''
          *,
          mentorship_programs(
            *,
            alumni_profiles:mentor_id(*)
          )
        ''');

    if (programId != null) {
      query = query.eq('program_id', programId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => MentorshipRequest.fromJson(json))
        .toList();
  }

  Future<MentorshipRequest> createMentorshipRequest(
      Map<String, dynamic> data) async {
    final response = await client
        .from('mentorship_requests')
        .insert(data)
        .select('''
          *,
          mentorship_programs(
            *,
            alumni_profiles:mentor_id(*)
          )
        ''')
        .single();

    return MentorshipRequest.fromJson(response);
  }

  Future<MentorshipRequest> updateMentorshipRequest(
      String requestId, Map<String, dynamic> data) async {
    final response = await client
        .from('mentorship_requests')
        .update(data)
        .eq('id', requestId)
        .select('''
          *,
          mentorship_programs(
            *,
            alumni_profiles:mentor_id(*)
          )
        ''')
        .single();

    return MentorshipRequest.fromJson(response);
  }

  // ============================================
  // SUCCESS STORIES
  // ============================================

  Future<List<AlumniSuccessStory>> getSuccessStories({
    String? status,
    bool? isFeatured,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('alumni_success_stories')
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AlumniSuccessStory.fromJson(json))
        .toList();
  }

  Future<AlumniSuccessStory> createSuccessStory(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('alumni_success_stories')
        .insert(data)
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .single();

    return AlumniSuccessStory.fromJson(response);
  }

  Future<AlumniSuccessStory> updateSuccessStory(
      String storyId, Map<String, dynamic> data) async {
    final response = await client
        .from('alumni_success_stories')
        .update(data)
        .eq('id', storyId)
        .select('''
          *,
          alumni_profiles:alumni_id(*)
        ''')
        .single();

    return AlumniSuccessStory.fromJson(response);
  }

  Future<void> deleteSuccessStory(String storyId) async {
    await client
        .from('alumni_success_stories')
        .delete()
        .eq('id', storyId);
  }

  // ============================================
  // STATS
  // ============================================

  Future<AlumniStats> getAlumniStats() async {
    try {
      // Alumni counts
      final alumniResponse = await client
          .from('alumni_profiles')
          .select('id, is_verified, is_mentor')
          .eq('tenant_id', requireTenantId);

      final alumni = alumniResponse as List;
      final totalAlumni = alumni.length;
      final verifiedAlumni =
          alumni.where((a) => a['is_verified'] == true).length;
      final mentorCount = alumni.where((a) => a['is_mentor'] == true).length;

      // Upcoming events
      final eventsResponse = await client
          .from('alumni_events')
          .select('id')
          .eq('tenant_id', requireTenantId)
          .eq('status', 'upcoming');
      final upcomingEventsCount = (eventsResponse as List).length;

      // Donation totals
      final donationResponse = await client
          .from('alumni_donations')
          .select('amount')
          .eq('tenant_id', requireTenantId)
          .eq('status', 'completed');

      double totalDonations = 0;
      for (final d in donationResponse as List) {
        totalDonations += (d['amount'] as num?)?.toDouble() ?? 0;
      }
      final donationCount = donationResponse.length;

      // Stories
      final storiesResponse = await client
          .from('alumni_success_stories')
          .select('id')
          .eq('tenant_id', requireTenantId)
          .eq('status', 'published');
      final storiesCount = (storiesResponse as List).length;

      // Active mentorships
      final mentorshipResponse = await client
          .from('mentorship_programs')
          .select('id')
          .eq('tenant_id', requireTenantId)
          .inFilter('status', ['open', 'in_progress']);
      final activeMentorships = (mentorshipResponse as List).length;

      return AlumniStats(
        totalAlumni: totalAlumni,
        verifiedAlumni: verifiedAlumni,
        mentorCount: mentorCount,
        upcomingEventsCount: upcomingEventsCount,
        totalDonations: totalDonations,
        donationCount: donationCount,
        storiesCount: storiesCount,
        activeMentorships: activeMentorships,
      );
    } catch (e) {
      return const AlumniStats();
    }
  }
}
