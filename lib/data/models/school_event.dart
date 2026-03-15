/// School Calendar & Events module models
library;

// ============================================
// ENUMS
// ============================================

enum EventType {
  academic,
  cultural,
  sports,
  holiday,
  exam,
  ptaMeeting,
  workshop,
  fieldTrip,
  competition,
  celebration;

  String get value {
    switch (this) {
      case EventType.academic:
        return 'academic';
      case EventType.cultural:
        return 'cultural';
      case EventType.sports:
        return 'sports';
      case EventType.holiday:
        return 'holiday';
      case EventType.exam:
        return 'exam';
      case EventType.ptaMeeting:
        return 'pta_meeting';
      case EventType.workshop:
        return 'workshop';
      case EventType.fieldTrip:
        return 'field_trip';
      case EventType.competition:
        return 'competition';
      case EventType.celebration:
        return 'celebration';
    }
  }

  String get label {
    switch (this) {
      case EventType.academic:
        return 'Academic';
      case EventType.cultural:
        return 'Cultural';
      case EventType.sports:
        return 'Sports';
      case EventType.holiday:
        return 'Holiday';
      case EventType.exam:
        return 'Exam';
      case EventType.ptaMeeting:
        return 'PTA Meeting';
      case EventType.workshop:
        return 'Workshop';
      case EventType.fieldTrip:
        return 'Field Trip';
      case EventType.competition:
        return 'Competition';
      case EventType.celebration:
        return 'Celebration';
    }
  }

  String get icon {
    switch (this) {
      case EventType.academic:
        return 'school';
      case EventType.cultural:
        return 'theater_comedy';
      case EventType.sports:
        return 'sports_soccer';
      case EventType.holiday:
        return 'beach_access';
      case EventType.exam:
        return 'quiz';
      case EventType.ptaMeeting:
        return 'groups';
      case EventType.workshop:
        return 'build';
      case EventType.fieldTrip:
        return 'directions_bus';
      case EventType.competition:
        return 'emoji_events';
      case EventType.celebration:
        return 'celebration';
    }
  }

  String get colorHex {
    switch (this) {
      case EventType.academic:
        return '#6366F1';
      case EventType.cultural:
        return '#EC4899';
      case EventType.sports:
        return '#22C55E';
      case EventType.holiday:
        return '#F59E0B';
      case EventType.exam:
        return '#EF4444';
      case EventType.ptaMeeting:
        return '#F97316';
      case EventType.workshop:
        return '#06B6D4';
      case EventType.fieldTrip:
        return '#F97316';
      case EventType.competition:
        return '#14B8A6';
      case EventType.celebration:
        return '#D946EF';
    }
  }

  static EventType fromString(String value) {
    switch (value) {
      case 'academic':
        return EventType.academic;
      case 'cultural':
        return EventType.cultural;
      case 'sports':
        return EventType.sports;
      case 'holiday':
        return EventType.holiday;
      case 'exam':
        return EventType.exam;
      case 'pta_meeting':
        return EventType.ptaMeeting;
      case 'workshop':
        return EventType.workshop;
      case 'field_trip':
        return EventType.fieldTrip;
      case 'competition':
        return EventType.competition;
      case 'celebration':
        return EventType.celebration;
      default:
        return EventType.academic;
    }
  }
}

enum EventVisibility {
  all,
  teachers,
  students,
  parents,
  staff;

  String get value {
    switch (this) {
      case EventVisibility.all:
        return 'all';
      case EventVisibility.teachers:
        return 'teachers';
      case EventVisibility.students:
        return 'students';
      case EventVisibility.parents:
        return 'parents';
      case EventVisibility.staff:
        return 'staff';
    }
  }

  String get label {
    switch (this) {
      case EventVisibility.all:
        return 'Everyone';
      case EventVisibility.teachers:
        return 'Teachers Only';
      case EventVisibility.students:
        return 'Students Only';
      case EventVisibility.parents:
        return 'Parents Only';
      case EventVisibility.staff:
        return 'Staff Only';
    }
  }

  static EventVisibility fromString(String value) {
    switch (value) {
      case 'all':
        return EventVisibility.all;
      case 'teachers':
        return EventVisibility.teachers;
      case 'students':
        return EventVisibility.students;
      case 'parents':
        return EventVisibility.parents;
      case 'staff':
        return EventVisibility.staff;
      default:
        return EventVisibility.all;
    }
  }
}

enum EventStatus {
  scheduled,
  ongoing,
  completed,
  cancelled,
  postponed;

