// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/relay_quote.m.dart';

part 'relay_quote_with_rpc.m.freezed.dart';
part 'relay_quote_with_rpc.m.g.dart';

@freezed
class RelayQuoteWithRpc with _$RelayQuoteWithRpc {
  factory RelayQuoteWithRpc({
    required RelayQuote details,
    required String rpcUrl,
  }) = _RelayQuoteWithRpc;

  factory RelayQuoteWithRpc.fromJson(Map<String, dynamic> json) =>
      _$RelayQuoteWithRpcFromJson(json);
}
