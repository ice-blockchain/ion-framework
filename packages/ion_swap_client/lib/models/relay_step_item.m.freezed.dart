// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_step_item.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayStepItem _$RelayStepItemFromJson(Map<String, dynamic> json) {
  return _RelayStepItem.fromJson(json);
}

/// @nodoc
mixin _$RelayStepItem {
  RelayStepItemData get data => throw _privateConstructorUsedError;

  /// Serializes this RelayStepItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayStepItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayStepItemCopyWith<RelayStepItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayStepItemCopyWith<$Res> {
  factory $RelayStepItemCopyWith(
          RelayStepItem value, $Res Function(RelayStepItem) then) =
      _$RelayStepItemCopyWithImpl<$Res, RelayStepItem>;
  @useResult
  $Res call({RelayStepItemData data});

  $RelayStepItemDataCopyWith<$Res> get data;
}

/// @nodoc
class _$RelayStepItemCopyWithImpl<$Res, $Val extends RelayStepItem>
    implements $RelayStepItemCopyWith<$Res> {
  _$RelayStepItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayStepItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as RelayStepItemData,
    ) as $Val);
  }

  /// Create a copy of RelayStepItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelayStepItemDataCopyWith<$Res> get data {
    return $RelayStepItemDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RelayStepItemImplCopyWith<$Res>
    implements $RelayStepItemCopyWith<$Res> {
  factory _$$RelayStepItemImplCopyWith(
          _$RelayStepItemImpl value, $Res Function(_$RelayStepItemImpl) then) =
      __$$RelayStepItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RelayStepItemData data});

  @override
  $RelayStepItemDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$RelayStepItemImplCopyWithImpl<$Res>
    extends _$RelayStepItemCopyWithImpl<$Res, _$RelayStepItemImpl>
    implements _$$RelayStepItemImplCopyWith<$Res> {
  __$$RelayStepItemImplCopyWithImpl(
      _$RelayStepItemImpl _value, $Res Function(_$RelayStepItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayStepItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
  }) {
    return _then(_$RelayStepItemImpl(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as RelayStepItemData,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayStepItemImpl implements _RelayStepItem {
  _$RelayStepItemImpl({required this.data});

  factory _$RelayStepItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayStepItemImplFromJson(json);

  @override
  final RelayStepItemData data;

  @override
  String toString() {
    return 'RelayStepItem(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayStepItemImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of RelayStepItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayStepItemImplCopyWith<_$RelayStepItemImpl> get copyWith =>
      __$$RelayStepItemImplCopyWithImpl<_$RelayStepItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayStepItemImplToJson(
      this,
    );
  }
}

abstract class _RelayStepItem implements RelayStepItem {
  factory _RelayStepItem({required final RelayStepItemData data}) =
      _$RelayStepItemImpl;

  factory _RelayStepItem.fromJson(Map<String, dynamic> json) =
      _$RelayStepItemImpl.fromJson;

  @override
  RelayStepItemData get data;

  /// Create a copy of RelayStepItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayStepItemImplCopyWith<_$RelayStepItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
