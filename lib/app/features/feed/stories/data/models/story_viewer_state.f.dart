// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';

part 'story_viewer_state.f.freezed.dart';

@freezed
class SingleUserStoriesViewerState with _$SingleUserStoriesViewerState {
  const factory SingleUserStoriesViewerState({
    required String pubkey,
    required int currentStoryIndex,
  }) = _SingleUserStoriesViewerState;

  const SingleUserStoriesViewerState._();

  bool get hasPreviousStory => currentStoryIndex > 0;
}

@freezed
class UserStoriesViewerState with _$UserStoriesViewerState {
  const factory UserStoriesViewerState({
    required int currentUserIndex,
    List<ModifiablePostEntity>? userStories,
  }) = _UserStoriesViewerState;

  const UserStoriesViewerState._();

  bool get hasNextUser => userStories != null && currentUserIndex < userStoriesCount - 1;

  bool get hasPreviousUser => currentUserIndex > 0;

  bool get isLoading => userStories == null;

  int get userStoriesCount => userStories?.length ?? 0;

  bool get isEmpty => userStoriesCount == 0;

  ModifiablePostEntity? get currentStory {
    return userStories?.elementAtOrNull(currentUserIndex);
  }

  String get currentUserPubkey {
    return pubkeyAtIndex(currentUserIndex) ?? '';
  }

  String? get nextUserPubkey {
    return pubkeyAtIndex(currentUserIndex + 1);
  }

  String? pubkeyAtIndex(int index) {
    if (userStories == null) return null;

    return userStories!.elementAtOrNull(index)?.masterPubkey;
  }
}
