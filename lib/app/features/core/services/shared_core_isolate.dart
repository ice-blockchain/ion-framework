// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/ion_connect/ion_connect_signature_verifier.dart';
import 'package:isolate_manager/isolate_manager.dart';

final sharedCoreIsolate = IsolateManager.createShared(
  isDebug: true,
  workerMappings: {
    ionConnectSignatureVerifierFn: 'ionConnectSignatureVerifierFn',
  },
);
