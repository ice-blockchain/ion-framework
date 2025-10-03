// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_asset.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletAsset _$WalletAssetFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'Native':
      return _WalletAssetNative.fromJson(json);
    case 'Erc20':
      return _WalletAssetErc20.fromJson(json);
    case 'Asa':
      return _WalletAssetAsa.fromJson(json);
    case 'Spl':
      return _WalletAssetSpl.fromJson(json);
    case 'Spl2022':
      return _WalletAssetSpl2022.fromJson(json);
    case 'Sep41':
      return _WalletAssetSep41.fromJson(json);
    case 'Tep74':
      return _WalletAssetTep74.fromJson(json);
    case 'Trc10':
      return _WalletAssetTrc10.fromJson(json);
    case 'Trc20':
      return _WalletAssetTrc20.fromJson(json);
    case 'Aip21':
      return _WalletAssetAip21.fromJson(json);

    default:
      return _WalletAssetUnknown.fromJson(json);
  }
}

/// @nodoc
mixin _$WalletAsset {
  String get symbol => throw _privateConstructorUsedError;
  int get decimals => throw _privateConstructorUsedError;
  @StringOrIntConverter()
  String get balance => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this WalletAsset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletAssetCopyWith<WalletAsset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletAssetCopyWith<$Res> {
  factory $WalletAssetCopyWith(
          WalletAsset value, $Res Function(WalletAsset) then) =
      _$WalletAssetCopyWithImpl<$Res, WalletAsset>;
  @useResult
  $Res call(
      {String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class _$WalletAssetCopyWithImpl<$Res, $Val extends WalletAsset>
    implements $WalletAssetCopyWith<$Res> {
  _$WalletAssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_value.copyWith(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletAssetNativeImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetNativeImplCopyWith(_$WalletAssetNativeImpl value,
          $Res Function(_$WalletAssetNativeImpl) then) =
      __$$WalletAssetNativeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      bool? verified,
      String? name});
}

/// @nodoc
class __$$WalletAssetNativeImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetNativeImpl>
    implements _$$WalletAssetNativeImplCopyWith<$Res> {
  __$$WalletAssetNativeImplCopyWithImpl(_$WalletAssetNativeImpl _value,
      $Res Function(_$WalletAssetNativeImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? verified = freezed,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetNativeImpl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      verified: freezed == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetNativeImpl extends _WalletAssetNative {
  const _$WalletAssetNativeImpl(
      {required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.verified,
      this.name})
      : super._();

  factory _$WalletAssetNativeImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetNativeImplFromJson(json);

  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final bool? verified;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.native(symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, verified: $verified, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetNativeImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, symbol, decimals, balance, kind, verified, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetNativeImplCopyWith<_$WalletAssetNativeImpl> get copyWith =>
      __$$WalletAssetNativeImplCopyWithImpl<_$WalletAssetNativeImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return native(symbol, decimals, balance, kind, verified, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return native?.call(symbol, decimals, balance, kind, verified, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (native != null) {
      return native(symbol, decimals, balance, kind, verified, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return native(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return native?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (native != null) {
      return native(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetNativeImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetNative extends WalletAsset {
  const factory _WalletAssetNative(
      {required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final bool? verified,
      final String? name}) = _$WalletAssetNativeImpl;
  const _WalletAssetNative._() : super._();

  factory _WalletAssetNative.fromJson(Map<String, dynamic> json) =
      _$WalletAssetNativeImpl.fromJson;

  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  bool? get verified;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetNativeImplCopyWith<_$WalletAssetNativeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetErc20ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetErc20ImplCopyWith(_$WalletAssetErc20Impl value,
          $Res Function(_$WalletAssetErc20Impl) then) =
      __$$WalletAssetErc20ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      bool? verified,
      String? contract,
      String? name});
}

/// @nodoc
class __$$WalletAssetErc20ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetErc20Impl>
    implements _$$WalletAssetErc20ImplCopyWith<$Res> {
  __$$WalletAssetErc20ImplCopyWithImpl(_$WalletAssetErc20Impl _value,
      $Res Function(_$WalletAssetErc20Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? verified = freezed,
    Object? contract = freezed,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetErc20Impl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      verified: freezed == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool?,
      contract: freezed == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetErc20Impl extends _WalletAssetErc20 {
  const _$WalletAssetErc20Impl(
      {required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.verified,
      this.contract,
      this.name})
      : super._();

  factory _$WalletAssetErc20Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetErc20ImplFromJson(json);

  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final bool? verified;
  @override
  final String? contract;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.erc20(symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, verified: $verified, contract: $contract, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetErc20Impl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, symbol, decimals, balance, kind, verified, contract, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetErc20ImplCopyWith<_$WalletAssetErc20Impl> get copyWith =>
      __$$WalletAssetErc20ImplCopyWithImpl<_$WalletAssetErc20Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return erc20(symbol, decimals, balance, kind, verified, contract, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return erc20?.call(
        symbol, decimals, balance, kind, verified, contract, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (erc20 != null) {
      return erc20(symbol, decimals, balance, kind, verified, contract, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return erc20(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return erc20?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (erc20 != null) {
      return erc20(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetErc20ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetErc20 extends WalletAsset {
  const factory _WalletAssetErc20(
      {required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final bool? verified,
      final String? contract,
      final String? name}) = _$WalletAssetErc20Impl;
  const _WalletAssetErc20._() : super._();

  factory _WalletAssetErc20.fromJson(Map<String, dynamic> json) =
      _$WalletAssetErc20Impl.fromJson;

  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  bool? get verified;
  String? get contract;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetErc20ImplCopyWith<_$WalletAssetErc20Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetAsaImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetAsaImplCopyWith(_$WalletAssetAsaImpl value,
          $Res Function(_$WalletAssetAsaImpl) then) =
      __$$WalletAssetAsaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String assetId,
      String symbol,
      int decimals,
      bool verified,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class __$$WalletAssetAsaImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetAsaImpl>
    implements _$$WalletAssetAsaImplCopyWith<$Res> {
  __$$WalletAssetAsaImplCopyWithImpl(
      _$WalletAssetAsaImpl _value, $Res Function(_$WalletAssetAsaImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assetId = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? verified = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetAsaImpl(
      assetId: null == assetId
          ? _value.assetId
          : assetId // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      verified: null == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetAsaImpl extends _WalletAssetAsa {
  const _$WalletAssetAsaImpl(
      {required this.assetId,
      required this.symbol,
      required this.decimals,
      required this.verified,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.name})
      : super._();

  factory _$WalletAssetAsaImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetAsaImplFromJson(json);

  @override
  final String assetId;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  final bool verified;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.asa(assetId: $assetId, symbol: $symbol, decimals: $decimals, verified: $verified, balance: $balance, kind: $kind, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetAsaImpl &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, assetId, symbol, decimals, verified, balance, kind, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetAsaImplCopyWith<_$WalletAssetAsaImpl> get copyWith =>
      __$$WalletAssetAsaImplCopyWithImpl<_$WalletAssetAsaImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return asa(assetId, symbol, decimals, verified, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return asa?.call(assetId, symbol, decimals, verified, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (asa != null) {
      return asa(assetId, symbol, decimals, verified, balance, kind, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return asa(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return asa?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (asa != null) {
      return asa(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetAsaImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetAsa extends WalletAsset {
  const factory _WalletAssetAsa(
      {required final String assetId,
      required final String symbol,
      required final int decimals,
      required final bool verified,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? name}) = _$WalletAssetAsaImpl;
  const _WalletAssetAsa._() : super._();

  factory _WalletAssetAsa.fromJson(Map<String, dynamic> json) =
      _$WalletAssetAsaImpl.fromJson;

  String get assetId;
  @override
  String get symbol;
  @override
  int get decimals;
  bool get verified;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetAsaImplCopyWith<_$WalletAssetAsaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetSplImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetSplImplCopyWith(_$WalletAssetSplImpl value,
          $Res Function(_$WalletAssetSplImpl) then) =
      __$$WalletAssetSplImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String mint,
      String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class __$$WalletAssetSplImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetSplImpl>
    implements _$$WalletAssetSplImplCopyWith<$Res> {
  __$$WalletAssetSplImplCopyWithImpl(
      _$WalletAssetSplImpl _value, $Res Function(_$WalletAssetSplImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetSplImpl(
      mint: null == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetSplImpl extends _WalletAssetSpl {
  const _$WalletAssetSplImpl(
      {required this.mint,
      required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.name})
      : super._();

  factory _$WalletAssetSplImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetSplImplFromJson(json);

  @override
  final String mint;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.spl(mint: $mint, symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetSplImpl &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, mint, symbol, decimals, balance, kind, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetSplImplCopyWith<_$WalletAssetSplImpl> get copyWith =>
      __$$WalletAssetSplImplCopyWithImpl<_$WalletAssetSplImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return spl(mint, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return spl?.call(mint, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (spl != null) {
      return spl(mint, symbol, decimals, balance, kind, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return spl(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return spl?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (spl != null) {
      return spl(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetSplImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetSpl extends WalletAsset {
  const factory _WalletAssetSpl(
      {required final String mint,
      required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? name}) = _$WalletAssetSplImpl;
  const _WalletAssetSpl._() : super._();

  factory _WalletAssetSpl.fromJson(Map<String, dynamic> json) =
      _$WalletAssetSplImpl.fromJson;

  String get mint;
  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetSplImplCopyWith<_$WalletAssetSplImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetSpl2022ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetSpl2022ImplCopyWith(_$WalletAssetSpl2022Impl value,
          $Res Function(_$WalletAssetSpl2022Impl) then) =
      __$$WalletAssetSpl2022ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String mint,
      String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class __$$WalletAssetSpl2022ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetSpl2022Impl>
    implements _$$WalletAssetSpl2022ImplCopyWith<$Res> {
  __$$WalletAssetSpl2022ImplCopyWithImpl(_$WalletAssetSpl2022Impl _value,
      $Res Function(_$WalletAssetSpl2022Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetSpl2022Impl(
      mint: null == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetSpl2022Impl extends _WalletAssetSpl2022 {
  const _$WalletAssetSpl2022Impl(
      {required this.mint,
      required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.name})
      : super._();

  factory _$WalletAssetSpl2022Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetSpl2022ImplFromJson(json);

  @override
  final String mint;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.spl2022(mint: $mint, symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetSpl2022Impl &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, mint, symbol, decimals, balance, kind, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetSpl2022ImplCopyWith<_$WalletAssetSpl2022Impl> get copyWith =>
      __$$WalletAssetSpl2022ImplCopyWithImpl<_$WalletAssetSpl2022Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return spl2022(mint, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return spl2022?.call(mint, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (spl2022 != null) {
      return spl2022(mint, symbol, decimals, balance, kind, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return spl2022(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return spl2022?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (spl2022 != null) {
      return spl2022(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetSpl2022ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetSpl2022 extends WalletAsset {
  const factory _WalletAssetSpl2022(
      {required final String mint,
      required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? name}) = _$WalletAssetSpl2022Impl;
  const _WalletAssetSpl2022._() : super._();

  factory _WalletAssetSpl2022.fromJson(Map<String, dynamic> json) =
      _$WalletAssetSpl2022Impl.fromJson;

  String get mint;
  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetSpl2022ImplCopyWith<_$WalletAssetSpl2022Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetSep41ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetSep41ImplCopyWith(_$WalletAssetSep41Impl value,
          $Res Function(_$WalletAssetSep41Impl) then) =
      __$$WalletAssetSep41ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String mint,
      String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class __$$WalletAssetSep41ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetSep41Impl>
    implements _$$WalletAssetSep41ImplCopyWith<$Res> {
  __$$WalletAssetSep41ImplCopyWithImpl(_$WalletAssetSep41Impl _value,
      $Res Function(_$WalletAssetSep41Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetSep41Impl(
      mint: null == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetSep41Impl extends _WalletAssetSep41 {
  const _$WalletAssetSep41Impl(
      {required this.mint,
      required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.name})
      : super._();

  factory _$WalletAssetSep41Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetSep41ImplFromJson(json);

  @override
  final String mint;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.sep41(mint: $mint, symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetSep41Impl &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, mint, symbol, decimals, balance, kind, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetSep41ImplCopyWith<_$WalletAssetSep41Impl> get copyWith =>
      __$$WalletAssetSep41ImplCopyWithImpl<_$WalletAssetSep41Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return sep41(mint, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return sep41?.call(mint, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (sep41 != null) {
      return sep41(mint, symbol, decimals, balance, kind, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return sep41(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return sep41?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (sep41 != null) {
      return sep41(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetSep41ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetSep41 extends WalletAsset {
  const factory _WalletAssetSep41(
      {required final String mint,
      required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? name}) = _$WalletAssetSep41Impl;
  const _WalletAssetSep41._() : super._();

  factory _WalletAssetSep41.fromJson(Map<String, dynamic> json) =
      _$WalletAssetSep41Impl.fromJson;

  String get mint;
  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetSep41ImplCopyWith<_$WalletAssetSep41Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetTep74ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetTep74ImplCopyWith(_$WalletAssetTep74Impl value,
          $Res Function(_$WalletAssetTep74Impl) then) =
      __$$WalletAssetTep74ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? mint,
      String? name});
}

/// @nodoc
class __$$WalletAssetTep74ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetTep74Impl>
    implements _$$WalletAssetTep74ImplCopyWith<$Res> {
  __$$WalletAssetTep74ImplCopyWithImpl(_$WalletAssetTep74Impl _value,
      $Res Function(_$WalletAssetTep74Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? mint = freezed,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetTep74Impl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      mint: freezed == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetTep74Impl extends _WalletAssetTep74 {
  const _$WalletAssetTep74Impl(
      {required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.mint,
      this.name})
      : super._();

  factory _$WalletAssetTep74Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetTep74ImplFromJson(json);

  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? mint;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.tep74(symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, mint: $mint, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetTep74Impl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, symbol, decimals, balance, kind, mint, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetTep74ImplCopyWith<_$WalletAssetTep74Impl> get copyWith =>
      __$$WalletAssetTep74ImplCopyWithImpl<_$WalletAssetTep74Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return tep74(symbol, decimals, balance, kind, mint, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return tep74?.call(symbol, decimals, balance, kind, mint, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (tep74 != null) {
      return tep74(symbol, decimals, balance, kind, mint, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return tep74(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return tep74?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (tep74 != null) {
      return tep74(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetTep74ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetTep74 extends WalletAsset {
  const factory _WalletAssetTep74(
      {required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? mint,
      final String? name}) = _$WalletAssetTep74Impl;
  const _WalletAssetTep74._() : super._();

  factory _WalletAssetTep74.fromJson(Map<String, dynamic> json) =
      _$WalletAssetTep74Impl.fromJson;

  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  String? get mint;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetTep74ImplCopyWith<_$WalletAssetTep74Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetTrc10ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetTrc10ImplCopyWith(_$WalletAssetTrc10Impl value,
          $Res Function(_$WalletAssetTrc10Impl) then) =
      __$$WalletAssetTrc10ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tokenId,
      String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class __$$WalletAssetTrc10ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetTrc10Impl>
    implements _$$WalletAssetTrc10ImplCopyWith<$Res> {
  __$$WalletAssetTrc10ImplCopyWithImpl(_$WalletAssetTrc10Impl _value,
      $Res Function(_$WalletAssetTrc10Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tokenId = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetTrc10Impl(
      tokenId: null == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetTrc10Impl extends _WalletAssetTrc10 {
  const _$WalletAssetTrc10Impl(
      {required this.tokenId,
      required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.name})
      : super._();

  factory _$WalletAssetTrc10Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetTrc10ImplFromJson(json);

  @override
  final String tokenId;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.trc10(tokenId: $tokenId, symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetTrc10Impl &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, tokenId, symbol, decimals, balance, kind, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetTrc10ImplCopyWith<_$WalletAssetTrc10Impl> get copyWith =>
      __$$WalletAssetTrc10ImplCopyWithImpl<_$WalletAssetTrc10Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return trc10(tokenId, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return trc10?.call(tokenId, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (trc10 != null) {
      return trc10(tokenId, symbol, decimals, balance, kind, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return trc10(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return trc10?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (trc10 != null) {
      return trc10(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetTrc10ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetTrc10 extends WalletAsset {
  const factory _WalletAssetTrc10(
      {required final String tokenId,
      required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? name}) = _$WalletAssetTrc10Impl;
  const _WalletAssetTrc10._() : super._();

  factory _WalletAssetTrc10.fromJson(Map<String, dynamic> json) =
      _$WalletAssetTrc10Impl.fromJson;

  String get tokenId;
  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetTrc10ImplCopyWith<_$WalletAssetTrc10Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetTrc20ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetTrc20ImplCopyWith(_$WalletAssetTrc20Impl value,
          $Res Function(_$WalletAssetTrc20Impl) then) =
      __$$WalletAssetTrc20ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String contract,
      String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? name});
}

/// @nodoc
class __$$WalletAssetTrc20ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetTrc20Impl>
    implements _$$WalletAssetTrc20ImplCopyWith<$Res> {
  __$$WalletAssetTrc20ImplCopyWithImpl(_$WalletAssetTrc20Impl _value,
      $Res Function(_$WalletAssetTrc20Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetTrc20Impl(
      contract: null == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetTrc20Impl extends _WalletAssetTrc20 {
  const _$WalletAssetTrc20Impl(
      {required this.contract,
      required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.name})
      : super._();

  factory _$WalletAssetTrc20Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetTrc20ImplFromJson(json);

  @override
  final String contract;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.trc20(contract: $contract, symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetTrc20Impl &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, contract, symbol, decimals, balance, kind, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetTrc20ImplCopyWith<_$WalletAssetTrc20Impl> get copyWith =>
      __$$WalletAssetTrc20ImplCopyWithImpl<_$WalletAssetTrc20Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return trc20(contract, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return trc20?.call(contract, symbol, decimals, balance, kind, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (trc20 != null) {
      return trc20(contract, symbol, decimals, balance, kind, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return trc20(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return trc20?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (trc20 != null) {
      return trc20(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetTrc20ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetTrc20 extends WalletAsset {
  const factory _WalletAssetTrc20(
      {required final String contract,
      required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? name}) = _$WalletAssetTrc20Impl;
  const _WalletAssetTrc20._() : super._();

  factory _WalletAssetTrc20.fromJson(Map<String, dynamic> json) =
      _$WalletAssetTrc20Impl.fromJson;

  String get contract;
  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetTrc20ImplCopyWith<_$WalletAssetTrc20Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetAip21ImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetAip21ImplCopyWith(_$WalletAssetAip21Impl value,
          $Res Function(_$WalletAssetAip21Impl) then) =
      __$$WalletAssetAip21ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String metadata,
      String symbol,
      int decimals,
      String kind,
      @StringOrIntConverter() String balance,
      String? name});
}

/// @nodoc
class __$$WalletAssetAip21ImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetAip21Impl>
    implements _$$WalletAssetAip21ImplCopyWith<$Res> {
  __$$WalletAssetAip21ImplCopyWithImpl(_$WalletAssetAip21Impl _value,
      $Res Function(_$WalletAssetAip21Impl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? symbol = null,
    Object? decimals = null,
    Object? kind = null,
    Object? balance = null,
    Object? name = freezed,
  }) {
    return _then(_$WalletAssetAip21Impl(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetAip21Impl extends _WalletAssetAip21 {
  const _$WalletAssetAip21Impl(
      {required this.metadata,
      required this.symbol,
      required this.decimals,
      required this.kind,
      @StringOrIntConverter() required this.balance,
      this.name})
      : super._();

  factory _$WalletAssetAip21Impl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetAip21ImplFromJson(json);

  @override
  final String metadata;
  @override
  final String symbol;
  @override
  final int decimals;
  @override
  final String kind;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String? name;

  @override
  String toString() {
    return 'WalletAsset.aip21(metadata: $metadata, symbol: $symbol, decimals: $decimals, kind: $kind, balance: $balance, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetAip21Impl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, metadata, symbol, decimals, kind, balance, name);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetAip21ImplCopyWith<_$WalletAssetAip21Impl> get copyWith =>
      __$$WalletAssetAip21ImplCopyWithImpl<_$WalletAssetAip21Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return aip21(metadata, symbol, decimals, kind, balance, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return aip21?.call(metadata, symbol, decimals, kind, balance, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (aip21 != null) {
      return aip21(metadata, symbol, decimals, kind, balance, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return aip21(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return aip21?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (aip21 != null) {
      return aip21(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetAip21ImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetAip21 extends WalletAsset {
  const factory _WalletAssetAip21(
      {required final String metadata,
      required final String symbol,
      required final int decimals,
      required final String kind,
      @StringOrIntConverter() required final String balance,
      final String? name}) = _$WalletAssetAip21Impl;
  const _WalletAssetAip21._() : super._();

  factory _WalletAssetAip21.fromJson(Map<String, dynamic> json) =
      _$WalletAssetAip21Impl.fromJson;

  String get metadata;
  @override
  String get symbol;
  @override
  int get decimals;
  @override
  String get kind;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String? get name;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetAip21ImplCopyWith<_$WalletAssetAip21Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WalletAssetUnknownImplCopyWith<$Res>
    implements $WalletAssetCopyWith<$Res> {
  factory _$$WalletAssetUnknownImplCopyWith(_$WalletAssetUnknownImpl value,
          $Res Function(_$WalletAssetUnknownImpl) then) =
      __$$WalletAssetUnknownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      int decimals,
      @StringOrIntConverter() String balance,
      String kind,
      String? contract,
      String? name,
      String? assetId,
      String? mint,
      String? tokenId,
      bool? verified});
}

/// @nodoc
class __$$WalletAssetUnknownImplCopyWithImpl<$Res>
    extends _$WalletAssetCopyWithImpl<$Res, _$WalletAssetUnknownImpl>
    implements _$$WalletAssetUnknownImplCopyWith<$Res> {
  __$$WalletAssetUnknownImplCopyWithImpl(_$WalletAssetUnknownImpl _value,
      $Res Function(_$WalletAssetUnknownImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? decimals = null,
    Object? balance = null,
    Object? kind = null,
    Object? contract = freezed,
    Object? name = freezed,
    Object? assetId = freezed,
    Object? mint = freezed,
    Object? tokenId = freezed,
    Object? verified = freezed,
  }) {
    return _then(_$WalletAssetUnknownImpl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      contract: freezed == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      assetId: freezed == assetId
          ? _value.assetId
          : assetId // ignore: cast_nullable_to_non_nullable
              as String?,
      mint: freezed == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenId: freezed == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String?,
      verified: freezed == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAssetUnknownImpl extends _WalletAssetUnknown {
  const _$WalletAssetUnknownImpl(
      {required this.symbol,
      required this.decimals,
      @StringOrIntConverter() required this.balance,
      required this.kind,
      this.contract,
      this.name,
      this.assetId,
      this.mint,
      this.tokenId,
      this.verified})
      : super._();

  factory _$WalletAssetUnknownImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAssetUnknownImplFromJson(json);

  @override
  final String symbol;
  @override
  final int decimals;
  @override
  @StringOrIntConverter()
  final String balance;
  @override
  final String kind;
  @override
  final String? contract;
  @override
  final String? name;
  @override
  final String? assetId;
  @override
  final String? mint;
  @override
  final String? tokenId;
  @override
  final bool? verified;

  @override
  String toString() {
    return 'WalletAsset.unknown(symbol: $symbol, decimals: $decimals, balance: $balance, kind: $kind, contract: $contract, name: $name, assetId: $assetId, mint: $mint, tokenId: $tokenId, verified: $verified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAssetUnknownImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.verified, verified) ||
                other.verified == verified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, symbol, decimals, balance, kind,
      contract, name, assetId, mint, tokenId, verified);

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAssetUnknownImplCopyWith<_$WalletAssetUnknownImpl> get copyWith =>
      __$$WalletAssetUnknownImplCopyWithImpl<_$WalletAssetUnknownImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)
        native,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)
        erc20,
    required TResult Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)
        asa,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        spl2022,
    required TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        sep41,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)
        tep74,
    required TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc10,
    required TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)
        trc20,
    required TResult Function(String metadata, String symbol, int decimals,
            String kind, @StringOrIntConverter() String balance, String? name)
        aip21,
    required TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)
        unknown,
  }) {
    return unknown(symbol, decimals, balance, kind, contract, name, assetId,
        mint, tokenId, verified);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult? Function(
            String assetId,
            String symbol,
            int decimals,
            bool verified,
            @StringOrIntConverter() String balance,
            String kind,
            String? name)?
        asa,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult? Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult? Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult? Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult? Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult? Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
  }) {
    return unknown?.call(symbol, decimals, balance, kind, contract, name,
        assetId, mint, tokenId, verified);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? name)?
        native,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            bool? verified,
            String? contract,
            String? name)?
        erc20,
    TResult Function(String assetId, String symbol, int decimals, bool verified,
            @StringOrIntConverter() String balance, String kind, String? name)?
        asa,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        spl2022,
    TResult Function(String mint, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        sep41,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? mint,
            String? name)?
        tep74,
    TResult Function(String tokenId, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc10,
    TResult Function(String contract, String symbol, int decimals,
            @StringOrIntConverter() String balance, String kind, String? name)?
        trc20,
    TResult Function(String metadata, String symbol, int decimals, String kind,
            @StringOrIntConverter() String balance, String? name)?
        aip21,
    TResult Function(
            String symbol,
            int decimals,
            @StringOrIntConverter() String balance,
            String kind,
            String? contract,
            String? name,
            String? assetId,
            String? mint,
            String? tokenId,
            bool? verified)?
        unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(symbol, decimals, balance, kind, contract, name, assetId,
          mint, tokenId, verified);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_WalletAssetNative value) native,
    required TResult Function(_WalletAssetErc20 value) erc20,
    required TResult Function(_WalletAssetAsa value) asa,
    required TResult Function(_WalletAssetSpl value) spl,
    required TResult Function(_WalletAssetSpl2022 value) spl2022,
    required TResult Function(_WalletAssetSep41 value) sep41,
    required TResult Function(_WalletAssetTep74 value) tep74,
    required TResult Function(_WalletAssetTrc10 value) trc10,
    required TResult Function(_WalletAssetTrc20 value) trc20,
    required TResult Function(_WalletAssetAip21 value) aip21,
    required TResult Function(_WalletAssetUnknown value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_WalletAssetNative value)? native,
    TResult? Function(_WalletAssetErc20 value)? erc20,
    TResult? Function(_WalletAssetAsa value)? asa,
    TResult? Function(_WalletAssetSpl value)? spl,
    TResult? Function(_WalletAssetSpl2022 value)? spl2022,
    TResult? Function(_WalletAssetSep41 value)? sep41,
    TResult? Function(_WalletAssetTep74 value)? tep74,
    TResult? Function(_WalletAssetTrc10 value)? trc10,
    TResult? Function(_WalletAssetTrc20 value)? trc20,
    TResult? Function(_WalletAssetAip21 value)? aip21,
    TResult? Function(_WalletAssetUnknown value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_WalletAssetNative value)? native,
    TResult Function(_WalletAssetErc20 value)? erc20,
    TResult Function(_WalletAssetAsa value)? asa,
    TResult Function(_WalletAssetSpl value)? spl,
    TResult Function(_WalletAssetSpl2022 value)? spl2022,
    TResult Function(_WalletAssetSep41 value)? sep41,
    TResult Function(_WalletAssetTep74 value)? tep74,
    TResult Function(_WalletAssetTrc10 value)? trc10,
    TResult Function(_WalletAssetTrc20 value)? trc20,
    TResult Function(_WalletAssetAip21 value)? aip21,
    TResult Function(_WalletAssetUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAssetUnknownImplToJson(
      this,
    );
  }
}

abstract class _WalletAssetUnknown extends WalletAsset {
  const factory _WalletAssetUnknown(
      {required final String symbol,
      required final int decimals,
      @StringOrIntConverter() required final String balance,
      required final String kind,
      final String? contract,
      final String? name,
      final String? assetId,
      final String? mint,
      final String? tokenId,
      final bool? verified}) = _$WalletAssetUnknownImpl;
  const _WalletAssetUnknown._() : super._();

  factory _WalletAssetUnknown.fromJson(Map<String, dynamic> json) =
      _$WalletAssetUnknownImpl.fromJson;

  @override
  String get symbol;
  @override
  int get decimals;
  @override
  @StringOrIntConverter()
  String get balance;
  @override
  String get kind;
  String? get contract;
  @override
  String? get name;
  String? get assetId;
  String? get mint;
  String? get tokenId;
  bool? get verified;

  /// Create a copy of WalletAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAssetUnknownImplCopyWith<_$WalletAssetUnknownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
