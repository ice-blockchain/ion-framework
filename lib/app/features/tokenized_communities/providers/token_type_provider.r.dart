// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_type_provider.r.g.dart';

enum CommunityContentTokenType { twitter, profile, postText, postImage, postVideo, article }

/// Use this to find the type for external address, if u don't know if
/// this is an ion connect address or not - e.g. on the token details page.
/// Works only for existing tokens.
@riverpod
Future<CommunityContentTokenType?> tokenTypeForExternalAddress(
  Ref ref,
  String externalAddress,
) async {
  final communityTokenDefinition = await ref
      .watch(tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress).future);

  if (communityTokenDefinition == null) {
    return null;
  }

  return ref.watch(tokenTypeForTokenDefinitionProvider(communityTokenDefinition).future);
}

/// Use this to find the type for ion connect entity.
/// Works even it was not bought yet.
@riverpod
Future<CommunityContentTokenType?> tokenTypeForIonConnectReference(
  Ref ref,
  EventReference eventReference,
) async {
  final communityTokenDefinition = await ref
      .watch(tokenDefinitionForIonConnectReferenceProvider(eventReference: eventReference).future);

  if (communityTokenDefinition == null) {
    return null;
  }

  return ref.watch(tokenTypeForTokenDefinitionProvider(communityTokenDefinition).future);
}

@riverpod
Future<CommunityContentTokenType?> tokenTypeForTokenDefinition(
  Ref ref,
  CommunityTokenDefinitionEntity tokenDefinition,
) async {
  CommunityContentTokenType? type;

  if (tokenDefinition.data.platform == CommunityTokenPlatform.x) {
    type = CommunityContentTokenType.twitter;
  } else if (tokenDefinition
      case CommunityTokenDefinitionEntity(data: final CommunityTokenDefinitionIon ionData)) {
    final originEntity = ref
        .watch(ionConnectEntityProvider(eventReference: ionData.eventReference, network: false))
        .valueOrNull;
    if (originEntity == null) {
      return null;
    }

    if (originEntity is UserMetadataEntity) {
      type = CommunityContentTokenType.profile;
    } else if (ionConnectEntity is ArticleEntity) {
      type = CommunityContentTokenType.article;
    } else if (ionConnectEntity is EntityDataWithMediaContent) {
      final entity = ionConnectEntity as EntityDataWithMediaContent;
      if (entity.hasVideo) {
        type = CommunityContentTokenType.postVideo;
      } else if (entity.visualMedias.isNotEmpty) {
        type = CommunityContentTokenType.postImage;
      } else {
        type = CommunityContentTokenType.postText;
      }
    }
  }

  return type;
}
