// SPDX-License-Identifier: ice License 1.0

part of '../user_mute_database.m.dart';

@DataClassName('UserMuteEventDbModel')
class UserMuteEventTable extends Table {
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
