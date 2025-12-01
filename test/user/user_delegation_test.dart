// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';

import '../test_utils.dart';

void main() {
  const pubkey = '477318cfb5427b9cfc66a9fa376150c1ddbc62115ae27cef72417eb959691396';
  NostrDart.configure();

  group('UserDelegation Tests', () {
    test('UserDelegation.fromEventMessage should work when all data is there', () async {
      final keyStore = await createTestSigner();

      final delegationEvent = await EventMessage.fromData(
        signer: keyStore,
        kind: 10100,
        tags: const [
          ['p', pubkey, '', 'active:1674834236:1,7'],
        ],
        content: '',
      );

      final userDelegation = UserDelegationEntity.fromEventMessage(delegationEvent);

      expect(userDelegation, isA<UserDelegationEntity>());
      expect(userDelegation.data.delegates.first.kinds?.length, 2);
    });

    test('UserDelegation.fromEventMessage should work when kinds are not set', () async {
      final keyStore = await createTestSigner();

      final delegationEvent = await EventMessage.fromData(
        signer: keyStore,
        kind: 10100,
        tags: const [
          ['p', pubkey, '', 'active:1674834236'],
        ],
        content: '',
      );

      final userDelegation = UserDelegationEntity.fromEventMessage(delegationEvent);

      expect(
        userDelegation.data.delegates.first.kinds,
        isNull,
      );
    });

    test('UserDelegation processes valid Event', () async {
      final masterKeyStore = KeyStore.generate();
      final subKeyStore = KeyStore.generate();

      final delegationEvent = await EventMessage.fromData(
        signer: masterKeyStore,
        kind: 10100,
        tags: [
          ['p', subKeyStore.publicKey, '', 'active:1674834236'],
        ],
        content: '',
      );

      final event = await EventMessage.fromData(
        signer: subKeyStore,
        kind: 1,
        content: 'test event',
      );

      final userDelegation = UserDelegationEntity.fromEventMessage(delegationEvent);

      expect(
        userDelegation.data.validate(event),
        isTrue,
      );
    });

    test('UserDelegation processes invalid Event [attestation]', () async {
      final masterKeyStore = KeyStore.generate();
      final subKeyStore = KeyStore.generate();

      final delegationEvent = await EventMessage.fromData(
        signer: masterKeyStore,
        kind: 10100,
        tags: [
          ['p', subKeyStore.publicKey, '', 'active:1674834236'],
          ['p', subKeyStore.publicKey, '', 'inactive:1684834236'],
        ],
        content: '',
      );

      final event = await EventMessage.fromData(
        signer: subKeyStore,
        kind: 1,
        content: 'test event',
      );

      final userDelegation = UserDelegationEntity.fromEventMessage(delegationEvent);

      expect(
        userDelegation.data.validate(event),
        isFalse,
      );
    });

    test('UserDelegation processes invalid Event [kind]', () async {
      final masterKeyStore = KeyStore.generate();
      final subKeyStore = KeyStore.generate();

      final delegationEvent = await EventMessage.fromData(
        signer: masterKeyStore,
        kind: 10100,
        tags: [
          ['p', subKeyStore.publicKey, '', 'active:1674834236:0,7'],
        ],
        content: '',
      );

      final event = await EventMessage.fromData(
        signer: subKeyStore,
        kind: 1,
        content: 'test event',
      );

      final userDelegation = UserDelegationEntity.fromEventMessage(delegationEvent);

      expect(
        userDelegation.data.validate(event),
        isFalse,
      );
    });

    test('UserDelegation adding new Delegates work', () async {
      final masterKeyStore = KeyStore.generate();
      final subKeyStore = KeyStore.generate();

      final initialTags = [
        ['p', subKeyStore.publicKey, '', 'active:1674834236:0,7'],
        ['p', subKeyStore.publicKey, '', 'inactive:1684834236'],
      ];

      final newTag = ['p', subKeyStore.publicKey, '', 'active:1674834236:7'];

      final delegationEvent = await EventMessage.fromData(
        signer: masterKeyStore,
        kind: 10100,
        tags: initialTags,
        content: '',
      );

      final initialUserDelegation = UserDelegationEntity.fromEventMessage(delegationEvent);

      final newUserDelegation = initialUserDelegation.copyWith(
        data: initialUserDelegation.data.copyWith(
          delegates: [...initialUserDelegation.data.delegates, UserDelegate.fromTag(newTag)],
        ),
      );

      expect(newUserDelegation.data.tags, [...initialTags, newTag]);
    });
  });
}
