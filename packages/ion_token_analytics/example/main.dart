import 'package:ion_token_analytics/ion_token_analytics.dart';

Future<void> main() async {
  final client = await IonTokenAnalyticsClient.create(
    options: IonTokenAnalyticsClientOptions(baseUrl: 'https://api.example.com'),
  );

  final tokens = await client.communityTokensService.getTokenInfo(['a', 'b']);
  print(tokens.firstOrNull?.creator);

  final subscription = await client.communityTokensService.subscribeToTokenInfo(['a', 'b']);
  final streamSubscription = subscription.stream.listen(print);

  await Future<void>.delayed(const Duration(seconds: 5));

  await streamSubscription.cancel();
  await subscription.close();
}
