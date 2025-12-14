// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/utils/poll_utils.dart';

void main() {
  group('PollUtils.pollDataToPollDraft', () {
    // Helper function to create PollData with a specific duration from now.
    // A null duration will result in a ttl of 0.
    PollData createPollData({required List<String> options, Duration? duration}) {
      int ttl;
      if (duration != null) {
        final closingTime = DateTime.now().add(duration);
        ttl = (closingTime.millisecondsSinceEpoch / 1000).floor();
      } else {
        ttl = 0; // Represents a poll that never expires
      }

      return PollData(
        options: options,
        ttl: ttl,
        type: '', // Default value
        title: '', // Default value
      );
    }

    // Test case 1: Poll has more than a day remaining
    test('should correctly convert PollData with days and hours remaining', () {
      // Arrange
      final pollData = createPollData(
        duration: const Duration(days: 2, hours: 3, minutes: 10),
        options: ['Yes', 'No'],
      );

      // Act
      final pollDraft = PollUtils.pollDataToPollDraft(pollData, isVoted: false);

      // Assert
      expect(pollDraft.lengthDays, 2);
      expect(pollDraft.lengthHours, 4); // 3 hours + 10 mins rounds up to 4 hours
      expect(pollDraft.answers.length, 2);
      expect(pollDraft.answers[0].text, 'Yes');
      expect(pollDraft.added, isTrue);
      expect(pollDraft.isVoted, isFalse);
    });

    // Test case 2: Poll has less than a day remaining
    test('should correctly convert PollData with only hours remaining', () {
      // Arrange
      final pollData = createPollData(
        duration: const Duration(hours: 5, minutes: 1, seconds: 30),
        options: ['A', 'B'],
      );

      // Act
      final pollDraft = PollUtils.pollDataToPollDraft(pollData, isVoted: true);

      // Assert
      expect(pollDraft.lengthDays, 0);
      expect(pollDraft.lengthHours, 6); // 5 hours + 1 min rounds up to 6 hours
      expect(pollDraft.isVoted, isTrue);
    });

    // Test case 3: Poll has just under an hour remaining
    test('should correctly round up when just a few minutes remain', () {
      // Arrange
      final pollData = createPollData(
        duration: const Duration(minutes: 59),
        options: ['Go'],
      );

      // Act
      final pollDraft = PollUtils.pollDataToPollDraft(pollData, isVoted: false);

      // Assert
      expect(pollDraft.lengthDays, 0);
      expect(pollDraft.lengthHours, 1);
    });

    // Test case 4: Poll has already expired
    test('should return zero length for an expired poll', () {
      // Arrange
      final pollData = createPollData(
        duration: const Duration(hours: -1), // A negative duration for the past
        options: ['Expired'],
      );

      // Act
      final pollDraft = PollUtils.pollDataToPollDraft(pollData, isVoted: false);

      // Assert
      expect(pollDraft.lengthDays, 0);
      expect(pollDraft.lengthHours, 0);
    });

    // Test case 5: Poll that never expires (ttl = 0)
    test('should handle polls that never expire', () {
      // Arrange
      // Pass null duration to the helper to get ttl = 0
      final pollData = createPollData(options: ['Forever']);

      // Act
      final pollDraft = PollUtils.pollDataToPollDraft(pollData, isVoted: false);

      // Assert
      expect(pollDraft.lengthDays, 0);
      expect(pollDraft.lengthHours, 0);
    });
  });
}
