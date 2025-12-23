// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

class ExternalAddressType {
  const ExternalAddressType(this.prefix);

  const ExternalAddressType.ionConnectUser() : prefix = 'a';
  const ExternalAddressType.ionConnectTextPost() : prefix = 'b';
  const ExternalAddressType.ionConnectVideoPost() : prefix = 'c';
  const ExternalAddressType.ionConnectArticle() : prefix = 'd';

  /// For X tokens we don't need to know the prefix (and we don't have it in the app)
  const ExternalAddressType.x() : prefix = '';

  final String prefix;

  static ExternalAddressType fromCommunityContentTokenType(CommunityContentTokenType input) {
    return switch (input) {
      CommunityContentTokenType.profile => ExternalAddressType.ionConnectUser,
      CommunityContentTokenType.postText => ExternalAddressType.ionConnectTextPost,
      CommunityContentTokenType.postVideo => ExternalAddressType.ionConnectVideoPost,
      CommunityContentTokenType.article => ExternalAddressType.ionConnectArticle,
      _ => throw ArgumentError('Invalid community content token type: $input'),
    }();
  }
}

extension ExternalAddressTypeTokenKind on ExternalAddressType {
  bool get isCreatorToken => prefix == const ExternalAddressType.ionConnectUser().prefix;
  bool get isXToken => prefix == const ExternalAddressType.x().prefix;
  bool get isContentToken => !isCreatorToken && !isXToken;
}

extension ExternalAddressExtension on IonConnectEntity {
  String? get externalAddress {
    if (externalAddressType == null) return null;
    return '${externalAddressType!.prefix}${toEventReference()}';
  }

  ExternalAddressType? get externalAddressType {
    return switch (this) {
      UserMetadataEntity() => const ExternalAddressType.ionConnectUser(),
      ArticleEntity() => const ExternalAddressType.ionConnectArticle(),
      ModifiablePostEntity(data: final EntityDataWithMediaContent postData) => switch (postData) {
          _ when postData.hasVideo => const ExternalAddressType.ionConnectVideoPost(),
          _ => const ExternalAddressType.ionConnectTextPost(),
        },
      PostEntity(data: final EntityDataWithMediaContent postData) => switch (postData) {
          _ when postData.hasVideo => const ExternalAddressType.ionConnectVideoPost(),
          _ => const ExternalAddressType.ionConnectTextPost(),
        },
      _ => null,
    };
  }
}
