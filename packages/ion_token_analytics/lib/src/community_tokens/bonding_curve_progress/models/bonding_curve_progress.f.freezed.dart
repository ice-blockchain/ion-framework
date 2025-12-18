// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bonding_curve_progress.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BondingCurveProgress _$BondingCurveProgressFromJson(Map<String, dynamic> json) {
  return _BondingCurveProgress.fromJson(json);
}

/// @nodoc
mixin _$BondingCurveProgress {
  String get currentAmount => throw _privateConstructorUsedError;
  double get currentAmountUSD => throw _privateConstructorUsedError;
  String get goalAmount => throw _privateConstructorUsedError;
  double get goalAmountUSD => throw _privateConstructorUsedError;
  bool get migrated => throw _privateConstructorUsedError;
  String get raisedAmount => throw _privateConstructorUsedError;

  /// Serializes this BondingCurveProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BondingCurveProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BondingCurveProgressCopyWith<BondingCurveProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BondingCurveProgressCopyWith<$Res> {
  factory $BondingCurveProgressCopyWith(
    BondingCurveProgress value,
    $Res Function(BondingCurveProgress) then,
  ) = _$BondingCurveProgressCopyWithImpl<$Res, BondingCurveProgress>;
  @useResult
  $Res call({
    String currentAmount,
    double currentAmountUSD,
    String goalAmount,
    double goalAmountUSD,
    bool migrated,
    String raisedAmount,
  });
}

/// @nodoc
class _$BondingCurveProgressCopyWithImpl<
  $Res,
  $Val extends BondingCurveProgress
