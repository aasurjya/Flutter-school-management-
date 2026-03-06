import '../models/school_event.dart';
import 'base_repository.dart';

class CalendarRepository extends BaseRepository {
  CalendarRepository(super.client);

  // ==================== SCHOOL EVENTS ====================

  /// Fetch events for a date range
  Future<List<SchoolEvent>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
    EventType? eventType,
    EventStatus? status,
  }) async {
    var query = client
        .from('school_events')
        .select('*, users!created_by(full_name)')
        .eq('tenant_id', requireTenantId)
        .gte('start_date', startDate.toIso8601String().split('T')[0])
        .lte('start_date', endDate.toIso8601String().split('T')[0]);

    if (eventType != null) {
      query = query.eq('event_type', eventType.value);
    }
    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response =
        await query.order('start_date', ascending: true);

    return (response as List)
        .map((json) => SchoolEvent.fromJson(json))
        .toList();
  }

  /// Fetch upcoming events (from today onwards)
  Future<List<SchoolEvent>> getUpcomingEvents({
    int limit = 20,
    EventType? eventType,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    var query = client
        .from('school_events')
        .select('*, users!created_by(full_name)')
        .eq('tenant_id', requireTenantId)
        .gte('end_date', today)
        .neq('status', 'cancelled');

    if (eventType != null) {
      query = query.eq('event_type', eventType.value);
    }

    final response = await query
        .order('start_date', ascending: true)
        .limit(limit);

    return (response as List)
        .map((json) => SchoolEvent.fromJson(json))
        .toList();
  }

  /// Get single event with details
  Future<SchoolEvent?> getEventById(String eventId) async {
    final response = await client
        .from('school_events')
        .select('*, users!created_by(full_name)')
        .eq('id', eventId)
        .maybeSingle();

    if (response == null) return null;
    return SchoolEvent.fromJson(response);
  }

  /// Create a new event
  Future<SchoolEvent> createEvent(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;

    final response = await client
        .from('school_events')
        .insert(data)
        .select('*, users!created_by(full_name)')
        .single();

    return SchoolEvent.fromJson(response);
  }

  /// Update an event
  Future<SchoolEvent> updateEvent(
      String eventId, Map<String, dynamic> data) async {
    final response = await client
        .from('school_events')
        .update(data)
        .eq('id', eventId)
        .select('*, users!created_by(full_name)')
        .single();

    return SchoolEvent.fromJson(response);
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    await client.from('school_events').delete().eq('id', eventId);
  }

  /// Update event status
  Future<void> updateEventStatus(
      String eventId, EventStatus status) async {
    await client
        .from('school_events')
        .update({'status': status.value})
        .eq('id', eventId);
  }

  // ==================== ATTENDEES ====================

  /// Get attendees for an event
  Future<List<EventAttendee>> getEventAttendees(String eventId) async {
    final response = await client
        .from('event_attendees')
        .select('*, users(full_name, email)')
        .eq('event_id', eventId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => EventAttendee.fromJson(json))
        .toList();
  }

  /// RSVP for an event (upsert)
  Future<EventAttendee> rsvpEvent({
    required String eventId,
    required RsvpStatus rsvpStatus,
  }) async {
    final response = await client
        .from('event_attendees')
        .upsert(
          {
            'event_id': eventId,
            'user_id': requireUserId,
            'rsvp_status': rsvpStatus.value,
          },
          onConflict: 'event_id,user_id',
        )
        .select('*, users(full_name, email)')
        .single();

    return EventAttendee.fromJson(response);
  }

  /// Check in attendee
  Future<void> checkInAttendee(String attendeeId) async {
    await client.from('event_attendees').update({
      'attended': true,
      'check_in_time': DateTime.now().toIso8601String(),
    }).eq('id', attendeeId);
  }

  /// Get user's RSVP for an event
  Future<EventAttendee?> getUserRsvp(String eventId) async {
    final response = await client
        .from('event_attendees')
        .select('*, users(full_name, email)')
        .eq('event_id', eventId)
        .eq('user_id', requireUserId)
        .maybeSingle();

    if (response == null) return null;
    return EventAttendee.fromJson(response);
  }

  // ==================== REMINDERS ====================

  /// Get reminders for an event
  Future<List<EventReminder>> getEventReminders(String eventId) async {
    final response = await client
        .from('event_reminders')
        .select()
        .eq('event_id', eventId)
        .order('minutes_before', ascending: true);

    return (response as List)
        .map((json) => EventReminder.fromJson(json))
        .toList();
  }

  /// Add reminder
  Future<EventReminder> addReminder(Map<String, dynamic> data) async {
    final response = await client
        .from('event_reminders')
        .insert(data)
        .select()
        .single();

    return EventReminder.fromJson(response);
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    await client.from('event_reminders').delete().eq('id', reminderId);
  }

  // ==================== ACADEMIC CALENDAR ====================

  /// Get academic calendar items for a year
  Future<List<AcademicCalendarItem>> getAcademicCalendarItems({
    required String academicYearId,
    AcademicItemType? itemType,
  }) async {
    var query = client
        .from('academic_calendar_items')
        .select('*, academic_years(name)')
        .eq('tenant_id', requireTenantId)
        .eq('academic_year_id', academicYearId);

    if (itemType != null) {
      query = query.eq('item_type', itemType.value);
    }

    final response =
        await query.order('date', ascending: true);

    return (response as List)
        .map((json) => AcademicCalendarItem.fromJson(json))
        .toList();
  }

  /// Create academic calendar item
  Future<AcademicCalendarItem> createAcademicCalendarItem(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('academic_calendar_items')
        .insert(data)
        .select('*, academic_years(name)')
        .single();

    return AcademicCalendarItem.fromJson(response);
  }

  /// Update academic calendar item
  Future<AcademicCalendarItem> updateAcademicCalendarItem(
      String itemId, Map<String, dynamic> data) async {
    final response = await client
        .from('academic_calendar_items')
        .update(data)
        .eq('id', itemId)
        .select('*, academic_years(name)')
        .single();

    return AcademicCalendarItem.fromJson(response);
  }

  /// Delete academic calendar item
  Future<void> deleteAcademicCalendarItem(String itemId) async {
    await client
        .from('academic_calendar_items')
        .delete()
        .eq('id', itemId);
  }

  // ==================== HOLIDAYS ====================

  /// Get holidays for an academic year
  Future<List<Holiday>> getHolidays({
    required String academicYearId,
    HolidayType? type,
  }) async {
    var query = client
        .from('holiday_calendar')
        .select('*, academic_years(name)')
        .eq('tenant_id', requireTenantId)
        .eq('academic_year_id', academicYearId);

    if (type != null) {
      query = query.eq('type', type.value);
    }

    final response =
        await query.order('date', ascending: true);

    return (response as List)
        .map((json) => Holiday.fromJson(json))
        .toList();
  }

  /// Create holiday
  Future<Holiday> createHoliday(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('holiday_calendar')
        .insert(data)
        .select('*, academic_years(name)')
        .single();

    return Holiday.fromJson(response);
  }

  /// Update holiday
  Future<Holiday> updateHoliday(
      String holidayId, Map<String, dynamic> data) async {
    final response = await client
        .from('holiday_calendar')
        .update(data)
        .eq('id', holidayId)
        .select('*, academic_years(name)')
        .single();

    return Holiday.fromJson(response);
  }

  /// Delete holiday
  Future<void> deleteHoliday(String holidayId) async {
    await client.from('holiday_calendar').delete().eq('id', holidayId);
  }

  /// Get all holidays as dates set (for calendar markers)
  Future<Set<DateTime>> getHolidayDates({
    required String academicYearId,
  }) async {
    final holidays = await getHolidays(academicYearId: academicYearId);
    final dates = <DateTime>{};
    for (final h in holidays) {
      final end = h.endDate ?? h.date;
      for (var d = h.date;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        dates.add(DateTime(d.year, d.month, d.day));
      }
    }
    return dates;
  }
}
