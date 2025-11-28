// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/user/model/interest_set.f.dart';

import '../test_utils.dart';

void main() {
  NostrDart.configure();

  group('InterestsSet Tests', () {
    test('InterestSet.fromEventMessage should work when all data is there', () async {
      final keyStore = await createTestSigner();

      final testEvent = await EventMessage.fromData(
        signer: keyStore,
        kind: 30015,
        tags: const [
          [MasterPubkeyTag.tagName, 'value'],
          ['d', 'languages'],
          ['t', 'en'],
          ['t', 'es'],
        ],
        content: '',
      );

      final interestSet = InterestSetEntity.fromEventMessage(testEvent);

      expect(interestSet, isA<InterestSetEntity>());
      expect(interestSet.data.type, InterestSetType.languages);
      expect(interestSet.data.hashtags.length, 2);
      expect(interestSet.data.hashtags[0], 'en');
    });
  });
}
