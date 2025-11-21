// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'latest_trade.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LatestTrade _$LatestTradeFromJson(Map<String, dynamic> json) {
  return _LatestTrade.fromJson(json);
}

/// @nodoc
mixin _$LatestTrade {
  Creator get trader => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get amountUSD => throw _privateConstructorUsedError;
  int get timestamp => throw _privateConstructorUsedError;
  String get side => throw _privateConstructorUsedError; // "buy" or "sell"
  Addresses get addresses => throw _privateConstructorUsedError;

  /// Serializes this LatestTrade to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LatestTradeCopyWith<LatestTrade> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LatestTradeCopyWith<$Res> {
  factory $LatestTradeCopyWith(
    LatestTrade value,
    $Res Function(LatestTrade) then,
  ) = _$LatestTradeCopyWithImpl<$Res, LatestTrade>;
  @useResult
  $Res call({
    Creator trader,
    double amount,
    double amountUSD,
    int timestamp,
    String side,
    Addresses addresses,
  });

  $CreatorCopyWith<$Res> get trader;
  $AddressesCopyWith<$Res> get addresses;
}

/// @nodoc
class _$LatestTradeCopyWithImpl<$Res, $Val extends LatestTrade>
    implements $LatestTradeCopyWith<$Res> {
  _$LatestTradeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trader = null,
    Object? amount = null,
    Object? amountUSD = null,
    Object? timestamp = null,
    Object? side = null,
    Object? addresses = null,
  }) {
    return _then(
      _value.copyWith(
            trader: null == trader
                ? _value.trader
                : trader // ignore: cast_nullable_to_non_nullable
                      as Creator,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            amountUSD: null == amountUSD
                ? _value.amountUSD
                : amountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int,
            side: null == side
                ? _value.side
                : side // ignore: cast_nullable_to_non_nullable
                      as String,
            addresses: null == addresses
                ? _value.addresses
                : addresses // ignore: cast_nullable_to_non_nullable
                      as Addresses,
          )
          as $Val,
    );
  }

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res> get trader {
    return $CreatorCopyWith<$Res>(_value.trader, (value) {
      return _then(_value.copyWith(trader: value) as $Val);
    });
  }

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressesCopyWith<$Res> get addresses {
    return $AddressesCopyWith<$Res>(_value.addresses, (value) {
      return _then(_value.copyWith(addresses: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LatestTradeImplCopyWith<$Res>
    implements $LatestTradeCopyWith<$Res> {
  factory _$$LatestTradeImplCopyWith(
    _$LatestTradeImpl value,
    $Res Function(_$LatestTradeImpl) then,
  ) = __$$LatestTradeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Creator trader,
    double amount,
    double amountUSD,
    int timestamp,
    String side,
    Addresses addresses,
  });

  @override
  $CreatorCopyWith<$Res> get trader;
  @override
  $AddressesCopyWith<$Res> get addresses;
}

/// @nodoc
class __$$LatestTradeImplCopyWithImpl<$Res>
    extends _$LatestTradeCopyWithImpl<$Res, _$LatestTradeImpl>
    implements _$$LatestTradeImplCopyWith<$Res> {
  __$$LatestTradeImplCopyWithImpl(
    _$LatestTradeImpl _value,
    $Res Function(_$LatestTradeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trader = null,
    Object? amount = null,
    Object? amountUSD = null,
    Object? timestamp = null,
    Object? side = null,
    Object? addresses = null,
  }) {
    return _then(
      _$LatestTradeImpl(
        trader: null == trader
            ? _value.trader
            : trader // ignore: cast_nullable_to_non_nullable
                  as Creator,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        amountUSD: null == amountUSD
            ? _value.amountUSD
            : amountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int,
        side: null == side
            ? _value.side
            : side // ignore: cast_nullable_to_non_nullable
                  as String,
        addresses: null == addresses
            ? _value.addresses
            : addresses // ignore: cast_nullable_to_non_nullable
                  as Addresses,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LatestTradeImpl implements _LatestTrade {
  const _$LatestTradeImpl({
    required this.trader,
    required this.amount,
    required this.amountUSD,
    required this.timestamp,
    required this.side,
    required this.addresses,
  });

  factory _$LatestTradeImpl.fromJson(Map<String, dynamic> json) =>
      _$$LatestTradeImplFromJson(json);

  @override
  final Creator trader;
  @override
  final double amount;
  @override
  final double amountUSD;
  @override
  final int timestamp;
  @override
  final String side;
  // "buy" or "sell"
  @override
  final Addresses addresses;

  @override
  String toString() {
    return 'LatestTrade(trader: $trader, amount: $amount, amountUSD: $amountUSD, timestamp: $timestamp, side: $side, addresses: $addresses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LatestTradeImpl &&
            (identical(other.trader, trader) || other.trader == trader) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.amountUSD, amountUSD) ||
                other.amountUSD == amountUSD) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.side, side) || other.side == side) &&
            (identical(other.addresses, addresses) ||
                other.addresses == addresses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    trader,
    amount,
    amountUSD,
    timestamp,
    side,
    addresses,
  );

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LatestTradeImplCopyWith<_$LatestTradeImpl> get copyWith =>
      __$$LatestTradeImplCopyWithImpl<_$LatestTradeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LatestTradeImplToJson(this);
  }
}

abstract class _LatestTrade implements LatestTrade {
  const factory _LatestTrade({
    required final Creator trader,
    required final double amount,
    required final double amountUSD,
    required final int timestamp,
    required final String side,
    required final Addresses addresses,
  }) = _$LatestTradeImpl;

  factory _LatestTrade.fromJson(Map<String, dynamic> json) =
      _$LatestTradeImpl.fromJson;

  @override
  Creator get trader;
  @override
  double get amount;
  @override
  double get amountUSD;
  @override
  int get timestamp;
  @override
  String get side; // "buy" or "sell"
  @override
  Addresses get addresses;

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LatestTradeImplCopyWith<_$LatestTradeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
