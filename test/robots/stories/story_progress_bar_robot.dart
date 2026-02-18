// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/components.dart';

import '../../app/features/stories/data/fake_feed_stories_state.dart';
import '../../helpers/robot_test_harness.dart';
import '../base_robot.dart';
import '../mixins/provider_scope_mixin.dart';
import '../mixins/story_state_mixin.dart';

class StoryProgressBarRobot extends BaseRobot with ProviderScopeMixin, StoryStateMixin {
  StoryProgressBarRobot(super.tester);

  static Future<StoryProgressBarRobot> launch(
    WidgetTester tester, {
    required List<ModifiablePostEntity> stories,
    required String viewerPubkey,
  }) async {
    await ScreenUtil.ensureScreenSize();

    final robot = StoryProgressBarRobot(tester);

    await tester.pumpWidget(
      RobotTestHarness(
        childBuilder: (_) => Scaffold(
          body: StoryProgressBarContainer(pubkey: viewerPubkey, showOnlySelectedUser: true),
        ),
        overrides: [
          feedStoriesProvider.overrideWith(() => FakeFeedStories(stories)),
          feedStoriesByPubkeyProvider(viewerPubkey).overrideWith((_) => stories),
        ],
      ),
    );

    await tester.pumpAndSettle();

    robot.initStoryState(
      pubkey: viewerPubkey,
      providerContainer: robot.getContainerFromFinder(find.byType(StoryProgressBarContainer)),
    );

    return robot;
  }

  Finder get _segmentFinder => find.byType(StoryProgressSegment);

  void advance({required List<ModifiablePostEntity> stories}) => container
      .read(singleUserStoryViewingControllerProvider(viewerPubkey).notifier)
      .advance(storiesLength: stories.length);

  List<StoryProgressSegment> get segments =>
      tester.widgetList<StoryProgressSegment>(_segmentFinder).toList();

  void expectSegmentCount(int expected) =>
      expect(segments.length, expected, reason: 'segment count');

  void expectSegmentState({
    required int index,
    required bool isCurrent,
    required bool isPrevious,
  }) {
    final segment = segments[index];
    expect(segment.isCurrent, isCurrent, reason: 'segments[$index].isCurrent');
    expect(
      segment.isPreviousStory,
      isPrevious,
      reason: 'segments[$index].isPreviousStory',
    );
  }
}
