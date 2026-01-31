import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/resource.dart';
import '../../providers/resource_provider.dart';

class ResourceLibraryScreen extends ConsumerStatefulWidget {
  const ResourceLibraryScreen({super.key});

  @override
  ConsumerState<ResourceLibraryScreen> createState() =>
      _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends ConsumerState<ResourceLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Library'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Recent'),
            Tab(text: 'Popular'),
            Tab(text: 'My Uploads'),
          ],
        ),
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchController),
          _FilterChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _BrowseTab(),
                _RecentTab(),
                _PopularTab(),
                _MyUploadsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _UploadResourceSheet(),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search resources...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref.read(resourceSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: (value) {
          ref.read(resourceSearchQueryProvider.notifier).state = value;
        },
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(resourceTypeFilterProvider);

    final types = [
      ('All', null),
      ('Documents', 'document'),
      ('Videos', 'video'),
      ('Audio', 'audio'),
      ('Links', 'link'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: types.map((type) {
          final isSelected = selectedType == type.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type.$1),
              selected: isSelected,
              onSelected: (_) {
                ref.read(resourceTypeFilterProvider.notifier).state = type.$2;
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BrowseTab extends ConsumerWidget {
  const _BrowseTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(filteredResourcesProvider);

    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('No resources found'),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) =>
              _ResourceCard(resource: resources[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _RecentTab extends ConsumerWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(recentResourcesProvider);

    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) {
          return const Center(child: Text('No recent resources'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) =>
              _ResourceCard(resource: resources[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _PopularTab extends ConsumerWidget {
  const _PopularTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(popularResourcesProvider);

    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) {
          return const Center(child: Text('No popular resources yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) => _ResourceCard(
            resource: resources[index],
            showStats: true,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _MyUploadsTab extends ConsumerWidget {
  const _MyUploadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(myUploadsProvider);

    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('You haven\'t uploaded any resources yet'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showUploadSheet(context),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Your First Resource'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) => _ResourceCard(
            resource: resources[index],
            showEditOptions: true,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _UploadResourceSheet(),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final StudyResource resource;
  final bool showStats;
  final bool showEditOptions;

  const _ResourceCard({
    required this.resource,
    this.showStats = false,
    this.showEditOptions = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openResource(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getTypeColor(resource.resourceType).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(resource.resourceType),
                  color: _getTypeColor(resource.resourceType),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (resource.description.isNotEmpty)
                      Text(
                        resource.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.category,
                          label: resource.resourceTypeDisplay,
                        ),
                        if (resource.subjectName != null)
                          _InfoChip(
                            icon: Icons.book,
                            label: resource.subjectName!,
                          ),
                        if (resource.fileSizeBytes != null)
                          _InfoChip(
                            icon: Icons.storage,
                            label: resource.fileSizeDisplay,
                          ),
                      ],
                    ),
                    if (showStats) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${resource.viewCount}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.download,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${resource.downloadCount}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (showEditOptions)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editResource(context);
                    } else if (value == 'delete') {
                      _deleteResource(context);
                    }
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadResource(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.play_circle_filled;
      case 'audio':
        return Icons.audiotrack;
      case 'link':
        return Icons.link;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'document':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.purple;
      case 'link':
        return Colors.green;
      case 'image':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _openResource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ResourceDetailSheet(resource: resource),
    );
  }

  void _downloadResource(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${resource.title}...'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {},
        ),
      ),
    );
  }

  void _editResource(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit resource')),
    );
  }

  void _deleteResource(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: Text(
          'Are you sure you want to delete "${resource.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resource deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ResourceDetailSheet extends StatelessWidget {
  final StudyResource resource;

  const _ResourceDetailSheet({required this.resource});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          resource.resourceTypeDisplay,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (resource.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(resource.description),
                const SizedBox(height: 24),
              ],
              _DetailRow(
                icon: Icons.person,
                label: 'Uploaded by',
                value: resource.uploaderName ?? 'Unknown',
              ),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value:
                    '${resource.createdAt.day}/${resource.createdAt.month}/${resource.createdAt.year}',
              ),
              if (resource.subjectName != null)
                _DetailRow(
                  icon: Icons.book,
                  label: 'Subject',
                  value: resource.subjectName!,
                ),
              if (resource.className != null)
                _DetailRow(
                  icon: Icons.class_,
                  label: 'Class',
                  value: resource.className!,
                ),
              if (resource.fileSizeBytes != null)
                _DetailRow(
                  icon: Icons.storage,
                  label: 'Size',
                  value: resource.fileSizeDisplay,
                ),
              _DetailRow(
                icon: Icons.visibility,
                label: 'Views',
                value: '${resource.viewCount}',
              ),
              _DetailRow(
                icon: Icons.download,
                label: 'Downloads',
                value: '${resource.downloadCount}',
              ),
              const SizedBox(height: 24),
              if (resource.tags.isNotEmpty) ...[
                Text(
                  'Tags',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resource.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${resource.title}...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ),
              const SizedBox(height: 12),
              if (resource.isExternalLink)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Open external link
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Link'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadResourceSheet extends ConsumerStatefulWidget {
  const _UploadResourceSheet();

  @override
  ConsumerState<_UploadResourceSheet> createState() =>
      _UploadResourceSheetState();
}

class _UploadResourceSheetState extends ConsumerState<_UploadResourceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  String _resourceType = 'document';
  String? _selectedSubject;
  String? _selectedClass;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Upload Resource',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe this resource...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _resourceType,
                    decoration: const InputDecoration(
                      labelText: 'Resource Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'document', child: Text('Document (PDF, DOC)')),
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                      DropdownMenuItem(value: 'audio', child: Text('Audio')),
                      DropdownMenuItem(
                          value: 'link', child: Text('External Link')),
                      DropdownMenuItem(value: 'image', child: Text('Image')),
                    ],
                    onChanged: (value) {
                      setState(() => _resourceType = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_resourceType == 'link')
                    TextFormField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        hintText: 'https://',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (_resourceType == 'link' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter a URL';
                        }
                        return null;
                      },
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to select a file',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PDF, DOC, MP4, MP3, JPG, PNG',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Select Subject')),
                      DropdownMenuItem(
                          value: 'math', child: Text('Mathematics')),
                      DropdownMenuItem(value: 'science', child: Text('Science')),
                      DropdownMenuItem(value: 'english', child: Text('English')),
                      DropdownMenuItem(value: 'history', child: Text('History')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSubject = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Class (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Select Class')),
                      DropdownMenuItem(value: 'class1', child: Text('Class 1')),
                      DropdownMenuItem(value: 'class2', child: Text('Class 2')),
                      DropdownMenuItem(value: 'class3', child: Text('Class 3')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedClass = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add Tags',
                            hintText: 'e.g., chapter1, exam',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (_tagController.text.trim().isNotEmpty) {
                            setState(() {
                              _tags.add(_tagController.text.trim());
                              _tagController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                onDeleted: () {
                                  setState(() => _tags.remove(tag));
                                },
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (uploadState.isUploading) ...[
                    LinearProgressIndicator(value: uploadState.progress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(uploadState.progress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _uploadResource,
                        child: const Text('Upload Resource'),
                      ),
                    ),
                  if (uploadState.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      uploadState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _uploadResource() {
    if (_formKey.currentState!.validate()) {
      // In a real app, this would upload the file
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
