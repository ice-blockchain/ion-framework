// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'viewing_session.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ViewingSession _$ViewingSessionFromJson(Map<String, dynamic> json) {
  return _ViewingSession.fromJson(json);
}

/// @nodoc
mixin _$ViewingSession {
  String get id => throw _privateConstructorUsedError;
  int get ttl => throw _privateConstructorUsedError;

  /// Serializes this ViewingSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ViewingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ViewingSessionCopyWith<ViewingSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewingSessionCopyWith<$Res> {
  factory $ViewingSessionCopyWith(
    ViewingSession value,
    $Res Function(ViewingSession) then,
  ) = _$ViewingSessionCopyWithImpl<$Res, ViewingSession>;
  @useResult
  $Res call({String id, int ttl});
}

/// @nodoc
class _$ViewingSessionCopyWithImpl<$Res, $Val extends ViewingSession>
    implements $ViewingSessionCopyWith<$Res> {
  _$ViewingSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ViewingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? ttl = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            ttl: null == ttl
                ? _value.ttl
                : ttl // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ViewingSessionImplCopyWith<$Res>
    implements $ViewingSessionCopyWith<$Res> {
  factory _$$ViewingSessionImplCopyWith(
    _$ViewingSessionImpl value,
    $Res Function(_$ViewingSessionImpl) then,
  ) = __$$ViewingSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, int ttl});
}

/// @nodoc
class __$$ViewingSessionImplCopyWithImpl<$Res>
    extends _$ViewingSessionCopyWithImpl<$Res, _$ViewingSessionImpl>
    implements _$$ViewingSessionImplCopyWith<$Res> {
  __$$ViewingSessionImplCopyWithImpl(
    _$ViewingSessionImpl _value,
    $Res Function(_$ViewingSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ViewingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? ttl = null}) {
    return _then(
      _$ViewingSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ttl: null == ttl
            ? _value.ttl
            : ttl // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ViewingSessionImpl implements _ViewingSession {
  const _$ViewingSessionImpl({required this.id, required this.ttl});

  factory _$ViewingSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ViewingSessionImplFromJson(json);

  @override
  final String id;
  @override
  final int ttl;

  @override
  String toString() {
    return 'ViewingSession(id: $id, ttl: $ttl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViewingSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ttl, ttl) || other.ttl == ttl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, ttl);

  /// Create a copy of ViewingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViewingSessionImplCopyWith<_$ViewingSessionImpl> get copyWith =>
      __$$ViewingSessionImplCopyWithImpl<_$ViewingSessionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ViewingSessionImplToJson(this);
  }
}

abstract class _ViewingSession implements ViewingSession {
  const factory _ViewingSession({
    required final String id,
    required final int ttl,
  }) = _$ViewingSessionImpl;

  factory _ViewingSession.fromJson(Map<String, dynamic> json) =
      _$ViewingSessionImpl.fromJson;

  @override
  String get id;
  @override
  int get ttl;

  /// Create a copy of ViewingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViewingSessionImplCopyWith<_$ViewingSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
