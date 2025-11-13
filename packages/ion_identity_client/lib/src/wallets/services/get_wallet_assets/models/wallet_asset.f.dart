// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/src/core/helpers/converters/string_or_int_converter.dart';

part 'wallet_asset.f.freezed.dart';
part 'wallet_asset.f.g.dart';

/// Provided by 3d party service.
///
/// [balance] can be very small or big value, so should be converted to double or BigInt
@Freezed(
  unionKey: 'kind',
  unionValueCase: FreezedUnionCase.pascal,
  fallbackUnion: 'unknown',
  fromJson: true,
)
sealed class WalletAsset with _$WalletAsset {
  @FreezedUnionValue('Native')
  const factory WalletAsset.native({
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    bool? verified,
    String? name,
  }) = _WalletAssetNative;

  @FreezedUnionValue('Erc20')
  const factory WalletAsset.erc20({
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    bool? verified,
    String? contract,
    String? name,
  }) = _WalletAssetErc20;

  @FreezedUnionValue('Asa')
  const factory WalletAsset.asa({
    required String assetId,
    required String symbol,
    required int decimals,
    required bool verified,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
  }) = _WalletAssetAsa;

  @FreezedUnionValue('Spl')
  const factory WalletAsset.spl({
    required String mint,
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
  }) = _WalletAssetSpl;

  @FreezedUnionValue('Spl2022')
  const factory WalletAsset.spl2022({
    required String mint,
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
  }) = _WalletAssetSpl2022;

  @FreezedUnionValue('Sep41')
  const factory WalletAsset.sep41({
    required String issuer,
    required String assetCode,
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
  }) = _WalletAssetSep41;

  @FreezedUnionValue('Tep74')
  const factory WalletAsset.tep74({
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
    String? master,
  }) = _WalletAssetTep74;

  @FreezedUnionValue('Trc10')
  const factory WalletAsset.trc10({
    required String tokenId,
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
  }) = _WalletAssetTrc10;

  @FreezedUnionValue('Trc20')
  const factory WalletAsset.trc20({
    required String contract,
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? name,
  }) = _WalletAssetTrc20;

  @FreezedUnionValue('Aip21')
  const factory WalletAsset.aip21({
    required String metadata,
    required String symbol,
    required int decimals,
    required String kind,
    @StringOrIntConverter() required String balance,
    String? name,
  }) = _WalletAssetAip21;

  const factory WalletAsset.unknown({
    required String symbol,
    required int decimals,
    @StringOrIntConverter() required String balance,
    required String kind,
    String? contract,
    String? master,
    String? name,
    String? assetId,
    String? mint,
    String? tokenId,
    bool? verified,
  }) = _WalletAssetUnknown;

  const WalletAsset._();

  factory WalletAsset.fromJson(Map<String, dynamic> json) => _$WalletAssetFromJson(json);

  bool get isNative => maybeMap(
        native: (e) => true,
        orElse: () => false,
      );
}
