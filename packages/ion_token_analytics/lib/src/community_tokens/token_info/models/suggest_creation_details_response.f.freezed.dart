// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggest_creation_details_response.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SuggestCreationDetailsResponse _$SuggestCreationDetailsResponseFromJson(
  Map<String, dynamic> json,
) {
  return _SuggestCreationDetailsResponse.fromJson(json);
}

/// @nodoc
mixin _$SuggestCreationDetailsResponse {
  String get ticker => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get picture => throw _privateConstructorUsedError;

  /// Serializes this SuggestCreationDetailsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SuggestCreationDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SuggestCreationDetailsResponseCopyWith<SuggestCreationDetailsResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuggestCreationDetailsResponseCopyWith<$Res> {
  factory $SuggestCreationDetailsResponseCopyWith(
    SuggestCreationDetailsResponse value,
    $Res Function(SuggestCreationDetailsResponse) then,
  ) =
      _$SuggestCreationDetailsResponseCopyWithImpl<
        $Res,
        SuggestCreationDetailsResponse
      >;
  @useResult
  $Res call({String ticker, String name, String picture});
}

/// @nodoc
class _$SuggestCreationDetailsResponseCopyWithImpl<
  $Res,
  $Val extends SuggestCreationDetailsResponse
>
    implements $SuggestCreationDetailsResponseCopyWith<$Res> {
  _$SuggestCreationDetailsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SuggestCreationDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ticker = null,
    Object? name = null,
    Object? picture = null,
  }) {
    return _then(
      _value.copyWith(
            ticker: null == ticker
                ? _value.ticker
                : ticker // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            picture: null == picture
                ? _value.picture
                : picture // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SuggestCreationDetailsResponseImplCopyWith<$Res>
    implements $SuggestCreationDetailsResponseCopyWith<$Res> {
  factory _$$SuggestCreationDetailsResponseImplCopyWith(
    _$SuggestCreationDetailsResponseImpl value,
    $Res Function(_$SuggestCreationDetailsResponseImpl) then,
  ) = __$$SuggestCreationDetailsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String ticker, String name, String picture});
}

/// @nodoc
class __$$SuggestCreationDetailsResponseImplCopyWithImpl<$Res>
    extends
        _$SuggestCreationDetailsResponseCopyWithImpl<
          $Res,
          _$SuggestCreationDetailsResponseImpl
        >
    implements _$$SuggestCreationDetailsResponseImplCopyWith<$Res> {
  __$$SuggestCreationDetailsResponseImplCopyWithImpl(
    _$SuggestCreationDetailsResponseImpl _value,
    $Res Function(_$SuggestCreationDetailsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SuggestCreationDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ticker = null,
    Object? name = null,
    Object? picture = null,
  }) {
    return _then(
      _$SuggestCreationDetailsResponseImpl(
        ticker: null == ticker
            ? _value.ticker
            : ticker // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        picture: null == picture
            ? _value.picture
            : picture // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SuggestCreationDetailsResponseImpl
    implements _SuggestCreationDetailsResponse {
  const _$SuggestCreationDetailsResponseImpl({
    required this.ticker,
    required this.name,
    required this.picture,
  });

  factory _$SuggestCreationDetailsResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$SuggestCreationDetailsResponseImplFromJson(json);

  @override
  final String ticker;
  @override
  final String name;
  @override
  final String picture;

  @override
  String toString() {
    return 'SuggestCreationDetailsResponse(ticker: $ticker, name: $name, picture: $picture)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestCreationDetailsResponseImpl &&
            (identical(other.ticker, ticker) || other.ticker == ticker) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.picture, picture) || other.picture == picture));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, ticker, name, picture);

  /// Create a copy of SuggestCreationDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuggestCreationDetailsResponseImplCopyWith<
    _$SuggestCreationDetailsResponseImpl
  >
  get copyWith =>
      __$$SuggestCreationDetailsResponseImplCopyWithImpl<
        _$SuggestCreationDetailsResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SuggestCreationDetailsResponseImplToJson(this);
  }
}

abstract class _SuggestCreationDetailsResponse
    implements SuggestCreationDetailsResponse {
  const factory _SuggestCreationDetailsResponse({
    required final String ticker,
    required final String name,
    required final String picture,
  }) = _$SuggestCreationDetailsResponseImpl;

  factory _SuggestCreationDetailsResponse.fromJson(Map<String, dynamic> json) =
      _$SuggestCreationDetailsResponseImpl.fromJson;

  @override
  String get ticker;
  @override
  String get name;
  @override
  String get picture;

  /// Create a copy of SuggestCreationDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuggestCreationDetailsResponseImplCopyWith<
    _$SuggestCreationDetailsResponseImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
