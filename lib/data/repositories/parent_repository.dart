import '../models/student.dart';
import 'base_repository.dart';

/// Repository for parents and student-parent junction operations.
///
/// All mutating operations return new objects and never mutate existing ones.
class ParentRepository extends BaseRepository {
  ParentRepository(super.client);

  /// Search parents by first_name, last_name, phone, or email using ilike.
  Future<List<Parent>> searchParents(String query, {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final pattern = '%$trimmed%';
    final response = await client
        .from('parents')
        .select()
        .eq('tenant_id', requireTenantId)
        .or(
          'first_name.ilike.$pattern,'
          'last_name.ilike.$pattern,'
          'phone.ilike.$pattern,'
          'email.ilike.$pattern',
        )
        .order('first_name')
        .limit(limit);

    return (response as List)
        .map((json) => Parent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Returns all parents linked to [studentId], joining through student_parents.
  Future<List<StudentParentLink>> getParentsByStudent(String studentId) async {
    final response = await client
        .from('student_parents')
        .select('id, is_primary, can_pickup, created_at, parents(*)')
        .eq('student_id', studentId)
        .order('is_primary', ascending: false);

    return (response as List)
        .map((json) => StudentParentLink.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new parent record in the parents table.
  ///
  /// Returns the created [Parent].
  Future<Parent> createParent({
    required String firstName,
    required String lastName,
    required String relation,
    String? email,
    String? phone,
    String? userId,
  }) async {
    final payload = <String, dynamic>{
      'tenant_id': requireTenantId,
      'first_name': firstName,
      'last_name': lastName,
      'relation': relation,
      if (email != null && email.isNotEmpty) 'email': email,
      'phone': phone ?? '',
      if (userId != null) 'user_id': userId,
    };

    final response = await client
        .from('parents')
        .insert(payload)
        .select()
        .single();

    return Parent.fromJson(response);
  }

  /// Updates mutable fields on a parent record identified by [parentId].
  ///
  /// [data] may contain any subset of: first_name, last_name, phone, email,
  /// relation, occupation, address, photo_url.
  Future<Parent> updateParent(String parentId, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('parents')
        .update(payload)
        .eq('id', parentId)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();
    return Parent.fromJson(response);
  }

  /// Links an existing parent to a student via the student_parents junction table.
  ///
  /// Returns the created [StudentParentLink].
  Future<StudentParentLink> linkParent({
    required String studentId,
    required String parentId,
    required String relation,
    bool isPrimary = false,
    bool canPickup = false,
  }) async {
    final payload = <String, dynamic>{
      'student_id': studentId,
      'parent_id': parentId,
      'is_primary': isPrimary,
      'can_pickup': canPickup,
    };

    final response = await client
        .from('student_parents')
        .insert(payload)
        .select('id, is_primary, can_pickup, created_at, parents(*)')
        .single();

    return StudentParentLink.fromJson(response);
  }

  /// Removes a student-parent link by [studentParentId] (the junction row id).
  Future<void> unlinkParent(String studentParentId) async {
    await client
        .from('student_parents')
        .delete()
        .eq('id', studentParentId);
  }

  /// Updates isPrimary or canPickup on a student_parents junction row.
  ///
  /// Returns the updated [StudentParentLink].
  Future<StudentParentLink> updateParentLink(
    String studentParentId, {
    bool? isPrimary,
    bool? canPickup,
  }) async {
    final updates = <String, dynamic>{
      if (isPrimary != null) 'is_primary': isPrimary,
      if (canPickup != null) 'can_pickup': canPickup,
    };

    if (updates.isEmpty) {
      throw ArgumentError('At least one of isPrimary or canPickup must be provided.');
    }

    final response = await client
        .from('student_parents')
        .update(updates)
        .eq('id', studentParentId)
        .select('id, is_primary, can_pickup, created_at, parents(*)')
        .single();

    return StudentParentLink.fromJson(response);
  }
}

/// Represents a row from student_parents with the nested parent record.
class StudentParentLink {
  final String id;
  final bool isPrimary;
  final bool canPickup;
  final DateTime createdAt;
  final Parent parent;

  const StudentParentLink({
    required this.id,
    required this.isPrimary,
    required this.canPickup,
    required this.createdAt,
    required this.parent,
  });

  factory StudentParentLink.fromJson(Map<String, dynamic> json) {
    final parentJson = json['parents'];
    if (parentJson == null) {
      throw StateError('StudentParentLink.fromJson: missing nested parents data');
    }
    return StudentParentLink(
      id: json['id'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      canPickup: json['can_pickup'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      parent: Parent.fromJson(parentJson as Map<String, dynamic>),
    );
  }
}
