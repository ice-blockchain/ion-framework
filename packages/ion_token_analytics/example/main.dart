import 'package:ion_token_analytics/ion_token_analytics.dart';

Future<void> main() async {
  final uri = Uri.parse('https://51.75.87.132:4443');
  final ws = await connectWebSocketOverHttp2(uri);

  final ws2 = await connectWebSocketOverHttp2(uri);
  if (ws2 != null) {
    ws2.stream.listen((m) => print('ws2: $m'));
    ws2.add('ws2: Hello HTTP/2 WebSocket!');
  }

  await Future<void>.delayed(const Duration(seconds: 60));
  ws?.close();
  ws2?.close();
}
