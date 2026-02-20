// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_token_analytics_response.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommunityTokenAnalyticsResponse _$CommunityTokenAnalyticsResponseFromJson(
  Map<String, dynamic> json,
) {
  return _CommunityTokenAnalyticsResponse.fromJson(json);
}

/// @nodoc
mixin _$CommunityTokenAnalyticsResponse {
  int get launched => throw _privateConstructorUsedError;
  int get migrated => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  /// Serializes this CommunityTokenAnalyticsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunityTokenAnalyticsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityTokenAnalyticsResponseCopyWith<CommunityTokenAnalyticsResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityTokenAnalyticsResponseCopyWith<$Res> {
  factory $CommunityTokenAnalyticsResponseCopyWith(
    CommunityTokenAnalyticsResponse value,
    $Res Function(CommunityTokenAnalyticsResponse) then,
  ) =
      _$CommunityTokenAnalyticsResponseCopyWithImpl<
        $Res,
        CommunityTokenAnalyticsResponse
      >;
  @useResult
  $Res call({int launched, int migrated, double volume});
}

/// @nodoc
class _$CommunityTokenAnalyticsResponseCopyWithImpl<
  $Res,
  $Val extends CommunityTokenAnalyticsResponse
>
    implements $CommunityTokenAnalyticsResponseCopyWith<$Res> {
  _$CommunityTokenAnalyticsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityTokenAnalyticsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? launched = null,
    Object? migrated = null,
    Object? volume = null,
  }) {
    return _then(
      _value.copyWith(
            launched: null == launched
                ? _value.launched
                : launched // ignore: cast_nullable_to_non_nullable
                      as int,
            migrated: null == migrated
                ? _value.migrated
                : migrated // ignore: cast_nullable_to_non_nullable
                      as int,
            volume: null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommunityTokenAnalyticsResponseImplCopyWith<$Res>
    implements $CommunityTokenAnalyticsResponseCopyWith<$Res> {
  factory _$$CommunityTokenAnalyticsResponseImplCopyWith(
    _$CommunityTokenAnalyticsResponseImpl value,
    $Res Function(_$CommunityTokenAnalyticsResponseImpl) then,
  ) = __$$CommunityTokenAnalyticsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int launched, int migrated, double volume});
}

/// @nodoc
class __$$CommunityTokenAnalyticsResponseImplCopyWithImpl<$Res>
    extends
        _$CommunityTokenAnalyticsResponseCopyWithImpl<
          $Res,
          _$CommunityTokenAnalyticsResponseImpl
        >
    implements _$$CommunityTokenAnalyticsResponseImplCopyWith<$Res> {
  __$$CommunityTokenAnalyticsResponseImplCopyWithImpl(
    _$CommunityTokenAnalyticsResponseImpl _value,
    $Res Function(_$CommunityTokenAnalyticsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunityTokenAnalyticsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? launched = null,
    Object? migrated = null,
    Object? volume = null,
  }) {
    return _then(
      _$CommunityTokenAnalyticsResponseImpl(
        launched: null == launched
            ? _value.launched
            : launched // ignore: cast_nullable_to_non_nullable
                  as int,
        migrated: null == migrated
            ? _value.migrated
            : migrated // ignore: cast_nullable_to_non_nullable
                  as int,
        volume: null == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommunityTokenAnalyticsResponseImpl
    implements _CommunityTokenAnalyticsResponse {
  const _$CommunityTokenAnalyticsResponseImpl({
    this.launched = 0,
    this.migrated = 0,
    this.volume = 0.0,
  });

  factory _$CommunityTokenAnalyticsResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$CommunityTokenAnalyticsResponseImplFromJson(json);

  @override
  @JsonKey()
  final int launched;
  @override
  @JsonKey()
  final int migrated;
  @override
  @JsonKey()
  final double volume;

  @override
  String toString() {
    return 'CommunityTokenAnalyticsResponse(launched: $launched, migrated: $migrated, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunityTokenAnalyticsResponseImpl &&
            (identical(other.launched, launched) ||
                other.launched == launched) &&
            (identical(other.migrated, migrated) ||
                other.migrated == migrated) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, launched, migrated, volume);

  /// Create a copy of CommunityTokenAnalyticsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunityTokenAnalyticsResponseImplCopyWith<
    _$CommunityTokenAnalyticsResponseImpl
  >
  get copyWith =>
      __$$CommunityTokenAnalyticsResponseImplCopyWithImpl<
        _$CommunityTokenAnalyticsResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunityTokenAnalyticsResponseImplToJson(this);
  }
}

abstract class _CommunityTokenAnalyticsResponse
    implements CommunityTokenAnalyticsResponse {
  const factory _CommunityTokenAnalyticsResponse({
    final int launched,
    final int migrated,
    final double volume,
  }) = _$CommunityTokenAnalyticsResponseImpl;

  factory _CommunityTokenAnalyticsResponse.fromJson(Map<String, dynamic> json) =
      _$CommunityTokenAnalyticsResponseImpl.fromJson;

  @override
  int get launched;
  @override
  int get migrated;
  @override
  double get volume;

  /// Create a copy of CommunityTokenAnalyticsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunityTokenAnalyticsResponseImplCopyWith<
    _$CommunityTokenAnalyticsResponseImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
