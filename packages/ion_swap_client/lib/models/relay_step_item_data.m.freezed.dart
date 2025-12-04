// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_step_item_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayStepItemData _$RelayStepItemDataFromJson(Map<String, dynamic> json) {
  return _RelayStepItemData.fromJson(json);
}

/// @nodoc
mixin _$RelayStepItemData {
  String get to => throw _privateConstructorUsedError;

  /// Serializes this RelayStepItemData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayStepItemData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayStepItemDataCopyWith<RelayStepItemData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayStepItemDataCopyWith<$Res> {
  factory $RelayStepItemDataCopyWith(
          RelayStepItemData value, $Res Function(RelayStepItemData) then) =
      _$RelayStepItemDataCopyWithImpl<$Res, RelayStepItemData>;
  @useResult
  $Res call({String to});
}

/// @nodoc
class _$RelayStepItemDataCopyWithImpl<$Res, $Val extends RelayStepItemData>
    implements $RelayStepItemDataCopyWith<$Res> {
  _$RelayStepItemDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayStepItemData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
  }) {
    return _then(_value.copyWith(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelayStepItemDataImplCopyWith<$Res>
    implements $RelayStepItemDataCopyWith<$Res> {
  factory _$$RelayStepItemDataImplCopyWith(_$RelayStepItemDataImpl value,
          $Res Function(_$RelayStepItemDataImpl) then) =
      __$$RelayStepItemDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String to});
}

/// @nodoc
class __$$RelayStepItemDataImplCopyWithImpl<$Res>
    extends _$RelayStepItemDataCopyWithImpl<$Res, _$RelayStepItemDataImpl>
    implements _$$RelayStepItemDataImplCopyWith<$Res> {
  __$$RelayStepItemDataImplCopyWithImpl(_$RelayStepItemDataImpl _value,
      $Res Function(_$RelayStepItemDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayStepItemData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
  }) {
    return _then(_$RelayStepItemDataImpl(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayStepItemDataImpl implements _RelayStepItemData {
  _$RelayStepItemDataImpl({required this.to});

  factory _$RelayStepItemDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayStepItemDataImplFromJson(json);

  @override
  final String to;

  @override
  String toString() {
    return 'RelayStepItemData(to: $to)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayStepItemDataImpl &&
            (identical(other.to, to) || other.to == to));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, to);

  /// Create a copy of RelayStepItemData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayStepItemDataImplCopyWith<_$RelayStepItemDataImpl> get copyWith =>
      __$$RelayStepItemDataImplCopyWithImpl<_$RelayStepItemDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayStepItemDataImplToJson(
      this,
    );
  }
}

abstract class _RelayStepItemData implements RelayStepItemData {
  factory _RelayStepItemData({required final String to}) =
      _$RelayStepItemDataImpl;

  factory _RelayStepItemData.fromJson(Map<String, dynamic> json) =
      _$RelayStepItemDataImpl.fromJson;

  @override
  String get to;

  /// Create a copy of RelayStepItemData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayStepItemDataImplCopyWith<_$RelayStepItemDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
