import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/bookmark.dart';

class BookmarkModel {
  final String id;

  /// BookmarkType.index
  final int type;

  /// BookmarkStatus.index
  final int status;

  final String title;
  final String? description;
  final String? thumbnailPath;
  final String? url;
  final String? sourceDomain;
  final String? filePath;
  final String? content;

  /// millisecondsSinceEpoch
  final int createdAtMs;

  /// millisecondsSinceEpoch, null이면 위젯에 한 번도 노출된 적 없음
  final int? lastShownAtMs;

  const BookmarkModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    this.thumbnailPath,
    this.url,
    this.sourceDomain,
    this.filePath,
    this.content,
    required this.createdAtMs,
    this.lastShownAtMs,
  });

  factory BookmarkModel.fromEntity(Bookmark entity) => BookmarkModel(
        id: entity.id,
        type: entity.type.index,
        status: entity.status.index,
        title: entity.title,
        description: entity.description,
        thumbnailPath: entity.thumbnailPath,
        url: entity.url,
        sourceDomain: entity.sourceDomain,
        filePath: entity.filePath,
        content: entity.content,
        createdAtMs: entity.createdAt.millisecondsSinceEpoch,
        lastShownAtMs: entity.lastShownAt?.millisecondsSinceEpoch,
      );

  Bookmark toEntity() => Bookmark(
        id: id,
        type: BookmarkType.values[type],
        status: BookmarkStatus.values[status],
        title: title,
        description: description,
        thumbnailPath: thumbnailPath,
        url: url,
        sourceDomain: sourceDomain,
        filePath: filePath,
        content: content,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        lastShownAt: lastShownAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastShownAtMs!)
            : null,
      );

  BookmarkModel copyWith({
    int? type,
    int? status,
    String? title,
    String? description,
    String? thumbnailPath,
    String? url,
    String? sourceDomain,
    String? filePath,
    String? content,
    int? createdAtMs,
    int? lastShownAtMs,
  }) =>
      BookmarkModel(
        id: id,
        type: type ?? this.type,
        status: status ?? this.status,
        title: title ?? this.title,
        description: description ?? this.description,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        url: url ?? this.url,
        sourceDomain: sourceDomain ?? this.sourceDomain,
        filePath: filePath ?? this.filePath,
        content: content ?? this.content,
        createdAtMs: createdAtMs ?? this.createdAtMs,
        lastShownAtMs: lastShownAtMs ?? this.lastShownAtMs,
      );
}

/// Hive TypeAdapter — 필드 인덱스는 한번 정하면 변경 불가 (마이그레이션 필요)
class BookmarkModelAdapter extends TypeAdapter<BookmarkModel> {
  @override
  final int typeId = 0;

  @override
  BookmarkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookmarkModel(
      id: fields[0] as String,
      type: fields[1] as int,
      status: fields[2] as int,
      title: fields[3] as String,
      description: fields[4] as String?,
      thumbnailPath: fields[5] as String?,
      url: fields[6] as String?,
      sourceDomain: fields[7] as String?,
      filePath: fields[8] as String?,
      content: fields[9] as String?,
      createdAtMs: fields[10] as int,
      lastShownAtMs: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.thumbnailPath)
      ..writeByte(6)
      ..write(obj.url)
      ..writeByte(7)
      ..write(obj.sourceDomain)
      ..writeByte(8)
      ..write(obj.filePath)
      ..writeByte(9)
      ..write(obj.content)
      ..writeByte(10)
      ..write(obj.createdAtMs)
      ..writeByte(11)
      ..write(obj.lastShownAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkModelAdapter && typeId == other.typeId;
}
