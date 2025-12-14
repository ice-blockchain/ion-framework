// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exolix_network.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExolixNetwork _$ExolixNetworkFromJson(Map<String, dynamic> json) {
  return _ExolixNetwork.fromJson(json);
}

/// @nodoc
mixin _$ExolixNetwork {
  String get network => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get shortName => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  String? get contract => throw _privateConstructorUsedError;

  /// Serializes this ExolixNetwork to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExolixNetwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExolixNetworkCopyWith<ExolixNetwork> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExolixNetworkCopyWith<$Res> {
  factory $ExolixNetworkCopyWith(
          ExolixNetwork value, $Res Function(ExolixNetwork) then) =
      _$ExolixNetworkCopyWithImpl<$Res, ExolixNetwork>;
  @useResult
  $Res call(
      {String network,
      String name,
      String shortName,
      bool isDefault,
      String? contract});
}

/// @nodoc
class _$ExolixNetworkCopyWithImpl<$Res, $Val extends ExolixNetwork>
    implements $ExolixNetworkCopyWith<$Res> {
  _$ExolixNetworkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExolixNetwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? network = null,
    Object? name = null,
    Object? shortName = null,
    Object? isDefault = null,
    Object? contract = freezed,
  }) {
    return _then(_value.copyWith(
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shortName: null == shortName
          ? _value.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      contract: freezed == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExolixNetworkImplCopyWith<$Res>
    implements $ExolixNetworkCopyWith<$Res> {
  factory _$$ExolixNetworkImplCopyWith(
          _$ExolixNetworkImpl value, $Res Function(_$ExolixNetworkImpl) then) =
      __$$ExolixNetworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String network,
      String name,
      String shortName,
      bool isDefault,
      String? contract});
}

/// @nodoc
class __$$ExolixNetworkImplCopyWithImpl<$Res>
    extends _$ExolixNetworkCopyWithImpl<$Res, _$ExolixNetworkImpl>
    implements _$$ExolixNetworkImplCopyWith<$Res> {
  __$$ExolixNetworkImplCopyWithImpl(
      _$ExolixNetworkImpl _value, $Res Function(_$ExolixNetworkImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExolixNetwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? network = null,
    Object? name = null,
    Object? shortName = null,
    Object? isDefault = null,
    Object? contract = freezed,
  }) {
    return _then(_$ExolixNetworkImpl(
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shortName: null == shortName
          ? _value.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      contract: freezed == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExolixNetworkImpl implements _ExolixNetwork {
  _$ExolixNetworkImpl(
      {required this.network,
      required this.name,
      required this.shortName,
      required this.isDefault,
      required this.contract});

  factory _$ExolixNetworkImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExolixNetworkImplFromJson(json);

  @override
  final String network;
  @override
  final String name;
  @override
  final String shortName;
  @override
  final bool isDefault;
  @override
  final String? contract;

  @override
  String toString() {
    return 'ExolixNetwork(network: $network, name: $name, shortName: $shortName, isDefault: $isDefault, contract: $contract)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExolixNetworkImpl &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.contract, contract) ||
                other.contract == contract));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, network, name, shortName, isDefault, contract);

  /// Create a copy of ExolixNetwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExolixNetworkImplCopyWith<_$ExolixNetworkImpl> get copyWith =>
      __$$ExolixNetworkImplCopyWithImpl<_$ExolixNetworkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExolixNetworkImplToJson(
      this,
    );
  }
}

abstract class _ExolixNetwork implements ExolixNetwork {
  factory _ExolixNetwork(
      {required final String network,
      required final String name,
      required final String shortName,
      required final bool isDefault,
      required final String? contract}) = _$ExolixNetworkImpl;

  factory _ExolixNetwork.fromJson(Map<String, dynamic> json) =
      _$ExolixNetworkImpl.fromJson;

  @override
  String get network;
  @override
  String get name;
  @override
  String get shortName;
  @override
  bool get isDefault;
  @override
  String? get contract;

  /// Create a copy of ExolixNetwork
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExolixNetworkImplCopyWith<_$ExolixNetworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
