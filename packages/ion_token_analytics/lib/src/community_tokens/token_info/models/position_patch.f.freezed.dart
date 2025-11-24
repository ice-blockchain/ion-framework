// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_patch.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

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

  /// Create a copy of PositionPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PositionPatchCopyWith<PositionPatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PositionPatchCopyWith<$Res> {
  factory $PositionPatchCopyWith(
    PositionPatch value,
    $Res Function(PositionPatch) then,
  ) = _$PositionPatchCopyWithImpl<$Res, PositionPatch>;
  @useResult
  $Res call({
    int? rank,
    double? amount,
    double? amountUSD,
    double? pnl,
    double? pnlPercentage,
  });
}

/// @nodoc
class _$PositionPatchCopyWithImpl<$Res, $Val extends PositionPatch>
    implements $PositionPatchCopyWith<$Res> {
  _$PositionPatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PositionPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = freezed,
    Object? amount = freezed,
    Object? amountUSD = freezed,
    Object? pnl = freezed,
    Object? pnlPercentage = freezed,
  }) {
    return _then(
      _value.copyWith(
            rank: freezed == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as int?,
            amount: freezed == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double?,
            amountUSD: freezed == amountUSD
                ? _value.amountUSD
                : amountUSD // ignore: cast_nullable_to_non_nullable
                      as double?,
            pnl: freezed == pnl
                ? _value.pnl
                : pnl // ignore: cast_nullable_to_non_nullable
                      as double?,
            pnlPercentage: freezed == pnlPercentage
                ? _value.pnlPercentage
                : pnlPercentage // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PositionPatchImplCopyWith<$Res>
    implements $PositionPatchCopyWith<$Res> {
  factory _$$PositionPatchImplCopyWith(
    _$PositionPatchImpl value,
    $Res Function(_$PositionPatchImpl) then,
  ) = __$$PositionPatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? rank,
    double? amount,
    double? amountUSD,
    double? pnl,
    double? pnlPercentage,
  });
}

/// @nodoc
class __$$PositionPatchImplCopyWithImpl<$Res>
    extends _$PositionPatchCopyWithImpl<$Res, _$PositionPatchImpl>
    implements _$$PositionPatchImplCopyWith<$Res> {
  __$$PositionPatchImplCopyWithImpl(
    _$PositionPatchImpl _value,
    $Res Function(_$PositionPatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PositionPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = freezed,
    Object? amount = freezed,
    Object? amountUSD = freezed,
    Object? pnl = freezed,
    Object? pnlPercentage = freezed,
  }) {
    return _then(
      _$PositionPatchImpl(
        rank: freezed == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as int?,
        amount: freezed == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double?,
        amountUSD: freezed == amountUSD
            ? _value.amountUSD
            : amountUSD // ignore: cast_nullable_to_non_nullable
                  as double?,
        pnl: freezed == pnl
            ? _value.pnl
            : pnl // ignore: cast_nullable_to_non_nullable
                  as double?,
        pnlPercentage: freezed == pnlPercentage
            ? _value.pnlPercentage
            : pnlPercentage // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PositionPatchImpl extends _PositionPatch {
  const _$PositionPatchImpl({
    this.rank,
    this.amount,
    this.amountUSD,
    this.pnl,
    this.pnlPercentage,
  }) : super._();

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
            (identical(other.amountUSD, amountUSD) ||
                other.amountUSD == amountUSD) &&
            (identical(other.pnl, pnl) || other.pnl == pnl) &&
            (identical(other.pnlPercentage, pnlPercentage) ||
                other.pnlPercentage == pnlPercentage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, rank, amount, amountUSD, pnl, pnlPercentage);

  /// Create a copy of PositionPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PositionPatchImplCopyWith<_$PositionPatchImpl> get copyWith =>
      __$$PositionPatchImplCopyWithImpl<_$PositionPatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PositionPatchImplToJson(this);
  }
}

abstract class _PositionPatch extends PositionPatch {
  const factory _PositionPatch({
    final int? rank,
    final double? amount,
    final double? amountUSD,
    final double? pnl,
    final double? pnlPercentage,
  }) = _$PositionPatchImpl;
  const _PositionPatch._() : super._();

  factory _PositionPatch.fromJson(Map<String, dynamic> json) =
      _$PositionPatchImpl.fromJson;

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

  /// Create a copy of PositionPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PositionPatchImplCopyWith<_$PositionPatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
