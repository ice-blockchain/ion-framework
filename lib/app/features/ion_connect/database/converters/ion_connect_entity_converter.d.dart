// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';

class IonConnectEntityConverter extends TypeConverter<IonConnectEntity, String>
    with JsonTypeConverter2<IonConnectEntity, String, Map<String, dynamic>> {
  const IonConnectEntityConverter();

  static const _parser = EventParser();

  @override
  IonConnectEntity fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb) as Map<String, dynamic>);
  }

  @override
  String toSql(IonConnectEntity value) {
    return jsonEncode(toJson(value));
  }

  @override
  IonConnectEntity fromJson(Map<String, dynamic> json) {
    final eventMessage = EventMessage.fromPayloadJson(json);
    return _parser.parse(eventMessage);
  }

  @override
  Map<String, dynamic> toJson(IonConnectEntity value) {
    if (value is! EntityEventSerializable) {
      throw UnsupportedEntityType(value);
    }

    final eventMessage = (value as EntityEventSerializable).toEntityEventMessage();

    if (eventMessage is! EventMessage) {
      throw UnsupportedEntityType(value);
    }

    return eventMessage.jsonPayload;
  }
}
