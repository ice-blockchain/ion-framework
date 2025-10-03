// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.f.freezed.dart';
part 'transfer.f.g.dart';

sealed class Transfer {
  const Transfer();

  Map<String, dynamic> toJson();
}

/// All EVM compatible networks and Bitcoin support priority. Not supported for
/// other networks. The accepted values are Slow, Standard and Fast. When
/// specified, it uses the estimate fees API to calculate the transfer fees.
/// When not specified, the transfer will use the fees returned from the
/// blockchain node providers.
enum TransferPriority {
  slow,
  standard,
  fast;

  // Capitalize the first letter of the enum name
  String toJson() => '${name[0].toUpperCase()}${name.substring(1)}';
}

@freezed
class NativeTokenTransfer with _$NativeTokenTransfer implements Transfer {
  const factory NativeTokenTransfer({
    /// The destination address
    required String to,

    /// The amount of native tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Native'
    @Default('Native') String kind,

    /// The priority that determines the fees paid for the transfer
    @JsonKey(includeIfNull: false) TransferPriority? priority,

    /// The memo or destination tag
    @JsonKey(includeIfNull: false) String? memo,
  }) = _NativeTokenTransfer;

  factory NativeTokenTransfer.fromJson(Map<String, dynamic> json) =>
      _$NativeTokenTransferFromJson(json);
}

@freezed
class AsaTransfer with _$AsaTransfer implements Transfer {
  const factory AsaTransfer({
    /// The asset ID of the token
    required String assetId,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Asa'
    @Default('Asa') String kind,
  }) = _AsaTransfer;

  factory AsaTransfer.fromJson(Map<String, dynamic> json) => _$AsaTransferFromJson(json);
}

@freezed
class Erc20Transfer with _$Erc20Transfer implements Transfer {
  const factory Erc20Transfer({
    /// The ERC20 contract address
    required String contract,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Erc20'
    @Default('Erc20') String kind,

    /// The priority that determines the fees paid for the transfer
    @JsonKey(includeIfNull: false) TransferPriority? priority,
  }) = _Erc20Transfer;

  factory Erc20Transfer.fromJson(Map<String, dynamic> json) => _$Erc20TransferFromJson(json);
}

@freezed
class Erc721Transfer with _$Erc721Transfer implements Transfer {
  const factory Erc721Transfer({
    /// The ERC721 contract address
    required String contract,

    /// The destination address
    required String to,

    /// The token to transfer
    required String tokenId,

    /// The kind, should be 'Erc721'
    @Default('Erc721') String kind,

    /// The priority that determines the fees paid for the transfer
    @JsonKey(includeIfNull: false) TransferPriority? priority,
  }) = _Erc721Transfer;

  factory Erc721Transfer.fromJson(Map<String, dynamic> json) => _$Erc721TransferFromJson(json);
}

@freezed
class SplTransfer with _$SplTransfer implements Transfer {
  const factory SplTransfer({
    /// The mint account address
    required String mint,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Spl'
    @Default('Spl') String kind,

    /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
    @JsonKey(includeIfNull: false) bool? createDestinationAccount,
  }) = _SplTransfer;

  factory SplTransfer.fromJson(Map<String, dynamic> json) => _$SplTransferFromJson(json);
}

@freezed
class Spl2022Transfer with _$Spl2022Transfer implements Transfer {
  const factory Spl2022Transfer({
    /// The mint account address
    required String mint,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Spl2022'
    @Default('Spl2022') String kind,

    /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
    @JsonKey(includeIfNull: false) bool? createDestinationAccount,
  }) = _Spl2022Transfer;

  factory Spl2022Transfer.fromJson(Map<String, dynamic> json) => _$Spl2022TransferFromJson(json);
}

@freezed
class Sep41Transfer with _$Sep41Transfer implements Transfer {
  const factory Sep41Transfer({
    /// The asset issuer address
    required String issuer,

    /// The asset code
    required String assetCode,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Sep41'
    @Default('Sep41') String kind,

    /// The memo
    @JsonKey(includeIfNull: false) String? memo,
  }) = _Sep41Transfer;

  factory Sep41Transfer.fromJson(Map<String, dynamic> json) => _$Sep41TransferFromJson(json);
}

@freezed
class Tep74Transfer with _$Tep74Transfer implements Transfer {
  const factory Tep74Transfer({
    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Tep74'
    @Default('Tep74') String kind,

    /// The jetton master address
    String? master,
  }) = _Tep74Transfer;

  factory Tep74Transfer.fromJson(Map<String, dynamic> json) => _$Tep74TransferFromJson(json);
}

@freezed
class Trc10Transfer with _$Trc10Transfer implements Transfer {
  const factory Trc10Transfer({
    /// The token ID
    required String tokenId,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Trc10'
    @Default('Trc10') String kind,
  }) = _Trc10Transfer;

  factory Trc10Transfer.fromJson(Map<String, dynamic> json) => _$Trc10TransferFromJson(json);
}

@freezed
class Trc20Transfer with _$Trc20Transfer implements Transfer {
  const factory Trc20Transfer({
    /// The smart contract address
    required String contract,

    /// The destination address
    required String to,

    /// The amount of tokens to transfer in minimum denomination
    required String amount,

    /// The kind, should be 'Trc20'
    @Default('Trc20') String kind,
  }) = _Trc20Transfer;

  factory Trc20Transfer.fromJson(Map<String, dynamic> json) => _$Trc20TransferFromJson(json);
}

@freezed
class Trc721Transfer with _$Trc721Transfer implements Transfer {
  const factory Trc721Transfer({
    /// The smart contract address
    required String contract,

    /// The destination address
    required String to,

    /// The token to transfer
    required String tokenId,

    /// The kind, should be 'Trc721'
    @Default('Trc721') String kind,
  }) = _Trc721Transfer;

  factory Trc721Transfer.fromJson(Map<String, dynamic> json) => _$Trc721TransferFromJson(json);
}

@freezed
class Aip21Transfer with _$Aip21Transfer implements Transfer {
  const factory Aip21Transfer({
    required String metadata,
    required String to,
    required String amount,
    @Default('Aip21') String kind,
  }) = _Aip21Transfer;

  factory Aip21Transfer.fromJson(Map<String, dynamic> json) => _$Aip21TransferFromJson(json);
}
