import 'package:tonutils/tonutils.dart';

class TonClient {
  TonClient({
    required String url,
  }) : _tonClient = TonJsonRpc(url);

  final TonJsonRpc _tonClient;

  Future<void> sendTransaction(Transaction transaction) async {}
}
