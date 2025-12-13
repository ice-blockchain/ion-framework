// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_asset.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletAssetNativeImpl _$$WalletAssetNativeImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetNativeImpl(
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      symbol: json['symbol'] as String?,
      contract: json['contract'] as String?,
      verified: json['verified'] as bool?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetNativeImplToJson(
        _$WalletAssetNativeImpl instance) =>
    <String, dynamic>{
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.symbol case final value?) 'symbol': value,
      if (instance.contract case final value?) 'contract': value,
      if (instance.verified case final value?) 'verified': value,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetErc20Impl _$$WalletAssetErc20ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetErc20Impl(
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      verified: json['verified'] as bool?,
      symbol: json['symbol'] as String?,
      contract: json['contract'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetErc20ImplToJson(
        _$WalletAssetErc20Impl instance) =>
    <String, dynamic>{
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.verified case final value?) 'verified': value,
      if (instance.symbol case final value?) 'symbol': value,
      if (instance.contract case final value?) 'contract': value,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetAsaImpl _$$WalletAssetAsaImplFromJson(Map<String, dynamic> json) =>
    _$WalletAssetAsaImpl(
      assetId: json['assetId'] as String,
      decimals: (json['decimals'] as num).toInt(),
      verified: json['verified'] as bool,
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      symbol: json['symbol'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetAsaImplToJson(
        _$WalletAssetAsaImpl instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'decimals': instance.decimals,
      'verified': instance.verified,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.symbol case final value?) 'symbol': value,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetSplImpl _$$WalletAssetSplImplFromJson(Map<String, dynamic> json) =>
    _$WalletAssetSplImpl(
      mint: json['mint'] as String,
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      symbol: json['symbol'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetSplImplToJson(
        _$WalletAssetSplImpl instance) =>
    <String, dynamic>{
      'mint': instance.mint,
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.symbol case final value?) 'symbol': value,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetSpl2022Impl _$$WalletAssetSpl2022ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetSpl2022Impl(
      mint: json['mint'] as String,
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetSpl2022ImplToJson(
        _$WalletAssetSpl2022Impl instance) =>
    <String, dynamic>{
      'mint': instance.mint,
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetSep41Impl _$$WalletAssetSep41ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetSep41Impl(
      issuer: json['issuer'] as String,
      assetCode: json['assetCode'] as String,
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetSep41ImplToJson(
        _$WalletAssetSep41Impl instance) =>
    <String, dynamic>{
      'issuer': instance.issuer,
      'assetCode': instance.assetCode,
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetTep74Impl _$$WalletAssetTep74ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetTep74Impl(
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      name: json['name'] as String?,
      master: json['master'] as String?,
    );

Map<String, dynamic> _$$WalletAssetTep74ImplToJson(
        _$WalletAssetTep74Impl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.name case final value?) 'name': value,
      if (instance.master case final value?) 'master': value,
    };

_$WalletAssetTrc10Impl _$$WalletAssetTrc10ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetTrc10Impl(
      tokenId: json['tokenId'] as String,
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetTrc10ImplToJson(
        _$WalletAssetTrc10Impl instance) =>
    <String, dynamic>{
      'tokenId': instance.tokenId,
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetTrc20Impl _$$WalletAssetTrc20ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetTrc20Impl(
      contract: json['contract'] as String,
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetTrc20ImplToJson(
        _$WalletAssetTrc20Impl instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetAip21Impl _$$WalletAssetAip21ImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetAip21Impl(
      metadata: json['metadata'] as String,
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as num).toInt(),
      kind: json['kind'] as String,
      balance: const StringOrIntConverter().fromJson(json['balance']),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$WalletAssetAip21ImplToJson(
        _$WalletAssetAip21Impl instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      'kind': instance.kind,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      if (instance.name case final value?) 'name': value,
    };

_$WalletAssetUnknownImpl _$$WalletAssetUnknownImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAssetUnknownImpl(
      decimals: (json['decimals'] as num).toInt(),
      balance: const StringOrIntConverter().fromJson(json['balance']),
      kind: json['kind'] as String,
      symbol: json['symbol'] as String?,
      contract: json['contract'] as String?,
      master: json['master'] as String?,
      name: json['name'] as String?,
      assetId: json['assetId'] as String?,
      mint: json['mint'] as String?,
      tokenId: json['tokenId'] as String?,
      verified: json['verified'] as bool?,
    );

Map<String, dynamic> _$$WalletAssetUnknownImplToJson(
        _$WalletAssetUnknownImpl instance) =>
    <String, dynamic>{
      'decimals': instance.decimals,
      if (const StringOrIntConverter().toJson(instance.balance)
          case final value?)
        'balance': value,
      'kind': instance.kind,
      if (instance.symbol case final value?) 'symbol': value,
      if (instance.contract case final value?) 'contract': value,
      if (instance.master case final value?) 'master': value,
      if (instance.name case final value?) 'name': value,
      if (instance.assetId case final value?) 'assetId': value,
      if (instance.mint case final value?) 'mint': value,
      if (instance.tokenId case final value?) 'tokenId': value,
      if (instance.verified case final value?) 'verified': value,
    };
