// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/services/compressors/brotli_compressor.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Shared Chat Long-Lived Isolate Manager
///
/// This manager handles the shared chat long-lived isolate used for offloading
/// operations from the main isolate.
///
/// NOTE: For frequently used operations, prefer using [sharedChatIsolate]
/// instead of spawning new isolates or using `compute`, to prevent excessive
/// isolate spawning and improve performance.
final sharedChatIsolate = IsolateManager.createShared(
  workerMappings: {
    unwrapGiftFn: 'unwrapGiftFn',
    createGiftWrapFn: 'createGiftWrapFn',
    encryptMediaFileFn: 'encryptMediaFileFn',
    decryptMediaFileFn: 'decryptMediaFileFn',
    compressBrotliFn: 'compressBrotliFn',
    decompressBrotliFn: 'decompressBrotliFn',
  },
  isDebug: true,
);
