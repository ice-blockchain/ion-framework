// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_type_provider.r.g.dart';

enum CommunityContentTokenType { twitter, profile, postText, postImage, postVideo, article }

/// Provides [CommunityContentTokenType] for given external address.
///
/// Use this to find the type for external address, if u don't know if
/// this is an ion connect address or not - e.g. on the token details page.
/// Works only for existing tokens because it needs to fetch token market info
/// to get the token definition.
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

/// Provides [CommunityContentTokenType] for given ion connect [EventReference].
///
/// Use this to find the type for ion connect entity.
/// Works even if it has not been bought yet.
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

/// Provides [CommunityContentTokenType] for given [CommunityTokenDefinitionEntity].
///
/// Detects the type based on the origin entity of the token definition.
@riverpod
Future<CommunityContentTokenType?> tokenTypeForTokenDefinition(
  Ref ref,
  CommunityTokenDefinitionEntity tokenDefinition,
) async {
  keepAliveWhenAuthenticated(ref);
  if (tokenDefinition.data.platform == CommunityTokenPlatform.x) {
    return CommunityContentTokenType.twitter;
  } else if (tokenDefinition
      case CommunityTokenDefinitionEntity(data: final CommunityTokenDefinitionIon ionData)) {
    return ref
        .watch(tokenTypeForIonConnectEntityProvider(eventReference: ionData.eventReference).future);
  }

  return null;
}

@riverpod
Future<CommunityContentTokenType?> tokenTypeForIonConnectEntity(
  Ref ref, {
  required EventReference eventReference,
}) async {
  final entity = await ref.watch(ionConnectEntityProvider(eventReference: eventReference).future);

  if (entity == null) {
    return null;
  }

  return switch (entity) {
    UserMetadataEntity() => CommunityContentTokenType.profile,
    ArticleEntity() => CommunityContentTokenType.article,
    ModifiablePostEntity(data: final EntityDataWithMediaContent postData) => switch (postData) {
        _ when postData.hasVideo => CommunityContentTokenType.postVideo,
        _ when postData.visualMedias.isNotEmpty => CommunityContentTokenType.postImage,
        _ => CommunityContentTokenType.postText,
      },
    PostEntity(data: final EntityDataWithMediaContent postData) => switch (postData) {
        _ when postData.hasVideo => CommunityContentTokenType.postVideo,
        _ when postData.visualMedias.isNotEmpty => CommunityContentTokenType.postImage,
        _ => CommunityContentTokenType.postText,
      },
    _ => null,
  };
}
