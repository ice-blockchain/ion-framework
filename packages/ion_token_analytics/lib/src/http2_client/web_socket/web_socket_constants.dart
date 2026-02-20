// SPDX-License-Identifier: ice License 1.0

/// WebSocket protocol constants (RFC 6455).
abstract final class WebSocketConstants {
  static const int opcodeText = 0x1;
  static const int opcodeBinary = 0x2;
  static const int opcodeClose = 0x8;
  static const int opcodePing = 0x9;
  static const int opcodePong = 0xA;

  static const int finBit = 0x80;
  static const int rsv1Bit = 0x40;
  static const int maskBit = 0x80;
  static const int opcodeMask = 0x0F;
  static const int payloadLengthMask = 0x7F;

  static const int payloadLength16Bit = 126;
  static const int payloadLength64Bit = 127;
  static const int maxSingleBytePayloadLength = 125;
  static const int maxUint16 = 65535;

  static const int closeCodeNormal = 1000;
  static const int closeCodeMin = 1000;
  static const int closeCodeMax = 4999;

  static const int maskKeyLength = 4;
  static const int randomBytesLength = 16;

  static const String webSocketVersion = '13';
  static const String webSocketGuid = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
  static const String webSocketExtension = 'permessage-deflate; client_max_window_bits';

  static const List<int> deflateTrailer = [0x00, 0x00, 0xFF, 0xFF];
}
