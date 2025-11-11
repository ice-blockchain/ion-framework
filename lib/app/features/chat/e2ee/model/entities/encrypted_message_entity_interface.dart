// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/entity_data_with_encrypted_media_content.dart';

/// Common interface for encrypted message entities that have media attachments
/// and a master pubkey for decryption
abstract interface class EncryptedMessageEntityWithMedia {
  /// The master pubkey used for decrypting media
  String get masterPubkey;

  /// The entity data containing media attachments
  EntityDataWithEncryptedMediaContent get data;
}
