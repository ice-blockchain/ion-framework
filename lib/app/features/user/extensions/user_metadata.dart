// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

extension UserMetadataEntityExtension on UserMetadataEntity? {
  bool get isDeleted {
    return this == null;
  }

  bool get hasBscWallet {
    return this?.data.wallets?.keys.any(
              (k) =>
                  k == TokenizedCommunitiesConstants.bscNetworkId ||
                  k == TokenizedCommunitiesConstants.bscTestnetNetworkId,
            ) ??
        false;
  }
}
