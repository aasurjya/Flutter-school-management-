import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/alumni.dart';
import '../../../data/repositories/alumni_repository.dart';

/// Repository provider
final alumniRepositoryProvider = Provider<AlumniRepository>((ref) {
  return AlumniRepository(ref.watch(supabaseProvider));
});

// ============================================
// PROFILE PROVIDERS
// ============================================

final alumniProfilesProvider =
    FutureProvider.family<List<AlumniProfile>, AlumniFilter>(
  (ref, filter) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getProfiles(
      search: filter.search,
      graduationYear: filter.graduationYear,
      industry: filter.industry,
      locationCity: filter.locationCity,
      isMentor: filter.isMentor,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allAlumniProfilesProvider =
    FutureProvider<List<AlumniProfile>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getProfiles();
});

final alumniProfileByIdProvider =
    FutureProvider.family<AlumniProfile?, String>(
  (ref, profileId) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getProfileById(profileId);
  },
);

final myAlumniProfileProvider =
    FutureProvider<AlumniProfile?>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  final userId = repository.currentUserId;
  if (userId == null) return null;
  return repository.getProfileByUserId(userId);
});

final alumniIndustriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getDistinctIndustries();
});

final alumniGraduationYearsProvider =
    FutureProvider<List<int>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getDistinctGraduationYears();
});

// ============================================
// EVENT PROVIDERS
// ============================================

final alumniEventsProvider =
    FutureProvider.family<List<AlumniEvent>, AlumniEventFilter>(
  (ref, filter) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getEvents(
      status: filter.status,
      eventType: filter.eventType,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allAlumniEventsProvider =
    FutureProvider<List<AlumniEvent>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getEvents();
});

final upcomingAlumniEventsProvider =
    FutureProvider<List<AlumniEvent>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getEvents(status: 'upcoming');
});

final alumniEventByIdProvider =
    FutureProvider.family<AlumniEvent?, String>(
  (ref, eventId) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getEventById(eventId);
  },
);

final eventRegistrationsProvider =
    FutureProvider.family<List<AlumniEventRegistration>, String>(
  (ref, eventId) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getEventRegistrations(eventId);
  },
);

// ============================================
// DONATION PROVIDERS
// ============================================

final alumniDonationsProvider =
    FutureProvider.family<List<AlumniDonation>, AlumniDonationFilter>(
  (ref, filter) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getDonations(
      alumniId: filter.alumniId,
      purpose: filter.purpose,
      status: filter.status,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allAlumniDonationsProvider =
    FutureProvider<List<AlumniDonation>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getDonations();
});

final donationSummaryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getDonationSummary();
});

// ============================================
// MENTORSHIP PROVIDERS
// ============================================

final mentorshipProgramsProvider =
    FutureProvider.family<List<MentorshipProgram>, MentorshipFilter>(
  (ref, filter) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getMentorshipPrograms(
      status: filter.status,
      mentorId: filter.mentorId,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allMentorshipProgramsProvider =
    FutureProvider<List<MentorshipProgram>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getMentorshipPrograms();
});

final openMentorshipProgramsProvider =
    FutureProvider<List<MentorshipProgram>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getMentorshipPrograms(status: 'open');
});

final mentorshipRequestsProvider =
    FutureProvider.family<List<MentorshipRequest>, MentorshipRequestFilter>(
  (ref, filter) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getMentorshipRequests(
      programId: filter.programId,
      studentId: filter.studentId,
      status: filter.status,
    );
  },
);

// ============================================
// SUCCESS STORY PROVIDERS
// ============================================

final alumniSuccessStoriesProvider =
    FutureProvider.family<List<AlumniSuccessStory>, AlumniStoryFilter>(
  (ref, filter) async {
    final repository = ref.watch(alumniRepositoryProvider);
    return repository.getSuccessStories(
      status: filter.status,
      isFeatured: filter.isFeatured,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final publishedStoriesProvider =
    FutureProvider<List<AlumniSuccessStory>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getSuccessStories(status: 'published');
});

final featuredStoriesProvider =
    FutureProvider<List<AlumniSuccessStory>>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getSuccessStories(status: 'published', isFeatured: true);
});

// ============================================
// STATS PROVIDER
// ============================================

final alumniStatsProvider = FutureProvider<AlumniStats>((ref) async {
  final repository = ref.watch(alumniRepositoryProvider);
  return repository.getAlumniStats();
});

// ============================================
// STATE NOTIFIERS
// ============================================

