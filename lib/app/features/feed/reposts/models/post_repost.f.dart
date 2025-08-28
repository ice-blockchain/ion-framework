// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

part 'post_repost.f.freezed.dart';

@freezed
class PostRepost with _$PostRepost implements OptimisticModel {
  const factory PostRepost({
    required EventReference eventReference,
    required int repostsCount,
    required int quotesCount,
    required bool repostedByMe,
    EventReference? myRepostReference,
  }) = _PostRepost;

  const PostRepost._();

  @override
  String get optimisticId => eventReference.toString();

  /// Returns the total count of reposts and quotes.
  /// Ensures minimum count of 1 if the current user has reposted.
  int get totalRepostsCount {
    final total = repostsCount + quotesCount;
    // If user has reposted but total is 0, return 1 to maintain UI consistency
    return (repostedByMe && total == 0) ? 1 : total;
  }
}

@freezed
class RepostEntities with _$RepostEntities {
  const factory RepostEntities({
    required List<CacheableEntity> items,
  }) = _RepostEntities;
}
