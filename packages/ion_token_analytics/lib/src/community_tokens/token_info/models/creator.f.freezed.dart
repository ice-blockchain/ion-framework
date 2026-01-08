// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Creator _$CreatorFromJson(Map<String, dynamic> json) {
  return _Creator.fromJson(json);
}

/// @nodoc
mixin _$Creator {
  String? get display => throw _privateConstructorUsedError;
  bool? get verified => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  Addresses? get addresses => throw _privateConstructorUsedError;

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorCopyWith<Creator> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorCopyWith<$Res> {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) then) =
      _$CreatorCopyWithImpl<$Res, Creator>;
  @useResult
  $Res call({
    String? display,
    bool? verified,
    String? name,
    String? avatar,
    Addresses? addresses,
  });

  $AddressesCopyWith<$Res>? get addresses;
}

/// @nodoc
class _$CreatorCopyWithImpl<$Res, $Val extends Creator>
    implements $CreatorCopyWith<$Res> {
  _$CreatorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? display = freezed,
    Object? verified = freezed,
    Object? name = freezed,
    Object? avatar = freezed,
    Object? addresses = freezed,
  }) {
    return _then(
      _value.copyWith(
            display: freezed == display
                ? _value.display
                : display // ignore: cast_nullable_to_non_nullable
                      as String?,
            verified: freezed == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                      as bool?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            addresses: freezed == addresses
                ? _value.addresses
                : addresses // ignore: cast_nullable_to_non_nullable
                      as Addresses?,
          )
          as $Val,
    );
  }

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressesCopyWith<$Res>? get addresses {
    if (_value.addresses == null) {
      return null;
    }

    return $AddressesCopyWith<$Res>(_value.addresses!, (value) {
      return _then(_value.copyWith(addresses: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CreatorImplCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$$CreatorImplCopyWith(
    _$CreatorImpl value,
    $Res Function(_$CreatorImpl) then,
  ) = __$$CreatorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? display,
    bool? verified,
    String? name,
    String? avatar,
    Addresses? addresses,
  });

  @override
  $AddressesCopyWith<$Res>? get addresses;
}

/// @nodoc
class __$$CreatorImplCopyWithImpl<$Res>
    extends _$CreatorCopyWithImpl<$Res, _$CreatorImpl>
    implements _$$CreatorImplCopyWith<$Res> {
  __$$CreatorImplCopyWithImpl(
    _$CreatorImpl _value,
    $Res Function(_$CreatorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? display = freezed,
    Object? verified = freezed,
    Object? name = freezed,
    Object? avatar = freezed,
    Object? addresses = freezed,
  }) {
    return _then(
      _$CreatorImpl(
        display: freezed == display
            ? _value.display
            : display // ignore: cast_nullable_to_non_nullable
                  as String?,
        verified: freezed == verified
            ? _value.verified
            : verified // ignore: cast_nullable_to_non_nullable
                  as bool?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        addresses: freezed == addresses
            ? _value.addresses
            : addresses // ignore: cast_nullable_to_non_nullable
                  as Addresses?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorImpl extends _Creator {
  const _$CreatorImpl({
    this.display,
    this.verified,
    this.name,
    this.avatar,
    this.addresses,
  }) : super._();

  factory _$CreatorImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorImplFromJson(json);

  @override
  final String? display;
  @override
  final bool? verified;
  @override
  final String? name;
  @override
  final String? avatar;
  @override
  final Addresses? addresses;

  @override
  String toString() {
    return 'Creator(display: $display, verified: $verified, name: $name, avatar: $avatar, addresses: $addresses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorImpl &&
            (identical(other.display, display) || other.display == display) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.addresses, addresses) ||
                other.addresses == addresses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, display, verified, name, avatar, addresses);

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorImplCopyWith<_$CreatorImpl> get copyWith =>
      __$$CreatorImplCopyWithImpl<_$CreatorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorImplToJson(this);
  }
}

abstract class _Creator extends Creator {
  const factory _Creator({
    final String? display,
    final bool? verified,
    final String? name,
    final String? avatar,
    final Addresses? addresses,
  }) = _$CreatorImpl;
  const _Creator._() : super._();

  factory _Creator.fromJson(Map<String, dynamic> json) = _$CreatorImpl.fromJson;

  @override
  String? get display;
  @override
  bool? get verified;
  @override
  String? get name;
  @override
  String? get avatar;
  @override
  Addresses? get addresses;

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorImplCopyWith<_$CreatorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
