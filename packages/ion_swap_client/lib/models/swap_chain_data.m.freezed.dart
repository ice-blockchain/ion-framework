// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_chain_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapChainData _$SwapChainDataFromJson(Map<String, dynamic> json) {
  return _SwapChainData.fromJson(json);
}

/// @nodoc
mixin _$SwapChainData {
  int get chainIndex => throw _privateConstructorUsedError;
  String get chainName => throw _privateConstructorUsedError;
  String get dexTokenApproveAddress => throw _privateConstructorUsedError;

  /// Serializes this SwapChainData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapChainData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapChainDataCopyWith<SwapChainData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapChainDataCopyWith<$Res> {
  factory $SwapChainDataCopyWith(SwapChainData value, $Res Function(SwapChainData) then) =
      _$SwapChainDataCopyWithImpl<$Res, SwapChainData>;
  @useResult
  $Res call({int chainIndex, String chainName, String dexTokenApproveAddress});
}

/// @nodoc
class _$SwapChainDataCopyWithImpl<$Res, $Val extends SwapChainData>
    implements $SwapChainDataCopyWith<$Res> {
  _$SwapChainDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapChainData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainIndex = null,
    Object? chainName = null,
    Object? dexTokenApproveAddress = null,
  }) {
    return _then(_value.copyWith(
      chainIndex: null == chainIndex
          ? _value.chainIndex
          : chainIndex // ignore: cast_nullable_to_non_nullable
              as int,
      chainName: null == chainName
          ? _value.chainName
          : chainName // ignore: cast_nullable_to_non_nullable
              as String,
      dexTokenApproveAddress: null == dexTokenApproveAddress
          ? _value.dexTokenApproveAddress
          : dexTokenApproveAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwapChainDataImplCopyWith<$Res> implements $SwapChainDataCopyWith<$Res> {
  factory _$$SwapChainDataImplCopyWith(
          _$SwapChainDataImpl value, $Res Function(_$SwapChainDataImpl) then) =
      __$$SwapChainDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int chainIndex, String chainName, String dexTokenApproveAddress});
}

/// @nodoc
class __$$SwapChainDataImplCopyWithImpl<$Res>
    extends _$SwapChainDataCopyWithImpl<$Res, _$SwapChainDataImpl>
    implements _$$SwapChainDataImplCopyWith<$Res> {
  __$$SwapChainDataImplCopyWithImpl(
      _$SwapChainDataImpl _value, $Res Function(_$SwapChainDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapChainData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainIndex = null,
    Object? chainName = null,
    Object? dexTokenApproveAddress = null,
  }) {
    return _then(_$SwapChainDataImpl(
      chainIndex: null == chainIndex
          ? _value.chainIndex
          : chainIndex // ignore: cast_nullable_to_non_nullable
              as int,
      chainName: null == chainName
          ? _value.chainName
          : chainName // ignore: cast_nullable_to_non_nullable
              as String,
      dexTokenApproveAddress: null == dexTokenApproveAddress
          ? _value.dexTokenApproveAddress
          : dexTokenApproveAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapChainDataImpl implements _SwapChainData {
  _$SwapChainDataImpl(
      {required this.chainIndex, required this.chainName, required this.dexTokenApproveAddress});

  factory _$SwapChainDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapChainDataImplFromJson(json);

  @override
  final int chainIndex;
  @override
  final String chainName;
  @override
  final String dexTokenApproveAddress;

  @override
  String toString() {
    return 'SwapChainData(chainIndex: $chainIndex, chainName: $chainName, dexTokenApproveAddress: $dexTokenApproveAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapChainDataImpl &&
            (identical(other.chainIndex, chainIndex) || other.chainIndex == chainIndex) &&
            (identical(other.chainName, chainName) || other.chainName == chainName) &&
            (identical(other.dexTokenApproveAddress, dexTokenApproveAddress) ||
                other.dexTokenApproveAddress == dexTokenApproveAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, chainIndex, chainName, dexTokenApproveAddress);

  /// Create a copy of SwapChainData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapChainDataImplCopyWith<_$SwapChainDataImpl> get copyWith =>
      __$$SwapChainDataImplCopyWithImpl<_$SwapChainDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapChainDataImplToJson(
      this,
    );
  }
}

abstract class _SwapChainData implements SwapChainData {
  factory _SwapChainData(
      {required final int chainIndex,
      required final String chainName,
      required final String dexTokenApproveAddress}) = _$SwapChainDataImpl;

  factory _SwapChainData.fromJson(Map<String, dynamic> json) = _$SwapChainDataImpl.fromJson;

  @override
  int get chainIndex;
  @override
  String get chainName;
  @override
  String get dexTokenApproveAddress;

  /// Create a copy of SwapChainData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapChainDataImplCopyWith<_$SwapChainDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
