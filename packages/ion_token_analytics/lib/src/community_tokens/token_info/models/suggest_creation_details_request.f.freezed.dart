// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggest_creation_details_request.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SuggestCreationDetailsRequest _$SuggestCreationDetailsRequestFromJson(
  Map<String, dynamic> json,
) {
  return _SuggestCreationDetailsRequest.fromJson(json);
}

/// @nodoc
mixin _$SuggestCreationDetailsRequest {
  String get content => throw _privateConstructorUsedError;
  CreatorInfo get creator => throw _privateConstructorUsedError;
  String get contentId => throw _privateConstructorUsedError;
  List<String> get contentVideoFrames => throw _privateConstructorUsedError;

  /// Serializes this SuggestCreationDetailsRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SuggestCreationDetailsRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SuggestCreationDetailsRequestCopyWith<SuggestCreationDetailsRequest>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuggestCreationDetailsRequestCopyWith<$Res> {
  factory $SuggestCreationDetailsRequestCopyWith(
    SuggestCreationDetailsRequest value,
    $Res Function(SuggestCreationDetailsRequest) then,
  ) =
      _$SuggestCreationDetailsRequestCopyWithImpl<
        $Res,
        SuggestCreationDetailsRequest
      >;
  @useResult
  $Res call({
    String content,
    CreatorInfo creator,
    String contentId,
    List<String> contentVideoFrames,
  });

  $CreatorInfoCopyWith<$Res> get creator;
}

/// @nodoc
class _$SuggestCreationDetailsRequestCopyWithImpl<
  $Res,
  $Val extends SuggestCreationDetailsRequest
