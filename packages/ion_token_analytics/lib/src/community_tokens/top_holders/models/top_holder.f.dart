// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/models/top_holder_position.f.dart';
import 'package:ion_token_analytics/src/core/map_utils.dart';

part 'top_holder.f.freezed.dart';
part 'top_holder.f.g.dart';

abstract class TopHolderBase {
  CreatorBase? get creator;
  TopHolderPositionBase? get position;
}

@freezed
class TopHolder with _$TopHolder implements TopHolderBase {
  const factory TopHolder({required Creator creator, required TopHolderPosition position}) =
      _TopHolder;

  factory TopHolder.fromJson(Map<String, dynamic> json) => _$TopHolderFromJson(json);
}

@Freezed(copyWith: false)
class TopHolderPatch with _$TopHolderPatch implements TopHolderBase {
  const factory TopHolderPatch({CreatorPatch? creator, TopHolderPositionPatch? position}) =
      _TopHolderPatch;

  factory TopHolderPatch.fromJson(Map<String, dynamic> json) => _$TopHolderPatchFromJson(json);
}

extension TopHolderPatchExtension on TopHolderPatch {
  bool isEmpty() {
    return creator == null && position == null;
  }
}

extension TopHolderExtension on TopHolder {
  TopHolder merge(TopHolderPatch patch) {
    final orgJson = toJson();
    final patchJson = patch.toJson();

    final mergedJson = deepMerge(orgJson, patchJson);

    return TopHolder.fromJson(mergedJson);
  }
}
