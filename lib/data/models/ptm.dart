// PTM (Parent-Teacher Meeting) Models

class PTMSchedule {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final String? academicYearId;
  final DateTime date;
  final String startTime; // HH:MM format
  final String endTime;
  final int slotDuration; // in minutes
  final int maxAppointmentsPerSlot;
  final String status; // draft, open, closed
  final DateTime createdAt;

  // Joined data
  final String? academicYearName;
  final int? totalSlots;
  final int? bookedSlots;

  const PTMSchedule({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    this.academicYearId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.slotDuration,
    this.maxAppointmentsPerSlot = 1,
    required this.status,
    required this.createdAt,
    this.academicYearName,
    this.totalSlots,
    this.bookedSlots,
  });

  factory PTMSchedule.fromJson(Map<String, dynamic> json) {
    return PTMSchedule(
      id: json['id'],
      tenantId: json['tenant_id'],
      title: json['title'],
      description: json['description'],
      academicYearId: json['academic_year_id'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      slotDuration: json['slot_duration'] ?? 15,
      maxAppointmentsPerSlot: json['max_appointments_per_slot'] ?? 1,
      status: json['status'] ?? 'draft',
      createdAt: DateTime.parse(json['created_at']),
      academicYearName: json['academic_year']?['name'],
      totalSlots: json['total_slots'],
      bookedSlots: json['booked_slots'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'academic_year_id': academicYearId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration': slotDuration,
      'max_appointments_per_slot': maxAppointmentsPerSlot,
      'status': status,
    };
  }

  bool get isDraft => status == 'draft';
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'open':
        return 'Open for Booking';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String get dateDisplay {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get timeRange => '$startTime - $endTime';

  List<TimeSlot> generateTimeSlots() {
    final slots = <TimeSlot>[];
    var currentTime = _parseTime(startTime);
    final endTimeMinutes = _parseTime(endTime);

    while (currentTime + slotDuration <= endTimeMinutes) {
      final slotStart = _formatTime(currentTime);
      final slotEnd = _formatTime(currentTime + slotDuration);
      slots.add(TimeSlot(
        startTime: slotStart,
        endTime: slotEnd,
        duration: slotDuration,
      ));
      currentTime += slotDuration;
    }

    return slots;
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final int duration;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  String get display => '$startTime - $endTime';
}

class TeacherAvailability {
  final String id;
  final String ptmScheduleId;
  final String teacherId;
  final String roomNumber;
  final bool isAvailable;
  final String? notes;

  // Joined data
  final String? teacherName;
  final String? subjectName;
  final List<String>? classNames;

  const TeacherAvailability({
    required this.id,
    required this.ptmScheduleId,
    required this.teacherId,
    required this.roomNumber,
    this.isAvailable = true,
    this.notes,
    this.teacherName,
    this.subjectName,
    this.classNames,
  });

  factory TeacherAvailability.fromJson(Map<String, dynamic> json) {
    return TeacherAvailability(
      id: json['id'],
      ptmScheduleId: json['ptm_schedule_id'],
      teacherId: json['teacher_id'],
      roomNumber: json['room_number'] ?? '',
      isAvailable: json['is_available'] ?? true,
      notes: json['notes'],
      teacherName: json['teacher']?['full_name'] ?? json['teacher_name'],
      subjectName: json['subject_name'],
      classNames: json['class_names'] != null
          ? List<String>.from(json['class_names'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ptm_schedule_id': ptmScheduleId,
      'teacher_id': teacherId,
      'room_number': roomNumber,
      'is_available': isAvailable,
      'notes': notes,
    };
  }
}

class PTMAppointment {
  final String id;
  final String tenantId;
  final String ptmScheduleId;
  final String teacherAvailabilityId;
  final String parentId;
  final String studentId;
  final String timeSlot; // HH:MM - HH:MM format
  final String status; // pending, confirmed, cancelled, completed
  final String? notes;
  final String? parentNotes;
  final String? teacherNotes;
  final String? meetingLink;
  final DateTime createdAt;

  // Joined data
  final String? teacherName;
  final String? parentName;
  final String? studentName;
  final String? roomNumber;

  const PTMAppointment({
    required this.id,
    required this.tenantId,
    required this.ptmScheduleId,
    required this.teacherAvailabilityId,
    required this.parentId,
    required this.studentId,
    required this.timeSlot,
    required this.status,
    this.notes,
    this.parentNotes,
    this.teacherNotes,
    this.meetingLink,
    required this.createdAt,
    this.teacherName,
    this.parentName,
    this.studentName,
    this.roomNumber,
  });

  factory PTMAppointment.fromJson(Map<String, dynamic> json) {
    return PTMAppointment(
      id: json['id'],
      tenantId: json['tenant_id'],
      ptmScheduleId: json['ptm_schedule_id'],
      teacherAvailabilityId: json['teacher_availability_id'],
      parentId: json['parent_id'],
      studentId: json['student_id'],
      timeSlot: json['time_slot'],
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      parentNotes: json['parent_notes'],
      teacherNotes: json['teacher_notes'],
      meetingLink: json['meeting_link'],
      createdAt: DateTime.parse(json['created_at']),
      teacherName: json['teacher_availability']?['teacher']?['full_name'] ??
          json['teacher_name'],
      parentName: json['parent']?['first_name'] ?? json['parent_name'],
      studentName: json['student']?['first_name'] ?? json['student_name'],
      roomNumber: json['teacher_availability']?['room_number'] ??
          json['room_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'ptm_schedule_id': ptmScheduleId,
      'teacher_availability_id': teacherAvailabilityId,
      'parent_id': parentId,
      'student_id': studentId,
      'time_slot': timeSlot,
      'status': status,
      'notes': notes,
      'parent_notes': parentNotes,
      'teacher_notes': teacherNotes,
      'meeting_link': meetingLink,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
