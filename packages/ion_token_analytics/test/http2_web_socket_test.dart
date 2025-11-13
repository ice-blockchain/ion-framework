import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:test/test.dart';

void main() {
  group('Http2WebSocket', () {
    const testHost = '51.75.87.132';
    const testPort = 4443;

    test('sends text message and receives NOTICE response', () async {
      final connection = Http2Connection(testHost, port: testPort);

      await connection.connect();

      final ws = await Http2WebSocket.fromHttp2Connection(connection);

      ws.add('Http2WebSocket test message');

      final message = await ws.stream.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Did not receive response within 5 seconds');
        },
      );

      expect(message.type, equals(WebSocketMessageType.text));
      expect(message.data, isA<String>());
      expect((message.data as String).toUpperCase(), contains('NOTICE'));

      ws.close();
    });
  });
}
