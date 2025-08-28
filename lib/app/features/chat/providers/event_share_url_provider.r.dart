// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_share_url_provider.r.g.dart';

@riverpod
Future<String> eventShareUrl(Ref ref, EventReference eventReference) async {
  final pubkey = eventReference.masterPubkey;
  final relays = await ref.watch(userRelaysManagerProvider.notifier).fetchReachableRelays([pubkey]);
  if (relays.isEmpty) {
    throw UserRelaysNotFoundException(pubkey);
  }
  final encodedRelays = [
    for (final relay in relays.first.data.list) jsonEncode(relay.toTag()),
  ];
  return eventReference.encode(relays: encodedRelays);
}
