// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Position _$PositionFromJson(Map<String, dynamic> json) {
  return _Position.fromJson(json);
}

/// @nodoc
mixin _$Position {
  int get rank => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get amountUSD => throw _privateConstructorUsedError;
  double get pnl => throw _privateConstructorUsedError;
  double get pnlPercentage => throw _privateConstructorUsedError;

  /// Serializes this Position to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PositionCopyWith<Position> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PositionCopyWith<$Res> {
  factory $PositionCopyWith(Position value, $Res Function(Position) then) =
      _$PositionCopyWithImpl<$Res, Position>;
  @useResult
  $Res call({int rank, double amount, double amountUSD, double pnl, double pnlPercentage});
}

/// @nodoc
class _$PositionCopyWithImpl<$Res, $Val extends Position> implements $PositionCopyWith<$Res> {
  _$PositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? amount = null,
    Object? amountUSD = null,
    Object? pnl = null,
    Object? pnlPercentage = null,
  }) {
    return _then(
      _value.copyWith(
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as int,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            amountUSD: null == amountUSD
                ? _value.amountUSD
                : amountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            pnl: null == pnl
                ? _value.pnl
                : pnl // ignore: cast_nullable_to_non_nullable
                      as double,
            pnlPercentage: null == pnlPercentage
                ? _value.pnlPercentage
                : pnlPercentage // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PositionImplCopyWith<$Res> implements $PositionCopyWith<$Res> {
  factory _$$PositionImplCopyWith(_$PositionImpl value, $Res Function(_$PositionImpl) then) =
      __$$PositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int rank, double amount, double amountUSD, double pnl, double pnlPercentage});
}

/// @nodoc
class __$$PositionImplCopyWithImpl<$Res> extends _$PositionCopyWithImpl<$Res, _$PositionImpl>
    implements _$$PositionImplCopyWith<$Res> {
  __$$PositionImplCopyWithImpl(_$PositionImpl _value, $Res Function(_$PositionImpl) _then)
    : super(_value, _then);

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? amount = null,
    Object? amountUSD = null,
    Object? pnl = null,
    Object? pnlPercentage = null,
  }) {
    return _then(
      _$PositionImpl(
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as int,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        amountUSD: null == amountUSD
            ? _value.amountUSD
            : amountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        pnl: null == pnl
            ? _value.pnl
            : pnl // ignore: cast_nullable_to_non_nullable
                  as double,
        pnlPercentage: null == pnlPercentage
            ? _value.pnlPercentage
            : pnlPercentage // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PositionImpl implements _Position {
  const _$PositionImpl({
    required this.rank,
    required this.amount,
    required this.amountUSD,
    required this.pnl,
    required this.pnlPercentage,
  });

  factory _$PositionImpl.fromJson(Map<String, dynamic> json) => _$$PositionImplFromJson(json);

  @override
  final int rank;
  @override
  final double amount;
  @override
  final double amountUSD;
  @override
  final double pnl;
  @override
  final double pnlPercentage;

  @override
  String toString() {
    return 'Position(rank: $rank, amount: $amount, amountUSD: $amountUSD, pnl: $pnl, pnlPercentage: $pnlPercentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PositionImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.amountUSD, amountUSD) || other.amountUSD == amountUSD) &&
            (identical(other.pnl, pnl) || other.pnl == pnl) &&
            (identical(other.pnlPercentage, pnlPercentage) ||
                other.pnlPercentage == pnlPercentage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rank, amount, amountUSD, pnl, pnlPercentage);

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PositionImplCopyWith<_$PositionImpl> get copyWith =>
      __$$PositionImplCopyWithImpl<_$PositionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PositionImplToJson(this);
  }
}

abstract class _Position implements Position {
  const factory _Position({
    required final int rank,
    required final double amount,
    required final double amountUSD,
    required final double pnl,
    required final double pnlPercentage,
  }) = _$PositionImpl;

  factory _Position.fromJson(Map<String, dynamic> json) = _$PositionImpl.fromJson;

  @override
  int get rank;
  @override
  double get amount;
  @override
  double get amountUSD;
  @override
  double get pnl;
  @override
  double get pnlPercentage;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PositionImplCopyWith<_$PositionImpl> get copyWith => throw _privateConstructorUsedError;
}

PositionPatch _$PositionPatchFromJson(Map<String, dynamic> json) {
  return _PositionPatch.fromJson(json);
}

/// @nodoc
mixin _$PositionPatch {
  int? get rank => throw _privateConstructorUsedError;
  double? get amount => throw _privateConstructorUsedError;
  double? get amountUSD => throw _privateConstructorUsedError;
  double? get pnl => throw _privateConstructorUsedError;
  double? get pnlPercentage => throw _privateConstructorUsedError;

  /// Serializes this PositionPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$PositionPatchImpl implements _PositionPatch {
  const _$PositionPatchImpl({this.rank, this.amount, this.amountUSD, this.pnl, this.pnlPercentage});

  factory _$PositionPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$PositionPatchImplFromJson(json);

  @override
  final int? rank;
  @override
  final double? amount;
  @override
  final double? amountUSD;
  @override
  final double? pnl;
  @override
  final double? pnlPercentage;

  @override
  String toString() {
    return 'PositionPatch(rank: $rank, amount: $amount, amountUSD: $amountUSD, pnl: $pnl, pnlPercentage: $pnlPercentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PositionPatchImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.amountUSD, amountUSD) || other.amountUSD == amountUSD) &&
            (identical(other.pnl, pnl) || other.pnl == pnl) &&
            (identical(other.pnlPercentage, pnlPercentage) ||
                other.pnlPercentage == pnlPercentage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rank, amount, amountUSD, pnl, pnlPercentage);

  @override
  Map<String, dynamic> toJson() {
    return _$$PositionPatchImplToJson(this);
  }
}

abstract class _PositionPatch implements PositionPatch {
  const factory _PositionPatch({
    final int? rank,
    final double? amount,
    final double? amountUSD,
    final double? pnl,
    final double? pnlPercentage,
  }) = _$PositionPatchImpl;

  factory _PositionPatch.fromJson(Map<String, dynamic> json) = _$PositionPatchImpl.fromJson;

  @override
  int? get rank;
  @override
  double? get amount;
  @override
  double? get amountUSD;
  @override
  double? get pnl;
  @override
  double? get pnlPercentage;
}