  String get value {
    switch (this) {
      case EventStatus.scheduled:
        return 'scheduled';
      case EventStatus.ongoing:
        return 'ongoing';
      case EventStatus.completed:
        return 'completed';
      case EventStatus.cancelled:
        return 'cancelled';
      case EventStatus.postponed:
        return 'postponed';
    }
  }

  String get label {
    switch (this) {
      case EventStatus.scheduled:
        return 'Scheduled';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
      case EventStatus.postponed:
        return 'Postponed';
    }
  }

  static EventStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return EventStatus.scheduled;
      case 'ongoing':
        return EventStatus.ongoing;
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'postponed':
        return EventStatus.postponed;
      default:
        return EventStatus.scheduled;
    }
  }
}

enum RsvpStatus {
  pending,
  attending,
  notAttending,
  maybe;

  String get value {
    switch (this) {
      case RsvpStatus.pending:
        return 'pending';
      case RsvpStatus.attending:
        return 'attending';
      case RsvpStatus.notAttending:
        return 'not_attending';
      case RsvpStatus.maybe:
        return 'maybe';
    }
  }

  String get label {
    switch (this) {
      case RsvpStatus.pending:
        return 'Pending';
      case RsvpStatus.attending:
        return 'Attending';
      case RsvpStatus.notAttending:
        return 'Not Attending';
      case RsvpStatus.maybe:
        return 'Maybe';
    }
  }

  static RsvpStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return RsvpStatus.pending;
      case 'attending':
        return RsvpStatus.attending;
      case 'not_attending':
        return RsvpStatus.notAttending;
      case 'maybe':
        return RsvpStatus.maybe;
      default:
        return RsvpStatus.pending;
    }
  }
}

enum ReminderType {
  push,
  email,
  sms;

  String get value {
    switch (this) {
      case ReminderType.push:
        return 'push';
      case ReminderType.email:
        return 'email';
      case ReminderType.sms:
        return 'sms';
    }
  }

  String get label {
    switch (this) {
      case ReminderType.push:
        return 'Push Notification';
      case ReminderType.email:
        return 'Email';
      case ReminderType.sms:
        return 'SMS';
    }
  }

  static ReminderType fromString(String value) {
    switch (value) {
      case 'push':
        return ReminderType.push;
      case 'email':
        return ReminderType.email;
      case 'sms':
        return ReminderType.sms;
      default:
        return ReminderType.push;
    }
  }
}

enum AcademicItemType {
  termStart,
  termEnd,
  examStart,
  examEnd,
  holiday,
  resultDate,
  admissionStart,
  admissionEnd,
  feeDeadline;

  String get value {
    switch (this) {
      case AcademicItemType.termStart:
        return 'term_start';
      case AcademicItemType.termEnd:
        return 'term_end';
      case AcademicItemType.examStart:
        return 'exam_start';
      case AcademicItemType.examEnd:
        return 'exam_end';
      case AcademicItemType.holiday:
        return 'holiday';
      case AcademicItemType.resultDate:
        return 'result_date';
      case AcademicItemType.admissionStart:
        return 'admission_start';
      case AcademicItemType.admissionEnd:
        return 'admission_end';
      case AcademicItemType.feeDeadline:
        return 'fee_deadline';
    }
  }

  String get label {
    switch (this) {
      case AcademicItemType.termStart:
        return 'Term Start';
      case AcademicItemType.termEnd:
        return 'Term End';
      case AcademicItemType.examStart:
        return 'Exam Start';
      case AcademicItemType.examEnd:
        return 'Exam End';
      case AcademicItemType.holiday:
        return 'Holiday';
      case AcademicItemType.resultDate:
        return 'Result Date';
      case AcademicItemType.admissionStart:
        return 'Admission Start';
      case AcademicItemType.admissionEnd:
        return 'Admission End';
      case AcademicItemType.feeDeadline:
        return 'Fee Deadline';
    }
  }

  static AcademicItemType fromString(String value) {
    switch (value) {
      case 'term_start':
        return AcademicItemType.termStart;
      case 'term_end':
        return AcademicItemType.termEnd;
      case 'exam_start':
        return AcademicItemType.examStart;
      case 'exam_end':
        return AcademicItemType.examEnd;
      case 'holiday':
        return AcademicItemType.holiday;
      case 'result_date':
        return AcademicItemType.resultDate;
      case 'admission_start':
        return AcademicItemType.admissionStart;
      case 'admission_end':
        return AcademicItemType.admissionEnd;
      case 'fee_deadline':
        return AcademicItemType.feeDeadline;
      default:
        return AcademicItemType.holiday;
    }
  }
}

enum HolidayType {
  national,
  state,
  religious,
  schoolDeclared,
  vacation;

