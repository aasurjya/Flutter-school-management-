import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/library.dart';
import '../../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String _searchQuery = '';
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/library/my-books'),
            tooltip: 'My Books',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BrowseTab(
            selectedCategory: _selectedCategory,
            availableOnly: _availableOnly,
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            onAvailableOnlyChanged: (val) => setState(() => _availableOnly = val),
          ),
          _SearchTab(
            searchQuery: _searchQuery,
            onSearchChanged: (query) => setState(() => _searchQuery = query),
          ),
        ],
      ),
    );
  }
}

class _BrowseTab extends ConsumerWidget {
  final String? selectedCategory;
  final bool availableOnly;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool> onAvailableOnlyChanged;

  const _BrowseTab({
    required this.selectedCategory,
    required this.availableOnly,
    required this.onCategoryChanged,
    required this.onAvailableOnlyChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(bookCategoriesProvider);
    final booksAsync = ref.watch(booksProvider(BooksFilter(
      category: selectedCategory,
      availableOnly: availableOnly,
    )));

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Category filter
              categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: selectedCategory == null,
                          onSelected: (_) => onCategoryChanged(null),
                        ),
                      ),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (_) => onCategoryChanged(category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox(height: 40),
              ),
              const SizedBox(height: 8),
              // Available only filter
              Row(
                children: [
                  FilterChip(
                    label: const Text('Available Only'),
                    selected: availableOnly,
                    onSelected: (val) => onAvailableOnlyChanged(val),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Books grid
        Expanded(
          child: booksAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return const Center(child: Text('No books found'));
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return _BookCard(book: books[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class _SearchTab extends ConsumerStatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _SearchTab({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider(BooksFilter(
      searchQuery: widget.searchQuery.isEmpty ? null : widget.searchQuery,
    )));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title, author, or ISBN...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: widget.onSearchChanged,
            onChanged: (value) {
              if (value.isEmpty) {
                widget.onSearchChanged('');
              }
            },
          ),
        ),
        Expanded(
          child: widget.searchQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text('Search for books'),
                    ],
                  ),
                )
              : booksAsync.when(
                  data: (books) {
                    if (books.isEmpty) {
                      return const Center(child: Text('No books found'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return _BookListTile(book: books[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                ),
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final LibraryBook book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/library/book/${book.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (book.coverUrl != null)
                    Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _BookPlaceholder(),
                    )
                  else
                    _BookPlaceholder(),
                  if (!book.isAvailable)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'Not Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author != null)
                      Text(
                        book.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Text(
                      book.availabilityText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: book.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final LibraryBook book;

  const _BookListTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: book.coverUrl != null
              ? Image.network(
                  book.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.book,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(
                  Icons.book,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        title: Text(book.title),
        subtitle: Text(book.author ?? 'Unknown Author'),
        trailing: book.isAvailable
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.red),
        onTap: () => context.push('/library/book/${book.id}'),
      ),
    );
  }
}

class _BookPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.book,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
