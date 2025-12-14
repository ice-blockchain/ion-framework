// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lets_exchange_coin.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LetsExchangeCoin _$LetsExchangeCoinFromJson(Map<String, dynamic> json) {
  return _LetsExchangeCoin.fromJson(json);
}

/// @nodoc
mixin _$LetsExchangeCoin {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  int get isActive => throw _privateConstructorUsedError;
  List<LetsExchangeNetwork> get networks => throw _privateConstructorUsedError;

  /// Serializes this LetsExchangeCoin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LetsExchangeCoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LetsExchangeCoinCopyWith<LetsExchangeCoin> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LetsExchangeCoinCopyWith<$Res> {
  factory $LetsExchangeCoinCopyWith(
          LetsExchangeCoin value, $Res Function(LetsExchangeCoin) then) =
      _$LetsExchangeCoinCopyWithImpl<$Res, LetsExchangeCoin>;
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'is_active') int isActive,
      List<LetsExchangeNetwork> networks});
}

/// @nodoc
class _$LetsExchangeCoinCopyWithImpl<$Res, $Val extends LetsExchangeCoin>
    implements $LetsExchangeCoinCopyWith<$Res> {
  _$LetsExchangeCoinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LetsExchangeCoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? isActive = null,
    Object? networks = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as int,
      networks: null == networks
          ? _value.networks
          : networks // ignore: cast_nullable_to_non_nullable
              as List<LetsExchangeNetwork>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LetsExchangeCoinImplCopyWith<$Res>
    implements $LetsExchangeCoinCopyWith<$Res> {
  factory _$$LetsExchangeCoinImplCopyWith(_$LetsExchangeCoinImpl value,
          $Res Function(_$LetsExchangeCoinImpl) then) =
      __$$LetsExchangeCoinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'is_active') int isActive,
      List<LetsExchangeNetwork> networks});
}

/// @nodoc
class __$$LetsExchangeCoinImplCopyWithImpl<$Res>
    extends _$LetsExchangeCoinCopyWithImpl<$Res, _$LetsExchangeCoinImpl>
    implements _$$LetsExchangeCoinImplCopyWith<$Res> {
  __$$LetsExchangeCoinImplCopyWithImpl(_$LetsExchangeCoinImpl _value,
      $Res Function(_$LetsExchangeCoinImpl) _then)
      : super(_value, _then);

  /// Create a copy of LetsExchangeCoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? isActive = null,
    Object? networks = null,
  }) {
    return _then(_$LetsExchangeCoinImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as int,
      networks: null == networks
          ? _value._networks
          : networks // ignore: cast_nullable_to_non_nullable
              as List<LetsExchangeNetwork>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LetsExchangeCoinImpl implements _LetsExchangeCoin {
  _$LetsExchangeCoinImpl(
      {required this.code,
      required this.name,
      @JsonKey(name: 'is_active') required this.isActive,
      required final List<LetsExchangeNetwork> networks})
      : _networks = networks;

  factory _$LetsExchangeCoinImpl.fromJson(Map<String, dynamic> json) =>
      _$$LetsExchangeCoinImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  @override
  @JsonKey(name: 'is_active')
  final int isActive;
  final List<LetsExchangeNetwork> _networks;
  @override
  List<LetsExchangeNetwork> get networks {
    if (_networks is EqualUnmodifiableListView) return _networks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_networks);
  }

  @override
  String toString() {
    return 'LetsExchangeCoin(code: $code, name: $name, isActive: $isActive, networks: $networks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LetsExchangeCoinImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(other._networks, _networks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, name, isActive,
      const DeepCollectionEquality().hash(_networks));

  /// Create a copy of LetsExchangeCoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LetsExchangeCoinImplCopyWith<_$LetsExchangeCoinImpl> get copyWith =>
      __$$LetsExchangeCoinImplCopyWithImpl<_$LetsExchangeCoinImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LetsExchangeCoinImplToJson(
      this,
    );
  }
}

abstract class _LetsExchangeCoin implements LetsExchangeCoin {
  factory _LetsExchangeCoin(
          {required final String code,
          required final String name,
          @JsonKey(name: 'is_active') required final int isActive,
          required final List<LetsExchangeNetwork> networks}) =
      _$LetsExchangeCoinImpl;

  factory _LetsExchangeCoin.fromJson(Map<String, dynamic> json) =
      _$LetsExchangeCoinImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  @JsonKey(name: 'is_active')
  int get isActive;
  @override
  List<LetsExchangeNetwork> get networks;

  /// Create a copy of LetsExchangeCoin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LetsExchangeCoinImplCopyWith<_$LetsExchangeCoinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
