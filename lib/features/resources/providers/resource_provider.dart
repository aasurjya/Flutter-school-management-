import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/resource.dart';
import '../../../data/repositories/resource_repository.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository(ref.watch(supabaseProvider));
});

final resourcesProvider =
    FutureProvider.family<List<StudyResource>, ResourceFilter>(
  (ref, filter) async {
    final repository = ref.watch(resourceRepositoryProvider);
    return repository.getResources(
      subjectId: filter.subjectId,
      classId: filter.classId,
      resourceType: filter.resourceType,
      searchQuery: filter.searchQuery,
      tags: filter.tags,
      uploadedBy: filter.uploadedBy,
      myUploadsOnly: filter.myUploadsOnly,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final resourceByIdProvider =
    FutureProvider.family<StudyResource?, String>((ref, id) async {
  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getResourceById(id);
});

final resourceCategoriesProvider =
    FutureProvider<List<ResourceCategory>>((ref) async {
  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getResourceCategories();
});

final recentResourcesProvider =
    FutureProvider<List<StudyResource>>((ref) async {
  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getRecentResources(limit: 10);
});

final popularResourcesProvider =
    FutureProvider<List<StudyResource>>((ref) async {
  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getPopularResources(limit: 10);
});

final myUploadsProvider = FutureProvider<List<StudyResource>>((ref) async {
  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getMyUploads();
});

final resourceFoldersProvider =
    FutureProvider.family<List<ResourceFolder>, String?>((ref, parentId) async {
  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getFolders(parentId: parentId);
});

// Search state
final resourceSearchQueryProvider = StateProvider<String>((ref) => '');

final resourceTypeFilterProvider = StateProvider<String?>((ref) => null);

final selectedSubjectProvider = StateProvider<String?>((ref) => null);

final selectedClassProvider = StateProvider<String?>((ref) => null);

// Filtered resources based on search and filters
final filteredResourcesProvider =
    FutureProvider<List<StudyResource>>((ref) async {
  final searchQuery = ref.watch(resourceSearchQueryProvider);
  final resourceType = ref.watch(resourceTypeFilterProvider);
  final subjectId = ref.watch(selectedSubjectProvider);
  final classId = ref.watch(selectedClassProvider);

  final filter = ResourceFilter(
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    resourceType: resourceType,
    subjectId: subjectId,
    classId: classId,
  );

  final repository = ref.watch(resourceRepositoryProvider);
  return repository.getResources(
    subjectId: filter.subjectId,
    classId: filter.classId,
    resourceType: filter.resourceType,
    searchQuery: filter.searchQuery,
  );
});

// Upload state management
class UploadState {
  final bool isUploading;
  final double progress;
  final String? error;
  final StudyResource? uploadedResource;

  const UploadState({
    this.isUploading = false,
    this.progress = 0,
    this.error,
    this.uploadedResource,
  });

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    StudyResource? uploadedResource,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error,
      uploadedResource: uploadedResource ?? this.uploadedResource,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final ResourceRepository _repository;

  UploadNotifier(this._repository) : super(const UploadState());

  Future<StudyResource?> uploadResource({
    required String title,
    required String description,
    required String resourceType,
    String? fileName,
    Uint8List? fileBytes,
    String? mimeType,
    String? externalUrl,
    String? subjectId,
    String? classId,
    List<String>? tags,
    bool isPublic = true,
  }) async {
    try {
      state = state.copyWith(isUploading: true, progress: 0, error: null);

      String? fileUrl;
      int? fileSizeBytes;

      // Upload file if provided
      if (fileBytes != null && fileName != null && mimeType != null) {
        state = state.copyWith(progress: 0.3);
        fileUrl = await _repository.uploadFile(fileName, fileBytes, mimeType);
        fileSizeBytes = fileBytes.length;
        state = state.copyWith(progress: 0.7);
      }

      // Create resource record
      final resource = await _repository.createResource(
        title: title,
        description: description,
        resourceType: resourceType,
        fileUrl: fileUrl,
        externalUrl: externalUrl,
        fileSizeBytes: fileSizeBytes,
        mimeType: mimeType,
        subjectId: subjectId,
        classId: classId,
        tags: tags,
        isPublic: isPublic,
      );

      state = state.copyWith(
        isUploading: false,
        progress: 1,
        uploadedResource: resource,
      );

      return resource;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const UploadState();
  }
}

final uploadNotifierProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final repository = ref.watch(resourceRepositoryProvider);
  return UploadNotifier(repository);
});
