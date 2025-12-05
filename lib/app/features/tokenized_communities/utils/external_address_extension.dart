// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

enum ExternalAddressType {
  user('a'),
  textPost('b'),
  videoPost('c'),
  article('d');

  const ExternalAddressType(this.prefix);
  final String prefix;
}

extension ExternalAddressExtension on IonConnectEntity {
  String? get externalAddress {
    final type = switch (this) {
      UserMetadataEntity() => ExternalAddressType.user,
      ModifiablePostEntity(:final data) when data.hasVideo => ExternalAddressType.videoPost,
      ModifiablePostEntity() => ExternalAddressType.textPost,
      PostEntity(:final data) when data.hasVideo => ExternalAddressType.videoPost,
      PostEntity() => ExternalAddressType.textPost,
      ArticleEntity() => ExternalAddressType.article,
      _ => null,
    };

    if (type == null) return null;

    return '${type.prefix}${toEventReference()}';
  }
}
