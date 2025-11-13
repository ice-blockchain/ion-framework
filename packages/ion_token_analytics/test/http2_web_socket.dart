import 'dart:convert';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:test/test.dart';

void main() {
  group('Http2WebSocket', () {
    test('connects to a relay and receives response', () async {
      Http2Connection? connection;
      Http2WebSocket? websocket;

      try {
        connection = await Http2Connection.connect('51.75.87.132', port: 4443);
        websocket = await Http2WebSocket.fromHttp2Connection(connection)
          ..add('dummy message');
        final response = await websocket.stream.first;

        final lastMessage = jsonDecode(response.asText) as List<dynamic>;

        expect(lastMessage[0], equals('NOTICE'));
        expect(lastMessage[1], equals('unknown message'));
      } finally {
        websocket?.close();
        await connection?.close();
      }
    });
  });
}
