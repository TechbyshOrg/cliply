import 'package:flutter/material.dart';

enum NoteFilter { all, recent, favorites, links, code }

class FilterChipsBar extends StatelessWidget {
  final NoteFilter activeFilter;
  final ValueChanged<NoteFilter> onFilterChanged;

  const FilterChipsBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  String _getFilterLabel(NoteFilter filter) {
    switch (filter) {
      case NoteFilter.all:
        return 'All';
      case NoteFilter.recent:
        return 'Recent';
      case NoteFilter.favorites:
        return 'Favorites';
      case NoteFilter.links:
        return 'Links';
      case NoteFilter.code:
        return 'Code';
    }
  }

  IconData _getFilterIcon(NoteFilter filter) {
    switch (filter) {
      case NoteFilter.all:
        return Icons.notes;
      case NoteFilter.recent:
        return Icons.schedule;
      case NoteFilter.favorites:
        return Icons.star;
      case NoteFilter.links:
        return Icons.link;
      case NoteFilter.code:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: NoteFilter.values.length,
        itemBuilder: (context, index) {
          final filter = NoteFilter.values[index];
          final isSelected = filter == activeFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                _getFilterIcon(filter),
                size: 16,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(_getFilterLabel(filter)),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.brightness == Brightness.light
                  ? Colors.white
                  : theme.colorScheme.surface,
              shadowColor: Colors.transparent,
              elevation: 0,
              pressElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : theme.colorScheme.outline.withAlpha(120),
                  width: 1,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
