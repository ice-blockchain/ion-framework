// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

class ExternalAddressType {
  const ExternalAddressType(this.prefix);

  const ExternalAddressType.ionConnectUser() : prefix = 'a';
  const ExternalAddressType.ionConnectTextPost() : prefix = 'b';
  const ExternalAddressType.ionConnectVideoPost() : prefix = 'c';
  const ExternalAddressType.ionConnectArticle() : prefix = 'd';

  final String prefix;
}

extension ExternalAddressExtension on IonConnectEntity {
  String? get externalAddress {
    final type = switch (this) {
      UserMetadataEntity() => ExternalAddressType.ionConnectUser,
      ModifiablePostEntity(:final data) when data.hasVideo =>
        ExternalAddressType.ionConnectVideoPost,
      ModifiablePostEntity() => ExternalAddressType.ionConnectTextPost,
      PostEntity(:final data) when data.hasVideo => ExternalAddressType.ionConnectVideoPost,
      PostEntity() => ExternalAddressType.ionConnectTextPost,
      ArticleEntity() => ExternalAddressType.ionConnectArticle,
      _ => null,
    };

    if (type == null) return null;

    final data = '${type().prefix}${toEventReference()}';
    return data;
  }
}
