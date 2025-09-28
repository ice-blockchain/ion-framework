// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@DataClassName('EventMessageDbModel')
@TableIndex(
  name: 'wrap_ids_index',
  columns: {#wrapIds},
)
class EventMessageTable extends Table {
  TextColumn get id => text()();
  IntColumn get kind => integer()();
  TextColumn get pubkey => text()();
  TextColumn get masterPubkey => text()();
  IntColumn get createdAt => integer()();
  TextColumn get content => text()();
  TextColumn get tags => text().map(const EventTagsConverter())();
  TextColumn get eventReference => text().map(const EventReferenceConverter())();
  TextColumn get wrapIds => text().map(const StringListConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {eventReference};
}

// Type converter for List<String> <-> JSON
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    throw const FormatException('Expected a JSON array for List<String>');
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}
