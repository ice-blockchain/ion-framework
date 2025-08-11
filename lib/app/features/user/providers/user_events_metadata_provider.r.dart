// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata_builder.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_events_metadata_provider.r.g.dart';

class UserEventsMetadataBuilder implements EventsMetadataBuilder {
  UserEventsMetadataBuilder(List<EventMessage> metadataEvents) : _metadataEvents = metadataEvents;

  final List<EventMessage> _metadataEvents;

  @override
  Future<List<EventsMetadataData>> buildMetadata(List<EventReference> eventReferences) async {
    return [
      for (final event in _metadataEvents)
        EventsMetadataData(
          eventReferences: eventReferences,
          metadata: event,
        ),
    ];
  }
}

@riverpod
Future<UserEventsMetadataBuilder> userEventsMetadataBuilder(Ref ref) async {
  final (
    currentUserMetadata,
    currentUserDelegation,
  ) = await (
    ref.watch(currentUserMetadataProvider.future),
    ref.watch(currentUserDelegationProvider.future),
  ).wait;
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);

  if (currentUserMetadata == null || currentUserDelegation == null) {
    throw UserEventsMetadataBuilderException();
  }

  return UserEventsMetadataBuilder(
    await Future.wait([
      // Do not use `toEntityEventMessage` for UserMetadataEntity because
      // recent changes removed some fields from MediaAttachment and now
      // toEntityEventMessage produces an event message that is not equal to original event.
      // TODO: use toEntityEventMessage after the release
      ionConnectNotifier.sign(currentUserMetadata.data),
      Future.value(currentUserDelegation.toEntityEventMessage()),
    ]),
  );
}
