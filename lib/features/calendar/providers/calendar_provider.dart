import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/school_event.dart';
import '../../../data/repositories/calendar_repository.dart';

// ==================== REPOSITORY ====================

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(supabaseProvider));
});

// ==================== EVENTS BY DATE RANGE ====================

final eventsForRangeProvider =
    FutureProvider.autoDispose.family<List<SchoolEvent>, CalendarFilter>(
  (ref, filter) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getEvents(
      startDate: filter.startDate ?? DateTime(DateTime.now().year, 1, 1),
      endDate: filter.endDate ?? DateTime(DateTime.now().year, 12, 31),
      eventType: filter.eventType,
      status: filter.status,
    );
  },
);

// ==================== UPCOMING EVENTS ====================

final upcomingEventsProvider =
    FutureProvider.autoDispose.family<List<SchoolEvent>, EventType?>(
  (ref, eventType) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getUpcomingEvents(
      limit: 20,
      eventType: eventType,
    );
  },
);

// ==================== SINGLE EVENT ====================

final eventDetailProvider =
    FutureProvider.autoDispose.family<SchoolEvent?, String>(
  (ref, eventId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getEventById(eventId);
  },
);

// ==================== EVENT ATTENDEES ====================

final eventAttendeesProvider =
    FutureProvider.autoDispose.family<List<EventAttendee>, String>(
  (ref, eventId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getEventAttendees(eventId);
  },
);

// ==================== USER RSVP ====================

final userRsvpProvider =
    FutureProvider.autoDispose.family<EventAttendee?, String>(
  (ref, eventId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getUserRsvp(eventId);
  },
);

// ==================== EVENT REMINDERS ====================

final eventRemindersProvider =
    FutureProvider.autoDispose.family<List<EventReminder>, String>(
  (ref, eventId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getEventReminders(eventId);
  },
);

// ==================== ACADEMIC CALENDAR ====================

final academicCalendarProvider =
    FutureProvider.autoDispose.family<List<AcademicCalendarItem>, String>(
  (ref, academicYearId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getAcademicCalendarItems(
      academicYearId: academicYearId,
    );
  },
);

// ==================== HOLIDAYS ====================

final holidaysProvider =
    FutureProvider.autoDispose.family<List<Holiday>, String>(
  (ref, academicYearId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getHolidays(academicYearId: academicYearId);
  },
);

// ==================== HOLIDAY DATES SET ====================

final holidayDatesProvider =
    FutureProvider.autoDispose.family<Set<DateTime>, String>(
  (ref, academicYearId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getHolidayDates(academicYearId: academicYearId);
  },
);

// ==================== SELECTED DATE STATE ====================

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// ==================== CALENDAR FORMAT STATE ====================

enum CalendarViewFormat { month, twoWeeks, week }

final calendarFormatProvider = StateProvider<CalendarViewFormat>((ref) {
  return CalendarViewFormat.month;
});

// ==================== SELECTED EVENT TYPE FILTER ====================

final selectedEventTypeFilterProvider = StateProvider<EventType?>((ref) {
  return null;
});
