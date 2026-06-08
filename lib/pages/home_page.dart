import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:cliply/models/item.dart';
import 'package:cliply/theme/app_theme.dart';
import 'package:cliply/widgets/note_card.dart';
import 'package:cliply/widgets/filter_chips_bar.dart';
import 'package:cliply/widgets/empty_state.dart';
import 'package:cliply/widgets/note_bottom_sheet.dart';

enum SortOption { lastUpdated, titleAsc, charCountDesc }

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ScrollController _scrollController = ScrollController();
  late Box<Item> itemsBox;
  
  // Search and Filter States
  final TextEditingController _searchController = TextEditingController();
  NoteFilter _activeFilter = NoteFilter.all;
  SortOption _sortOption = SortOption.lastUpdated;
  bool _isGridView = false;
  bool _isFabExtended = true;

  @override
  void initState() {
    super.initState();
    itemsBox = Hive.box<Item>('itemsBox');
    
    _searchController.addListener(() {
      setState(() {});
    });

    // Animate FAB on scroll
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabExtended) {
          setState(() {
            _isFabExtended = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabExtended) {
          setState(() {
            _isFabExtended = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get and filter notes from Hive
  List<Item> _getFilteredAndSortedNotes() {
    List<Item> allNotes = itemsBox.values.toList();
    final query = _searchController.text.trim().toLowerCase();

    // 1. Filter by NoteFilter type
    List<Item> filtered = allNotes.where((note) {
      switch (_activeFilter) {
        case NoteFilter.all:
          return true;
        case NoteFilter.recent:
          // Recent: edited in the last 48 hours or is among the top 5 newest
          final diff = DateTime.now().difference(note.lastUpdated);
          return diff.inHours <= 48;
        case NoteFilter.favorites:
          return note.favorite;
        case NoteFilter.links:
          return note.itemType == 'link';
        case NoteFilter.code:
          return note.itemType == 'code';
      }
    }).toList();

    // 2. Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(query) ||
               note.content.toLowerCase().contains(query);
      }).toList();
    }

    // 3. Sort
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.lastUpdated:
          return b.lastUpdated.compareTo(a.lastUpdated);
        case SortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.charCountDesc:
          return b.content.length.compareTo(a.content.length);
      }
    });

    return filtered;
  }

  void _openNoteSheet({Item? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteBottomSheet(
        item: item,
        onSave: ({
          required String title,
          required String content,
          required String type,
          required bool isPinned,
          required bool isFavorite,
        }) {
          final now = DateTime.now();
          if (item == null) {
            // Add note
            final newItem = Item(
              id: itemsBox.isNotEmpty
                  ? itemsBox.values.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1
                  : 1,
              title: title,
              content: content,
              type: type,
              isPinned: isPinned,
              isFavorite: isFavorite,
              updatedAt: now,
            );
            itemsBox.add(newItem);
          } else {
            // Update note
            setState(() {
              item.title = title;
              item.content = content;
              item.type = type;
              item.isPinned = isPinned;
              item.isFavorite = isFavorite;
              item.updatedAt = now;
            });
            item.save();
          }
          Navigator.pop(context);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(item == null ? 'Note created successfully' : 'Note updated successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  void _deleteNote(Item note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to permanently delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                note.delete();
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Note deleted'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _shareNote(String content) {
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied note contents to clipboard for sharing!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withAlpha(150),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Sort Notes By',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                _buildSortOptionTile(
                  icon: Icons.update_rounded,
                  title: 'Last Updated',
                  option: SortOption.lastUpdated,
                  theme: theme,
                ),
                _buildSortOptionTile(
                  icon: Icons.sort_by_alpha_rounded,
                  title: 'Title (A-Z)',
                  option: SortOption.titleAsc,
                  theme: theme,
                ),
                _buildSortOptionTile(
                  icon: Icons.text_fields_rounded,
                  title: 'Character Count',
                  option: SortOption.charCountDesc,
                  theme: theme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile({
    required IconData icon,
    required String title,
    required SortOption option,
    required ThemeData theme,
  }) {
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        Navigator.pop(context);
      },
    );
  }

  String _getSectionTitle(int count) {
    String filterName = 'NOTES';
    switch (_activeFilter) {
      case NoteFilter.all:
        filterName = 'ALL NOTES';
        break;
      case NoteFilter.recent:
        filterName = 'RECENT NOTES';
        break;
      case NoteFilter.favorites:
        filterName = 'FAVORITES';
        break;
      case NoteFilter.links:
        filterName = 'LINKS';
        break;
      case NoteFilter.code:
        filterName = 'CODE SNIPPETS';
        break;
    }
    return '$filterName • $count';
  }

  String _getEmptyStateTitle() {
    switch (_activeFilter) {
      case NoteFilter.favorites:
        return 'No favorites yet';
      case NoteFilter.links:
        return 'No links saved';
      case NoteFilter.code:
        return 'No code snippets';
      default:
        return 'Write down your ideas';
    }
  }

  String _getEmptyStateDescription() {
    switch (_activeFilter) {
      case NoteFilter.favorites:
        return 'Pin or favorite notes from their action menu to make them show up here.';
      case NoteFilter.links:
        return 'Save articles, website URLs, and hyperlinks for easy access later.';
      case NoteFilter.code:
        return 'Organize your scripts, functions, terminal commands, and configuration code blocks.';
      default:
        return 'Create a note to start organizing your daily thoughts, code snippets, and web links.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visibleNotes = _getFilteredAndSortedNotes();
    final pinnedNotes = visibleNotes.where((note) => note.pinned).toList();
    final regularNotes = visibleNotes.where((note) => !note.pinned).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  SvgPicture.string(
                    _getSvgLogo(theme.brightness == Brightness.dark),
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cliply',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Note count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${itemsBox.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Sort Button
                  IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    tooltip: 'Sort Options',
                    onPressed: _showSortSheet,
                  ),

                  // Grid/List Toggle
                  IconButton(
                    icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                    tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),

                  // Dark/Light Theme Toggle
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppTheme.themeModeNotifier,
                    builder: (context, currentMode, _) {
                      final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
                      final activeDark = currentMode == ThemeMode.dark || 
                                         (currentMode == ThemeMode.system && isSystemDark);
                      return IconButton(
                        icon: Icon(activeDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                        tooltip: activeDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        onPressed: () {
                          AppTheme.themeModeNotifier.value =
                              activeDark ? ThemeMode.light : ThemeMode.dark;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes, links, snippets...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Filter Chips Bar
            FilterChipsBar(
              activeFilter: _activeFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _activeFilter = filter;
                });
              },
            ),

            const SizedBox(height: 8),

            // Refresh & Scrollable Notes List/Grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Pinned Notes Section
                    if (pinnedNotes.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PINNED',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _isGridView
                          ? _buildNotesGrid(pinnedNotes)
                          : _buildNotesList(pinnedNotes),
                    ],

                    // Standard Notes Section Header
                    if (regularNotes.isNotEmpty || pinnedNotes.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            _getSectionTitle(regularNotes.length),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ),
                      ),

                    // Empty State or Notes List/Grid
                    if (visibleNotes.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          title: _getEmptyStateTitle(),
                          description: _getEmptyStateDescription(),
                          onActionPressed: () => _openNoteSheet(),
                          actionLabel: 'Create Note',
                        ),
                      )
                    else
                      _isGridView
                          ? _buildNotesGrid(regularNotes)
                          : _buildNotesList(regularNotes),

                    // Extra space at bottom to prevent FAB covering card content
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteSheet(),
        isExtended: _isFabExtended,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildNotesList(List<Item> notes) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NoteCard(
                item: note,
                isGridView: false,
                onTap: () => _openNoteSheet(item: note),
                onEdit: () => _openNoteSheet(item: note),
                onDelete: () => _deleteNote(note),
                onTogglePin: () {
                  setState(() {
                    note.isPinned = !note.pinned;
                  });
                  note.save();
                },
                onToggleFavorite: () {
                  setState(() {
                    note.isFavorite = !note.favorite;
                  });
                  note.save();
                },
                onShare: _shareNote,
              ),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildNotesGrid(List<Item> notes) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return NoteCard(
              item: note,
              isGridView: true,
              onTap: () => _openNoteSheet(item: note),
              onEdit: () => _openNoteSheet(item: note),
              onDelete: () => _deleteNote(note),
              onTogglePin: () {
                setState(() {
                  note.isPinned = !note.pinned;
                });
                note.save();
              },
              onToggleFavorite: () {
                setState(() {
                  note.isFavorite = !note.favorite;
                });
                note.save();
              },
              onShare: _shareNote,
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }

  String _getSvgLogo(bool isDark) {
    final backingColor = isDark ? '#ffffff' : '#323232';
    final stripesColor = isDark ? '#323232' : '#ffffff';
    return '''<svg id="Layer_2" data-name="Layer 2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 424.16 530.21"><g id="Layer_1-2" data-name="Layer 1"><g><rect fill="$stripesColor" x="71.14" y="53.02" width="281.88" height="149.08"/><path fill="$backingColor" fill-rule="evenodd" d="M424.16,130.81v268.59c0,23.5,0,43.75-2.18,59.97-2.34,17.38-7.61,34.04-21.12,47.55-13.51,13.51-30.17,18.78-47.55,21.12-16.22,2.18-36.46,2.18-59.97,2.18h-162.55c-23.5,0-43.75,0-59.97-2.18-17.38-2.34-34.04-7.61-47.55-21.12-13.51-13.51-18.78-30.17-21.12-47.55C0,443.15,0,422.9,0,399.4V130.81c0-23.5,0-43.75,2.18-59.97,2.34-17.38,7.61-34.04,21.12-47.55C36.81,9.78,53.46,4.51,70.84,2.18,87.06,0,107.31,0,130.81,0h160.81C292.2,0,292.78,0,293.36,0c23.5,0,43.75,0,59.97,2.18,17.38,2.34,34.04,7.61,47.55,21.12,13.51,13.51,18.78,30.17,21.12,47.55,2.18,16.22,2.18,36.46,2.18,59.97ZM132.55,53.02c14.64,0,26.51,11.87,26.51,26.51v26.51c0,14.64,11.87,26.51,26.51,26.51h53.02c14.64,0,26.51-11.87,26.51-26.51v-26.51c0-14.64,11.87-26.51,26.51-26.51s26.51,11.87,26.51,26.51v26.51c0,43.92-35.61,79.53-79.53,79.53h-53.02c-43.92,0-79.53-35.61-79.53-79.53v-26.51c0-14.64,11.87-26.51,26.51-26.51Z"/><g><rect fill="$stripesColor" x="71.14" y="249.1" width="281.88" height="28.59" rx="12" ry="12"/><rect fill="$stripesColor" x="71.14" y="297.81" width="228.35" height="28.59" rx="12" ry="12"/><rect fill="$stripesColor" x="71.14" y="346.51" width="197.64" height="28.59" rx="12" ry="12"/><rect fill="$stripesColor" x="71.14" y="395.22" width="281.88" height="28.59" rx="12" ry="12"/></g></g></g></svg>''';
  }
}