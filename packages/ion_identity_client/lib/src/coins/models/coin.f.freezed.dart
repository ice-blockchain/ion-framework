// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coin.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Coin _$CoinFromJson(Map<String, dynamic> json) {
  return _Coin.fromJson(json);
}

/// @nodoc
mixin _$Coin {
  String get contractAddress => throw _privateConstructorUsedError;
  int get decimals => throw _privateConstructorUsedError;
  String get iconURL => throw _privateConstructorUsedError;
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get network => throw _privateConstructorUsedError;
  double get priceUSD => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  String get symbolGroup => throw _privateConstructorUsedError;
  @SyncFrequencyConverter()
  Duration get syncFrequency => throw _privateConstructorUsedError;
  bool? get native => throw _privateConstructorUsedError;
  bool? get prioritized => throw _privateConstructorUsedError;
  String? get tokenizedCommunityExternalAddress =>
      throw _privateConstructorUsedError;
  String? get tokenizedCommunityTokenType => throw _privateConstructorUsedError;

  /// Serializes this Coin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Coin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoinCopyWith<Coin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinCopyWith<$Res> {
  factory $CoinCopyWith(Coin value, $Res Function(Coin) then) =
      _$CoinCopyWithImpl<$Res, Coin>;
  @useResult
  $Res call(
      {String contractAddress,
      int decimals,
      String iconURL,
      String id,
      String name,
      String network,
      double priceUSD,
      String symbol,
      String symbolGroup,
      @SyncFrequencyConverter() Duration syncFrequency,
      bool? native,
      bool? prioritized,
      String? tokenizedCommunityExternalAddress,
      String? tokenizedCommunityTokenType});
}

