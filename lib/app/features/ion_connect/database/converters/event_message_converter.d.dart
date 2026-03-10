// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

class EventMessageConverter extends TypeConverter<EventMessage, String>
    with JsonTypeConverter2<EventMessage, String, Map<String, dynamic>> {
  const EventMessageConverter();

  @override
  EventMessage fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb) as Map<String, dynamic>);
  }

  @override
  String toSql(EventMessage value) {
    return jsonEncode(toJson(value));
  }

  @override
  EventMessage fromJson(Map<String, dynamic> json) {
    return EventMessage.fromPayloadJson(json);
  }

  @override
  Map<String, dynamic> toJson(EventMessage value) {
    return value.jsonPayload;
  }
}
