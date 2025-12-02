// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_quote_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapQuoteData _$SwapQuoteDataFromJson(Map<String, dynamic> json) {
  return _SwapQuoteData.fromJson(json);
}

/// @nodoc
mixin _$SwapQuoteData {
  String get chainIndex => throw _privateConstructorUsedError;

  /// Serializes this SwapQuoteData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapQuoteDataCopyWith<SwapQuoteData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapQuoteDataCopyWith<$Res> {
  factory $SwapQuoteDataCopyWith(SwapQuoteData value, $Res Function(SwapQuoteData) then) =
      _$SwapQuoteDataCopyWithImpl<$Res, SwapQuoteData>;
  @useResult
  $Res call({String chainIndex});
}

/// @nodoc
class _$SwapQuoteDataCopyWithImpl<$Res, $Val extends SwapQuoteData>
    implements $SwapQuoteDataCopyWith<$Res> {
  _$SwapQuoteDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainIndex = null,
  }) {
    return _then(_value.copyWith(
      chainIndex: null == chainIndex
          ? _value.chainIndex
          : chainIndex // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwapQuoteDataImplCopyWith<$Res> implements $SwapQuoteDataCopyWith<$Res> {
  factory _$$SwapQuoteDataImplCopyWith(
          _$SwapQuoteDataImpl value, $Res Function(_$SwapQuoteDataImpl) then) =
      __$$SwapQuoteDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String chainIndex});
}

/// @nodoc
class __$$SwapQuoteDataImplCopyWithImpl<$Res>
    extends _$SwapQuoteDataCopyWithImpl<$Res, _$SwapQuoteDataImpl>
    implements _$$SwapQuoteDataImplCopyWith<$Res> {
  __$$SwapQuoteDataImplCopyWithImpl(
      _$SwapQuoteDataImpl _value, $Res Function(_$SwapQuoteDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainIndex = null,
  }) {
    return _then(_$SwapQuoteDataImpl(
      chainIndex: null == chainIndex
          ? _value.chainIndex
          : chainIndex // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapQuoteDataImpl implements _SwapQuoteData {
  _$SwapQuoteDataImpl({required this.chainIndex});

  factory _$SwapQuoteDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapQuoteDataImplFromJson(json);

  @override
  final String chainIndex;

  @override
  String toString() {
    return 'SwapQuoteData(chainIndex: $chainIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapQuoteDataImpl &&
            (identical(other.chainIndex, chainIndex) || other.chainIndex == chainIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, chainIndex);

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapQuoteDataImplCopyWith<_$SwapQuoteDataImpl> get copyWith =>
      __$$SwapQuoteDataImplCopyWithImpl<_$SwapQuoteDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapQuoteDataImplToJson(
      this,
    );
  }
}

abstract class _SwapQuoteData implements SwapQuoteData {
  factory _SwapQuoteData({required final String chainIndex}) = _$SwapQuoteDataImpl;

  factory _SwapQuoteData.fromJson(Map<String, dynamic> json) = _$SwapQuoteDataImpl.fromJson;

  @override
  String get chainIndex;

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapQuoteDataImplCopyWith<_$SwapQuoteDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
