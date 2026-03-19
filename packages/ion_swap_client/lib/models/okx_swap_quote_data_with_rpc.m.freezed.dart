// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'okx_swap_quote_data_with_rpc.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OkxSwapQuoteDataWithRpc _$OkxSwapQuoteDataWithRpcFromJson(
    Map<String, dynamic> json) {
  return _OkxSwapQuoteDataWithRpc.fromJson(json);
}

/// @nodoc
mixin _$OkxSwapQuoteDataWithRpc {
  SwapQuoteData get swapQuoteData => throw _privateConstructorUsedError;
  String? get rpcUrl => throw _privateConstructorUsedError;

  /// Serializes this OkxSwapQuoteDataWithRpc to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OkxSwapQuoteDataWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OkxSwapQuoteDataWithRpcCopyWith<OkxSwapQuoteDataWithRpc> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OkxSwapQuoteDataWithRpcCopyWith<$Res> {
  factory $OkxSwapQuoteDataWithRpcCopyWith(OkxSwapQuoteDataWithRpc value,
          $Res Function(OkxSwapQuoteDataWithRpc) then) =
      _$OkxSwapQuoteDataWithRpcCopyWithImpl<$Res, OkxSwapQuoteDataWithRpc>;
  @useResult
  $Res call({SwapQuoteData swapQuoteData, String? rpcUrl});

  $SwapQuoteDataCopyWith<$Res> get swapQuoteData;
}

/// @nodoc
class _$OkxSwapQuoteDataWithRpcCopyWithImpl<$Res,
        $Val extends OkxSwapQuoteDataWithRpc>
    implements $OkxSwapQuoteDataWithRpcCopyWith<$Res> {
  _$OkxSwapQuoteDataWithRpcCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OkxSwapQuoteDataWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? swapQuoteData = null,
    Object? rpcUrl = freezed,
  }) {
    return _then(_value.copyWith(
      swapQuoteData: null == swapQuoteData
          ? _value.swapQuoteData
          : swapQuoteData // ignore: cast_nullable_to_non_nullable
              as SwapQuoteData,
      rpcUrl: freezed == rpcUrl
          ? _value.rpcUrl
          : rpcUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of OkxSwapQuoteDataWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SwapQuoteDataCopyWith<$Res> get swapQuoteData {
    return $SwapQuoteDataCopyWith<$Res>(_value.swapQuoteData, (value) {
      return _then(_value.copyWith(swapQuoteData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OkxSwapQuoteDataWithRpcImplCopyWith<$Res>
    implements $OkxSwapQuoteDataWithRpcCopyWith<$Res> {
  factory _$$OkxSwapQuoteDataWithRpcImplCopyWith(
          _$OkxSwapQuoteDataWithRpcImpl value,
          $Res Function(_$OkxSwapQuoteDataWithRpcImpl) then) =
      __$$OkxSwapQuoteDataWithRpcImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SwapQuoteData swapQuoteData, String? rpcUrl});

  @override
  $SwapQuoteDataCopyWith<$Res> get swapQuoteData;
}

/// @nodoc
class __$$OkxSwapQuoteDataWithRpcImplCopyWithImpl<$Res>
    extends _$OkxSwapQuoteDataWithRpcCopyWithImpl<$Res,
        _$OkxSwapQuoteDataWithRpcImpl>
    implements _$$OkxSwapQuoteDataWithRpcImplCopyWith<$Res> {
  __$$OkxSwapQuoteDataWithRpcImplCopyWithImpl(
      _$OkxSwapQuoteDataWithRpcImpl _value,
      $Res Function(_$OkxSwapQuoteDataWithRpcImpl) _then)
      : super(_value, _then);

  /// Create a copy of OkxSwapQuoteDataWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? swapQuoteData = null,
    Object? rpcUrl = freezed,
  }) {
    return _then(_$OkxSwapQuoteDataWithRpcImpl(
      swapQuoteData: null == swapQuoteData
          ? _value.swapQuoteData
          : swapQuoteData // ignore: cast_nullable_to_non_nullable
              as SwapQuoteData,
      rpcUrl: freezed == rpcUrl
          ? _value.rpcUrl
          : rpcUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OkxSwapQuoteDataWithRpcImpl implements _OkxSwapQuoteDataWithRpc {
  _$OkxSwapQuoteDataWithRpcImpl(
      {required this.swapQuoteData, required this.rpcUrl});

  factory _$OkxSwapQuoteDataWithRpcImpl.fromJson(Map<String, dynamic> json) =>
      _$$OkxSwapQuoteDataWithRpcImplFromJson(json);

  @override
  final SwapQuoteData swapQuoteData;
  @override
  final String? rpcUrl;

  @override
  String toString() {
    return 'OkxSwapQuoteDataWithRpc(swapQuoteData: $swapQuoteData, rpcUrl: $rpcUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OkxSwapQuoteDataWithRpcImpl &&
            (identical(other.swapQuoteData, swapQuoteData) ||
                other.swapQuoteData == swapQuoteData) &&
            (identical(other.rpcUrl, rpcUrl) || other.rpcUrl == rpcUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, swapQuoteData, rpcUrl);

  /// Create a copy of OkxSwapQuoteDataWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OkxSwapQuoteDataWithRpcImplCopyWith<_$OkxSwapQuoteDataWithRpcImpl>
      get copyWith => __$$OkxSwapQuoteDataWithRpcImplCopyWithImpl<
          _$OkxSwapQuoteDataWithRpcImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OkxSwapQuoteDataWithRpcImplToJson(
      this,
    );
  }
}

abstract class _OkxSwapQuoteDataWithRpc implements OkxSwapQuoteDataWithRpc {
  factory _OkxSwapQuoteDataWithRpc(
      {required final SwapQuoteData swapQuoteData,
      required final String? rpcUrl}) = _$OkxSwapQuoteDataWithRpcImpl;

  factory _OkxSwapQuoteDataWithRpc.fromJson(Map<String, dynamic> json) =
      _$OkxSwapQuoteDataWithRpcImpl.fromJson;

  @override
  SwapQuoteData get swapQuoteData;
  @override
  String? get rpcUrl;

  /// Create a copy of OkxSwapQuoteDataWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OkxSwapQuoteDataWithRpcImplCopyWith<_$OkxSwapQuoteDataWithRpcImpl>
      get copyWith => throw _privateConstructorUsedError;
}
