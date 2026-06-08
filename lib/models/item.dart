import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  bool? isPinned;

  @HiveField(4)
  bool? isFavorite;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  String? type;

  Item({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.isFavorite = false,
    DateTime? updatedAt,
    this.type = 'note',
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get pinned => isPinned ?? false;
  bool get favorite => isFavorite ?? false;
  DateTime get lastUpdated => updatedAt ?? DateTime.now();
  String get itemType => type ?? 'note';
}

