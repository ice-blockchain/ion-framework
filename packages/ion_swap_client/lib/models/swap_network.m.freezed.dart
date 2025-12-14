// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_network.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapNetwork _$SwapNetworkFromJson(Map<String, dynamic> json) {
  return _SwapNetwork.fromJson(json);
}

/// @nodoc
mixin _$SwapNetwork {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this SwapNetwork to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapNetwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapNetworkCopyWith<SwapNetwork> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapNetworkCopyWith<$Res> {
  factory $SwapNetworkCopyWith(
          SwapNetwork value, $Res Function(SwapNetwork) then) =
      _$SwapNetworkCopyWithImpl<$Res, SwapNetwork>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$SwapNetworkCopyWithImpl<$Res, $Val extends SwapNetwork>
    implements $SwapNetworkCopyWith<$Res> {
  _$SwapNetworkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapNetwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwapNetworkImplCopyWith<$Res>
    implements $SwapNetworkCopyWith<$Res> {
  factory _$$SwapNetworkImplCopyWith(
          _$SwapNetworkImpl value, $Res Function(_$SwapNetworkImpl) then) =
      __$$SwapNetworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$SwapNetworkImplCopyWithImpl<$Res>
    extends _$SwapNetworkCopyWithImpl<$Res, _$SwapNetworkImpl>
    implements _$$SwapNetworkImplCopyWith<$Res> {
  __$$SwapNetworkImplCopyWithImpl(
      _$SwapNetworkImpl _value, $Res Function(_$SwapNetworkImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapNetwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$SwapNetworkImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapNetworkImpl implements _SwapNetwork {
  _$SwapNetworkImpl({required this.id, required this.name});

  factory _$SwapNetworkImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapNetworkImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'SwapNetwork(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapNetworkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of SwapNetwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapNetworkImplCopyWith<_$SwapNetworkImpl> get copyWith =>
      __$$SwapNetworkImplCopyWithImpl<_$SwapNetworkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapNetworkImplToJson(
      this,
    );
  }
}

abstract class _SwapNetwork implements SwapNetwork {
  factory _SwapNetwork({required final String id, required final String name}) =
      _$SwapNetworkImpl;

  factory _SwapNetwork.fromJson(Map<String, dynamic> json) =
      _$SwapNetworkImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of SwapNetwork
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapNetworkImplCopyWith<_$SwapNetworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
