// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'get_wallet_history_request_params.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GetWalletHistoryRequestParams _$GetWalletHistoryRequestParamsFromJson(
    Map<String, dynamic> json) {
  return _GetWalletHistoryRequestParams.fromJson(json);
}

/// @nodoc
mixin _$GetWalletHistoryRequestParams {
  @JsonKey(includeFromJson: false, includeToJson: true)
  int? get limit => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: true)
  String? get paginationToken => throw _privateConstructorUsedError;

  /// Serializes this GetWalletHistoryRequestParams to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GetWalletHistoryRequestParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GetWalletHistoryRequestParamsCopyWith<GetWalletHistoryRequestParams>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GetWalletHistoryRequestParamsCopyWith<$Res> {
  factory $GetWalletHistoryRequestParamsCopyWith(
          GetWalletHistoryRequestParams value,
          $Res Function(GetWalletHistoryRequestParams) then) =
      _$GetWalletHistoryRequestParamsCopyWithImpl<$Res,
          GetWalletHistoryRequestParams>;
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: true) int? limit,
      @JsonKey(includeFromJson: false, includeToJson: true)
      String? paginationToken});
}

/// @nodoc
class _$GetWalletHistoryRequestParamsCopyWithImpl<$Res,
        $Val extends GetWalletHistoryRequestParams>
    implements $GetWalletHistoryRequestParamsCopyWith<$Res> {
  _$GetWalletHistoryRequestParamsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GetWalletHistoryRequestParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? limit = freezed,
    Object? paginationToken = freezed,
  }) {
    return _then(_value.copyWith(
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      paginationToken: freezed == paginationToken
          ? _value.paginationToken
          : paginationToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GetWalletHistoryRequestParamsImplCopyWith<$Res>
    implements $GetWalletHistoryRequestParamsCopyWith<$Res> {
  factory _$$GetWalletHistoryRequestParamsImplCopyWith(
          _$GetWalletHistoryRequestParamsImpl value,
          $Res Function(_$GetWalletHistoryRequestParamsImpl) then) =
      __$$GetWalletHistoryRequestParamsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: true) int? limit,
      @JsonKey(includeFromJson: false, includeToJson: true)
      String? paginationToken});
}

/// @nodoc
class __$$GetWalletHistoryRequestParamsImplCopyWithImpl<$Res>
    extends _$GetWalletHistoryRequestParamsCopyWithImpl<$Res,
        _$GetWalletHistoryRequestParamsImpl>
    implements _$$GetWalletHistoryRequestParamsImplCopyWith<$Res> {
  __$$GetWalletHistoryRequestParamsImplCopyWithImpl(
      _$GetWalletHistoryRequestParamsImpl _value,
      $Res Function(_$GetWalletHistoryRequestParamsImpl) _then)
      : super(_value, _then);

  /// Create a copy of GetWalletHistoryRequestParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? limit = freezed,
    Object? paginationToken = freezed,
  }) {
    return _then(_$GetWalletHistoryRequestParamsImpl(
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      paginationToken: freezed == paginationToken
          ? _value.paginationToken
          : paginationToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GetWalletHistoryRequestParamsImpl
    implements _GetWalletHistoryRequestParams {
  const _$GetWalletHistoryRequestParamsImpl(
      {@JsonKey(includeFromJson: false, includeToJson: true) this.limit,
      @JsonKey(includeFromJson: false, includeToJson: true)
      this.paginationToken});

  factory _$GetWalletHistoryRequestParamsImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$GetWalletHistoryRequestParamsImplFromJson(json);

  @override
  @JsonKey(includeFromJson: false, includeToJson: true)
  final int? limit;
  @override
  @JsonKey(includeFromJson: false, includeToJson: true)
  final String? paginationToken;

  @override
  String toString() {
    return 'GetWalletHistoryRequestParams(limit: $limit, paginationToken: $paginationToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetWalletHistoryRequestParamsImpl &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.paginationToken, paginationToken) ||
                other.paginationToken == paginationToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, limit, paginationToken);

  /// Create a copy of GetWalletHistoryRequestParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetWalletHistoryRequestParamsImplCopyWith<
          _$GetWalletHistoryRequestParamsImpl>
      get copyWith => __$$GetWalletHistoryRequestParamsImplCopyWithImpl<
          _$GetWalletHistoryRequestParamsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GetWalletHistoryRequestParamsImplToJson(
      this,
    );
  }
}

abstract class _GetWalletHistoryRequestParams
    implements GetWalletHistoryRequestParams {
  const factory _GetWalletHistoryRequestParams(
      {@JsonKey(includeFromJson: false, includeToJson: true) final int? limit,
      @JsonKey(includeFromJson: false, includeToJson: true)
      final String? paginationToken}) = _$GetWalletHistoryRequestParamsImpl;

  factory _GetWalletHistoryRequestParams.fromJson(Map<String, dynamic> json) =
      _$GetWalletHistoryRequestParamsImpl.fromJson;

  @override
  @JsonKey(includeFromJson: false, includeToJson: true)
  int? get limit;
  @override
  @JsonKey(includeFromJson: false, includeToJson: true)
  String? get paginationToken;

  /// Create a copy of GetWalletHistoryRequestParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetWalletHistoryRequestParamsImplCopyWith<
          _$GetWalletHistoryRequestParamsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
