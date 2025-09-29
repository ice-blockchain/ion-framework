// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/ion_connect/ion_connect_signature_verifier.dart';
import 'package:isolate_manager/isolate_manager.dart';

///
/// It is used to offload work from the main isolate.
/// Prevents spawning multiple isolates for redundant tasks.
/// Use this to efficiently handle background tasks without blocking the main isolate.
///
final sharedCoreIsolate = IsolateManager.createShared(
  workerMappings: {
    ionConnectSignatureVerifierFn: 'ionConnectSignatureVerifierFn',
  },
);
