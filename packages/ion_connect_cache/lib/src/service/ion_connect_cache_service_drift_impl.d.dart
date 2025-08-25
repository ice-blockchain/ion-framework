// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion_connect_cache/src/database/event_messages_database.d.dart';
import 'package:ion_connect_cache/src/database/tables/event_messages_table.d.dart';
import 'package:ion_connect_cache/src/extensions/event_message_cache_db_model.dart';
import 'package:ion_connect_cache/src/service/ion_connect_cache_service.dart';
import 'package:nostr_dart/nostr_dart.dart';

part 'ion_connect_cache_service_drift_impl.d.g.dart';

@DriftAccessor(tables: [EventMessagesTable])
class IonConnectCacheServiceDriftImpl extends DatabaseAccessor<EventMessagesDatabase>
    with _$IonConnectCacheServiceDriftImplMixin
    implements IonConnectCacheService {
  IonConnectCacheServiceDriftImpl({required EventMessagesDatabase db}) : super(db);

  @override
  Future<EventMessage> put(EventMessage eventMessage) {
    final dbModel = IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(eventMessage);

    return into(eventMessagesTable).insertOnConflictUpdate(dbModel).then((value) => eventMessage);
  }

  @override
  Future<EventMessage> get(String id) async {
    final dbModel =
        await (select(eventMessagesTable)
              ..limit(1)
              ..where((tbl) => tbl.id.equals(id)))
            .getSingle();

    return dbModel.toEventMessage();
  }

  @override
  Future<int> remove(String id) async {
    return (delete(eventMessagesTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<int> clearDatabase() {
    return delete(eventMessagesTable).go();
  }
}
