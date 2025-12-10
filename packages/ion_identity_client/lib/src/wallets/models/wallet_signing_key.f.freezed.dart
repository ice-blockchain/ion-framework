// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_signing_key.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletSigningKey _$WalletSigningKeyFromJson(Map<String, dynamic> json) {
  return _WalletSigningKey.fromJson(json);
}

/// @nodoc
mixin _$WalletSigningKey {
  String get scheme => throw _privateConstructorUsedError;
  String get curve => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;
  String get id => throw _privateConstructorUsedError;

  /// Serializes this WalletSigningKey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletSigningKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletSigningKeyCopyWith<WalletSigningKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletSigningKeyCopyWith<$Res> {
  factory $WalletSigningKeyCopyWith(
          WalletSigningKey value, $Res Function(WalletSigningKey) then) =
      _$WalletSigningKeyCopyWithImpl<$Res, WalletSigningKey>;
  @useResult
  $Res call({String scheme, String curve, String publicKey, String id});
}

/// @nodoc
class _$WalletSigningKeyCopyWithImpl<$Res, $Val extends WalletSigningKey>
    implements $WalletSigningKeyCopyWith<$Res> {
  _$WalletSigningKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletSigningKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scheme = null,
    Object? curve = null,
    Object? publicKey = null,
    Object? id = null,
  }) {
    return _then(_value.copyWith(
      scheme: null == scheme
          ? _value.scheme
          : scheme // ignore: cast_nullable_to_non_nullable
              as String,
      curve: null == curve
          ? _value.curve
          : curve // ignore: cast_nullable_to_non_nullable
              as String,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletSigningKeyImplCopyWith<$Res>
    implements $WalletSigningKeyCopyWith<$Res> {
  factory _$$WalletSigningKeyImplCopyWith(_$WalletSigningKeyImpl value,
          $Res Function(_$WalletSigningKeyImpl) then) =
      __$$WalletSigningKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String scheme, String curve, String publicKey, String id});
}

/// @nodoc
class __$$WalletSigningKeyImplCopyWithImpl<$Res>
    extends _$WalletSigningKeyCopyWithImpl<$Res, _$WalletSigningKeyImpl>
    implements _$$WalletSigningKeyImplCopyWith<$Res> {
  __$$WalletSigningKeyImplCopyWithImpl(_$WalletSigningKeyImpl _value,
      $Res Function(_$WalletSigningKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletSigningKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scheme = null,
    Object? curve = null,
    Object? publicKey = null,
    Object? id = null,
  }) {
    return _then(_$WalletSigningKeyImpl(
      scheme: null == scheme
          ? _value.scheme
          : scheme // ignore: cast_nullable_to_non_nullable
              as String,
      curve: null == curve
          ? _value.curve
          : curve // ignore: cast_nullable_to_non_nullable
              as String,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletSigningKeyImpl implements _WalletSigningKey {
  _$WalletSigningKeyImpl(
      {required this.scheme,
      required this.curve,
      required this.publicKey,
      required this.id});

  factory _$WalletSigningKeyImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletSigningKeyImplFromJson(json);

  @override
  final String scheme;
  @override
  final String curve;
  @override
  final String publicKey;
  @override
  final String id;

  @override
  String toString() {
    return 'WalletSigningKey(scheme: $scheme, curve: $curve, publicKey: $publicKey, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletSigningKeyImpl &&
            (identical(other.scheme, scheme) || other.scheme == scheme) &&
            (identical(other.curve, curve) || other.curve == curve) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, scheme, curve, publicKey, id);

  /// Create a copy of WalletSigningKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletSigningKeyImplCopyWith<_$WalletSigningKeyImpl> get copyWith =>
      __$$WalletSigningKeyImplCopyWithImpl<_$WalletSigningKeyImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletSigningKeyImplToJson(
      this,
    );
  }
}

abstract class _WalletSigningKey implements WalletSigningKey {
  factory _WalletSigningKey(
      {required final String scheme,
      required final String curve,
      required final String publicKey,
      required final String id}) = _$WalletSigningKeyImpl;

  factory _WalletSigningKey.fromJson(Map<String, dynamic> json) =
      _$WalletSigningKeyImpl.fromJson;

  @override
  String get scheme;
  @override
  String get curve;
  @override
  String get publicKey;
  @override
  String get id;

  /// Create a copy of WalletSigningKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletSigningKeyImplCopyWith<_$WalletSigningKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
