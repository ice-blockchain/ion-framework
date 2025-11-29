// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_position.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TradePosition _$TradePositionFromJson(Map<String, dynamic> json) {
  return _TradePosition.fromJson(json);
}

/// @nodoc
mixin _$TradePosition {
  Creator get holder => throw _privateConstructorUsedError;
  Addresses get addresses => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // "buy/sell"
  double get amount => throw _privateConstructorUsedError;
  double get amountUSD => throw _privateConstructorUsedError;
  double get balance => throw _privateConstructorUsedError;
  double get balanceUSD => throw _privateConstructorUsedError;

  /// Serializes this TradePosition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TradePosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TradePositionCopyWith<TradePosition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TradePositionCopyWith<$Res> {
  factory $TradePositionCopyWith(
    TradePosition value,
    $Res Function(TradePosition) then,
  ) = _$TradePositionCopyWithImpl<$Res, TradePosition>;
  @useResult
  $Res call({
    Creator holder,
    Addresses addresses,
    String createdAt,
    String type,
    double amount,
    double amountUSD,
    double balance,
    double balanceUSD,
  });

  $CreatorCopyWith<$Res> get holder;
  $AddressesCopyWith<$Res> get addresses;
}

/// @nodoc
class _$TradePositionCopyWithImpl<$Res, $Val extends TradePosition>
    implements $TradePositionCopyWith<$Res> {
  _$TradePositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TradePosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? holder = null,
    Object? addresses = null,
    Object? createdAt = null,
    Object? type = null,
    Object? amount = null,
    Object? amountUSD = null,
    Object? balance = null,
    Object? balanceUSD = null,
  }) {
    return _then(
      _value.copyWith(
            holder: null == holder
                ? _value.holder
                : holder // ignore: cast_nullable_to_non_nullable
                      as Creator,
            addresses: null == addresses
                ? _value.addresses
                : addresses // ignore: cast_nullable_to_non_nullable
                      as Addresses,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            amountUSD: null == amountUSD
                ? _value.amountUSD
                : amountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
            balanceUSD: null == balanceUSD
                ? _value.balanceUSD
                : balanceUSD // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }

  /// Create a copy of TradePosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res> get holder {
    return $CreatorCopyWith<$Res>(_value.holder, (value) {
      return _then(_value.copyWith(holder: value) as $Val);
    });
  }

  /// Create a copy of TradePosition
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
abstract class _$$TradePositionImplCopyWith<$Res>
    implements $TradePositionCopyWith<$Res> {
  factory _$$TradePositionImplCopyWith(
    _$TradePositionImpl value,
    $Res Function(_$TradePositionImpl) then,
  ) = __$$TradePositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Creator holder,
    Addresses addresses,
    String createdAt,
    String type,
    double amount,
    double amountUSD,
    double balance,
    double balanceUSD,
  });

  @override
  $CreatorCopyWith<$Res> get holder;
  @override
  $AddressesCopyWith<$Res> get addresses;
}

/// @nodoc
class __$$TradePositionImplCopyWithImpl<$Res>
    extends _$TradePositionCopyWithImpl<$Res, _$TradePositionImpl>
    implements _$$TradePositionImplCopyWith<$Res> {
  __$$TradePositionImplCopyWithImpl(
    _$TradePositionImpl _value,
    $Res Function(_$TradePositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TradePosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? holder = null,
    Object? addresses = null,
    Object? createdAt = null,
    Object? type = null,
    Object? amount = null,
    Object? amountUSD = null,
    Object? balance = null,
    Object? balanceUSD = null,
  }) {
    return _then(
      _$TradePositionImpl(
        holder: null == holder
            ? _value.holder
            : holder // ignore: cast_nullable_to_non_nullable
                  as Creator,
        addresses: null == addresses
            ? _value.addresses
            : addresses // ignore: cast_nullable_to_non_nullable
                  as Addresses,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        amountUSD: null == amountUSD
            ? _value.amountUSD
            : amountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
        balanceUSD: null == balanceUSD
            ? _value.balanceUSD
            : balanceUSD // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TradePositionImpl implements _TradePosition {
  const _$TradePositionImpl({
    required this.holder,
    required this.addresses,
    required this.createdAt,
    required this.type,
    required this.amount,
    required this.amountUSD,
    required this.balance,
    required this.balanceUSD,
  });

  factory _$TradePositionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TradePositionImplFromJson(json);

  @override
  final Creator holder;
  @override
  final Addresses addresses;
  @override
  final String createdAt;
  @override
  final String type;
  // "buy/sell"
  @override
  final double amount;
  @override
  final double amountUSD;
  @override
  final double balance;
  @override
  final double balanceUSD;

  @override
  String toString() {
    return 'TradePosition(holder: $holder, addresses: $addresses, createdAt: $createdAt, type: $type, amount: $amount, amountUSD: $amountUSD, balance: $balance, balanceUSD: $balanceUSD)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TradePositionImpl &&
            (identical(other.holder, holder) || other.holder == holder) &&
            (identical(other.addresses, addresses) ||
                other.addresses == addresses) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.amountUSD, amountUSD) ||
                other.amountUSD == amountUSD) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.balanceUSD, balanceUSD) ||
                other.balanceUSD == balanceUSD));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    holder,
    addresses,
    createdAt,
    type,
    amount,
    amountUSD,
    balance,
    balanceUSD,
  );

  /// Create a copy of TradePosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TradePositionImplCopyWith<_$TradePositionImpl> get copyWith =>
      __$$TradePositionImplCopyWithImpl<_$TradePositionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TradePositionImplToJson(this);
  }
}

