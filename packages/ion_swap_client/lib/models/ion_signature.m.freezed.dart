// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ion_signature.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IonSignature _$IonSignatureFromJson(Map<String, dynamic> json) {
  return _IonSignature.fromJson(json);
}

/// @nodoc
mixin _$IonSignature {
  String get r => throw _privateConstructorUsedError;
  String get s => throw _privateConstructorUsedError;
  String? get encoded => throw _privateConstructorUsedError;

  /// Serializes this IonSignature to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IonSignature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IonSignatureCopyWith<IonSignature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IonSignatureCopyWith<$Res> {
  factory $IonSignatureCopyWith(
          IonSignature value, $Res Function(IonSignature) then) =
      _$IonSignatureCopyWithImpl<$Res, IonSignature>;
  @useResult
  $Res call({String r, String s, String? encoded});
}

/// @nodoc
class _$IonSignatureCopyWithImpl<$Res, $Val extends IonSignature>
    implements $IonSignatureCopyWith<$Res> {
  _$IonSignatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IonSignature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? r = null,
    Object? s = null,
    Object? encoded = freezed,
  }) {
    return _then(_value.copyWith(
      r: null == r
          ? _value.r
          : r // ignore: cast_nullable_to_non_nullable
              as String,
      s: null == s
          ? _value.s
          : s // ignore: cast_nullable_to_non_nullable
              as String,
      encoded: freezed == encoded
          ? _value.encoded
          : encoded // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IonSignatureImplCopyWith<$Res>
    implements $IonSignatureCopyWith<$Res> {
  factory _$$IonSignatureImplCopyWith(
          _$IonSignatureImpl value, $Res Function(_$IonSignatureImpl) then) =
      __$$IonSignatureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String r, String s, String? encoded});
}

/// @nodoc
class __$$IonSignatureImplCopyWithImpl<$Res>
    extends _$IonSignatureCopyWithImpl<$Res, _$IonSignatureImpl>
    implements _$$IonSignatureImplCopyWith<$Res> {
  __$$IonSignatureImplCopyWithImpl(
      _$IonSignatureImpl _value, $Res Function(_$IonSignatureImpl) _then)
      : super(_value, _then);

  /// Create a copy of IonSignature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? r = null,
    Object? s = null,
    Object? encoded = freezed,
  }) {
    return _then(_$IonSignatureImpl(
      r: null == r
          ? _value.r
          : r // ignore: cast_nullable_to_non_nullable
              as String,
      s: null == s
          ? _value.s
          : s // ignore: cast_nullable_to_non_nullable
              as String,
      encoded: freezed == encoded
          ? _value.encoded
          : encoded // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IonSignatureImpl implements _IonSignature {
  _$IonSignatureImpl({required this.r, required this.s, required this.encoded});

  factory _$IonSignatureImpl.fromJson(Map<String, dynamic> json) =>
      _$$IonSignatureImplFromJson(json);

  @override
  final String r;
  @override
  final String s;
  @override
  final String? encoded;

  @override
  String toString() {
    return 'IonSignature(r: $r, s: $s, encoded: $encoded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IonSignatureImpl &&
            (identical(other.r, r) || other.r == r) &&
            (identical(other.s, s) || other.s == s) &&
            (identical(other.encoded, encoded) || other.encoded == encoded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, r, s, encoded);

  /// Create a copy of IonSignature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IonSignatureImplCopyWith<_$IonSignatureImpl> get copyWith =>
      __$$IonSignatureImplCopyWithImpl<_$IonSignatureImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IonSignatureImplToJson(
      this,
    );
  }
}

abstract class _IonSignature implements IonSignature {
  factory _IonSignature(
      {required final String r,
      required final String s,
      required final String? encoded}) = _$IonSignatureImpl;

  factory _IonSignature.fromJson(Map<String, dynamic> json) =
      _$IonSignatureImpl.fromJson;

  @override
  String get r;
  @override
  String get s;
  @override
  String? get encoded;

  /// Create a copy of IonSignature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IonSignatureImplCopyWith<_$IonSignatureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
