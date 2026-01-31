import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource.dart';
import 'base_repository.dart';

class ResourceRepository extends BaseRepository {
  ResourceRepository(super.client);

  Future<List<StudyResource>> getResources({
    String? subjectId,
    String? classId,
    String? resourceType,
    String? searchQuery,
    List<String>? tags,
    String? uploadedBy,
    bool myUploadsOnly = false,
    int? limit,
    int? offset,
  }) async {
    var query = client
        .from('study_resources')
        .select('''
          *,
          subject:subjects(name),
          class:classes(name),
          uploader:users!uploaded_by(full_name)
        ''')
        .eq('tenant_id', tenantId!)
        .eq('is_public', true);

    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (resourceType != null) {
      query = query.eq('resource_type', resourceType);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }
    if (tags != null && tags.isNotEmpty) {
      query = query.contains('tags', tags);
    }
    if (uploadedBy != null) {
      query = query.eq('uploaded_by', uploadedBy);
    }
    if (myUploadsOnly) {
      query = query.eq('uploaded_by', currentUserId!);
    }

    final response = await query.order('created_at', ascending: false);

    List<dynamic> results = response as List;

    if (offset != null && limit != null) {
      final end = offset + limit;
      if (offset < results.length) {
        results = results.sublist(offset, end > results.length ? results.length : end);
      } else {
        results = [];
      }
    } else if (limit != null) {
      results = results.take(limit).toList();
    }

    return results
        .map((json) => StudyResource.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<StudyResource?> getResourceById(String id) async {
    final response = await client
        .from('study_resources')
        .select('''
          *,
          subject:subjects(name),
          class:classes(name),
          uploader:users!uploaded_by(full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return StudyResource.fromJson(response);
  }

  Future<List<ResourceCategory>> getResourceCategories() async {
    final response = await client
        .from('subjects')
        .select('''
          id,
          name,
          study_resources(count)
        ''')
        .eq('tenant_id', tenantId!);

    return (response as List).map((json) {
      final count = json['study_resources'] is List
          ? (json['study_resources'] as List).length
          : json['study_resources']?[0]?['count'] ?? 0;
      return ResourceCategory(
        id: json['id'],
        name: json['name'],
        resourceCount: count,
      );
    }).toList();
  }

  Future<StudyResource> createResource({
    required String title,
    required String description,
    required String resourceType,
    String? fileUrl,
    String? externalUrl,
    String? thumbnailUrl,
    int? fileSizeBytes,
    String? mimeType,
    String? subjectId,
    String? classId,
    String? chapterId,
    List<String>? tags,
    bool isPublic = true,
  }) async {
    final response = await client
        .from('study_resources')
        .insert({
          'tenant_id': tenantId,
          'title': title,
          'description': description,
          'resource_type': resourceType,
          'file_url': fileUrl,
          'external_url': externalUrl,
          'thumbnail_url': thumbnailUrl,
          'file_size_bytes': fileSizeBytes,
          'mime_type': mimeType,
          'subject_id': subjectId,
          'class_id': classId,
          'chapter_id': chapterId,
          'tags': tags ?? [],
          'uploaded_by': currentUserId,
          'is_public': isPublic,
        })
        .select()
        .single();

    return StudyResource.fromJson(response);
  }

  Future<void> updateResource(String id, {
    String? title,
    String? description,
    String? subjectId,
    String? classId,
    List<String>? tags,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (subjectId != null) updates['subject_id'] = subjectId;
    if (classId != null) updates['class_id'] = classId;
    if (tags != null) updates['tags'] = tags;
    if (isPublic != null) updates['is_public'] = isPublic;

    await client.from('study_resources').update(updates).eq('id', id);
  }

  Future<void> deleteResource(String id) async {
    // First get the resource to delete the file if it exists
    final resource = await getResourceById(id);
    if (resource?.fileUrl != null) {
      // Extract file path from URL and delete from storage
      final uri = Uri.parse(resource!.fileUrl!);
      final pathSegments = uri.pathSegments;
      if (pathSegments.contains('resources')) {
        final fileIndex = pathSegments.indexOf('resources');
        final filePath = pathSegments.sublist(fileIndex + 1).join('/');
        await client.storage.from('resources').remove([filePath]);
      }
    }

    await client.from('study_resources').delete().eq('id', id);
  }

  Future<String> uploadFile(
    String fileName,
    Uint8List fileBytes,
    String mimeType,
  ) async {
    final path = '$tenantId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await client.storage.from('resources').uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    final url = client.storage.from('resources').getPublicUrl(path);
    return url;
  }

  Future<void> incrementViewCount(String id) async {
    await client.rpc('increment_resource_view', params: {'resource_id': id});
  }

  Future<void> incrementDownloadCount(String id) async {
    await client.rpc('increment_resource_download', params: {'resource_id': id});
  }

  Future<List<StudyResource>> getRecentResources({int limit = 10}) async {
    final response = await client
        .from('study_resources')
        .select('''
          *,
          subject:subjects(name),
          uploader:users!uploaded_by(full_name)
        ''')
        .eq('tenant_id', tenantId!)
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => StudyResource.fromJson(json))
        .toList();
  }

  Future<List<StudyResource>> getPopularResources({int limit = 10}) async {
    final response = await client
        .from('study_resources')
        .select('''
          *,
          subject:subjects(name),
          uploader:users!uploaded_by(full_name)
        ''')
        .eq('tenant_id', tenantId!)
        .eq('is_public', true)
        .order('download_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => StudyResource.fromJson(json))
        .toList();
  }

  Future<List<StudyResource>> getMyUploads() async {
    final response = await client
        .from('study_resources')
        .select('''
          *,
          subject:subjects(name),
          class:classes(name)
        ''')
        .eq('tenant_id', tenantId!)
        .eq('uploaded_by', currentUserId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StudyResource.fromJson(json))
        .toList();
  }

  // Folder operations
  Future<List<ResourceFolder>> getFolders({String? parentId}) async {
    var query = client
        .from('resource_folders')
        .select('''
          *,
          subject:subjects(name),
          class:classes(name)
        ''')
        .eq('tenant_id', tenantId!);

    if (parentId != null) {
      query = query.eq('parent_id', parentId);
    } else {
      query = query.isFilter('parent_id', null);
    }

    final response = await query.order('name');
    return (response as List)
        .map((json) => ResourceFolder.fromJson(json))
        .toList();
  }

  Future<ResourceFolder> createFolder({
    required String name,
    String? description,
    String? parentId,
    String? subjectId,
    String? classId,
  }) async {
    final response = await client
        .from('resource_folders')
        .insert({
          'tenant_id': tenantId,
          'name': name,
          'description': description,
          'parent_id': parentId,
          'subject_id': subjectId,
          'class_id': classId,
          'created_by': currentUserId,
        })
        .select()
        .single();

    return ResourceFolder.fromJson(response);
  }

  Future<void> deleteFolder(String id) async {
    await client.from('resource_folders').delete().eq('id', id);
  }
}
