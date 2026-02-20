// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ion_token_analytics/src/http2_client/http2_exceptions.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_web_socket_message.dart';
import 'package:ion_token_analytics/src/http2_client/web_socket/web_socket_constants.dart';

/// Parses raw bytes into WebSocket frames according to RFC 6455.
///
/// Handles fragmented messages, compression (permessage-deflate), masking,
/// and extended payload lengths.
class WebSocketFrameParser {
  final BytesBuilder _fragmentBuffer = BytesBuilder();
  int? _fragmentOpcode;

  /// Parses a single WebSocket frame from raw [frame] bytes.
  ///
  /// Returns a [Http2WebSocketMessage] for complete data frames, or `null`
  /// for control frames (ping/pong/close) and intermediate fragments.
  ///
  /// When a ping is received, [onPing] is called with the payload so the
  /// caller can send a pong response.
  ///
  /// When a close frame is received, [onClose] is called so the caller
  /// can clean up the connection.
  Http2WebSocketMessage? parse(
    Uint8List frame, {
    required void Function(Uint8List payload) onPing,
    required void Function() onClose,
  }) {
    if (frame.length < 2) {
      throw const WebSocketFrameTooShortException();
    }

    final firstByte = frame[0];
    final fin = (firstByte & WebSocketConstants.finBit) != 0;
    final opcode = firstByte & WebSocketConstants.opcodeMask;
    final rsv1 = (firstByte & WebSocketConstants.rsv1Bit) != 0;
    final maskLen = frame[1];
    final masked = (maskLen & WebSocketConstants.maskBit) != 0;
    var payloadLen = maskLen & WebSocketConstants.payloadLengthMask;
    var offset = 2;

    if (payloadLen == WebSocketConstants.payloadLength16Bit) {
      if (frame.length < 4) {
        throw const WebSocketFrame16BitLengthException();
      }
      payloadLen = (frame[2] << 8) | frame[3];
      offset = 4;
    } else if (payloadLen == WebSocketConstants.payloadLength64Bit) {
      if (frame.length < 10) {
        throw const WebSocketFrame64BitLengthException();
      }
      final view = ByteData.sublistView(frame, 2, 10);
      payloadLen = view.getUint64(0);
      offset = 10;
    }

    Uint8List? maskKey;
    if (masked) {
      if (frame.length < offset + WebSocketConstants.maskKeyLength) {
        throw const WebSocketFrameMissingMaskException();
      }
      maskKey = frame.sublist(offset, offset + WebSocketConstants.maskKeyLength);
      offset += WebSocketConstants.maskKeyLength;
    }

    if (frame.length < offset + payloadLen) {
      throw WebSocketFramePayloadMismatchException(payloadLen, frame.length - offset);
    }

    final payload = frame.sublist(offset, offset + payloadLen);
    var unmasked = Uint8List(payloadLen);

    if (masked && maskKey != null) {
      for (var i = 0; i < payloadLen; i++) {
        unmasked[i] = payload[i] ^ maskKey[i % WebSocketConstants.maskKeyLength];
      }
    } else {
      unmasked.setRange(0, payloadLen, payload);
    }

    if (rsv1 &&
        (opcode == WebSocketConstants.opcodeText || opcode == WebSocketConstants.opcodeBinary)) {
      unmasked = _decompressPayload(unmasked);
    }

    // Continuation frame
    if (opcode == 0x0) {
      if (_fragmentOpcode == null) {
        throw WebSocketFrameUnsupportedOpcodeException(0x0);
      }
      _fragmentBuffer.add(unmasked);
      if (fin) {
        final completePayload = _fragmentBuffer.toBytes();
        final messageOpcode = _fragmentOpcode!;
        _fragmentBuffer.clear();
        _fragmentOpcode = null;
        return _toMessage(messageOpcode, Uint8List.fromList(completePayload));
      }
      return null;
    }

    // Data frames
    if (opcode == WebSocketConstants.opcodeText || opcode == WebSocketConstants.opcodeBinary) {
      if (!fin) {
        _fragmentOpcode = opcode;
        _fragmentBuffer.add(unmasked);
        return null;
      }
      return _toMessage(opcode, unmasked);
    }

    // Control frames
    return _handleControlFrame(opcode, unmasked, onPing: onPing, onClose: onClose);
  }

  /// Clears any in-progress fragmentation state.
  void reset() {
    _fragmentBuffer.clear();
    _fragmentOpcode = null;
  }

  Uint8List _decompressPayload(Uint8List compressed) {
    try {
      final withTrailer = BytesBuilder()
        ..add(compressed)
        ..add(WebSocketConstants.deflateTrailer);
      final decompressed = ZLibDecoder(raw: true).convert(withTrailer.toBytes());
      return Uint8List.fromList(decompressed);
    } catch (e, stackTrace) {
      throw WebSocketDecompressionException('$e\n$stackTrace');
    }
  }

  Http2WebSocketMessage? _toMessage(int opcode, Uint8List payload) {
    switch (opcode) {
      case WebSocketConstants.opcodeText:
        try {
          final text = utf8.decode(payload);
          return Http2WebSocketMessage(type: WebSocketMessageType.text, data: text);
        } catch (e, stackTrace) {
          throw WebSocketDecodingException('$e\n$stackTrace');
        }
      case WebSocketConstants.opcodeBinary:
        return Http2WebSocketMessage(type: WebSocketMessageType.binary, data: payload);
      default:
        throw WebSocketFrameUnsupportedOpcodeException(opcode);
    }
  }

  Http2WebSocketMessage? _handleControlFrame(
    int opcode,
    Uint8List payload, {
    required void Function(Uint8List payload) onPing,
    required void Function() onClose,
  }) {
    switch (opcode) {
      case WebSocketConstants.opcodeClose:
        onClose();
        return null;
      case WebSocketConstants.opcodePing:
        onPing(payload);
        return null;
      case WebSocketConstants.opcodePong:
        return null;
      default:
        throw WebSocketFrameUnsupportedOpcodeException(opcode);
    }
  }
}
