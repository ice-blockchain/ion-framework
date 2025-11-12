import 'package:ion_token_analytics/ion_token_analytics.dart';

Future<void> main() async {
  final connection = await Http2Connection.connect('51.75.87.132', port: 4443);
  final websocket = await Http2WebSocket.fromHttp2Connection(connection);
  if (websocket != null) {
    websocket.stream.listen((m) => print('ws2: ${m.data}'));
    websocket.add('ws2: Hello HTTP/2 WebSocket!');
  }

  await Future<void>.delayed(const Duration(seconds: 60));
  websocket?.close();
}
