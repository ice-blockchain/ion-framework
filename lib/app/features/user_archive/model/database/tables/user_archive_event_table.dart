// SPDX-License-Identifier: ice License 1.0

part of '../user_archive_database.m.dart';

@DataClassName('UserArchiveEventDbModel')
class UserArchiveEventTable extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  IntColumn get kind => integer()();
  TextColumn get pubkey => text()();
  TextColumn get masterPubkey => text()();
  IntColumn get createdAt => integer()();
  TextColumn get tags => text().map(const EventTagsConverter())();
  TextColumn get eventReference => text().map(const EventReferenceConverter())();

  @override
  Set<Column> get primaryKey => {eventReference};
}
