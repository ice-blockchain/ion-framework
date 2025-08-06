// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

part 'bookmark.f.freezed.dart';

@freezed
class Bookmark with _$Bookmark implements OptimisticModel {
  const factory Bookmark({
    required EventReference eventReference,
    required String collectionDTag,
    required bool bookmarked,
  }) = _Bookmark;

  const Bookmark._();

  @override
  String get optimisticId => '${collectionDTag}_${eventReference.encode()}';
}
