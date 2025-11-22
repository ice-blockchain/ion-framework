// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'viewing_session.f.freezed.dart';
part 'viewing_session.f.g.dart';

@freezed
class ViewingSession with _$ViewingSession {
  const factory ViewingSession({
    required String id,
    required int ttl, // Time to live in milliseconds
  }) = _ViewingSession;

  factory ViewingSession.fromJson(Map<String, dynamic> json) => _$ViewingSessionFromJson(json);
}
