// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

extension ExternalAddressExtension on ReplaceableEntity {
  String get externalAddress {
    return 'ion_connect:0:27b85b3b0364482d65c13a873dcd93e65daf0eb817cfaaeb94a5de4a56473328:';
    final String prefix;

    if (data is UserMetadata) {
      prefix = 'a';
    } else if (data is ModifiablePostData) {
      final post = data as ModifiablePostData;
      if (!post.hasVideo) {
        prefix = 'b';
      } else {
        prefix = 'c';
      }
    } else if (data is ArticleEntity) {
      prefix = 'd';
    } else {
      throw Exception('Unsupported data type');
    }
    return '$prefix${toEventReference()}';
  }
}

//TODO handle x.com prefix

///
/// x.com:
/// z - twitter profile
/// y - twitter post
/// x - twitter video post
/// w - twitter article
///