  String get value {
    switch (this) {
      case HolidayType.national:
        return 'national';
      case HolidayType.state:
        return 'state';
      case HolidayType.religious:
        return 'religious';
      case HolidayType.schoolDeclared:
        return 'school_declared';
      case HolidayType.vacation:
        return 'vacation';
    }
  }

  String get label {
    switch (this) {
      case HolidayType.national:
        return 'National';
      case HolidayType.state:
        return 'State';
      case HolidayType.religious:
        return 'Religious';
      case HolidayType.schoolDeclared:
        return 'School Declared';
      case HolidayType.vacation:
        return 'Vacation';
    }
  }

  static HolidayType fromString(String value) {
    switch (value) {
      case 'national':
        return HolidayType.national;
      case 'state':
        return HolidayType.state;
      case 'religious':
        return HolidayType.religious;
      case 'school_declared':
        return HolidayType.schoolDeclared;
      case 'vacation':
        return HolidayType.vacation;
      default:
        return HolidayType.schoolDeclared;
    }
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Recurrence rule for recurring events
class RecurrenceRule {
  final String frequency; // daily, weekly, monthly, yearly
  final int interval;
  final DateTime? endDate;
  final List<int>? daysOfWeek; // 1=Mon, 7=Sun

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.daysOfWeek,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: json['frequency'] ?? 'weekly',
      interval: json['interval'] ?? 1,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      daysOfWeek: json['days_of_week'] != null
          ? (json['days_of_week'] as List).map((e) => e as int).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'interval': interval,
      if (endDate != null)
        'end_date': endDate!.toIso8601String().split('T')[0],
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
    };
  }
}

/// School Event model
class SchoolEvent {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final EventType eventType;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final bool isAllDay;
  final String? location;
  final bool isRecurring;
  final RecurrenceRule? recurrenceRule;
  final String? colorHex;
  final String? icon;
  final String? createdBy;
  final EventVisibility visibility;
  final List<String>? targetClasses;
  final bool isMandatory;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? createdByName;
  final int? attendeeCount;
  final int? attendingCount;

  const SchoolEvent({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.isAllDay = true,
    this.location,
    this.isRecurring = false,
    this.recurrenceRule,
    this.colorHex,
    this.icon,
    this.createdBy,
    this.visibility = EventVisibility.all,
    this.targetClasses,
    this.isMandatory = false,
    this.status = EventStatus.scheduled,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.attendeeCount,
    this.attendingCount,
  });

  factory SchoolEvent.fromJson(Map<String, dynamic> json) {
    String? createdByName;
    if (json['users'] != null) {
      createdByName = json['users']['full_name'];
    }

    List<String>? targetClasses;
    if (json['target_classes'] != null && json['target_classes'] is List) {
      targetClasses =
          (json['target_classes'] as List).map((e) => e.toString()).toList();
    }

    RecurrenceRule? recurrenceRule;
    if (json['recurrence_rule'] != null &&
        json['recurrence_rule'] is Map<String, dynamic>) {
      recurrenceRule = RecurrenceRule.fromJson(json['recurrence_rule']);
    }

    return SchoolEvent(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventType: EventType.fromString(json['event_type'] ?? 'academic'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      startTime: json['start_time'],
      endTime: json['end_time'],
      isAllDay: json['is_all_day'] ?? true,
      location: json['location'],
      isRecurring: json['is_recurring'] ?? false,
      recurrenceRule: recurrenceRule,
      colorHex: json['color_hex'],
      icon: json['icon'],
      createdBy: json['created_by'],
      visibility:
          EventVisibility.fromString(json['visibility'] ?? 'all'),
      targetClasses: targetClasses,
      isMandatory: json['is_mandatory'] ?? false,
      status: EventStatus.fromString(json['status'] ?? 'scheduled'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      createdByName: createdByName,
      attendeeCount: json['attendee_count'],
      attendingCount: json['attending_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'event_type': eventType.value,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'is_all_day': isAllDay,
      'location': location,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule?.toJson(),
      'color_hex': colorHex,
      'icon': icon,
      'created_by': createdBy,
      'visibility': visibility.value,
      'target_classes': targetClasses,
      'is_mandatory': isMandatory,
      'status': status.value,
    };
  }

  /// Whether this event spans multiple days
  bool get isMultiDay =>
      endDate.difference(startDate).inDays > 0;

  /// Duration display string
  String get durationDisplay {
    if (isAllDay) {
      final days = endDate.difference(startDate).inDays + 1;
      return days == 1 ? 'All Day' : '$days Days';
    }
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    }
    return 'All Day';
  }

  /// Whether the event is happening today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !startDate.isAfter(today) && !endDate.isBefore(today);
  }

  /// Whether the event is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return endDate.isBefore(today);
  }
}

