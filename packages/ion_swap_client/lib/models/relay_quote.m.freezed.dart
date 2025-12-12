// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_quote.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayQuote _$RelayQuoteFromJson(Map<String, dynamic> json) {
  return _RelayQuote.fromJson(json);
}

/// @nodoc
mixin _$RelayQuote {
  RelayQuoteDetails get details => throw _privateConstructorUsedError;
  List<RelayStep> get steps => throw _privateConstructorUsedError;
  @JsonKey(name: 'fees')
  Map<String, dynamic>? get fees => throw _privateConstructorUsedError;

  /// Serializes this RelayQuote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayQuote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayQuoteCopyWith<RelayQuote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayQuoteCopyWith<$Res> {
  factory $RelayQuoteCopyWith(
          RelayQuote value, $Res Function(RelayQuote) then) =
      _$RelayQuoteCopyWithImpl<$Res, RelayQuote>;
  @useResult
  $Res call(
      {RelayQuoteDetails details,
      List<RelayStep> steps,
      @JsonKey(name: 'fees') Map<String, dynamic>? fees});

  $RelayQuoteDetailsCopyWith<$Res> get details;
}

/// @nodoc
class _$RelayQuoteCopyWithImpl<$Res, $Val extends RelayQuote>
    implements $RelayQuoteCopyWith<$Res> {
  _$RelayQuoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayQuote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? details = null,
    Object? steps = null,
    Object? fees = freezed,
  }) {
    return _then(_value.copyWith(
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as RelayQuoteDetails,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RelayStep>,
      fees: freezed == fees
          ? _value.fees
          : fees // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }

  /// Create a copy of RelayQuote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelayQuoteDetailsCopyWith<$Res> get details {
    return $RelayQuoteDetailsCopyWith<$Res>(_value.details, (value) {
      return _then(_value.copyWith(details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RelayQuoteImplCopyWith<$Res>
    implements $RelayQuoteCopyWith<$Res> {
  factory _$$RelayQuoteImplCopyWith(
          _$RelayQuoteImpl value, $Res Function(_$RelayQuoteImpl) then) =
      __$$RelayQuoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {RelayQuoteDetails details,
      List<RelayStep> steps,
      @JsonKey(name: 'fees') Map<String, dynamic>? fees});

  @override
  $RelayQuoteDetailsCopyWith<$Res> get details;
}

/// @nodoc
class __$$RelayQuoteImplCopyWithImpl<$Res>
    extends _$RelayQuoteCopyWithImpl<$Res, _$RelayQuoteImpl>
    implements _$$RelayQuoteImplCopyWith<$Res> {
  __$$RelayQuoteImplCopyWithImpl(
      _$RelayQuoteImpl _value, $Res Function(_$RelayQuoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayQuote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? details = null,
    Object? steps = null,
    Object? fees = freezed,
  }) {
    return _then(_$RelayQuoteImpl(
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as RelayQuoteDetails,
      steps: null == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RelayStep>,
      fees: freezed == fees
          ? _value._fees
          : fees // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayQuoteImpl implements _RelayQuote {
  _$RelayQuoteImpl(
      {required this.details,
      required final List<RelayStep> steps,
      @JsonKey(name: 'fees') final Map<String, dynamic>? fees})
      : _steps = steps,
        _fees = fees;

  factory _$RelayQuoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayQuoteImplFromJson(json);

  @override
  final RelayQuoteDetails details;
  final List<RelayStep> _steps;
  @override
  List<RelayStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  final Map<String, dynamic>? _fees;
  @override
  @JsonKey(name: 'fees')
  Map<String, dynamic>? get fees {
    final value = _fees;
    if (value == null) return null;
    if (_fees is EqualUnmodifiableMapView) return _fees;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'RelayQuote(details: $details, steps: $steps, fees: $fees)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayQuoteImpl &&
            (identical(other.details, details) || other.details == details) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            const DeepCollectionEquality().equals(other._fees, _fees));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      details,
      const DeepCollectionEquality().hash(_steps),
      const DeepCollectionEquality().hash(_fees));

  /// Create a copy of RelayQuote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayQuoteImplCopyWith<_$RelayQuoteImpl> get copyWith =>
      __$$RelayQuoteImplCopyWithImpl<_$RelayQuoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayQuoteImplToJson(
      this,
    );
  }
}

abstract class _RelayQuote implements RelayQuote {
  factory _RelayQuote(
          {required final RelayQuoteDetails details,
          required final List<RelayStep> steps,
          @JsonKey(name: 'fees') final Map<String, dynamic>? fees}) =
      _$RelayQuoteImpl;

  factory _RelayQuote.fromJson(Map<String, dynamic> json) =
      _$RelayQuoteImpl.fromJson;

  @override
  RelayQuoteDetails get details;
  @override
  List<RelayStep> get steps;
  @override
  @JsonKey(name: 'fees')
  Map<String, dynamic>? get fees;

  /// Create a copy of RelayQuote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayQuoteImplCopyWith<_$RelayQuoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
