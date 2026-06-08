import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cliply/models/item.dart';

class NoteCard extends StatefulWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleFavorite;
  final Function(String) onShare;
  final bool isGridView;

  const NoteCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleFavorite,
    required this.onShare,
    this.isGridView = false,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  double _dragExtend = 0.0;
  static const double _maxDragDistance = 240.0; // 3 action buttons

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-_maxDragDistance, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isGridView) return; // Disable swipe in grid view
    setState(() {
      _dragExtend += details.primaryDelta!;
      // Limit drag to left only (negative values)
      if (_dragExtend > 0) {
        _dragExtend = 0;
      } else if (_dragExtend < -_maxDragDistance - 30) {
        _dragExtend = -_maxDragDistance - 30; // rubber band effect
      }
      _slideController.value = -_dragExtend / _maxDragDistance;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isGridView) return;
    final velocity = details.primaryVelocity!;
    if (velocity < -300 || _dragExtend < -_maxDragDistance / 2) {
      // Open action drawer
      _slideController.forward();
      _dragExtend = -_maxDragDistance;
      HapticFeedback.lightImpact();
    } else {
      // Close action drawer
      _slideController.reverse();
      _dragExtend = 0.0;
    }
  }

  void closeActions() {
    if (_slideController.value > 0) {
      _slideController.reverse();
      _dragExtend = 0.0;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (difference.inDays == 0 && now.day == dt.day) {
      return 'Today • $timeStr';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dt.day)) {
      return 'Yesterday • $timeStr';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day} • $timeStr';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'link':
        return Icons.link_rounded;
      case 'code':
        return Icons.code_rounded;
      default:
        return Icons.notes_rounded;
    }
  }

  Color _getTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'link':
        return Colors.blue;
      case 'code':
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(isDark ? 80 : 180),
          width: 1,
        ),
      ),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withAlpha(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (_slideController.value > 0) {
            closeActions();
          } else {
            widget.onTap();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getTypeIcon(widget.item.itemType),
                    size: 18,
                    color: _getTypeColor(widget.item.itemType, theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.item.pinned)
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  if (widget.item.favorite) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ],
                  // Quick Action Popup Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 140, maxWidth: 140),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              widget.item.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(widget.item.pinned ? 'Unpin' : 'Pin'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              widget.item.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Text(widget.item.favorite ? 'Unfavorite' : 'Favorite'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_rounded, size: 18, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            const Text('Share'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 18, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          widget.onTogglePin();
                          break;
                        case 'favorite':
                          widget.onToggleFavorite();
                          break;
                        case 'edit':
                          widget.onEdit();
                          break;
                        case 'share':
                          widget.onShare(widget.item.content);
                          break;
                        case 'delete':
                          widget.onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.isGridView)
                Expanded(
                  child: Text(
                    widget.item.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(200),
                      fontSize: 13,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  widget.item.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(200),
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // Footer Row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(widget.item.lastUpdated),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.item.content.length} chars',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Material(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _copyToClipboard(context, widget.item.content);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'lib/assets/copy.png',
                          width: 15,
                          height: 15,
                          color: theme.colorScheme.primary,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.copy_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isGridView) {
      return cardContent;
    }

    // List view with swipe actions
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Background Action Buttons
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E1E26)
                    : const Color(0xFFF1F0F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Pin Action
                  _buildActionButton(
                    icon: widget.item.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: theme.colorScheme.primary,
                    label: widget.item.pinned ? 'Unpin' : 'Pin',
                    onTap: () {
                      closeActions();
                      widget.onTogglePin();
                    },
                  ),
                  // Edit Action
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: Colors.blue.shade600,
                    label: 'Edit',
                    onTap: () {
                      closeActions();
                      widget.onEdit();
                    },
                  ),
                  // Share Action
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    color: Colors.green.shade600,
                    label: 'Share',
                    onTap: () {
                      closeActions();
                      widget.onShare(widget.item.content);
                    },
                  ),
                  // Delete Action
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    color: theme.colorScheme.error,
                    label: 'Delete',
                    onTap: () {
                      closeActions();
                      widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Foreground Sliding Card
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimation.value,
                child: child,
              );
            },
            child: cardContent,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 18),
              const SizedBox(width: 8),
              const Text('Copied to clipboard'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }
}