class AlumniProfileNotifier
    extends StateNotifier<AsyncValue<List<AlumniProfile>>> {
  final AlumniRepository _repository;

  AlumniProfileNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadProfiles({
    String? search,
    int? graduationYear,
    String? industry,
    String? locationCity,
    bool? isMentor,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profiles = await _repository.getProfiles(
        search: search,
        graduationYear: graduationYear,
        industry: industry,
        locationCity: locationCity,
        isMentor: isMentor,
      );
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AlumniProfile> createProfile(Map<String, dynamic> data) async {
    final profile = await _repository.createProfile(data);
    await loadProfiles();
    return profile;
  }

  Future<AlumniProfile> updateProfile(
      String profileId, Map<String, dynamic> data) async {
    final profile = await _repository.updateProfile(profileId, data);
    await loadProfiles();
    return profile;
  }

  Future<void> deleteProfile(String profileId) async {
    await _repository.deleteProfile(profileId);
    await loadProfiles();
  }
}

final alumniProfileNotifierProvider = StateNotifierProvider<
    AlumniProfileNotifier, AsyncValue<List<AlumniProfile>>>((ref) {
  final repository = ref.watch(alumniRepositoryProvider);
  return AlumniProfileNotifier(repository);
});

class AlumniEventNotifier
    extends StateNotifier<AsyncValue<List<AlumniEvent>>> {
  final AlumniRepository _repository;

  AlumniEventNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadEvents({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final events = await _repository.getEvents(status: status);
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AlumniEvent> createEvent(Map<String, dynamic> data) async {
    final event = await _repository.createEvent(data);
    await loadEvents();
    return event;
  }

  Future<AlumniEvent> updateEvent(
      String eventId, Map<String, dynamic> data) async {
    final event = await _repository.updateEvent(eventId, data);
    await loadEvents();
    return event;
  }

  Future<void> deleteEvent(String eventId) async {
    await _repository.deleteEvent(eventId);
    await loadEvents();
  }
}

final alumniEventNotifierProvider = StateNotifierProvider<
    AlumniEventNotifier, AsyncValue<List<AlumniEvent>>>((ref) {
  final repository = ref.watch(alumniRepositoryProvider);
  return AlumniEventNotifier(repository);
});

// ============================================
// FILTER CLASSES
// ============================================

class AlumniFilter {
  final String? search;
  final int? graduationYear;
  final String? industry;
  final String? locationCity;
  final bool? isMentor;
  final int limit;
  final int offset;

  const AlumniFilter({
    this.search,
    this.graduationYear,
    this.industry,
    this.locationCity,
    this.isMentor,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlumniFilter &&
          other.search == search &&
          other.graduationYear == graduationYear &&
          other.industry == industry &&
          other.locationCity == locationCity &&
          other.isMentor == isMentor &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(
      search, graduationYear, industry, locationCity, isMentor, limit, offset);
}

class AlumniEventFilter {
  final String? status;
  final AlumniEventType? eventType;
  final int limit;
  final int offset;

  const AlumniEventFilter({
    this.status,
    this.eventType,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlumniEventFilter &&
          other.status == status &&
          other.eventType == eventType &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(status, eventType, limit, offset);
}

class AlumniDonationFilter {
  final String? alumniId;
  final String? purpose;
  final String? status;
  final int limit;
  final int offset;

  const AlumniDonationFilter({
    this.alumniId,
    this.purpose,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlumniDonationFilter &&
          other.alumniId == alumniId &&
          other.purpose == purpose &&
          other.status == status &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(alumniId, purpose, status, limit, offset);
}

class MentorshipFilter {
  final String? status;
  final String? mentorId;
  final int limit;
  final int offset;

  const MentorshipFilter({
    this.status,
    this.mentorId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorshipFilter &&
          other.status == status &&
          other.mentorId == mentorId &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(status, mentorId, limit, offset);
}

class MentorshipRequestFilter {
  final String? programId;
  final String? studentId;
  final String? status;

  const MentorshipRequestFilter({
    this.programId,
    this.studentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorshipRequestFilter &&
          other.programId == programId &&
          other.studentId == studentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(programId, studentId, status);
}

class AlumniStoryFilter {
  final String? status;
  final bool? isFeatured;
  final int limit;
  final int offset;

  const AlumniStoryFilter({
    this.status,
    this.isFeatured,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlumniStoryFilter &&
          other.status == status &&
          other.isFeatured == isFeatured &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(status, isFeatured, limit, offset);
}
