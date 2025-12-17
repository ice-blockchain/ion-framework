// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/missing_events_handler.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_dependency_handler.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_definition_dependency_handler.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'default_events_metadata_handler.r.g.dart';

/// Class for handling [EventsMetadataEntity]s through multiple handlers in sequence.
class DefaultEventsMetadataHandler {
  DefaultEventsMetadataHandler(this.handlers);

  Iterable<EventsMetadataHandler> handlers;

  Future<Iterable<EventsMetadataEntity>> handle(Iterable<EventsMetadataEntity> source) async {
    var current = source;

    for (final handler in handlers) {
      current = await handler.handle(current);
    }

    return current;
  }
}

@riverpod
Future<DefaultEventsMetadataHandler> defaultEventsMetadataHandler(Ref ref) async {
  final handlers = [
    await ref.read(tokenDefinitionDependencyHandlerProvider.future),
    await ref.read(tokenActionFirstBuyDependencyHandlerProvider.future),
    ref.read(missingEventsHandlerProvider),
  ];
  return DefaultEventsMetadataHandler(handlers);
}
