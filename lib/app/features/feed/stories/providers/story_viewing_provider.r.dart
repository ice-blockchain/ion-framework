// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/data/models/models.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_index_keeper_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_viewing_provider.r.g.dart';

/// A controller for managing story viewing state and navigation in a story viewer interface.
///
/// This controller maintains the state of currently viewed user stories and provides methods
/// to navigate between users and their stories.
@riverpod
class UserStoriesViewingNotifier extends _$UserStoriesViewingNotifier {
  @override
  UserStoriesViewerState build(String initialPubkey, {bool showOnlySelectedUser = false}) {
    final stories = ref.watch(
      feedStoriesByPubkeyProvider(initialPubkey, showOnlySelectedUser: showOnlySelectedUser),
    );

    return UserStoriesViewerState(
      userStories: stories,
      currentUserIndex: 0,
    );
  }

  Future<void> setUserStoryByReference(EventReference eventReference) async {
    final storyEntity = await ref.read(
      ionConnectEntityProvider(eventReference: eventReference).future,
    );

    if (storyEntity == null) {
      return;
    }

    state = state.copyWith(
      userStories: [
        storyEntity as ModifiablePostEntity,
      ],
      currentUserIndex: 0,
    );
  }

  void _moveToNextUser() => state = state.copyWith(
        currentUserIndex: state.currentUserIndex + 1,
      );

  void _moveToPreviousUser() => state = state.copyWith(
        currentUserIndex: state.currentUserIndex - 1,
      );

  /// user -> nextUser -> close
  bool advance({VoidCallback? onClose}) {
    if (state.hasNextUser) {
      _moveToNextUser();
      return true;
    }
    onClose?.call();
    return false;
  }

  /// user ← prevUser ← close
  bool rewind({VoidCallback? onClose}) {
    if (state.hasPreviousUser) {
      _moveToPreviousUser();
      return true;
    }
    onClose?.call();
    return false;
  }

  void moveTo(int index) {
    if (index == -1) return;

    state = state.copyWith(
      currentUserIndex: index,
    );
  }
}

/// A controller for managing single user stories viewing state and navigation in a story page view.
///
/// This controller maintains the state of currently viewed single user stories and provides methods
/// to navigate between stories.
@riverpod
class SingleUserStoryViewingController extends _$SingleUserStoryViewingController {
  @override
  SingleUserStoriesViewerState build(String pubkey) => SingleUserStoriesViewerState(
        pubkey: pubkey,
        currentStoryIndex: 0,
      );

  void _moveToNextStory() {
    state = state.copyWith(currentStoryIndex: state.currentStoryIndex + 1);
    saveCurrentIndex();
  }

  void _moveToPreviousStory() {
    state = state.copyWith(currentStoryIndex: state.currentStoryIndex - 1);
    saveCurrentIndex();
  }

  /// story → nextStory → close
  bool advance({required int storiesLength, VoidCallback? onSeenAll}) {
    if (state.currentStoryIndex < storiesLength - 1) {
      _moveToNextStory();
      return true;
    }
    onSeenAll?.call();
    return false;
  }

  /// story ← prevStory ← close
  bool rewind({VoidCallback? onRewoundAll}) {
    if (state.hasPreviousStory) {
      _moveToPreviousStory();
      return true;
    }
    onRewoundAll?.call();
    return false;
  }

  void moveToStoryIndex(int index) {
    if (index == -1) return;

    state = state.copyWith(
      currentStoryIndex: index,
    );
  }

  /// Save the current story index to the keeper when user switches away
  void saveCurrentIndex() {
    ref.read(storyIndexKeeperProvider.notifier).setStoryIndex(
          state.pubkey,
          state.currentStoryIndex,
        );
  }
}
