// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_mentions_provider.r.g.dart';

@riverpod
Set<String> postMentionsPubkeys(
  Ref ref, {
  required IonConnectEntity entity,
}) {
  final data = switch (entity) {
    final ModifiablePostEntity post => post.data,
    final PostEntity post => post.data,
    _ => null,
  };

  if (data is! EntityDataWithMediaContent) {
    return {};
  }
  final richText = data.richText;
  if (richText == null) {
    return {};
  }

  final richTextDecoded = Delta.fromJson(jsonDecode(richText.content) as List<dynamic>);
  return richTextDecoded.extractMentionPubkeys().toSet();
}
