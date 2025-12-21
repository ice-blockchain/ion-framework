// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';

void main() {
  group('ImmutableEventReference encode and decode', () {
    const pubkey = 'f5d70542664e65719b55d8d6250b7d51cbbea7711412dbb524108682cbd7f0d4';
    const eventId = '496bf22b76e63553b2cac70c44b53867368b4b7612053a2c78609f3144324807';
    const encodedNostr =
        'nostr:nevent1qqsyj6lj9dmwvd2nkt9vwrzyk5uxwd5tfdmpypf693uxp8e3gseyspczyr6awp2zve8x2uvm2hvdvfgt04guh048wy2p9ka4ysggdqkt6lcdgxatx7l';
    const encodedIon =
        'ion:nevent1qqsyj6lj9dmwvd2nkt9vwrzyk5uxwd5tfdmpypf693uxp8e3gseyspczyr6awp2zve8x2uvm2hvdvfgt04guh048wy2p9ka4ysggdqkt6lcdgxatx7l';

    test('encode produces correct output', () {
      const reference = ImmutableEventReference(masterPubkey: pubkey, eventId: eventId);

      expect(reference.encode(), equals(encodedIon));
    });

    test('decode produces correct output', () {
      final nostr = EventReference.fromEncoded(encodedNostr);
      final ion = EventReference.fromEncoded(encodedIon);

      expect(nostr, isA<ImmutableEventReference>());
      expect(nostr.masterPubkey, equals(pubkey));
      expect((nostr as ImmutableEventReference).eventId, equals(eventId));

      expect(ion, isA<ImmutableEventReference>());
      expect(ion.masterPubkey, equals(pubkey));
      expect((ion as ImmutableEventReference).eventId, equals(eventId));
    });
  });

  group('ReplaceableEventReference encode and decode for addressable events', () {
    const pubkey = 'f5d70542664e65719b55d8d6250b7d51cbbea7711412dbb524108682cbd7f0d4';
    const kind = ModifiablePostEntity.kind;
    const dTag = '496bf22b76e63553b2cac70c44b53867368b4b7612053a2c78609f3144324807';
    const encodedNostr =
        'nostr:naddr1qpqrgwfkvfnryvnzxumx2d3nx56nxc3jvdskxdesvv6rgc34xvurvdenxcuxydrzxumrzv3sx5ekzvnrxuurvvpevcenzdp5xvergwpsxupzpawhq4pxvnn9wxd4tkxky59h65wth6nhz9qjmw6jgyyxst9a0ux5qvzqqqr4muv6xeqv';
    const encodedIon =
        'ion:naddr1qpqrgwfkvfnryvnzxumx2d3nx56nxc3jvdskxdesvv6rgc34xvurvdenxcuxydrzxumrzv3sx5ekzvnrxuurvvpevcenzdp5xvergwpsxupzpawhq4pxvnn9wxd4tkxky59h65wth6nhz9qjmw6jgyyxst9a0ux5qvzqqqr4muv6xeqv';

    test('encode produces correct output', () {
      const reference = ReplaceableEventReference(masterPubkey: pubkey, kind: kind, dTag: dTag);

      expect(reference.encode(), equals(encodedIon));
    });

    test('decode produces correct output', () {
      final nostrReference = EventReference.fromEncoded(encodedNostr);
      final ionReference = EventReference.fromEncoded(encodedIon);

      expect(nostrReference, isA<ReplaceableEventReference>());
      expect((nostrReference as ReplaceableEventReference).masterPubkey, equals(pubkey));
      expect(nostrReference.dTag, equals(dTag));
      expect(nostrReference.kind, equals(kind));

      expect(ionReference, isA<ReplaceableEventReference>());
      expect((ionReference as ReplaceableEventReference).masterPubkey, equals(pubkey));
      expect(ionReference.dTag, equals(dTag));
      expect(ionReference.kind, equals(kind));
    });
  });

  group('ReplaceableEventReference encode and decode for normal replaceable events', () {
    const pubkey = 'f5d70542664e65719b55d8d6250b7d51cbbea7711412dbb524108682cbd7f0d4';
    const kind = UserRelaysEntity.kind;
    const encodedNostr =
        'nostr:naddr1qqqqyg846uz5yejwv4cek4wc6cjskl23ewl2wug5ztdm2fqss6pvh4ls6spsgqqqyufq4vsghj';
    const encodedIon =
        'ion:naddr1qqqqyg846uz5yejwv4cek4wc6cjskl23ewl2wug5ztdm2fqss6pvh4ls6spsgqqqyufq4vsghj';

    test('encode produces correct output', () {
      const reference = ReplaceableEventReference(masterPubkey: pubkey, kind: kind);

      expect(reference.encode(), equals(encodedIon));
    });

    test('decode produces correct output', () {
      final nostrReference = EventReference.fromEncoded(encodedNostr);
      final ionReference = EventReference.fromEncoded(encodedIon);

      expect(nostrReference, isA<ReplaceableEventReference>());
      expect((nostrReference as ReplaceableEventReference).masterPubkey, equals(pubkey));
      expect(nostrReference.kind, equals(kind));

      expect(ionReference, isA<ReplaceableEventReference>());
      expect((ionReference as ReplaceableEventReference).masterPubkey, equals(pubkey));
      expect(ionReference.kind, equals(kind));
    });
  });

  group('ReplaceableEventReference encode and decode for profiles', () {
    const pubkey = 'f5d70542664e65719b55d8d6250b7d51cbbea7711412dbb524108682cbd7f0d4';
    const kind = UserMetadataEntity.kind;
    const encodedNostr =
        'nostr:nprofile1qqs0t4c9gfnyuet3nd2a3439pd74rja75ac3gykmk5jppp5ze0tlp4q9xpcn0';
    const encodedIon = 'ion:nprofile1qqs0t4c9gfnyuet3nd2a3439pd74rja75ac3gykmk5jppp5ze0tlp4q9xpcn0';

    test('encode produces correct output', () {
      const reference = ReplaceableEventReference(masterPubkey: pubkey, kind: kind);

      expect(reference.encode(), equals(encodedIon));
    });

    test('decode produces correct output', () {
      final nostrReference = EventReference.fromEncoded(encodedNostr);
      final ionReference = EventReference.fromEncoded(encodedIon);

      expect(nostrReference, isA<ReplaceableEventReference>());
      expect((nostrReference as ReplaceableEventReference).masterPubkey, equals(pubkey));
      expect(nostrReference.kind, equals(kind));

      expect(ionReference, isA<ReplaceableEventReference>());
      expect((ionReference as ReplaceableEventReference).masterPubkey, equals(pubkey));
      expect(ionReference.kind, equals(kind));
    });
  });
}
