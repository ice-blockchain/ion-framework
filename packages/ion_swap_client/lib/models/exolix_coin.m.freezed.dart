// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exolix_coin.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExolixCoin _$ExolixCoinFromJson(Map<String, dynamic> json) {
  return _ExolixCoin.fromJson(json);
}

/// @nodoc
mixin _$ExolixCoin {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<ExolixNetwork> get networks => throw _privateConstructorUsedError;

  /// Serializes this ExolixCoin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExolixCoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExolixCoinCopyWith<ExolixCoin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExolixCoinCopyWith<$Res> {
  factory $ExolixCoinCopyWith(ExolixCoin value, $Res Function(ExolixCoin) then) =
      _$ExolixCoinCopyWithImpl<$Res, ExolixCoin>;
  @useResult
  $Res call({String code, String name, List<ExolixNetwork> networks});
}

/// @nodoc
class _$ExolixCoinCopyWithImpl<$Res, $Val extends ExolixCoin> implements $ExolixCoinCopyWith<$Res> {
  _$ExolixCoinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExolixCoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
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
      networks: null == networks
          ? _value.networks
          : networks // ignore: cast_nullable_to_non_nullable
              as List<ExolixNetwork>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExolixCoinImplCopyWith<$Res> implements $ExolixCoinCopyWith<$Res> {
  factory _$$ExolixCoinImplCopyWith(_$ExolixCoinImpl value, $Res Function(_$ExolixCoinImpl) then) =
      __$$ExolixCoinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String name, List<ExolixNetwork> networks});
}

/// @nodoc
class __$$ExolixCoinImplCopyWithImpl<$Res> extends _$ExolixCoinCopyWithImpl<$Res, _$ExolixCoinImpl>
    implements _$$ExolixCoinImplCopyWith<$Res> {
  __$$ExolixCoinImplCopyWithImpl(_$ExolixCoinImpl _value, $Res Function(_$ExolixCoinImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExolixCoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? networks = null,
  }) {
    return _then(_$ExolixCoinImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      networks: null == networks
          ? _value._networks
          : networks // ignore: cast_nullable_to_non_nullable
              as List<ExolixNetwork>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExolixCoinImpl implements _ExolixCoin {
  _$ExolixCoinImpl(
      {required this.code, required this.name, required final List<ExolixNetwork> networks})
      : _networks = networks;

  factory _$ExolixCoinImpl.fromJson(Map<String, dynamic> json) => _$$ExolixCoinImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  final List<ExolixNetwork> _networks;
  @override
  List<ExolixNetwork> get networks {
    if (_networks is EqualUnmodifiableListView) return _networks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_networks);
  }

  @override
  String toString() {
    return 'ExolixCoin(code: $code, name: $name, networks: $networks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExolixCoinImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._networks, _networks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, code, name, const DeepCollectionEquality().hash(_networks));

  /// Create a copy of ExolixCoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExolixCoinImplCopyWith<_$ExolixCoinImpl> get copyWith =>
      __$$ExolixCoinImplCopyWithImpl<_$ExolixCoinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExolixCoinImplToJson(
      this,
    );
  }
}

abstract class _ExolixCoin implements ExolixCoin {
  factory _ExolixCoin(
      {required final String code,
      required final String name,
      required final List<ExolixNetwork> networks}) = _$ExolixCoinImpl;

  factory _ExolixCoin.fromJson(Map<String, dynamic> json) = _$ExolixCoinImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  List<ExolixNetwork> get networks;

  /// Create a copy of ExolixCoin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExolixCoinImplCopyWith<_$ExolixCoinImpl> get copyWith => throw _privateConstructorUsedError;
}
