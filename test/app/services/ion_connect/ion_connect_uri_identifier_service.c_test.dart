// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/services/bech32/bech32_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_protocol_identifier_type.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';

void main() {
  late IonConnectUriIdentifierService service;

  setUp(() {
    service = IonConnectUriIdentifierService(bech32Service: Bech32Service());
  });

  group('encodeShareableIdentifiers', () {
    test('encodes nprofile with all fields', () {
      final result = service.encodeShareableIdentifiers(
        prefix: IonConnectProtocolIdentifierType.nprofile,
        special: '477318cfb5427b9cfc66a9fa376150c1ddbc62115ae27cef72417eb959691396',
      );
      expect(result.startsWith('nprofile1'), isTrue);
    });

    test('throws when trying to encode non-shareable identifier', () {
      expect(
        () => service.encodeShareableIdentifiers(
          prefix: IonConnectProtocolIdentifierType.note,
          special: 'test',
        ),
        throwsException,
      );
    });
  });

  group('decodeShareableIdentifiers', () {
    test('decodes nprofile with all fields', () {
      final result = service.decodeShareableIdentifiers(
        payload:
            'nprofile1qqsv7r6t6vs2sjpn7evhw8dwd84szqun4xfnqculuh5mtha6fwlm0wcp9pdjyu3z9s38wumn8ghj7wf59ccnqvpwxymzuv3nxvargdp5xv3zcgnhwf5hgefzt5qjvkezwg3zcgnhwden5te0xy6rzt3ex5hr2wfwxucr5dp5xsejytpzwfjkzepzt5qjskezwg3zcgnhwden5te0xyurzt35xyhrzdpj9cerzde6xs6rgvez9s38yetpvs396p6vguv',
      );

      expect(result, isNotNull);
      expect(result.prefix, IonConnectProtocolIdentifierType.nprofile);
      expect(result.special, 'cf0f4bd320a84833f659771dae69eb010393a99330639fe5e9b5dfba4bbfb7bb');
      expect(result.relays, [
        '["r","wss://94.100.16.233:4443","write"]',
        '["r","wss://141.95.59.70:4443","read"]',
        '["r","wss://181.41.142.217:4443","read"]',
      ]);
    });

    test('decodes naddr with all fields', () {
      final result = service.decodeShareableIdentifiers(
        payload:
            'naddr1qqjrqvfe8qunjeps95mnxwt995mkvvnp95uxvdnr95crqcmyvvukvvmyxa3kgqfgtv38yg3vyfmhxue69uhnjdpwxycrqt33xchryven8g6rgdpnygkzyamjd96x2gjaqyn9kgnjygkzyamnwvaz7te3xscjuwf49c6njt3hxqargdp5xv3zcgnjv4skggjaqy59kgnjygkzyamnwvaz7te38qcjudp39ccngv3wxgcnww35xs6rxg3vyfex2ctyyfwsygx0pa9axg9gfqelvkthrkhxn6cpqwf6nyesvw07t6d4m7ayh0ahhvpsgqqqwh0szdtljw',
      );

      expect(result, isNotNull);
      expect(result.prefix, IonConnectProtocolIdentifierType.naddr);
      expect(result.special, '019899d0-739e-7f2a-8f6c-00cdc9f3d7cd');
      expect(result.author, 'cf0f4bd320a84833f659771dae69eb010393a99330639fe5e9b5dfba4bbfb7bb');
      expect(result.relays, [
        '["r","wss://94.100.16.233:4443","write"]',
        '["r","wss://141.95.59.70:4443","read"]',
        '["r","wss://181.41.142.217:4443","read"]',
      ]);
    });

    test('encode -> decode identifier', () {
      final encoded = service.encodeShareableIdentifiers(
        prefix: IonConnectProtocolIdentifierType.nprofile,
        special: '477318cfb5427b9cfc66a9fa376150c1ddbc62115ae27cef72417eb959691396',
        author: '0dbf0a9e694522618ba64e6d7a4cd0e38711fe75dd6bf1830682862df12229f0',
        kind: 0,
        relays: [
          '["r","wss://94.100.16.233:4443","write"]',
          '["r","wss://141.95.59.70:4443","read"]',
          '["r","wss://181.41.142.217:4443","read"]',
        ],
      );
      final result = service.decodeShareableIdentifiers(payload: encoded);
      expect(result.prefix, IonConnectProtocolIdentifierType.nprofile);
      expect(result.special, '477318cfb5427b9cfc66a9fa376150c1ddbc62115ae27cef72417eb959691396');
      expect(result.author, '0dbf0a9e694522618ba64e6d7a4cd0e38711fe75dd6bf1830682862df12229f0');
      expect(result.kind, 0);
      expect(result.relays, [
        '["r","wss://94.100.16.233:4443","write"]',
        '["r","wss://141.95.59.70:4443","read"]',
        '["r","wss://181.41.142.217:4443","read"]',
      ]);
    });

    test('throws on invalid input', () {
      expect(
        () => service.decodeShareableIdentifiers(payload: 'invalid'),
        throwsException,
      );
    });
  });
}
