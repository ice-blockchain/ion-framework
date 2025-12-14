// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'okx_swap_response.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OkxSwapResponse _$OkxSwapResponseFromJson(Map<String, dynamic> json) {
  return _OkxSwapResponse.fromJson(json);
}

/// @nodoc
mixin _$OkxSwapResponse {
  OkxSwapTransaction get tx => throw _privateConstructorUsedError;

  /// Serializes this OkxSwapResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OkxSwapResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OkxSwapResponseCopyWith<OkxSwapResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OkxSwapResponseCopyWith<$Res> {
  factory $OkxSwapResponseCopyWith(
          OkxSwapResponse value, $Res Function(OkxSwapResponse) then) =
      _$OkxSwapResponseCopyWithImpl<$Res, OkxSwapResponse>;
  @useResult
  $Res call({OkxSwapTransaction tx});

  $OkxSwapTransactionCopyWith<$Res> get tx;
}

/// @nodoc
class _$OkxSwapResponseCopyWithImpl<$Res, $Val extends OkxSwapResponse>
    implements $OkxSwapResponseCopyWith<$Res> {
  _$OkxSwapResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OkxSwapResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tx = null,
  }) {
    return _then(_value.copyWith(
      tx: null == tx
          ? _value.tx
          : tx // ignore: cast_nullable_to_non_nullable
              as OkxSwapTransaction,
    ) as $Val);
  }

  /// Create a copy of OkxSwapResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OkxSwapTransactionCopyWith<$Res> get tx {
    return $OkxSwapTransactionCopyWith<$Res>(_value.tx, (value) {
      return _then(_value.copyWith(tx: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OkxSwapResponseImplCopyWith<$Res>
    implements $OkxSwapResponseCopyWith<$Res> {
  factory _$$OkxSwapResponseImplCopyWith(_$OkxSwapResponseImpl value,
          $Res Function(_$OkxSwapResponseImpl) then) =
      __$$OkxSwapResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({OkxSwapTransaction tx});

  @override
  $OkxSwapTransactionCopyWith<$Res> get tx;
}

/// @nodoc
class __$$OkxSwapResponseImplCopyWithImpl<$Res>
    extends _$OkxSwapResponseCopyWithImpl<$Res, _$OkxSwapResponseImpl>
    implements _$$OkxSwapResponseImplCopyWith<$Res> {
  __$$OkxSwapResponseImplCopyWithImpl(
      _$OkxSwapResponseImpl _value, $Res Function(_$OkxSwapResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of OkxSwapResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tx = null,
  }) {
    return _then(_$OkxSwapResponseImpl(
      tx: null == tx
          ? _value.tx
          : tx // ignore: cast_nullable_to_non_nullable
              as OkxSwapTransaction,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OkxSwapResponseImpl implements _OkxSwapResponse {
  _$OkxSwapResponseImpl({required this.tx});

  factory _$OkxSwapResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$OkxSwapResponseImplFromJson(json);

  @override
  final OkxSwapTransaction tx;

  @override
  String toString() {
    return 'OkxSwapResponse(tx: $tx)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OkxSwapResponseImpl &&
            (identical(other.tx, tx) || other.tx == tx));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tx);

  /// Create a copy of OkxSwapResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OkxSwapResponseImplCopyWith<_$OkxSwapResponseImpl> get copyWith =>
      __$$OkxSwapResponseImplCopyWithImpl<_$OkxSwapResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OkxSwapResponseImplToJson(
      this,
    );
  }
}

abstract class _OkxSwapResponse implements OkxSwapResponse {
  factory _OkxSwapResponse({required final OkxSwapTransaction tx}) =
      _$OkxSwapResponseImpl;

  factory _OkxSwapResponse.fromJson(Map<String, dynamic> json) =
      _$OkxSwapResponseImpl.fromJson;

  @override
  OkxSwapTransaction get tx;

  /// Create a copy of OkxSwapResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OkxSwapResponseImplCopyWith<_$OkxSwapResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
