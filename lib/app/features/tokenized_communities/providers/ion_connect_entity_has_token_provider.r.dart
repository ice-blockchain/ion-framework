// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_entity_has_token_provider.r.g.dart';

@riverpod
Future<bool> ionConnectEntityHasToken(
  Ref ref, {
  required EventReference eventReference,
}) async {
  // TODO: Implement actual logic to check if entity has token
  // TEMPORARY: Random true/false for testing
  final random = Random(eventReference.toString().hashCode);
  return random.nextBool();
}