abstract class _TradePosition implements TradePosition {
  const factory _TradePosition({
    required final Creator holder,
    required final Addresses addresses,
    required final String createdAt,
    required final String type,
    required final double amount,
    required final double amountUSD,
    required final double balance,
    required final double balanceUSD,
  }) = _$TradePositionImpl;

  factory _TradePosition.fromJson(Map<String, dynamic> json) =
      _$TradePositionImpl.fromJson;

  @override
  Creator get holder;
  @override
  Addresses get addresses;
  @override
  String get createdAt;
  @override
  String get type; // "buy/sell"
  @override
  double get amount;
  @override
  double get amountUSD;
  @override
  double get balance;
  @override
  double get balanceUSD;

  /// Create a copy of TradePosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TradePositionImplCopyWith<_$TradePositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TradePositionPatch _$TradePositionPatchFromJson(Map<String, dynamic> json) {
  return _TradePositionPatch.fromJson(json);
}

/// @nodoc
mixin _$TradePositionPatch {
  CreatorPatch? get holder => throw _privateConstructorUsedError;
  AddressesPatch? get addresses => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  double? get amount => throw _privateConstructorUsedError;
  double? get amountUSD => throw _privateConstructorUsedError;
  double? get balance => throw _privateConstructorUsedError;
  double? get balanceUSD => throw _privateConstructorUsedError;

  /// Serializes this TradePositionPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$TradePositionPatchImpl implements _TradePositionPatch {
  const _$TradePositionPatchImpl({
    this.holder,
    this.addresses,
    this.createdAt,
    this.type,
    this.amount,
    this.amountUSD,
    this.balance,
    this.balanceUSD,
  });

  factory _$TradePositionPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$TradePositionPatchImplFromJson(json);

  @override
  final CreatorPatch? holder;
  @override
  final AddressesPatch? addresses;
  @override
  final String? createdAt;
  @override
  final String? type;
  @override
  final double? amount;
  @override
  final double? amountUSD;
  @override
  final double? balance;
  @override
  final double? balanceUSD;

  @override
  String toString() {
    return 'TradePositionPatch(holder: $holder, addresses: $addresses, createdAt: $createdAt, type: $type, amount: $amount, amountUSD: $amountUSD, balance: $balance, balanceUSD: $balanceUSD)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TradePositionPatchImpl &&
            (identical(other.holder, holder) || other.holder == holder) &&
            (identical(other.addresses, addresses) ||
                other.addresses == addresses) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.amountUSD, amountUSD) ||
                other.amountUSD == amountUSD) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.balanceUSD, balanceUSD) ||
                other.balanceUSD == balanceUSD));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    holder,
    addresses,
    createdAt,
    type,
    amount,
    amountUSD,
    balance,
    balanceUSD,
  );

  @override
  Map<String, dynamic> toJson() {
    return _$$TradePositionPatchImplToJson(this);
  }
}

abstract class _TradePositionPatch implements TradePositionPatch {
  const factory _TradePositionPatch({
    final CreatorPatch? holder,
    final AddressesPatch? addresses,
    final String? createdAt,
    final String? type,
    final double? amount,
    final double? amountUSD,
    final double? balance,
    final double? balanceUSD,
  }) = _$TradePositionPatchImpl;

  factory _TradePositionPatch.fromJson(Map<String, dynamic> json) =
      _$TradePositionPatchImpl.fromJson;

  @override
  CreatorPatch? get holder;
  @override
  AddressesPatch? get addresses;
  @override
  String? get createdAt;
  @override
  String? get type;
  @override
  double? get amount;
  @override
  double? get amountUSD;
  @override
  double? get balance;
  @override
  double? get balanceUSD;
}
