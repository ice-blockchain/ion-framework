// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/interests.f.dart';

import '../test_utils.dart';

void main() {
  NostrDart.configure();

  group('Interests Tests', () {
    test('Interests.fromEventMessage should work when all data is there', () async {
      final keyStore = await createTestSigner();

      final testEvent = await EventMessage.fromData(
        signer: keyStore,
        kind: 10015,
        tags: const [
          [MasterPubkeyTag.tagName, 'value'],
          ['t', 'tag'],
          ['a', '2:13:123'],
          ['a', '3:222:123'],
        ],
        content: '',
      );

      final interest = InterestsEntity.fromEventMessage(testEvent);

      expect(interest, isA<InterestsEntity>());
      expect(interest.data.hashtags.length, 1);
      expect(interest.data.interestSetRefs.length, 2);
      expect(interest.data.hashtags[0], 'tag');
      expect(
        interest.data.interestSetRefs[0],
        const ReplaceableEventReference(kind: 2, masterPubkey: '13', dTag: '123'),
      );
    });
  });
}
