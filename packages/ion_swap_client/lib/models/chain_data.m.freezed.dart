// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chain_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChainData _$ChainDataFromJson(Map<String, dynamic> json) {
  return _ChainData.fromJson(json);
}

/// @nodoc
mixin _$ChainData {
  String get name => throw _privateConstructorUsedError;
  int get networkId => throw _privateConstructorUsedError;

  /// Serializes this ChainData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChainData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChainDataCopyWith<ChainData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChainDataCopyWith<$Res> {
  factory $ChainDataCopyWith(ChainData value, $Res Function(ChainData) then) =
      _$ChainDataCopyWithImpl<$Res, ChainData>;
  @useResult
  $Res call({String name, int networkId});
}

/// @nodoc
class _$ChainDataCopyWithImpl<$Res, $Val extends ChainData>
    implements $ChainDataCopyWith<$Res> {
  _$ChainDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChainData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? networkId = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      networkId: null == networkId
          ? _value.networkId
          : networkId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChainDataImplCopyWith<$Res>
    implements $ChainDataCopyWith<$Res> {
  factory _$$ChainDataImplCopyWith(
          _$ChainDataImpl value, $Res Function(_$ChainDataImpl) then) =
      __$$ChainDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int networkId});
}

/// @nodoc
class __$$ChainDataImplCopyWithImpl<$Res>
    extends _$ChainDataCopyWithImpl<$Res, _$ChainDataImpl>
    implements _$$ChainDataImplCopyWith<$Res> {
  __$$ChainDataImplCopyWithImpl(
      _$ChainDataImpl _value, $Res Function(_$ChainDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChainData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? networkId = null,
  }) {
    return _then(_$ChainDataImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      networkId: null == networkId
          ? _value.networkId
          : networkId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChainDataImpl implements _ChainData {
  _$ChainDataImpl({required this.name, required this.networkId});

  factory _$ChainDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChainDataImplFromJson(json);

  @override
  final String name;
  @override
  final int networkId;

  @override
  String toString() {
    return 'ChainData(name: $name, networkId: $networkId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChainDataImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.networkId, networkId) ||
                other.networkId == networkId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, networkId);

  /// Create a copy of ChainData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChainDataImplCopyWith<_$ChainDataImpl> get copyWith =>
      __$$ChainDataImplCopyWithImpl<_$ChainDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChainDataImplToJson(
      this,
    );
  }
}

abstract class _ChainData implements ChainData {
  factory _ChainData(
      {required final String name,
      required final int networkId}) = _$ChainDataImpl;

  factory _ChainData.fromJson(Map<String, dynamic> json) =
      _$ChainDataImpl.fromJson;

  @override
  String get name;
  @override
  int get networkId;

  /// Create a copy of ChainData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChainDataImplCopyWith<_$ChainDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
