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
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/deep_link/deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
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
  });

  final String? imageUrl;
  final String userDisplayName;
  final String shareAppName;
  final String? content;
  final SharedContentType contentType;
  final String? articleTitle;
}

@riverpod
ShareOptionsData? shareOptionsData(
  Ref ref,
  EventReference eventReference,
  UserMetadata userMetadata,
  String prefixUsername,
) {
  final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

  if (entity == null) {
    return null;
  }

  final shareAppName = ref.read(envProvider.notifier).get<String>(EnvVariable.SHARE_APP_NAME);
  return _getShareOptionsData(entity, userMetadata, shareAppName, prefixUsername);
}

ShareOptionsData? _getShareOptionsData(
  IonConnectEntity entity,
  UserMetadata userMetadata,
  String shareAppName,
  String prefixUsername,
) {
  final userDisplayName = '${userMetadata.displayName} ($prefixUsername)';

  switch (entity) {
    case ModifiablePostEntity():
      final content = entity.data.richText?.content ?? entity.data.textContent;
      String? imageUrl;
      if (!entity.isStory) {
        final firstMedia = entity.data.media.values.firstOrNull;
        imageUrl = firstMedia?.image ?? firstMedia?.url;
      } else {
        imageUrl = userMetadata.picture;
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
        imageUrl: userMetadata.picture,
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
    final document = Document.fromDelta(delta);
    return document.toPlainText().trim();
  } catch (e) {
    return '';
  }
}
