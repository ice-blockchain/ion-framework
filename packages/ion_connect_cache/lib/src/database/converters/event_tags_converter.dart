// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:drift/drift.dart';

class EventTagsConverter extends TypeConverter<List<List<String>>, String>
    with JsonTypeConverter2<List<List<String>>, String, List<List<String>>> {
  const EventTagsConverter();

  @override
  List<List<String>> fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb) as List<dynamic>);
  }

  @override
  String toSql(List<List<String>> value) {
    return jsonEncode(toJson(value));
  }

  @override
  List<List<String>> fromJson(List<dynamic> json) {
    return _parseNestedList(json);
  }

  @override
  List<List<String>> toJson(List<List<String>> value) {
    return value;
  }

  List<List<String>> _parseNestedList(List<dynamic> jsonList) {
    return jsonList.map((inner) {
      if (inner is! List) {
        throw const FormatException('Expected nested JSON array');
      }
      return List<String>.from(inner);
    }).toList();
  }
}
