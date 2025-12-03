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
  $Res call({String rate});
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
  }) {
    return _then(_value.copyWith(
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
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
  $Res call({String rate});
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
  }) {
    return _then(_$RelayQuoteDetailsImpl(
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayQuoteDetailsImpl implements _RelayQuoteDetails {
  _$RelayQuoteDetailsImpl({required this.rate});

  factory _$RelayQuoteDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayQuoteDetailsImplFromJson(json);

  @override
  final String rate;

  @override
  String toString() {
    return 'RelayQuoteDetails(rate: $rate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayQuoteDetailsImpl &&
            (identical(other.rate, rate) || other.rate == rate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rate);

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
  factory _RelayQuoteDetails({required final String rate}) =
      _$RelayQuoteDetailsImpl;

  factory _RelayQuoteDetails.fromJson(Map<String, dynamic> json) =
      _$RelayQuoteDetailsImpl.fromJson;

  @override
  String get rate;

  /// Create a copy of RelayQuoteDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayQuoteDetailsImplCopyWith<_$RelayQuoteDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
