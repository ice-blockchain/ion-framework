// SPDX-License-Identifier: ice License 1.0

import 'dart:math';
import 'dart:typed_data';

import 'package:ion_token_analytics/src/http2_client/web_socket/web_socket_constants.dart';

/// Builds masked WebSocket frames according to RFC 6455.
class WebSocketFrameBuilder {
  /// Builds a complete masked WebSocket frame with the given [payload] and [opcode].
  Uint8List build(Uint8List payload, {required int opcode}) {
    final maskKey = _generateMaskKey();
    final maskedPayload = _maskPayload(payload, maskKey);

    final header = BytesBuilder()..addByte(WebSocketConstants.finBit | opcode);

    final len = maskedPayload.length;
    if (len <= WebSocketConstants.maxSingleBytePayloadLength) {
      header.addByte(WebSocketConstants.maskBit | len);
    } else if (len <= WebSocketConstants.maxUint16) {
      header
        ..addByte(WebSocketConstants.maskBit | WebSocketConstants.payloadLength16Bit)
        ..addByte((len >> 8) & 0xFF)
        ..addByte(len & 0xFF);
    } else {
      header.addByte(WebSocketConstants.maskBit | WebSocketConstants.payloadLength64Bit);
      final byteData = ByteData(8)..setUint64(0, len);
      header.add(Uint8List.view(byteData.buffer));
    }

    return (header
          ..add(maskKey)
          ..add(maskedPayload))
        .toBytes();
  }

  Uint8List _generateMaskKey() {
    return Uint8List.fromList(
      List.generate(WebSocketConstants.maskKeyLength, (_) => Random().nextInt(256)),
    );
  }

  Uint8List _maskPayload(Uint8List payload, Uint8List maskKey) {
    final masked = Uint8List(payload.length);
    for (var i = 0; i < payload.length; i++) {
      masked[i] = payload[i] ^ maskKey[i % WebSocketConstants.maskKeyLength];
    }
    return masked;
  }
}