/// Event Attendee model
class EventAttendee {
  final String id;
  final String eventId;
  final String userId;
  final RsvpStatus rsvpStatus;
  final bool attended;
  final DateTime? checkInTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? userName;
  final String? userEmail;

  const EventAttendee({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rsvpStatus,
    this.attended = false,
    this.checkInTime,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    String? userName;
    String? userEmail;
    if (json['users'] != null) {
      userName = json['users']['full_name'];
      userEmail = json['users']['email'];
    }

    return EventAttendee(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      rsvpStatus: RsvpStatus.fromString(json['rsvp_status'] ?? 'pending'),
      attended: json['attended'] ?? false,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userName: userName,
      userEmail: userEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'rsvp_status': rsvpStatus.value,
      'attended': attended,
      'check_in_time': checkInTime?.toIso8601String(),
    };
  }
}

/// Event Reminder model
class EventReminder {
  final String id;
  final String eventId;
  final ReminderType reminderType;
  final int minutesBefore;
  final bool sent;
  final DateTime? sentAt;
  final DateTime createdAt;

  const EventReminder({
    required this.id,
    required this.eventId,
    required this.reminderType,
    this.minutesBefore = 30,
    this.sent = false,
    this.sentAt,
    required this.createdAt,
  });

  factory EventReminder.fromJson(Map<String, dynamic> json) {
    return EventReminder(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      reminderType:
          ReminderType.fromString(json['reminder_type'] ?? 'push'),
      minutesBefore: json['minutes_before'] ?? 30,
      sent: json['sent'] ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'reminder_type': reminderType.value,
      'minutes_before': minutesBefore,
    };
  }

  String get displayLabel {
    if (minutesBefore < 60) return '$minutesBefore min before';
    if (minutesBefore == 60) return '1 hour before';
    if (minutesBefore < 1440) return '${minutesBefore ~/ 60} hours before';
    if (minutesBefore == 1440) return '1 day before';
    return '${minutesBefore ~/ 1440} days before';
  }
}

/// Academic Calendar Item model
class AcademicCalendarItem {
  final String id;
  final String tenantId;
  final String academicYearId;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final AcademicItemType itemType;
  final bool isHoliday;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? academicYearName;

  const AcademicCalendarItem({
    required this.id,
    required this.tenantId,
    required this.academicYearId,
    required this.title,
    required this.date,
    this.endDate,
    required this.itemType,
    this.isHoliday = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.academicYearName,
  });

  factory AcademicCalendarItem.fromJson(Map<String, dynamic> json) {
    String? academicYearName;
    if (json['academic_years'] != null) {
      academicYearName = json['academic_years']['name'];
    }

    return AcademicCalendarItem(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      academicYearId: json['academic_year_id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      itemType:
          AcademicItemType.fromString(json['item_type'] ?? 'holiday'),
      isHoliday: json['is_holiday'] ?? false,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      academicYearName: academicYearName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'academic_year_id': academicYearId,
      'title': title,
      'date': date.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'item_type': itemType.value,
      'is_holiday': isHoliday,
      'notes': notes,
    };
  }
}

/// Holiday model
class Holiday {
  final String id;
  final String tenantId;
  final String academicYearId;
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final HolidayType type;
  final bool isOptional;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? academicYearName;

  const Holiday({
    required this.id,
    required this.tenantId,
    required this.academicYearId,
    required this.name,
    required this.date,
    this.endDate,
    required this.type,
    this.isOptional = false,
    required this.createdAt,
    required this.updatedAt,
    this.academicYearName,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    String? academicYearName;
    if (json['academic_years'] != null) {
      academicYearName = json['academic_years']['name'];
    }

    return Holiday(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      academicYearId: json['academic_year_id'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      type: HolidayType.fromString(json['type'] ?? 'school_declared'),
      isOptional: json['is_optional'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      academicYearName: academicYearName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'academic_year_id': academicYearId,
      'name': name,
      'date': date.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'type': type.value,
      'is_optional': isOptional,
    };
  }

  /// Total number of days for this holiday
  int get totalDays {
    if (endDate == null) return 1;
    return endDate!.difference(date).inDays + 1;
  }
}

/// Filter for calendar queries
class CalendarFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final EventType? eventType;
  final EventStatus? status;
  final EventVisibility? visibility;

  const CalendarFilter({
    this.startDate,
    this.endDate,
    this.eventType,
    this.status,
    this.visibility,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarFilter &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          eventType == other.eventType &&
          status == other.status &&
          visibility == other.visibility;

  @override
  int get hashCode => Object.hash(startDate, endDate, eventType, status, visibility);
}
