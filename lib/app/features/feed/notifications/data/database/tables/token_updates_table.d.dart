// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_message_converter.d.dart';

@DataClassName('TokenUpdate')
class TokenUpdatesTable extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get kind => integer()();
  TextColumn get eventMessage => text().map(const EventMessageConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