>
    implements $BondingCurveProgressCopyWith<$Res> {
  _$BondingCurveProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BondingCurveProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentAmount = null,
    Object? currentAmountUSD = null,
    Object? goalAmount = null,
    Object? goalAmountUSD = null,
    Object? migrated = null,
    Object? raisedAmount = null,
  }) {
    return _then(
      _value.copyWith(
            currentAmount: null == currentAmount
                ? _value.currentAmount
                : currentAmount // ignore: cast_nullable_to_non_nullable
                      as String,
            currentAmountUSD: null == currentAmountUSD
                ? _value.currentAmountUSD
                : currentAmountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            goalAmount: null == goalAmount
                ? _value.goalAmount
                : goalAmount // ignore: cast_nullable_to_non_nullable
                      as String,
            goalAmountUSD: null == goalAmountUSD
                ? _value.goalAmountUSD
                : goalAmountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            migrated: null == migrated
                ? _value.migrated
                : migrated // ignore: cast_nullable_to_non_nullable
                      as bool,
            raisedAmount: null == raisedAmount
                ? _value.raisedAmount
                : raisedAmount // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BondingCurveProgressImplCopyWith<$Res>
    implements $BondingCurveProgressCopyWith<$Res> {
  factory _$$BondingCurveProgressImplCopyWith(
    _$BondingCurveProgressImpl value,
    $Res Function(_$BondingCurveProgressImpl) then,
  ) = __$$BondingCurveProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String currentAmount,
    double currentAmountUSD,
    String goalAmount,
    double goalAmountUSD,
    bool migrated,
    String raisedAmount,
  });
}

/// @nodoc
class __$$BondingCurveProgressImplCopyWithImpl<$Res>
    extends _$BondingCurveProgressCopyWithImpl<$Res, _$BondingCurveProgressImpl>
    implements _$$BondingCurveProgressImplCopyWith<$Res> {
  __$$BondingCurveProgressImplCopyWithImpl(
    _$BondingCurveProgressImpl _value,
    $Res Function(_$BondingCurveProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BondingCurveProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentAmount = null,
    Object? currentAmountUSD = null,
    Object? goalAmount = null,
    Object? goalAmountUSD = null,
    Object? migrated = null,
    Object? raisedAmount = null,
  }) {
    return _then(
      _$BondingCurveProgressImpl(
        currentAmount: null == currentAmount
            ? _value.currentAmount
            : currentAmount // ignore: cast_nullable_to_non_nullable
                  as String,
        currentAmountUSD: null == currentAmountUSD
            ? _value.currentAmountUSD
            : currentAmountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        goalAmount: null == goalAmount
            ? _value.goalAmount
            : goalAmount // ignore: cast_nullable_to_non_nullable
                  as String,
        goalAmountUSD: null == goalAmountUSD
            ? _value.goalAmountUSD
            : goalAmountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        migrated: null == migrated
            ? _value.migrated
            : migrated // ignore: cast_nullable_to_non_nullable
                  as bool,
        raisedAmount: null == raisedAmount
            ? _value.raisedAmount
            : raisedAmount // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BondingCurveProgressImpl implements _BondingCurveProgress {
  const _$BondingCurveProgressImpl({
    required this.currentAmount,
    required this.currentAmountUSD,
    required this.goalAmount,
    required this.goalAmountUSD,
    required this.migrated,
    required this.raisedAmount,
  });

  factory _$BondingCurveProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$BondingCurveProgressImplFromJson(json);

  @override
  final String currentAmount;
  @override
  final double currentAmountUSD;
  @override
  final String goalAmount;
  @override
  final double goalAmountUSD;
  @override
  final bool migrated;
  @override
  final String raisedAmount;

  @override
  String toString() {
    return 'BondingCurveProgress(currentAmount: $currentAmount, currentAmountUSD: $currentAmountUSD, goalAmount: $goalAmount, goalAmountUSD: $goalAmountUSD, migrated: $migrated, raisedAmount: $raisedAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BondingCurveProgressImpl &&
            (identical(other.currentAmount, currentAmount) ||
                other.currentAmount == currentAmount) &&
            (identical(other.currentAmountUSD, currentAmountUSD) ||
                other.currentAmountUSD == currentAmountUSD) &&
            (identical(other.goalAmount, goalAmount) ||
                other.goalAmount == goalAmount) &&
            (identical(other.goalAmountUSD, goalAmountUSD) ||
                other.goalAmountUSD == goalAmountUSD) &&
            (identical(other.migrated, migrated) ||
                other.migrated == migrated) &&
            (identical(other.raisedAmount, raisedAmount) ||
                other.raisedAmount == raisedAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentAmount,
    currentAmountUSD,
    goalAmount,
    goalAmountUSD,
    migrated,
    raisedAmount,
  );

  /// Create a copy of BondingCurveProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BondingCurveProgressImplCopyWith<_$BondingCurveProgressImpl>
  get copyWith =>
      __$$BondingCurveProgressImplCopyWithImpl<_$BondingCurveProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BondingCurveProgressImplToJson(this);
  }
}

abstract class _BondingCurveProgress implements BondingCurveProgress {
  const factory _BondingCurveProgress({
    required final String currentAmount,
    required final double currentAmountUSD,
    required final String goalAmount,
    required final double goalAmountUSD,
    required final bool migrated,
    required final String raisedAmount,
  }) = _$BondingCurveProgressImpl;

  factory _BondingCurveProgress.fromJson(Map<String, dynamic> json) =
      _$BondingCurveProgressImpl.fromJson;

  @override
  String get currentAmount;
  @override
  double get currentAmountUSD;
  @override
  String get goalAmount;
  @override
  double get goalAmountUSD;
  @override
  bool get migrated;
  @override
  String get raisedAmount;

  /// Create a copy of BondingCurveProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BondingCurveProgressImplCopyWith<_$BondingCurveProgressImpl>
  get copyWith => throw _privateConstructorUsedError;
}

BondingCurveProgressPatch _$BondingCurveProgressPatchFromJson(
  Map<String, dynamic> json,
) {
  return _BondingCurveProgressPatch.fromJson(json);
}

/// @nodoc
mixin _$BondingCurveProgressPatch {
  String? get currentAmount => throw _privateConstructorUsedError;
  double? get currentAmountUSD => throw _privateConstructorUsedError;
  String? get goalAmount => throw _privateConstructorUsedError;
  double? get goalAmountUSD => throw _privateConstructorUsedError;
  bool? get migrated => throw _privateConstructorUsedError;
  String? get raisedAmount => throw _privateConstructorUsedError;

  /// Serializes this BondingCurveProgressPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$BondingCurveProgressPatchImpl implements _BondingCurveProgressPatch {
  const _$BondingCurveProgressPatchImpl({
    this.currentAmount,
    this.currentAmountUSD,
    this.goalAmount,
    this.goalAmountUSD,
    this.migrated,
    this.raisedAmount,
  });

  factory _$BondingCurveProgressPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$BondingCurveProgressPatchImplFromJson(json);

  @override
  final String? currentAmount;
  @override
  final double? currentAmountUSD;
  @override
  final String? goalAmount;
  @override
  final double? goalAmountUSD;
  @override
  final bool? migrated;
  @override
  final String? raisedAmount;

  @override
  String toString() {
    return 'BondingCurveProgressPatch(currentAmount: $currentAmount, currentAmountUSD: $currentAmountUSD, goalAmount: $goalAmount, goalAmountUSD: $goalAmountUSD, migrated: $migrated, raisedAmount: $raisedAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BondingCurveProgressPatchImpl &&
            (identical(other.currentAmount, currentAmount) ||
                other.currentAmount == currentAmount) &&
            (identical(other.currentAmountUSD, currentAmountUSD) ||
                other.currentAmountUSD == currentAmountUSD) &&
            (identical(other.goalAmount, goalAmount) ||
                other.goalAmount == goalAmount) &&
            (identical(other.goalAmountUSD, goalAmountUSD) ||
                other.goalAmountUSD == goalAmountUSD) &&
            (identical(other.migrated, migrated) ||
                other.migrated == migrated) &&
            (identical(other.raisedAmount, raisedAmount) ||
                other.raisedAmount == raisedAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentAmount,
    currentAmountUSD,
    goalAmount,
    goalAmountUSD,
    migrated,
    raisedAmount,
  );

  @override
  Map<String, dynamic> toJson() {
    return _$$BondingCurveProgressPatchImplToJson(this);
  }
}

abstract class _BondingCurveProgressPatch implements BondingCurveProgressPatch {
  const factory _BondingCurveProgressPatch({
    final String? currentAmount,
    final double? currentAmountUSD,
    final String? goalAmount,
    final double? goalAmountUSD,
    final bool? migrated,
    final String? raisedAmount,
  }) = _$BondingCurveProgressPatchImpl;

  factory _BondingCurveProgressPatch.fromJson(Map<String, dynamic> json) =
      _$BondingCurveProgressPatchImpl.fromJson;

  @override
  String? get currentAmount;
  @override
  double? get currentAmountUSD;
  @override
  String? get goalAmount;
  @override
  double? get goalAmountUSD;
  @override
  bool? get migrated;
  @override
  String? get raisedAmount;
}
