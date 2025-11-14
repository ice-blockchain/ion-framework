// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/services/entity_serialization_worker.dart'
    show serializeEntitiesFn, serializeEntityFn;
import 'package:isolate_manager/isolate_manager.dart';

/// Shared ION Connect Long-Lived Isolate Manager
///
/// This manager handles the shared ION Connect long-lived isolate used for offloading
/// entity serialization operations from the main isolate.
///
/// NOTE: For entity serialization operations, prefer using [sharedIonConnectIsolate]
/// instead of spawning new isolates or using `compute`, to prevent excessive
/// isolate spawning and improve performance.
final sharedIonConnectIsolate = IsolateManager.createShared(
  workerMappings: {
    serializeEntityFn: 'serializeEntityFn',
    serializeEntitiesFn: 'serializeEntitiesFn',
  },
);
