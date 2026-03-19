// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_quote_details.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayQuoteDetails _$RelayQuoteDetailsFromJson(Map<String, dynamic> json) {
  return _RelayQuoteDetails.fromJson(json);
}

/// @nodoc
mixin _$RelayQuoteDetails {
  String get rate => throw _privateConstructorUsedError;
  RelaySwapImpact? get swapImpact => throw _privateConstructorUsedError;

  /// Serializes this RelayQuoteDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayQuoteDetailsCopyWith<RelayQuoteDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayQuoteDetailsCopyWith<$Res> {
  factory $RelayQuoteDetailsCopyWith(
          RelayQuoteDetails value, $Res Function(RelayQuoteDetails) then) =
      _$RelayQuoteDetailsCopyWithImpl<$Res, RelayQuoteDetails>;
  @useResult
  $Res call({String rate, RelaySwapImpact? swapImpact});

  $RelaySwapImpactCopyWith<$Res>? get swapImpact;
}

/// @nodoc
class _$RelayQuoteDetailsCopyWithImpl<$Res, $Val extends RelayQuoteDetails>
    implements $RelayQuoteDetailsCopyWith<$Res> {
  _$RelayQuoteDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rate = null,
    Object? swapImpact = freezed,
  }) {
    return _then(_value.copyWith(
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as String,
      swapImpact: freezed == swapImpact
          ? _value.swapImpact
          : swapImpact // ignore: cast_nullable_to_non_nullable
              as RelaySwapImpact?,
    ) as $Val);
  }

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelaySwapImpactCopyWith<$Res>? get swapImpact {
    if (_value.swapImpact == null) {
      return null;
    }

    return $RelaySwapImpactCopyWith<$Res>(_value.swapImpact!, (value) {
      return _then(_value.copyWith(swapImpact: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RelayQuoteDetailsImplCopyWith<$Res>
    implements $RelayQuoteDetailsCopyWith<$Res> {
  factory _$$RelayQuoteDetailsImplCopyWith(_$RelayQuoteDetailsImpl value,
          $Res Function(_$RelayQuoteDetailsImpl) then) =
      __$$RelayQuoteDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rate, RelaySwapImpact? swapImpact});

  @override
  $RelaySwapImpactCopyWith<$Res>? get swapImpact;
}

/// @nodoc
class __$$RelayQuoteDetailsImplCopyWithImpl<$Res>
    extends _$RelayQuoteDetailsCopyWithImpl<$Res, _$RelayQuoteDetailsImpl>
    implements _$$RelayQuoteDetailsImplCopyWith<$Res> {
  __$$RelayQuoteDetailsImplCopyWithImpl(_$RelayQuoteDetailsImpl _value,
      $Res Function(_$RelayQuoteDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rate = null,
    Object? swapImpact = freezed,
  }) {
    return _then(_$RelayQuoteDetailsImpl(
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as String,
      swapImpact: freezed == swapImpact
          ? _value.swapImpact
          : swapImpact // ignore: cast_nullable_to_non_nullable
              as RelaySwapImpact?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayQuoteDetailsImpl implements _RelayQuoteDetails {
  _$RelayQuoteDetailsImpl({required this.rate, this.swapImpact});

  factory _$RelayQuoteDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayQuoteDetailsImplFromJson(json);

  @override
  final String rate;
  @override
  final RelaySwapImpact? swapImpact;

  @override
  String toString() {
    return 'RelayQuoteDetails(rate: $rate, swapImpact: $swapImpact)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayQuoteDetailsImpl &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.swapImpact, swapImpact) ||
                other.swapImpact == swapImpact));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rate, swapImpact);

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayQuoteDetailsImplCopyWith<_$RelayQuoteDetailsImpl> get copyWith =>
      __$$RelayQuoteDetailsImplCopyWithImpl<_$RelayQuoteDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayQuoteDetailsImplToJson(
      this,
    );
  }
}

abstract class _RelayQuoteDetails implements RelayQuoteDetails {
  factory _RelayQuoteDetails(
      {required final String rate,
      final RelaySwapImpact? swapImpact}) = _$RelayQuoteDetailsImpl;

  factory _RelayQuoteDetails.fromJson(Map<String, dynamic> json) =
      _$RelayQuoteDetailsImpl.fromJson;

  @override
  String get rate;
  @override
  RelaySwapImpact? get swapImpact;

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayQuoteDetailsImplCopyWith<_$RelayQuoteDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RelaySwapImpact _$RelaySwapImpactFromJson(Map<String, dynamic> json) {
  return _RelaySwapImpact.fromJson(json);
}

/// @nodoc
mixin _$RelaySwapImpact {
  String? get percent => throw _privateConstructorUsedError;

  /// Serializes this RelaySwapImpact to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelaySwapImpact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelaySwapImpactCopyWith<RelaySwapImpact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelaySwapImpactCopyWith<$Res> {
  factory $RelaySwapImpactCopyWith(
          RelaySwapImpact value, $Res Function(RelaySwapImpact) then) =
      _$RelaySwapImpactCopyWithImpl<$Res, RelaySwapImpact>;
  @useResult
  $Res call({String? percent});
}

/// @nodoc
class _$RelaySwapImpactCopyWithImpl<$Res, $Val extends RelaySwapImpact>
    implements $RelaySwapImpactCopyWith<$Res> {
  _$RelaySwapImpactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelaySwapImpact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = freezed,
  }) {
    return _then(_value.copyWith(
      percent: freezed == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelaySwapImpactImplCopyWith<$Res>
    implements $RelaySwapImpactCopyWith<$Res> {
  factory _$$RelaySwapImpactImplCopyWith(_$RelaySwapImpactImpl value,
          $Res Function(_$RelaySwapImpactImpl) then) =
      __$$RelaySwapImpactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? percent});
}

/// @nodoc
class __$$RelaySwapImpactImplCopyWithImpl<$Res>
    extends _$RelaySwapImpactCopyWithImpl<$Res, _$RelaySwapImpactImpl>
    implements _$$RelaySwapImpactImplCopyWith<$Res> {
  __$$RelaySwapImpactImplCopyWithImpl(
      _$RelaySwapImpactImpl _value, $Res Function(_$RelaySwapImpactImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelaySwapImpact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = freezed,
  }) {
    return _then(_$RelaySwapImpactImpl(
      percent: freezed == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelaySwapImpactImpl implements _RelaySwapImpact {
  _$RelaySwapImpactImpl({this.percent});

  factory _$RelaySwapImpactImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelaySwapImpactImplFromJson(json);

  @override
  final String? percent;

  @override
  String toString() {
    return 'RelaySwapImpact(percent: $percent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelaySwapImpactImpl &&
            (identical(other.percent, percent) || other.percent == percent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, percent);

  /// Create a copy of RelaySwapImpact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelaySwapImpactImplCopyWith<_$RelaySwapImpactImpl> get copyWith =>
      __$$RelaySwapImpactImplCopyWithImpl<_$RelaySwapImpactImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelaySwapImpactImplToJson(
      this,
    );
  }
}

abstract class _RelaySwapImpact implements RelaySwapImpact {
  factory _RelaySwapImpact({final String? percent}) = _$RelaySwapImpactImpl;

  factory _RelaySwapImpact.fromJson(Map<String, dynamic> json) =
      _$RelaySwapImpactImpl.fromJson;

  @override
  String? get percent;

  /// Create a copy of RelaySwapImpact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelaySwapImpactImplCopyWith<_$RelaySwapImpactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
