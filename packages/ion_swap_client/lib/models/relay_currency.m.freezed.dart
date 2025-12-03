// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_currency.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayCurrency _$RelayCurrencyFromJson(Map<String, dynamic> json) {
  return _RelayCurrency.fromJson(json);
}

/// @nodoc
mixin _$RelayCurrency {
  String get id => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  int get decimals => throw _privateConstructorUsedError;

  /// Serializes this RelayCurrency to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayCurrency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayCurrencyCopyWith<RelayCurrency> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayCurrencyCopyWith<$Res> {
  factory $RelayCurrencyCopyWith(
          RelayCurrency value, $Res Function(RelayCurrency) then) =
      _$RelayCurrencyCopyWithImpl<$Res, RelayCurrency>;
  @useResult
  $Res call(
      {String id, String symbol, String name, String address, int decimals});
}

/// @nodoc
class _$RelayCurrencyCopyWithImpl<$Res, $Val extends RelayCurrency>
    implements $RelayCurrencyCopyWith<$Res> {
  _$RelayCurrencyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayCurrency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? name = null,
    Object? address = null,
    Object? decimals = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelayCurrencyImplCopyWith<$Res>
    implements $RelayCurrencyCopyWith<$Res> {
  factory _$$RelayCurrencyImplCopyWith(
          _$RelayCurrencyImpl value, $Res Function(_$RelayCurrencyImpl) then) =
      __$$RelayCurrencyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String symbol, String name, String address, int decimals});
}

/// @nodoc
class __$$RelayCurrencyImplCopyWithImpl<$Res>
    extends _$RelayCurrencyCopyWithImpl<$Res, _$RelayCurrencyImpl>
    implements _$$RelayCurrencyImplCopyWith<$Res> {
  __$$RelayCurrencyImplCopyWithImpl(
      _$RelayCurrencyImpl _value, $Res Function(_$RelayCurrencyImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayCurrency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? name = null,
    Object? address = null,
    Object? decimals = null,
  }) {
    return _then(_$RelayCurrencyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      decimals: null == decimals
          ? _value.decimals
          : decimals // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayCurrencyImpl implements _RelayCurrency {
  _$RelayCurrencyImpl(
      {required this.id,
      required this.symbol,
      required this.name,
      required this.address,
      required this.decimals});

  factory _$RelayCurrencyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayCurrencyImplFromJson(json);

  @override
  final String id;
  @override
  final String symbol;
  @override
  final String name;
  @override
  final String address;
  @override
  final int decimals;

  @override
  String toString() {
    return 'RelayCurrency(id: $id, symbol: $symbol, name: $name, address: $address, decimals: $decimals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayCurrencyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.decimals, decimals) ||
                other.decimals == decimals));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, symbol, name, address, decimals);

  /// Create a copy of RelayCurrency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayCurrencyImplCopyWith<_$RelayCurrencyImpl> get copyWith =>
      __$$RelayCurrencyImplCopyWithImpl<_$RelayCurrencyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayCurrencyImplToJson(
      this,
    );
  }
}

abstract class _RelayCurrency implements RelayCurrency {
  factory _RelayCurrency(
      {required final String id,
      required final String symbol,
      required final String name,
      required final String address,
      required final int decimals}) = _$RelayCurrencyImpl;

  factory _RelayCurrency.fromJson(Map<String, dynamic> json) =
      _$RelayCurrencyImpl.fromJson;

  @override
  String get id;
  @override
  String get symbol;
  @override
  String get name;
  @override
  String get address;
  @override
  int get decimals;

  /// Create a copy of RelayCurrency
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayCurrencyImplCopyWith<_$RelayCurrencyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
