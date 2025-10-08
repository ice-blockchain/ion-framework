// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/model/user_metadata.f.dart';

extension UserMetadataEntityExtension on UserMetadataEntity? {
  bool get isDeleted {
    return this == null;
  }
}
