// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/bech32/bech32_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_protocol_identifier_type.dart';
import 'package:ion/app/services/ion_connect/shareable_identifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_uri_identifier_service.r.g.dart';

///
/// https://github.com/nostr-protocol/nips/blob/master/19.md
///
class IonConnectUriIdentifierService {
  const IonConnectUriIdentifierService({required this.bech32Service});

  final Bech32Service bech32Service;

  static const _shareableIdentifiersPrefixes = [
    IonConnectProtocolIdentifierType.nprofile,
    IonConnectProtocolIdentifierType.nevent,
    IonConnectProtocolIdentifierType.naddr,
  ];

  ({IonConnectProtocolIdentifierType prefix, String data}) decode({required String payload}) {
    final decoded = bech32Service.decode(payload);
    if (_shareableIdentifiersPrefixes.contains(decoded.prefix)) {
      throw Exception('use decodeShareableIdentifiers instead');
    }
    return decoded;
  }

  String encode({
    required IonConnectProtocolIdentifierType prefix,
    required String data,
  }) {
    if (_shareableIdentifiersPrefixes.contains(prefix)) {
      throw Exception('use encodeShareableIdentifiers instead');
    }
    return bech32Service.encode(prefix, data);
  }

  String encodeShareableIdentifiers({
    required IonConnectProtocolIdentifierType prefix,
    required String special,
    List<String>? relays,
    String? author,
    int? kind,
  }) {
    if (!_shareableIdentifiersPrefixes.contains(prefix)) {
      throw Exception('$prefix not in $_shareableIdentifiersPrefixes');
    }

    // 0: special
    if (prefix == IonConnectProtocolIdentifierType.naddr) {
      special = special.codeUnits.map((number) => number.toRadixString(16).padLeft(2, '0')).join();
    }
    var result = '00${hex.decode(special).length.toRadixString(16).padLeft(2, '0')}$special';

    // 1: relay
    if (relays != null) {
      for (final relay in relays) {
        final buffer = StringBuffer()
          ..write(result)
          ..write('01');

        final value =
            relay.codeUnits.map((number) => number.toRadixString(16).padLeft(2, '0')).join();

        buffer
          ..write(hex.decode(value).length.toRadixString(16).padLeft(2, '0'))
          ..write(value);

        result = buffer.toString();
      }
    }

    // 2: author
    if (author != null) {
      result = '${result}02';
      result = '$result${hex.decode(author).length.toRadixString(16).padLeft(2, '0')}$author';
    }

    // 3: kind
    if (kind != null) {
      result = '${result}03';
      final byteData = ByteData(4)..setUint32(0, kind);
      final value = List.generate(
        byteData.lengthInBytes,
        (index) => byteData.getUint8(index).toRadixString(16).padLeft(2, '0'),
      ).join();
      result = '$result${hex.decode(value).length.toRadixString(16).padLeft(2, '0')}$value';
    }
    return bech32Service.encode(prefix, result, length: result.length + 90);
  }

  /// For these events, the contents are a binary-encoded list of TLV (type-length-value),
  /// with T and L being 1 byte each (uint8, i.e. a number in the range of 0-255),
  ///  and V being a sequence of bytes of the size indicated by L.
  ///
  /// 0: special depends on the bech32 prefix:
  /// - for nprofile it will be the 32 bytes of the profile public key
  /// - for nevent it will be the 32 bytes of the event id
  /// - for naddr, it is the identifier (the "d" tag) of the event being referenced. For normal replaceable events use an empty string.
  ///
  /// 1: relay for nprofile, nevent and naddr, optionally, a relay in which the entity
  /// (profile or event) is more likely to be found, encoded as ascii this may be included multiple times
  ///
  /// 2: author
  /// - for naddr, the 32 bytes of the pubkey of the event
  /// - for nevent, optionally, the 32 bytes of the pubkey of the event
  ///
  /// 3: kind
  /// - for naddr, the 32-bit unsigned integer of the kind, big-endian
  /// - for nevent, optionally, the 32-bit unsigned integer of the kind, big-endian
  ShareableIdentifier decodeShareableIdentifiers({
    required String payload,
  }) {
    try {
      var special = '';
      final relays = <String>[];
      String? author;
      int? kind;
      final decoded = bech32Service.decode(payload, length: payload.length);
      final data = hex.decode(decoded.data);

      var index = 0;
      while (index < data.length) {
        final type = data[index++];
        final length = data[index++];

        final value = Uint8List.fromList(data.sublist(index, index + length));
        index += length;

        if (type == 0) {
          special = (decoded.prefix == IonConnectProtocolIdentifierType.naddr)
              ? String.fromCharCodes(value)
              : hex.encode(value);
        } else if (type == 1) {
          relays.add(String.fromCharCodes(value));
        } else if (type == 2) {
          author = hex.encode(value);
        } else if (type == 3) {
          final byteData = ByteData.sublistView(value);
          kind = byteData.getUint32(0);
        }
      }

      return ShareableIdentifier(
        prefix: decoded.prefix,
        special: special,
        relays: relays,
        author: author,
        kind: kind,
      );
    } catch (e) {
      throw Exception('Failed to decode shareable entity: $e');
    }
  }
}

@riverpod
IonConnectUriIdentifierService ionConnectUriIdentifierService(Ref ref) {
  return IonConnectUriIdentifierService(bech32Service: ref.read(bech32ServiceProvider));
}
