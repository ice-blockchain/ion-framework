// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_quote_with_rpc.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayQuoteWithRpc _$RelayQuoteWithRpcFromJson(Map<String, dynamic> json) {
  return _RelayQuoteWithRpc.fromJson(json);
}

/// @nodoc
mixin _$RelayQuoteWithRpc {
  RelayQuote get details => throw _privateConstructorUsedError;
  String get rpcUrl => throw _privateConstructorUsedError;

  /// Serializes this RelayQuoteWithRpc to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayQuoteWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayQuoteWithRpcCopyWith<RelayQuoteWithRpc> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayQuoteWithRpcCopyWith<$Res> {
  factory $RelayQuoteWithRpcCopyWith(
          RelayQuoteWithRpc value, $Res Function(RelayQuoteWithRpc) then) =
      _$RelayQuoteWithRpcCopyWithImpl<$Res, RelayQuoteWithRpc>;
  @useResult
  $Res call({RelayQuote details, String rpcUrl});

  $RelayQuoteCopyWith<$Res> get details;
}

/// @nodoc
class _$RelayQuoteWithRpcCopyWithImpl<$Res, $Val extends RelayQuoteWithRpc>
    implements $RelayQuoteWithRpcCopyWith<$Res> {
  _$RelayQuoteWithRpcCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayQuoteWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? details = null,
    Object? rpcUrl = null,
  }) {
    return _then(_value.copyWith(
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as RelayQuote,
      rpcUrl: null == rpcUrl
          ? _value.rpcUrl
          : rpcUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of RelayQuoteWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelayQuoteCopyWith<$Res> get details {
    return $RelayQuoteCopyWith<$Res>(_value.details, (value) {
      return _then(_value.copyWith(details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RelayQuoteWithRpcImplCopyWith<$Res>
    implements $RelayQuoteWithRpcCopyWith<$Res> {
  factory _$$RelayQuoteWithRpcImplCopyWith(_$RelayQuoteWithRpcImpl value,
          $Res Function(_$RelayQuoteWithRpcImpl) then) =
      __$$RelayQuoteWithRpcImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RelayQuote details, String rpcUrl});

  @override
  $RelayQuoteCopyWith<$Res> get details;
}

/// @nodoc
class __$$RelayQuoteWithRpcImplCopyWithImpl<$Res>
    extends _$RelayQuoteWithRpcCopyWithImpl<$Res, _$RelayQuoteWithRpcImpl>
    implements _$$RelayQuoteWithRpcImplCopyWith<$Res> {
  __$$RelayQuoteWithRpcImplCopyWithImpl(_$RelayQuoteWithRpcImpl _value,
      $Res Function(_$RelayQuoteWithRpcImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayQuoteWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? details = null,
    Object? rpcUrl = null,
  }) {
    return _then(_$RelayQuoteWithRpcImpl(
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as RelayQuote,
      rpcUrl: null == rpcUrl
          ? _value.rpcUrl
          : rpcUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayQuoteWithRpcImpl implements _RelayQuoteWithRpc {
  _$RelayQuoteWithRpcImpl({required this.details, required this.rpcUrl});

  factory _$RelayQuoteWithRpcImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayQuoteWithRpcImplFromJson(json);

  @override
  final RelayQuote details;
  @override
  final String rpcUrl;

  @override
  String toString() {
    return 'RelayQuoteWithRpc(details: $details, rpcUrl: $rpcUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayQuoteWithRpcImpl &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.rpcUrl, rpcUrl) || other.rpcUrl == rpcUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, details, rpcUrl);

  /// Create a copy of RelayQuoteWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayQuoteWithRpcImplCopyWith<_$RelayQuoteWithRpcImpl> get copyWith =>
      __$$RelayQuoteWithRpcImplCopyWithImpl<_$RelayQuoteWithRpcImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayQuoteWithRpcImplToJson(
      this,
    );
  }
}

abstract class _RelayQuoteWithRpc implements RelayQuoteWithRpc {
  factory _RelayQuoteWithRpc(
      {required final RelayQuote details,
      required final String rpcUrl}) = _$RelayQuoteWithRpcImpl;

  factory _RelayQuoteWithRpc.fromJson(Map<String, dynamic> json) =
      _$RelayQuoteWithRpcImpl.fromJson;

  @override
  RelayQuote get details;
  @override
  String get rpcUrl;

  /// Create a copy of RelayQuoteWithRpc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayQuoteWithRpcImplCopyWith<_$RelayQuoteWithRpcImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
