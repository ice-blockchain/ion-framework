// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/nsfw/static/shared/nsfw_isolate_functions.dart';
import 'package:isolate_manager/isolate_manager.dart';

// Persistent isolate that handles all NSFW detection without spawning/destroying isolates for each request.
final sharedNsfwIsolate = IsolateManager.createShared(
  workerMappings: {
    nsfwInitializeModelFn: 'nsfwInitializeModelFn',
    nsfwCheckImageFn: 'nsfwCheckImageFn',
    nsfwCheckImagesFn: 'nsfwCheckImagesFn',
  },
);
