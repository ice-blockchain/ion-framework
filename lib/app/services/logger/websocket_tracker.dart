// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/ion_connect.dart';

// Tracks WebSocket instances with unique IDs + per-host WS identity
class WebSocketTracker {
  WebSocketTracker._();

  static int _nextSocketId = 1;
  static final Map<IonConnectRelay, int> _socketIds = {};

  // per-host auth identity (host -> entry with pubkey + socketId)
  static final Map<String, _WsIdentity> _hostIdentity = {};

  static int register(IonConnectRelay relay) {
    final socketId = _nextSocketId++;
    _socketIds[relay] = socketId;
    return socketId;
  }

  static int? getSocketId(IonConnectRelay relay) => _socketIds[relay];

  static void unregister(IonConnectRelay relay) {
    _socketIds.remove(relay);
    // identity cleared on WS close via clearOnClose
  }

  static String getHost(String url) {
    final uri = Uri.parse(url);
    return uri.authority.isNotEmpty ? uri.authority : uri.host;
  }

  // set WS auth identity for a host
  static void setAuthOk({required String host, required String pubkey, required int socketId}) {
    _hostIdentity[host] = _WsIdentity(pubkey: pubkey, socketId: socketId);
  }

  //  clear WS identity on close (only if owned by this socket)
  static void clearOnClose({required String host, required int socketId}) {
    final e = _hostIdentity[host];
    if (e != null && e.socketId == socketId) {
      _hostIdentity.remove(host);
    }
  }

  //  read WS-auth pubkey for a host
  static String? getAuthPubkey(String host) => _hostIdentity[host]?.pubkey;
}

class _WsIdentity {
  _WsIdentity({required this.pubkey, required this.socketId});
  final String pubkey;
  final int socketId;
}
