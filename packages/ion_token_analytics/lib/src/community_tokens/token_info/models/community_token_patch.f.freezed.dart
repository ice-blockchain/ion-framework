// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_token_patch.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommunityTokenPatch _$CommunityTokenPatchFromJson(Map<String, dynamic> json) {
  return _CommunityTokenPatch.fromJson(json);
}

/// @nodoc
mixin _$CommunityTokenPatch {
  String? get type => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  AddressesPatch? get addresses => throw _privateConstructorUsedError;
  Creator? get creator =>
      throw _privateConstructorUsedError; // Optional: present in full tokens, null in partial updates
  MarketDataPatch? get marketData => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CommunityTokenPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityTokenPatchCopyWith<CommunityTokenPatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityTokenPatchCopyWith<$Res> {
  factory $CommunityTokenPatchCopyWith(
    CommunityTokenPatch value,
    $Res Function(CommunityTokenPatch) then,
  ) = _$CommunityTokenPatchCopyWithImpl<$Res, CommunityTokenPatch>;
  @useResult
  $Res call({
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    AddressesPatch? addresses,
    Creator? creator,
    MarketDataPatch? marketData,
    String? createdAt,
  });

  $AddressesPatchCopyWith<$Res>? get addresses;
  $CreatorCopyWith<$Res>? get creator;
  $MarketDataPatchCopyWith<$Res>? get marketData;
}

/// @nodoc
class _$CommunityTokenPatchCopyWithImpl<$Res, $Val extends CommunityTokenPatch>
    implements $CommunityTokenPatchCopyWith<$Res> {
  _$CommunityTokenPatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = freezed,
    Object? title = freezed,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? addresses = freezed,
    Object? creator = freezed,
    Object? marketData = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            addresses: freezed == addresses
                ? _value.addresses
                : addresses // ignore: cast_nullable_to_non_nullable
                      as AddressesPatch?,
            creator: freezed == creator
                ? _value.creator
                : creator // ignore: cast_nullable_to_non_nullable
                      as Creator?,
            marketData: freezed == marketData
                ? _value.marketData
                : marketData // ignore: cast_nullable_to_non_nullable
                      as MarketDataPatch?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressesPatchCopyWith<$Res>? get addresses {
    if (_value.addresses == null) {
      return null;
    }

    return $AddressesPatchCopyWith<$Res>(_value.addresses!, (value) {
      return _then(_value.copyWith(addresses: value) as $Val);
    });
  }

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res>? get creator {
    if (_value.creator == null) {
      return null;
    }

    return $CreatorCopyWith<$Res>(_value.creator!, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MarketDataPatchCopyWith<$Res>? get marketData {
    if (_value.marketData == null) {
      return null;
    }

    return $MarketDataPatchCopyWith<$Res>(_value.marketData!, (value) {
      return _then(_value.copyWith(marketData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommunityTokenPatchImplCopyWith<$Res>
    implements $CommunityTokenPatchCopyWith<$Res> {
  factory _$$CommunityTokenPatchImplCopyWith(
    _$CommunityTokenPatchImpl value,
    $Res Function(_$CommunityTokenPatchImpl) then,
  ) = __$$CommunityTokenPatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    AddressesPatch? addresses,
    Creator? creator,
    MarketDataPatch? marketData,
    String? createdAt,
  });

  @override
  $AddressesPatchCopyWith<$Res>? get addresses;
  @override
  $CreatorCopyWith<$Res>? get creator;
  @override
  $MarketDataPatchCopyWith<$Res>? get marketData;
}

/// @nodoc
class __$$CommunityTokenPatchImplCopyWithImpl<$Res>
    extends _$CommunityTokenPatchCopyWithImpl<$Res, _$CommunityTokenPatchImpl>
    implements _$$CommunityTokenPatchImplCopyWith<$Res> {
  __$$CommunityTokenPatchImplCopyWithImpl(
    _$CommunityTokenPatchImpl _value,
    $Res Function(_$CommunityTokenPatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = freezed,
    Object? title = freezed,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? addresses = freezed,
    Object? creator = freezed,
    Object? marketData = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CommunityTokenPatchImpl(
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        addresses: freezed == addresses
            ? _value.addresses
            : addresses // ignore: cast_nullable_to_non_nullable
                  as AddressesPatch?,
        creator: freezed == creator
            ? _value.creator
            : creator // ignore: cast_nullable_to_non_nullable
                  as Creator?,
        marketData: freezed == marketData
            ? _value.marketData
            : marketData // ignore: cast_nullable_to_non_nullable
                  as MarketDataPatch?,
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
class _$CommunityTokenPatchImpl extends _CommunityTokenPatch {
  const _$CommunityTokenPatchImpl({
    this.type,
    this.title,
    this.description,
    this.imageUrl,
    this.addresses,
    this.creator,
    this.marketData,
    this.createdAt,
  }) : super._();

  factory _$CommunityTokenPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunityTokenPatchImplFromJson(json);

  @override
  final String? type;
  @override
  final String? title;
  @override
  final String? description;
  @override
  final String? imageUrl;
  @override
  final AddressesPatch? addresses;
  @override
  final Creator? creator;
  // Optional: present in full tokens, null in partial updates
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

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunityTokenPatchImplCopyWith<_$CommunityTokenPatchImpl> get copyWith =>
      __$$CommunityTokenPatchImplCopyWithImpl<_$CommunityTokenPatchImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunityTokenPatchImplToJson(this);
  }
}

abstract class _CommunityTokenPatch extends CommunityTokenPatch {
  const factory _CommunityTokenPatch({
    final String? type,
    final String? title,
    final String? description,
    final String? imageUrl,
    final AddressesPatch? addresses,
    final Creator? creator,
    final MarketDataPatch? marketData,
    final String? createdAt,
  }) = _$CommunityTokenPatchImpl;
  const _CommunityTokenPatch._() : super._();

  factory _CommunityTokenPatch.fromJson(Map<String, dynamic> json) =
      _$CommunityTokenPatchImpl.fromJson;

  @override
  String? get type;
  @override
  String? get title;
  @override
  String? get description;
  @override
  String? get imageUrl;
  @override
  AddressesPatch? get addresses;
  @override
  Creator? get creator; // Optional: present in full tokens, null in partial updates
  @override
  MarketDataPatch? get marketData;
  @override
  String? get createdAt;

  /// Create a copy of CommunityTokenPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunityTokenPatchImplCopyWith<_$CommunityTokenPatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
