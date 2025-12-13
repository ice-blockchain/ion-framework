import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_type_provider.r.g.dart';

enum CommunityContentTokenType { twitter, profile, postText, postImage, postVideo, article }

@riverpod
Future<CommunityContentTokenType?> getTokenType(
  Ref ref,
  String externalAddress,
) async {
  CommunityContentTokenType? type;

  final communityTokenDefinition =
      await ref.watch(communityTokenDefinitionProvider(externalAddress: externalAddress).future);

  if (communityTokenDefinition?.data.platform == CommunityTokenPlatform.x) {
    type = CommunityContentTokenType.twitter;
  } else if (communityTokenDefinition
      case CommunityTokenDefinitionEntity(data: final CommunityTokenDefinitionIon ionData)) {
    final originEntity = ref
        .watch(ionConnectEntityProvider(eventReference: ionData.eventReference, network: false))
        .valueOrNull;
    if (originEntity == null) {
      return null;
    }

    if (originEntity is UserMetadataEntity) {
      type = CommunityContentTokenType.profile;
    } else if (originEntity is ModifiablePostEntity) {
      if (originEntity.data.hasVideo) {
        type = CommunityContentTokenType.postVideo;
      } else if (originEntity.data.visualMedias.isNotEmpty) {
        type = CommunityContentTokenType.postImage;
      } else {
        type = CommunityContentTokenType.postText;
      }
    } else if (originEntity is PostEntity) {
      if (originEntity.data.hasVideo) {
        type = CommunityContentTokenType.postVideo;
      } else if (originEntity.data.visualMedias.isNotEmpty) {
        type = CommunityContentTokenType.postImage;
      } else {
        type = CommunityContentTokenType.postText;
      }
    } else if (originEntity is ArticleEntity) {
      type = CommunityContentTokenType.article;
    }
  }

  return type;
}
