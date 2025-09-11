// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_request_body.f.freezed.dart';
part 'transfer_request_body.f.g.dart';

abstract class CoinTransferRequestBody {
  String get amount;
}

@Freezed(unionKey: 'kind')
class TransferRequestBody with _$TransferRequestBody {
  @FreezedUnionValue('Native')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.native({
    required String kind,
    required String to,
    required String amount,
    String? memo,
  }) = NativeTransferRequestBody;

  @FreezedUnionValue('Erc721')
  const factory TransferRequestBody.erc721({
    required String kind,
    required String contract,
    required String to,
    required String tokenId,
  }) = Erc721TransferRequestBody;

  @FreezedUnionValue('Asa')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.asa({
    required String kind,
    required String assetId,
    required String to,
    required String amount,
  }) = AsaTransferRequestBody;

  @FreezedUnionValue('Erc20')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.erc20({
    required String kind,
    required String contract,
    required String amount,
    required String to,
  }) = Erc20TransferRequestBody;

  @FreezedUnionValue('Spl')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.spl({
    required String kind,
    required String mint,
    required String to,
    required String amount,
  }) = SplTransferRequestBody;

  @FreezedUnionValue('Spl2022')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.spl2022({
    required String kind,
    required String mint,
    required String to,
    required String amount,
  }) = Spl2022TransferRequestBody;

  @FreezedUnionValue('Sep41')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.sep41({
    required String kind,
    required String issuer,
    required String assetCode,
    required String to,
    required String amount,
    String? memo,
  }) = Sep41TransferRequestBody;

  @FreezedUnionValue('Tep74')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.tep74({
    required String kind,
    required String master,
    required String to,
    required String amount,
  }) = Tep74TransferRequestBody;

  @FreezedUnionValue('Trc10')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.trc10({
    required String kind,
    required String tokenId,
    required String to,
    required String amount,
  }) = Trc10TransferRequestBody;

  @FreezedUnionValue('Trc20')
  @Implements<CoinTransferRequestBody>()
  const factory TransferRequestBody.trc20({
    required String kind,
    required String contract,
    required String to,
    required String amount,
  }) = Trc20TransferRequestBody;

  @FreezedUnionValue('Trc721')
  const factory TransferRequestBody.trc721({
    required String kind,
    required String contract,
    required String to,
    required String tokenId,
  }) = Trc721TransferRequestBody;

  @FreezedUnionValue('Aip21')
  const factory TransferRequestBody.aip21({
    required String kind,
    required String to,
    required String amount,
    required String metadata,
  }) = Aip21TransferRequestBody;

  factory TransferRequestBody.fromJson(Map<String, dynamic> json) =>
      _$TransferRequestBodyFromJson(json);
}