>
    implements $SuggestCreationDetailsRequestCopyWith<$Res> {
  _$SuggestCreationDetailsRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SuggestCreationDetailsRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? creator = null,
    Object? contentId = null,
    Object? contentVideoFrames = null,
  }) {
    return _then(
      _value.copyWith(
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            creator: null == creator
                ? _value.creator
                : creator // ignore: cast_nullable_to_non_nullable
                      as CreatorInfo,
            contentId: null == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String,
            contentVideoFrames: null == contentVideoFrames
                ? _value.contentVideoFrames
                : contentVideoFrames // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of SuggestCreationDetailsRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorInfoCopyWith<$Res> get creator {
    return $CreatorInfoCopyWith<$Res>(_value.creator, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SuggestCreationDetailsRequestImplCopyWith<$Res>
    implements $SuggestCreationDetailsRequestCopyWith<$Res> {
  factory _$$SuggestCreationDetailsRequestImplCopyWith(
    _$SuggestCreationDetailsRequestImpl value,
    $Res Function(_$SuggestCreationDetailsRequestImpl) then,
  ) = __$$SuggestCreationDetailsRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String content,
    CreatorInfo creator,
    String contentId,
    List<String> contentVideoFrames,
  });

  @override
  $CreatorInfoCopyWith<$Res> get creator;
}

/// @nodoc
class __$$SuggestCreationDetailsRequestImplCopyWithImpl<$Res>
    extends
        _$SuggestCreationDetailsRequestCopyWithImpl<
          $Res,
          _$SuggestCreationDetailsRequestImpl
        >
    implements _$$SuggestCreationDetailsRequestImplCopyWith<$Res> {
  __$$SuggestCreationDetailsRequestImplCopyWithImpl(
    _$SuggestCreationDetailsRequestImpl _value,
    $Res Function(_$SuggestCreationDetailsRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SuggestCreationDetailsRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? creator = null,
    Object? contentId = null,
    Object? contentVideoFrames = null,
  }) {
    return _then(
      _$SuggestCreationDetailsRequestImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        creator: null == creator
            ? _value.creator
            : creator // ignore: cast_nullable_to_non_nullable
                  as CreatorInfo,
        contentId: null == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String,
        contentVideoFrames: null == contentVideoFrames
            ? _value._contentVideoFrames
            : contentVideoFrames // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SuggestCreationDetailsRequestImpl
    implements _SuggestCreationDetailsRequest {
  const _$SuggestCreationDetailsRequestImpl({
    required this.content,
    required this.creator,
    required this.contentId,
    final List<String> contentVideoFrames = const [],
  }) : _contentVideoFrames = contentVideoFrames;

  factory _$SuggestCreationDetailsRequestImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$SuggestCreationDetailsRequestImplFromJson(json);

  @override
  final String content;
  @override
  final CreatorInfo creator;
  @override
  final String contentId;
  final List<String> _contentVideoFrames;
  @override
  @JsonKey()
  List<String> get contentVideoFrames {
    if (_contentVideoFrames is EqualUnmodifiableListView)
      return _contentVideoFrames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contentVideoFrames);
  }

  @override
  String toString() {
    return 'SuggestCreationDetailsRequest(content: $content, creator: $creator, contentId: $contentId, contentVideoFrames: $contentVideoFrames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestCreationDetailsRequestImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            const DeepCollectionEquality().equals(
              other._contentVideoFrames,
              _contentVideoFrames,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    content,
    creator,
    contentId,
    const DeepCollectionEquality().hash(_contentVideoFrames),
  );

  /// Create a copy of SuggestCreationDetailsRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuggestCreationDetailsRequestImplCopyWith<
    _$SuggestCreationDetailsRequestImpl
  >
  get copyWith =>
      __$$SuggestCreationDetailsRequestImplCopyWithImpl<
        _$SuggestCreationDetailsRequestImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SuggestCreationDetailsRequestImplToJson(this);
  }
}

abstract class _SuggestCreationDetailsRequest
    implements SuggestCreationDetailsRequest {
  const factory _SuggestCreationDetailsRequest({
    required final String content,
    required final CreatorInfo creator,
    required final String contentId,
    final List<String> contentVideoFrames,
  }) = _$SuggestCreationDetailsRequestImpl;

  factory _SuggestCreationDetailsRequest.fromJson(Map<String, dynamic> json) =
      _$SuggestCreationDetailsRequestImpl.fromJson;

  @override
  String get content;
  @override
  CreatorInfo get creator;
  @override
  String get contentId;
  @override
  List<String> get contentVideoFrames;

  /// Create a copy of SuggestCreationDetailsRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuggestCreationDetailsRequestImplCopyWith<
    _$SuggestCreationDetailsRequestImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

CreatorInfo _$CreatorInfoFromJson(Map<String, dynamic> json) {
  return _CreatorInfo.fromJson(json);
}

/// @nodoc
mixin _$CreatorInfo {
  String get name => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;

  /// Serializes this CreatorInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorInfoCopyWith<CreatorInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorInfoCopyWith<$Res> {
  factory $CreatorInfoCopyWith(
    CreatorInfo value,
    $Res Function(CreatorInfo) then,
  ) = _$CreatorInfoCopyWithImpl<$Res, CreatorInfo>;
  @useResult
  $Res call({String name, String username, String? bio, String? website});
}

/// @nodoc
class _$CreatorInfoCopyWithImpl<$Res, $Val extends CreatorInfo>
    implements $CreatorInfoCopyWith<$Res> {
  _$CreatorInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? username = null,
    Object? bio = freezed,
    Object? website = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorInfoImplCopyWith<$Res>
    implements $CreatorInfoCopyWith<$Res> {
  factory _$$CreatorInfoImplCopyWith(
    _$CreatorInfoImpl value,
    $Res Function(_$CreatorInfoImpl) then,
  ) = __$$CreatorInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String username, String? bio, String? website});
}

/// @nodoc
class __$$CreatorInfoImplCopyWithImpl<$Res>
    extends _$CreatorInfoCopyWithImpl<$Res, _$CreatorInfoImpl>
    implements _$$CreatorInfoImplCopyWith<$Res> {
  __$$CreatorInfoImplCopyWithImpl(
    _$CreatorInfoImpl _value,
    $Res Function(_$CreatorInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? username = null,
    Object? bio = freezed,
    Object? website = freezed,
  }) {
    return _then(
      _$CreatorInfoImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorInfoImpl implements _CreatorInfo {
  const _$CreatorInfoImpl({
    required this.name,
    required this.username,
    this.bio,
    this.website,
  });

  factory _$CreatorInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorInfoImplFromJson(json);

  @override
  final String name;
  @override
  final String username;
  @override
  final String? bio;
  @override
  final String? website;

  @override
  String toString() {
    return 'CreatorInfo(name: $name, username: $username, bio: $bio, website: $website)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.website, website) || other.website == website));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, username, bio, website);

  /// Create a copy of CreatorInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorInfoImplCopyWith<_$CreatorInfoImpl> get copyWith =>
      __$$CreatorInfoImplCopyWithImpl<_$CreatorInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorInfoImplToJson(this);
  }
}

abstract class _CreatorInfo implements CreatorInfo {
  const factory _CreatorInfo({
    required final String name,
    required final String username,
    final String? bio,
    final String? website,
  }) = _$CreatorInfoImpl;

  factory _CreatorInfo.fromJson(Map<String, dynamic> json) =
      _$CreatorInfoImpl.fromJson;

  @override
  String get name;
  @override
  String get username;
  @override
  String? get bio;
  @override
  String? get website;

  /// Create a copy of CreatorInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorInfoImplCopyWith<_$CreatorInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
