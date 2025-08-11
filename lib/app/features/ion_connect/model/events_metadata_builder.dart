// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';

abstract class EventsMetadataBuilder {
  Future<List<EventsMetadataData>> buildMetadata(List<EventReference> eventReferences);
}
