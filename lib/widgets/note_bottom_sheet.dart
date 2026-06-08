import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cliply/models/item.dart';

class NoteBottomSheet extends StatefulWidget {
  final Item? item;
  final Function({
    required String title,
    required String content,
    required String type,
    required bool isPinned,
    required bool isFavorite,
  }) onSave;

  const NoteBottomSheet({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<NoteBottomSheet> createState() => _NoteBottomSheetState();
}

class _NoteBottomSheetState extends State<NoteBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedType;
  late bool _isPinned;
  late bool _isFavorite;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _contentController = TextEditingController(text: widget.item?.content ?? '');
    _selectedType = widget.item?.itemType ?? 'note';
    _isPinned = widget.item?.pinned ?? false;
    _isFavorite = widget.item?.favorite ?? false;

    // Autofocus title on create
    if (widget.item == null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _titleFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar for swipe down
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withAlpha(150),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    widget.item == null ? 'New Note' : 'Edit Note',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  // Favorite Toggle
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _isFavorite ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                  // Copy Action
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Copy Note Content',
                    onPressed: () {
                      if (_contentController.text.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: _contentController.text)).then((_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Note content copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        });
                      }
                    },
                  ),
                  // Pin Toggle
                  IconButton(
                    icon: Icon(
                      _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      color: _isPinned ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPinned = !_isPinned;
                      });
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Note Type Chips
                    Text(
                      'Note Type',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip('note', Icons.notes_outlined, 'Note', theme),
                        const SizedBox(width: 8),
                        _buildTypeChip('link', Icons.link_outlined, 'Link', theme),
                        const SizedBox(width: 8),
                        _buildTypeChip('code', Icons.code_outlined, 'Code', theme),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title TextField
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        fillColor: isDark ? const Color(0xFF23232C) : const Color(0xFFF3F2F6),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        _contentFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content TextField & Char Count Stack
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        TextField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          maxLines: 8,
                          minLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Start writing...',
                            fillColor: isDark ? const Color(0xFF23232C) : const Color(0xFFF3F2F6),
                            filled: true,
                            contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        // Live character counter & copy chip in corner
                        Padding(
                          padding: const EdgeInsets.only(right: 16, bottom: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_contentController.text.length} characters',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Material(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () {
                                    if (_contentController.text.isNotEmpty) {
                                      Clipboard.setData(ClipboardData(text: _contentController.text)).then((_) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Copied to clipboard'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy_rounded,
                                          size: 12,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon, String label, ThemeData theme) {
    final isSelected = _selectedType == type;
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? Colors.white
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? const Color(0xFF23232C) : const Color(0xFFF3F2F6),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  void _saveNote() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    widget.onSave(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _selectedType,
      isPinned: _isPinned,
      isFavorite: _isFavorite,
    );
  }
}
