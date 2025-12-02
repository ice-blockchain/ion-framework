// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_token.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommunityToken _$CommunityTokenFromJson(Map<String, dynamic> json) {
  return _CommunityToken.fromJson(json);
}

/// @nodoc
mixin _$CommunityToken {
  CommunityTokenType get type => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  Addresses get addresses => throw _privateConstructorUsedError;
  Creator get creator => throw _privateConstructorUsedError;
  MarketData get marketData => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CommunityToken to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityTokenCopyWith<CommunityToken> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityTokenCopyWith<$Res> {
  factory $CommunityTokenCopyWith(
    CommunityToken value,
    $Res Function(CommunityToken) then,
  ) = _$CommunityTokenCopyWithImpl<$Res, CommunityToken>;
  @useResult
  $Res call({
    CommunityTokenType type,
    String title,
    String description,
    Addresses addresses,
    Creator creator,
    MarketData marketData,
    String? imageUrl,
    String? createdAt,
  });

  $AddressesCopyWith<$Res> get addresses;
  $CreatorCopyWith<$Res> get creator;
  $MarketDataCopyWith<$Res> get marketData;
}

/// @nodoc
class _$CommunityTokenCopyWithImpl<$Res, $Val extends CommunityToken>
    implements $CommunityTokenCopyWith<$Res> {
  _$CommunityTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? addresses = null,
    Object? creator = null,
    Object? marketData = null,
    Object? imageUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as CommunityTokenType,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            addresses: null == addresses
                ? _value.addresses
                : addresses // ignore: cast_nullable_to_non_nullable
                      as Addresses,
            creator: null == creator
                ? _value.creator
                : creator // ignore: cast_nullable_to_non_nullable
                      as Creator,
            marketData: null == marketData
                ? _value.marketData
                : marketData // ignore: cast_nullable_to_non_nullable
                      as MarketData,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressesCopyWith<$Res> get addresses {
    return $AddressesCopyWith<$Res>(_value.addresses, (value) {
      return _then(_value.copyWith(addresses: value) as $Val);
    });
  }

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res> get creator {
    return $CreatorCopyWith<$Res>(_value.creator, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MarketDataCopyWith<$Res> get marketData {
    return $MarketDataCopyWith<$Res>(_value.marketData, (value) {
      return _then(_value.copyWith(marketData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommunityTokenImplCopyWith<$Res>
    implements $CommunityTokenCopyWith<$Res> {
  factory _$$CommunityTokenImplCopyWith(
    _$CommunityTokenImpl value,
    $Res Function(_$CommunityTokenImpl) then,
  ) = __$$CommunityTokenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CommunityTokenType type,
    String title,
    String description,
    Addresses addresses,
    Creator creator,
    MarketData marketData,
    String? imageUrl,
    String? createdAt,
  });

  @override
  $AddressesCopyWith<$Res> get addresses;
  @override
  $CreatorCopyWith<$Res> get creator;
  @override
  $MarketDataCopyWith<$Res> get marketData;
}

/// @nodoc
class __$$CommunityTokenImplCopyWithImpl<$Res>
    extends _$CommunityTokenCopyWithImpl<$Res, _$CommunityTokenImpl>
    implements _$$CommunityTokenImplCopyWith<$Res> {
  __$$CommunityTokenImplCopyWithImpl(
    _$CommunityTokenImpl _value,
    $Res Function(_$CommunityTokenImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? addresses = null,
    Object? creator = null,
    Object? marketData = null,
    Object? imageUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CommunityTokenImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as CommunityTokenType,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        addresses: null == addresses
            ? _value.addresses
            : addresses // ignore: cast_nullable_to_non_nullable
                  as Addresses,
        creator: null == creator
            ? _value.creator
            : creator // ignore: cast_nullable_to_non_nullable
                  as Creator,
        marketData: null == marketData
            ? _value.marketData
            : marketData // ignore: cast_nullable_to_non_nullable
                  as MarketData,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommunityTokenImpl implements _CommunityToken {
  const _$CommunityTokenImpl({
    required this.type,
    required this.title,
    required this.description,
    required this.addresses,
    required this.creator,
    required this.marketData,
    this.imageUrl,
    this.createdAt,
  });

  factory _$CommunityTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunityTokenImplFromJson(json);

  @override
  final CommunityTokenType type;
  @override
  final String title;
  @override
  final String description;
  @override
  final Addresses addresses;
  @override
  final Creator creator;
  @override
  final MarketData marketData;
  @override
  final String? imageUrl;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'CommunityToken(type: $type, title: $title, description: $description, addresses: $addresses, creator: $creator, marketData: $marketData, imageUrl: $imageUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunityTokenImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.addresses, addresses) ||
                other.addresses == addresses) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.marketData, marketData) ||
                other.marketData == marketData) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    title,
    description,
    addresses,
    creator,
    marketData,
    imageUrl,
    createdAt,
  );

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunityTokenImplCopyWith<_$CommunityTokenImpl> get copyWith =>
      __$$CommunityTokenImplCopyWithImpl<_$CommunityTokenImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunityTokenImplToJson(this);
  }
}

abstract class _CommunityToken implements CommunityToken {
  const factory _CommunityToken({
    required final CommunityTokenType type,
    required final String title,
    required final String description,
    required final Addresses addresses,
    required final Creator creator,
    required final MarketData marketData,
    final String? imageUrl,
    final String? createdAt,
  }) = _$CommunityTokenImpl;

  factory _CommunityToken.fromJson(Map<String, dynamic> json) =
      _$CommunityTokenImpl.fromJson;

  @override
  CommunityTokenType get type;
  @override
  String get title;
  @override
  String get description;
  @override
  Addresses get addresses;
  @override
  Creator get creator;
  @override
  MarketData get marketData;
  @override
  String? get imageUrl;
  @override
  String? get createdAt;

  /// Create a copy of CommunityToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunityTokenImplCopyWith<_$CommunityTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommunityTokenPatch _$CommunityTokenPatchFromJson(Map<String, dynamic> json) {
  return _CommunityTokenPatch.fromJson(json);
}

/// @nodoc
mixin _$CommunityTokenPatch {
  CommunityTokenType? get type => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  AddressesPatch? get addresses => throw _privateConstructorUsedError;
  CreatorPatch? get creator => throw _privateConstructorUsedError;
  MarketDataPatch? get marketData => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CommunityTokenPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$CommunityTokenPatchImpl implements _CommunityTokenPatch {
  const _$CommunityTokenPatchImpl({
    this.type,
    this.title,
    this.description,
    this.imageUrl,
    this.addresses,
    this.creator,
    this.marketData,
    this.createdAt,
  });

  factory _$CommunityTokenPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunityTokenPatchImplFromJson(json);

  @override
  final CommunityTokenType? type;
  @override
  final String? title;
  @override
  final String? description;
  @override
  final String? imageUrl;
  @override
  final AddressesPatch? addresses;
  @override
  final CreatorPatch? creator;
  @override
  final MarketDataPatch? marketData;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'CommunityTokenPatch(type: $type, title: $title, description: $description, imageUrl: $imageUrl, addresses: $addresses, creator: $creator, marketData: $marketData, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunityTokenPatchImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.addresses, addresses) ||
                other.addresses == addresses) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.marketData, marketData) ||
                other.marketData == marketData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    title,
    description,
    imageUrl,
    addresses,
    creator,
    marketData,
    createdAt,
  );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunityTokenPatchImplToJson(this);
  }
}

abstract class _CommunityTokenPatch implements CommunityTokenPatch {
  const factory _CommunityTokenPatch({
    final CommunityTokenType? type,
    final String? title,
    final String? description,
    final String? imageUrl,
    final AddressesPatch? addresses,
    final CreatorPatch? creator,
    final MarketDataPatch? marketData,
    final String? createdAt,
  }) = _$CommunityTokenPatchImpl;

  factory _CommunityTokenPatch.fromJson(Map<String, dynamic> json) =
      _$CommunityTokenPatchImpl.fromJson;

  @override
  CommunityTokenType? get type;
  @override
  String? get title;
  @override
  String? get description;
  @override
  String? get imageUrl;
  @override
  AddressesPatch? get addresses;
  @override
  CreatorPatch? get creator;
  @override
  MarketDataPatch? get marketData;
  @override
  String? get createdAt;
}
