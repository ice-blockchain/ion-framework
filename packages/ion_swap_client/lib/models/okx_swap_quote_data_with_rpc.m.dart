// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';

part 'okx_swap_quote_data_with_rpc.m.freezed.dart';
part 'okx_swap_quote_data_with_rpc.m.g.dart';

@freezed
class OkxSwapQuoteDataWithRpc with _$OkxSwapQuoteDataWithRpc {
  factory OkxSwapQuoteDataWithRpc({
    required SwapQuoteData swapQuoteData,
    required String? rpcUrl,
  }) = _OkxSwapQuoteDataWithRpc;

  factory OkxSwapQuoteDataWithRpc.fromJson(Map<String, dynamic> json) =>
      _$OkxSwapQuoteDataWithRpcFromJson(json);
}
