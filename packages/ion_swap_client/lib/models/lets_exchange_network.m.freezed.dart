// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lets_exchange_network.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LetsExchangeNetwork _$LetsExchangeNetworkFromJson(Map<String, dynamic> json) {
  return _LetsExchangeNetwork.fromJson(json);
}

/// @nodoc
mixin _$LetsExchangeNetwork {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  int get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'contract_address')
  String? get contractAddress => throw _privateConstructorUsedError;

  /// Serializes this LetsExchangeNetwork to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LetsExchangeNetwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LetsExchangeNetworkCopyWith<LetsExchangeNetwork> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LetsExchangeNetworkCopyWith<$Res> {
  factory $LetsExchangeNetworkCopyWith(
          LetsExchangeNetwork value, $Res Function(LetsExchangeNetwork) then) =
      _$LetsExchangeNetworkCopyWithImpl<$Res, LetsExchangeNetwork>;
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'is_active') int isActive,
      @JsonKey(name: 'contract_address') String? contractAddress});
}

/// @nodoc
class _$LetsExchangeNetworkCopyWithImpl<$Res, $Val extends LetsExchangeNetwork>
    implements $LetsExchangeNetworkCopyWith<$Res> {
  _$LetsExchangeNetworkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LetsExchangeNetwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? isActive = null,
    Object? contractAddress = freezed,
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
      contractAddress: freezed == contractAddress
          ? _value.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LetsExchangeNetworkImplCopyWith<$Res>
    implements $LetsExchangeNetworkCopyWith<$Res> {
  factory _$$LetsExchangeNetworkImplCopyWith(_$LetsExchangeNetworkImpl value,
          $Res Function(_$LetsExchangeNetworkImpl) then) =
      __$$LetsExchangeNetworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      String name,
      @JsonKey(name: 'is_active') int isActive,
      @JsonKey(name: 'contract_address') String? contractAddress});
}

/// @nodoc
class __$$LetsExchangeNetworkImplCopyWithImpl<$Res>
    extends _$LetsExchangeNetworkCopyWithImpl<$Res, _$LetsExchangeNetworkImpl>
    implements _$$LetsExchangeNetworkImplCopyWith<$Res> {
  __$$LetsExchangeNetworkImplCopyWithImpl(_$LetsExchangeNetworkImpl _value,
      $Res Function(_$LetsExchangeNetworkImpl) _then)
      : super(_value, _then);

  /// Create a copy of LetsExchangeNetwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? isActive = null,
    Object? contractAddress = freezed,
  }) {
    return _then(_$LetsExchangeNetworkImpl(
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
      contractAddress: freezed == contractAddress
          ? _value.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LetsExchangeNetworkImpl implements _LetsExchangeNetwork {
  _$LetsExchangeNetworkImpl(
      {required this.code,
      required this.name,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'contract_address') required this.contractAddress});

  factory _$LetsExchangeNetworkImpl.fromJson(Map<String, dynamic> json) =>
      _$$LetsExchangeNetworkImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  @override
  @JsonKey(name: 'is_active')
  final int isActive;
  @override
  @JsonKey(name: 'contract_address')
  final String? contractAddress;

  @override
  String toString() {
    return 'LetsExchangeNetwork(code: $code, name: $name, isActive: $isActive, contractAddress: $contractAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LetsExchangeNetworkImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.contractAddress, contractAddress) ||
                other.contractAddress == contractAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, code, name, isActive, contractAddress);

  /// Create a copy of LetsExchangeNetwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LetsExchangeNetworkImplCopyWith<_$LetsExchangeNetworkImpl> get copyWith =>
      __$$LetsExchangeNetworkImplCopyWithImpl<_$LetsExchangeNetworkImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LetsExchangeNetworkImplToJson(
      this,
    );
  }
}

abstract class _LetsExchangeNetwork implements LetsExchangeNetwork {
  factory _LetsExchangeNetwork(
      {required final String code,
      required final String name,
      @JsonKey(name: 'is_active') required final int isActive,
      @JsonKey(name: 'contract_address')
      required final String? contractAddress}) = _$LetsExchangeNetworkImpl;

  factory _LetsExchangeNetwork.fromJson(Map<String, dynamic> json) =
      _$LetsExchangeNetworkImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  @JsonKey(name: 'is_active')
  int get isActive;
  @override
  @JsonKey(name: 'contract_address')
  String? get contractAddress;

  /// Create a copy of LetsExchangeNetwork
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LetsExchangeNetworkImplCopyWith<_$LetsExchangeNetworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
