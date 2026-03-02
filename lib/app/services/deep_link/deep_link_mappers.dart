// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';

/// Maps an IonConnectEntity to its corresponding SharedContentType
/// based on entity properties like isStory and hasVideo
///
/// Priority order:
/// 1. Stories (regardless of media type) -> story
/// 2. Regular posts with video -> postWithVideo
/// 3. Regular posts -> post
/// 4. Articles -> article
/// 5. User profiles -> profile
/// 6. Community tokens -> communityToken
SharedContentType mapEntityToSharedContentType(IonConnectEntity entity) {
  return switch (entity) {
    ModifiablePostEntity() when entity.isStory => SharedContentType.story,
    ModifiablePostEntity() when entity.data.hasVideo => SharedContentType.postWithVideo,
    ModifiablePostEntity() => SharedContentType.post,
    ArticleEntity() => SharedContentType.article,
    UserMetadataEntity() => SharedContentType.profile,
    CommunityTokenDefinitionEntity() => SharedContentType.communityToken,
    _ => throw UnsupportedError('Unsupported IonConnectEntity: $entity'),
  };
}
