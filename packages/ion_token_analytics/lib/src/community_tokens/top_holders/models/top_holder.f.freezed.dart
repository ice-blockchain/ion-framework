// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'top_holder.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TopHolder _$TopHolderFromJson(Map<String, dynamic> json) {
  return _TopHolder.fromJson(json);
}

/// @nodoc
mixin _$TopHolder {
  Creator get creator => throw _privateConstructorUsedError;
  TopHolderPosition get position => throw _privateConstructorUsedError;

  /// Serializes this TopHolder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopHolderCopyWith<TopHolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopHolderCopyWith<$Res> {
  factory $TopHolderCopyWith(TopHolder value, $Res Function(TopHolder) then) =
      _$TopHolderCopyWithImpl<$Res, TopHolder>;
  @useResult
  $Res call({Creator creator, TopHolderPosition position});

  $CreatorCopyWith<$Res> get creator;
  $TopHolderPositionCopyWith<$Res> get position;
}

/// @nodoc
class _$TopHolderCopyWithImpl<$Res, $Val extends TopHolder>
    implements $TopHolderCopyWith<$Res> {
  _$TopHolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? creator = null, Object? position = null}) {
    return _then(
      _value.copyWith(
            creator: null == creator
                ? _value.creator
                : creator // ignore: cast_nullable_to_non_nullable
                      as Creator,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as TopHolderPosition,
          )
          as $Val,
    );
  }

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res> get creator {
    return $CreatorCopyWith<$Res>(_value.creator, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TopHolderPositionCopyWith<$Res> get position {
    return $TopHolderPositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TopHolderImplCopyWith<$Res>
    implements $TopHolderCopyWith<$Res> {
  factory _$$TopHolderImplCopyWith(
    _$TopHolderImpl value,
    $Res Function(_$TopHolderImpl) then,
  ) = __$$TopHolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Creator creator, TopHolderPosition position});

  @override
  $CreatorCopyWith<$Res> get creator;
  @override
  $TopHolderPositionCopyWith<$Res> get position;
}

/// @nodoc
class __$$TopHolderImplCopyWithImpl<$Res>
    extends _$TopHolderCopyWithImpl<$Res, _$TopHolderImpl>
    implements _$$TopHolderImplCopyWith<$Res> {
  __$$TopHolderImplCopyWithImpl(
    _$TopHolderImpl _value,
    $Res Function(_$TopHolderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? creator = null, Object? position = null}) {
    return _then(
      _$TopHolderImpl(
        creator: null == creator
            ? _value.creator
            : creator // ignore: cast_nullable_to_non_nullable
                  as Creator,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as TopHolderPosition,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TopHolderImpl implements _TopHolder {
  const _$TopHolderImpl({required this.creator, required this.position});

  factory _$TopHolderImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopHolderImplFromJson(json);

  @override
  final Creator creator;
  @override
  final TopHolderPosition position;

  @override
  String toString() {
    return 'TopHolder(creator: $creator, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopHolderImpl &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, creator, position);

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopHolderImplCopyWith<_$TopHolderImpl> get copyWith =>
      __$$TopHolderImplCopyWithImpl<_$TopHolderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopHolderImplToJson(this);
  }
}

abstract class _TopHolder implements TopHolder {
  const factory _TopHolder({
    required final Creator creator,
    required final TopHolderPosition position,
  }) = _$TopHolderImpl;

  factory _TopHolder.fromJson(Map<String, dynamic> json) =
      _$TopHolderImpl.fromJson;

  @override
  Creator get creator;
  @override
  TopHolderPosition get position;

  /// Create a copy of TopHolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopHolderImplCopyWith<_$TopHolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
