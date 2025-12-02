// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'okx_api_response.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OkxApiResponse<T> _$OkxApiResponseFromJson<T>(
    Map<String, dynamic> json, T Function(Object?) fromJsonT) {
  return _OkxApiResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$OkxApiResponse<T> {
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'data')
  T get data => throw _privateConstructorUsedError;

  /// Serializes this OkxApiResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => throw _privateConstructorUsedError;

  /// Create a copy of OkxApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OkxApiResponseCopyWith<T, OkxApiResponse<T>> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OkxApiResponseCopyWith<T, $Res> {
  factory $OkxApiResponseCopyWith(OkxApiResponse<T> value, $Res Function(OkxApiResponse<T>) then) =
      _$OkxApiResponseCopyWithImpl<T, $Res, OkxApiResponse<T>>;
  @useResult
  $Res call({String code, @JsonKey(name: 'data') T data});
}

/// @nodoc
class _$OkxApiResponseCopyWithImpl<T, $Res, $Val extends OkxApiResponse<T>>
    implements $OkxApiResponseCopyWith<T, $Res> {
  _$OkxApiResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OkxApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? data = freezed,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as T,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OkxApiResponseImplCopyWith<T, $Res> implements $OkxApiResponseCopyWith<T, $Res> {
  factory _$$OkxApiResponseImplCopyWith(
          _$OkxApiResponseImpl<T> value, $Res Function(_$OkxApiResponseImpl<T>) then) =
      __$$OkxApiResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({String code, @JsonKey(name: 'data') T data});
}

/// @nodoc
class __$$OkxApiResponseImplCopyWithImpl<T, $Res>
    extends _$OkxApiResponseCopyWithImpl<T, $Res, _$OkxApiResponseImpl<T>>
    implements _$$OkxApiResponseImplCopyWith<T, $Res> {
  __$$OkxApiResponseImplCopyWithImpl(
      _$OkxApiResponseImpl<T> _value, $Res Function(_$OkxApiResponseImpl<T>) _then)
      : super(_value, _then);

  /// Create a copy of OkxApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? data = freezed,
  }) {
    return _then(_$OkxApiResponseImpl<T>(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as T,
    ));
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$OkxApiResponseImpl<T> implements _OkxApiResponse<T> {
  _$OkxApiResponseImpl({required this.code, @JsonKey(name: 'data') required this.data});

  factory _$OkxApiResponseImpl.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$$OkxApiResponseImplFromJson(json, fromJsonT);

  @override
  final String code;
  @override
  @JsonKey(name: 'data')
  final T data;

  @override
  String toString() {
    return 'OkxApiResponse<$T>(code: $code, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OkxApiResponseImpl<T> &&
            (identical(other.code, code) || other.code == code) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, const DeepCollectionEquality().hash(data));

  /// Create a copy of OkxApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OkxApiResponseImplCopyWith<T, _$OkxApiResponseImpl<T>> get copyWith =>
      __$$OkxApiResponseImplCopyWithImpl<T, _$OkxApiResponseImpl<T>>(this, _$identity);

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$OkxApiResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _OkxApiResponse<T> implements OkxApiResponse<T> {
  factory _OkxApiResponse(
      {required final String code,
      @JsonKey(name: 'data') required final T data}) = _$OkxApiResponseImpl<T>;

  factory _OkxApiResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =
      _$OkxApiResponseImpl<T>.fromJson;

  @override
  String get code;
  @override
  @JsonKey(name: 'data')
  T get data;

  /// Create a copy of OkxApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OkxApiResponseImplCopyWith<T, _$OkxApiResponseImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}