/// @nodoc
class _$CoinCopyWithImpl<$Res, $Val extends Coin>
    implements $CoinCopyWith<$Res> {
  _$CoinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Coin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contractAddress = null,
    Object? decimals = null,
    Object? iconURL = null,
    Object? id = null,
    Object? name = null,
    Object? network = null,
    Object? priceUSD = null,
    Object? symbol = null,
    Object? symbolGroup = null,
    Object? syncFrequency = null,
    Object? native = freezed,
    Object? prioritized = freezed,
    Object? tokenizedCommunityExternalAddress = freezed,
    Object? tokenizedCommunityTokenType = freezed,
  }) {
    return _then(_value.copyWith(
      contractAddress: null == contractAddress
          ? _value.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      iconURL: null == iconURL
          ? _value.iconURL
          : iconURL // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      priceUSD: null == priceUSD
          ? _value.priceUSD
          : priceUSD // ignore: cast_nullable_to_non_nullable
              as double,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      symbolGroup: null == symbolGroup
          ? _value.symbolGroup
          : symbolGroup // ignore: cast_nullable_to_non_nullable
              as String,
      syncFrequency: null == syncFrequency
          ? _value.syncFrequency
          : syncFrequency // ignore: cast_nullable_to_non_nullable
              as Duration,
      native: freezed == native
          ? _value.native
          : native // ignore: cast_nullable_to_non_nullable
              as bool?,
      prioritized: freezed == prioritized
          ? _value.prioritized
          : prioritized // ignore: cast_nullable_to_non_nullable
              as bool?,
      tokenizedCommunityExternalAddress: freezed ==
              tokenizedCommunityExternalAddress
          ? _value.tokenizedCommunityExternalAddress
          : tokenizedCommunityExternalAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenizedCommunityTokenType: freezed == tokenizedCommunityTokenType
          ? _value.tokenizedCommunityTokenType
          : tokenizedCommunityTokenType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CoinImplCopyWith<$Res> implements $CoinCopyWith<$Res> {
  factory _$$CoinImplCopyWith(
          _$CoinImpl value, $Res Function(_$CoinImpl) then) =
      __$$CoinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String contractAddress,
      int decimals,
      String iconURL,
      String id,
      String name,
      String network,
      double priceUSD,
      String symbol,
      String symbolGroup,
      @SyncFrequencyConverter() Duration syncFrequency,
      bool? native,
      bool? prioritized,
      String? tokenizedCommunityExternalAddress,
      String? tokenizedCommunityTokenType});
}

/// @nodoc
class __$$CoinImplCopyWithImpl<$Res>
    extends _$CoinCopyWithImpl<$Res, _$CoinImpl>
    implements _$$CoinImplCopyWith<$Res> {
  __$$CoinImplCopyWithImpl(_$CoinImpl _value, $Res Function(_$CoinImpl) _then)
      : super(_value, _then);

  /// Create a copy of Coin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contractAddress = null,
    Object? decimals = null,
    Object? iconURL = null,
    Object? id = null,
    Object? name = null,
    Object? network = null,
    Object? priceUSD = null,
    Object? symbol = null,
    Object? symbolGroup = null,
    Object? syncFrequency = null,
    Object? native = freezed,
    Object? prioritized = freezed,
    Object? tokenizedCommunityExternalAddress = freezed,
    Object? tokenizedCommunityTokenType = freezed,
  }) {
    return _then(_$CoinImpl(
      contractAddress: null == contractAddress
          ? _value.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
      iconURL: null == iconURL
          ? _value.iconURL
          : iconURL // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      priceUSD: null == priceUSD
          ? _value.priceUSD
          : priceUSD // ignore: cast_nullable_to_non_nullable
              as double,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      symbolGroup: null == symbolGroup
          ? _value.symbolGroup
          : symbolGroup // ignore: cast_nullable_to_non_nullable
              as String,
      syncFrequency: null == syncFrequency
          ? _value.syncFrequency
          : syncFrequency // ignore: cast_nullable_to_non_nullable
              as Duration,
      native: freezed == native
          ? _value.native
          : native // ignore: cast_nullable_to_non_nullable
              as bool?,
      prioritized: freezed == prioritized
          ? _value.prioritized
          : prioritized // ignore: cast_nullable_to_non_nullable
              as bool?,
      tokenizedCommunityExternalAddress: freezed ==
              tokenizedCommunityExternalAddress
          ? _value.tokenizedCommunityExternalAddress
          : tokenizedCommunityExternalAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenizedCommunityTokenType: freezed == tokenizedCommunityTokenType
          ? _value.tokenizedCommunityTokenType
          : tokenizedCommunityTokenType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CoinImpl implements _Coin {
  _$CoinImpl(
      {required this.contractAddress,
      required this.decimals,
      required this.iconURL,
      required this.id,
      required this.name,
      required this.network,
      required this.priceUSD,
      required this.symbol,
      required this.symbolGroup,
      @SyncFrequencyConverter() required this.syncFrequency,
      this.native = false,
      this.prioritized = false,
      this.tokenizedCommunityExternalAddress,
      this.tokenizedCommunityTokenType});

  factory _$CoinImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoinImplFromJson(json);

  @override
  final String contractAddress;
  @override
  final int decimals;
  @override
  final String iconURL;
  @override
  final String id;
  @override
  final String name;
  @override
  final String network;
  @override
  final double priceUSD;
  @override
  final String symbol;
  @override
  final String symbolGroup;
  @override
  @SyncFrequencyConverter()
  final Duration syncFrequency;
  @override
  @JsonKey()
  final bool? native;
  @override
  @JsonKey()
  final bool? prioritized;
  @override
  final String? tokenizedCommunityExternalAddress;
  @override
  final String? tokenizedCommunityTokenType;

  @override
  String toString() {
    return 'Coin(contractAddress: $contractAddress, decimals: $decimals, iconURL: $iconURL, id: $id, name: $name, network: $network, priceUSD: $priceUSD, symbol: $symbol, symbolGroup: $symbolGroup, syncFrequency: $syncFrequency, native: $native, prioritized: $prioritized, tokenizedCommunityExternalAddress: $tokenizedCommunityExternalAddress, tokenizedCommunityTokenType: $tokenizedCommunityTokenType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoinImpl &&
            (identical(other.contractAddress, contractAddress) ||
                other.contractAddress == contractAddress) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals) &&
            (identical(other.iconURL, iconURL) || other.iconURL == iconURL) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.priceUSD, priceUSD) ||
                other.priceUSD == priceUSD) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.symbolGroup, symbolGroup) ||
                other.symbolGroup == symbolGroup) &&
            (identical(other.syncFrequency, syncFrequency) ||
                other.syncFrequency == syncFrequency) &&
            (identical(other.native, native) || other.native == native) &&
            (identical(other.prioritized, prioritized) ||
                other.prioritized == prioritized) &&
            (identical(other.tokenizedCommunityExternalAddress,
                    tokenizedCommunityExternalAddress) ||
                other.tokenizedCommunityExternalAddress ==
                    tokenizedCommunityExternalAddress) &&
            (identical(other.tokenizedCommunityTokenType,
                    tokenizedCommunityTokenType) ||
                other.tokenizedCommunityTokenType ==
                    tokenizedCommunityTokenType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      contractAddress,
      decimals,
      iconURL,
      id,
      name,
      network,
      priceUSD,
      symbol,
      symbolGroup,
      syncFrequency,
      native,
      prioritized,
      tokenizedCommunityExternalAddress,
      tokenizedCommunityTokenType);

  /// Create a copy of Coin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoinImplCopyWith<_$CoinImpl> get copyWith =>
      __$$CoinImplCopyWithImpl<_$CoinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoinImplToJson(
      this,
    );
  }
}

abstract class _Coin implements Coin {
  factory _Coin(
      {required final String contractAddress,
      required final int decimals,
      required final String iconURL,
      required final String id,
      required final String name,
      required final String network,
      required final double priceUSD,
      required final String symbol,
      required final String symbolGroup,
      @SyncFrequencyConverter() required final Duration syncFrequency,
      final bool? native,
      final bool? prioritized,
      final String? tokenizedCommunityExternalAddress,
      final String? tokenizedCommunityTokenType}) = _$CoinImpl;

  factory _Coin.fromJson(Map<String, dynamic> json) = _$CoinImpl.fromJson;

  @override
  String get contractAddress;
  @override
  int get decimals;
  @override
  String get iconURL;
  @override
  String get id;
  @override
  String get name;
  @override
  String get network;
  @override
  double get priceUSD;
  @override
  String get symbol;
  @override
  String get symbolGroup;
  @override
  @SyncFrequencyConverter()
  Duration get syncFrequency;
  @override
  bool? get native;
  @override
  bool? get prioritized;
  @override
  String? get tokenizedCommunityExternalAddress;
  @override
  String? get tokenizedCommunityTokenType;

  /// Create a copy of Coin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoinImplCopyWith<_$CoinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
