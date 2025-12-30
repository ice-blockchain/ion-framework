// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_options_provider.r.g.dart';

class ShareOptionsData {
  const ShareOptionsData({
    required this.imageUrl,
    required this.userDisplayName,
    required this.shareAppName,
    required this.contentType,
    this.content,
    this.articleTitle,
    this.tickerName,
    this.tokenTitle,
  });

  final String? imageUrl;
  final String userDisplayName;
  final String shareAppName;
  final String? content;
  final SharedContentType contentType;
  final String? articleTitle;
  final String? tickerName;
  final String? tokenTitle;
}

@riverpod
ShareOptionsData? shareOptionsData(
  Ref ref,
  EventReference eventReference,
  UserPreviewData? userPreviewData,
  String prefixUsername,
) {
  final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

  if (entity == null) {
    return null;
  }
  final shareAppName = ref.read(envProvider.notifier).get<String>(EnvVariable.SHARE_APP_NAME);

  if (entity is CommunityTokenDefinitionEntity) {
    final communityTokenInfo =
        ref.watch(tokenMarketInfoProvider(entity.data.externalAddress)).valueOrNull;
    if (communityTokenInfo == null) {
      return null;
    }

    return _getShareOptionsData(
      entity,
      userPreviewData,
      shareAppName,
      prefixUsername,
      communityTokenInfo,
    );
  }

  return _getShareOptionsData(entity, userPreviewData, shareAppName, prefixUsername, null);
}

ShareOptionsData? _getShareOptionsData(
  IonConnectEntity entity,
  UserPreviewData? userPreviewData,
  String shareAppName,
  String prefixUsername,
  CommunityToken? communityTokenInfo,
) {
  if (entity is CommunityTokenDefinitionEntity) {
    return ShareOptionsData(
      imageUrl: communityTokenInfo?.imageUrl,
      userDisplayName: '',
      shareAppName: shareAppName,
      contentType: SharedContentType.communityToken,
      tickerName: communityTokenInfo?.marketData.ticker,
      tokenTitle: communityTokenInfo?.title,
    );
  }

  if (userPreviewData == null) {
    return null;
  }
  final userDisplayName = '${userPreviewData.displayName} ($prefixUsername)';

  switch (entity) {
    case ModifiablePostEntity():
      final content = entity.data.richText?.content ?? entity.data.textContent;
      String? imageUrl;
      if (!entity.isStory) {
        final firstMedia = entity.data.media.values.firstOrNull;
        imageUrl = firstMedia?.image ?? firstMedia?.url;
      } else {
        imageUrl = userPreviewData.avatarUrl;
      }

      final plainTextContent = _convertDeltaToPlainText(content);
      final contentType = mapEntityToSharedContentType(entity);

      return ShareOptionsData(
        imageUrl: imageUrl,
        userDisplayName: userDisplayName,
        shareAppName: shareAppName,
        content: plainTextContent,
        contentType: contentType,
      );
    case ArticleEntity():
      return ShareOptionsData(
        imageUrl: entity.data.image,
        userDisplayName: userDisplayName,
        shareAppName: shareAppName,
        content: entity.data.title,
        contentType: SharedContentType.article,
        articleTitle: entity.data.title,
      );
    case UserMetadataEntity():
      return ShareOptionsData(
        imageUrl: userPreviewData.avatarUrl,
        userDisplayName: userDisplayName,
        shareAppName: shareAppName,
        contentType: SharedContentType.profile,
      );
    case _:
      return null;
  }
}

/// Converts a Quill Delta JSON string to plain text
String _convertDeltaToPlainText(String? value) {
  if (value == null) {
    return '';
  }
  try {
    final deltaJson = jsonDecode(value) as List<dynamic>;
    final delta = Delta.fromJson(deltaJson);

    final filteredDelta = Delta();
    for (final op in delta.operations) {
      // exclude links from the plain text
      if (op.attributes?.containsKey(Attribute.link.key) ?? false) {
        continue;
      }
      filteredDelta.push(op);
    }

    final document = Document.fromDelta(filteredDelta);
    return document.toPlainText().trim();
  } catch (e) {
    return '';
  }
}
