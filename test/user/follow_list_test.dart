// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';

import '../test_utils.dart';

void main() {
  NostrDart.configure();

  group('FollowList Tests', () {
    test('FollowList.fromEventMessage should work when all data is there', () async {
      final keyStore = await createTestSigner();

      final testEvent = await EventMessage.fromData(
        signer: keyStore,
        kind: 3,
        tags: const [
          [MasterPubkeyTag.tagName, 'value'],
          ['p', '91cf9..4e5ca', 'wss://alicerelay.com/', 'alice'],
          ['p', '14aeb..8dad4', 'wss://bobrelay.com/ionConnect', 'bob'],
          ['p', '612ae..e610f', 'ws://carolrelay.com/ws', 'carol'],
        ],
        content: '',
      );

      final followList = FollowListEntity.fromEventMessage(testEvent);

      expect(followList, isA<FollowListEntity>());
      expect(followList.data.list.length, 3);
      expect(followList.data.list[1].pubkey, '14aeb..8dad4');
      expect(followList.data.list[1].relayUrl, 'wss://bobrelay.com/ionConnect');
      expect(followList.data.list[1].petname, 'bob');
    });
  });
}
