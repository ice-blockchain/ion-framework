import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/services/compressors/brotli_compressor.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_signature_verifier.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Global Long-Lived Isolate Manager
///
/// This manager handles the global long-lived isolate used for offloading
/// operations from the main isolate.
///
/// NOTE: For frequently used operations, prefer using [globalLongLivedIsolate]
/// instead of spawning new isolates or using `compute`, to prevent excessive
/// isolate spawning and improve performance.

final globalLongLivedIsolate = IsolateManager.createShared(
  //TODO: remove this after testing
  isDebug: true,
  workerMappings: {
    unwrapGiftFn: 'unwrapGiftFn',
    createGiftWrapFn: 'createGiftWrapFn',
    encryptMediaFileFn: 'encryptMediaFileFn',
    decryptMediaFileFn: 'decryptMediaFileFn',
    compressBrotliFn: 'compressBrotliFn',
    decompressBrotliFn: 'decompressBrotliFn',
    verifyEddsaCurve25519SignatureFn: 'verifyEddsaCurve25519SignatureFn',
  },
);
