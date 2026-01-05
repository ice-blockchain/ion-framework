// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'latest_trade.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LatestTrade _$LatestTradeFromJson(Map<String, dynamic> json) {
  return _LatestTrade.fromJson(json);
}

/// @nodoc
mixin _$LatestTrade {
  Creator get creator => throw _privateConstructorUsedError;
  TradePosition get position => throw _privateConstructorUsedError;

  /// Serializes this LatestTrade to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LatestTradeCopyWith<LatestTrade> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LatestTradeCopyWith<$Res> {
  factory $LatestTradeCopyWith(
    LatestTrade value,
    $Res Function(LatestTrade) then,
  ) = _$LatestTradeCopyWithImpl<$Res, LatestTrade>;
  @useResult
  $Res call({Creator creator, TradePosition position});

  $CreatorCopyWith<$Res> get creator;
  $TradePositionCopyWith<$Res> get position;
}

/// @nodoc
class _$LatestTradeCopyWithImpl<$Res, $Val extends LatestTrade>
    implements $LatestTradeCopyWith<$Res> {
  _$LatestTradeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LatestTrade
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
                      as TradePosition,
          )
          as $Val,
    );
  }

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res> get creator {
    return $CreatorCopyWith<$Res>(_value.creator, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradePositionCopyWith<$Res> get position {
    return $TradePositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LatestTradeImplCopyWith<$Res>
    implements $LatestTradeCopyWith<$Res> {
  factory _$$LatestTradeImplCopyWith(
    _$LatestTradeImpl value,
    $Res Function(_$LatestTradeImpl) then,
  ) = __$$LatestTradeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Creator creator, TradePosition position});

  @override
  $CreatorCopyWith<$Res> get creator;
  @override
  $TradePositionCopyWith<$Res> get position;
}

/// @nodoc
class __$$LatestTradeImplCopyWithImpl<$Res>
    extends _$LatestTradeCopyWithImpl<$Res, _$LatestTradeImpl>
    implements _$$LatestTradeImplCopyWith<$Res> {
  __$$LatestTradeImplCopyWithImpl(
    _$LatestTradeImpl _value,
    $Res Function(_$LatestTradeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? creator = null, Object? position = null}) {
    return _then(
      _$LatestTradeImpl(
        creator: null == creator
            ? _value.creator
            : creator // ignore: cast_nullable_to_non_nullable
                  as Creator,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as TradePosition,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LatestTradeImpl implements _LatestTrade {
  const _$LatestTradeImpl({required this.creator, required this.position});

  factory _$LatestTradeImpl.fromJson(Map<String, dynamic> json) =>
      _$$LatestTradeImplFromJson(json);

  @override
  final Creator creator;
  @override
  final TradePosition position;

  @override
  String toString() {
    return 'LatestTrade(creator: $creator, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LatestTradeImpl &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, creator, position);

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LatestTradeImplCopyWith<_$LatestTradeImpl> get copyWith =>
      __$$LatestTradeImplCopyWithImpl<_$LatestTradeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LatestTradeImplToJson(this);
  }
}

abstract class _LatestTrade implements LatestTrade {
  const factory _LatestTrade({
    required final Creator creator,
    required final TradePosition position,
  }) = _$LatestTradeImpl;

  factory _LatestTrade.fromJson(Map<String, dynamic> json) =
      _$LatestTradeImpl.fromJson;

  @override
  Creator get creator;
  @override
  TradePosition get position;

  /// Create a copy of LatestTrade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LatestTradeImplCopyWith<_$LatestTradeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LatestTradePatch _$LatestTradePatchFromJson(Map<String, dynamic> json) {
  return _LatestTradePatch.fromJson(json);
}

/// @nodoc
mixin _$LatestTradePatch {
  Creator? get creator => throw _privateConstructorUsedError;
  TradePositionPatch? get position => throw _privateConstructorUsedError;

  /// Serializes this LatestTradePatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$LatestTradePatchImpl implements _LatestTradePatch {
  const _$LatestTradePatchImpl({this.creator, this.position});

  factory _$LatestTradePatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$LatestTradePatchImplFromJson(json);

  @override
  final Creator? creator;
  @override
  final TradePositionPatch? position;

  @override
  String toString() {
    return 'LatestTradePatch(creator: $creator, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LatestTradePatchImpl &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, creator, position);

  @override
  Map<String, dynamic> toJson() {
    return _$$LatestTradePatchImplToJson(this);
  }
}

abstract class _LatestTradePatch implements LatestTradePatch {
  const factory _LatestTradePatch({
    final Creator? creator,
    final TradePositionPatch? position,
  }) = _$LatestTradePatchImpl;

  factory _LatestTradePatch.fromJson(Map<String, dynamic> json) =
      _$LatestTradePatchImpl.fromJson;

  @override
  Creator? get creator;
  @override
  TradePositionPatch? get position;
}
