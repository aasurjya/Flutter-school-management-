/// Hostel model
class Hostel {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final String? wardenId;
  final String? address;
  final String? contactNumber;
  final int totalRooms;
  final int totalCapacity;
  final double? feePerMonth;
  final bool isActive;
  final DateTime createdAt;

  // Related data
  final String? wardenName;
  final List<HostelRoom>? rooms;
  final int? occupiedCount;

  const Hostel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    this.wardenId,
    this.address,
    this.contactNumber,
    this.totalRooms = 0,
    this.totalCapacity = 0,
    this.feePerMonth,
    this.isActive = true,
    required this.createdAt,
    this.wardenName,
    this.rooms,
    this.occupiedCount,
  });

  factory Hostel.fromJson(Map<String, dynamic> json) {
    List<HostelRoom>? rooms;
    if (json['hostel_rooms'] != null) {
      rooms = (json['hostel_rooms'] as List)
          .map((room) => HostelRoom.fromJson(room))
          .toList();
    }

    String? wardenName;
    if (json['users'] != null) {
      wardenName = json['users']['full_name'];
    }

    return Hostel(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      type: json['type'],
      wardenId: json['warden_id'],
      address: json['address'],
      contactNumber: json['contact_number'],
      totalRooms: json['total_rooms'] ?? 0,
      totalCapacity: json['total_capacity'] ?? 0,
      feePerMonth: (json['fee_per_month'] as num?)?.toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      wardenName: wardenName,
      rooms: rooms,
      occupiedCount: json['occupied_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'type': type,
      'warden_id': wardenId,
      'address': address,
      'contact_number': contactNumber,
      'total_rooms': totalRooms,
      'total_capacity': totalCapacity,
      'fee_per_month': feePerMonth,
      'is_active': isActive,
    };
  }

  String get typeDisplay => type == 'boys' ? 'Boys Hostel' : 'Girls Hostel';

  String get feeFormatted =>
      feePerMonth != null ? '\u20B9${feePerMonth!.toStringAsFixed(2)}/month' : 'N/A';

  int get availableCapacity => totalCapacity - (occupiedCount ?? 0);

  String get occupancyText => '${occupiedCount ?? 0}/$totalCapacity occupied';
}

/// Hostel room model
class HostelRoom {
  final String id;
  final String tenantId;
  final String hostelId;
  final String roomNumber;
  final int? floor;
  final String? roomType;
  final int capacity;
  final int occupied;
  final List<String>? amenities;
  final bool isAvailable;
  final DateTime createdAt;

  // Related data
  final List<RoomAllocation>? allocations;

  const HostelRoom({
    required this.id,
    required this.tenantId,
    required this.hostelId,
    required this.roomNumber,
    this.floor,
    this.roomType,
    this.capacity = 1,
    this.occupied = 0,
    this.amenities,
    this.isAvailable = true,
    required this.createdAt,
    this.allocations,
  });

  factory HostelRoom.fromJson(Map<String, dynamic> json) {
    List<RoomAllocation>? allocations;
    if (json['room_allocations'] != null) {
      allocations = (json['room_allocations'] as List)
          .map((a) => RoomAllocation.fromJson(a))
          .toList();
    }

    List<String>? amenities;
    if (json['amenities'] != null) {
      amenities = List<String>.from(json['amenities']);
    }

    return HostelRoom(
      id: json['id'],
      tenantId: json['tenant_id'],
      hostelId: json['hostel_id'],
      roomNumber: json['room_number'],
      floor: json['floor'],
      roomType: json['room_type'],
      capacity: json['capacity'] ?? 1,
      occupied: json['occupied'] ?? 0,
      amenities: amenities,
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      allocations: allocations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'hostel_id': hostelId,
      'room_number': roomNumber,
      'floor': floor,
      'room_type': roomType,
      'capacity': capacity,
      'occupied': occupied,
      'amenities': amenities,
      'is_available': isAvailable,
    };
  }

  bool get hasVacancy => occupied < capacity && isAvailable;

  int get availableBeds => capacity - occupied;

  String get occupancyText => '$occupied/$capacity beds';

  String get floorText => floor != null ? 'Floor $floor' : '';
}

/// Room allocation model
class RoomAllocation {
  final String id;
  final String tenantId;
  final String roomId;
  final String studentId;
  final String academicYearId;
  final String? bedNumber;
  final DateTime allocatedDate;
  final DateTime? vacatedDate;
  final bool isActive;
  final DateTime createdAt;

  // Related data
  final String? studentName;
  final String? roomNumber;
  final String? hostelName;

  const RoomAllocation({
    required this.id,
    required this.tenantId,
    required this.roomId,
    required this.studentId,
    required this.academicYearId,
    this.bedNumber,
    required this.allocatedDate,
    this.vacatedDate,
    this.isActive = true,
    required this.createdAt,
    this.studentName,
    this.roomNumber,
    this.hostelName,
  });

  factory RoomAllocation.fromJson(Map<String, dynamic> json) {
    String? studentName;
    if (json['students'] != null) {
      studentName =
          '${json['students']['first_name']} ${json['students']['last_name'] ?? ''}'.trim();
    }

    String? roomNumber;
    String? hostelName;
    if (json['hostel_rooms'] != null) {
      roomNumber = json['hostel_rooms']['room_number'];
      if (json['hostel_rooms']['hostels'] != null) {
        hostelName = json['hostel_rooms']['hostels']['name'];
      }
    }

    return RoomAllocation(
      id: json['id'],
      tenantId: json['tenant_id'],
      roomId: json['room_id'],
      studentId: json['student_id'],
      academicYearId: json['academic_year_id'],
      bedNumber: json['bed_number'],
      allocatedDate: DateTime.parse(json['allocated_date']),
      vacatedDate: json['vacated_date'] != null
          ? DateTime.parse(json['vacated_date'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      studentName: studentName,
      roomNumber: roomNumber,
      hostelName: hostelName,
    );
  }
}
