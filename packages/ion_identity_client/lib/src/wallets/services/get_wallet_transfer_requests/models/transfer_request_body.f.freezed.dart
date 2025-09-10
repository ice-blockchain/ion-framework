// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_request_body.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TransferRequestBody _$TransferRequestBodyFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'Native':
      return NativeTransferRequestBody.fromJson(json);
    case 'Erc721':
      return Erc721TransferRequestBody.fromJson(json);
    case 'Asa':
      return AsaTransferRequestBody.fromJson(json);
    case 'Erc20':
      return Erc20TransferRequestBody.fromJson(json);
    case 'Spl':
      return SplTransferRequestBody.fromJson(json);
    case 'Spl2022':
      return Spl2022TransferRequestBody.fromJson(json);
    case 'Sep41':
      return Sep41TransferRequestBody.fromJson(json);
    case 'Tep74':
      return Tep74TransferRequestBody.fromJson(json);
    case 'Trc10':
      return Trc10TransferRequestBody.fromJson(json);
    case 'Trc20':
      return Trc20TransferRequestBody.fromJson(json);
    case 'Trc721':
      return Trc721TransferRequestBody.fromJson(json);
    case 'Aip21':
      return Aip21TransferRequestBody.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'TransferRequestBody',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$TransferRequestBody {
  String get kind => throw _privateConstructorUsedError;
  String get to => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this TransferRequestBody to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransferRequestBodyCopyWith<TransferRequestBody> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferRequestBodyCopyWith<$Res> {
  factory $TransferRequestBodyCopyWith(
          TransferRequestBody value, $Res Function(TransferRequestBody) then) =
      _$TransferRequestBodyCopyWithImpl<$Res, TransferRequestBody>;
  @useResult
  $Res call({String kind, String to});
}

/// @nodoc
class _$TransferRequestBodyCopyWithImpl<$Res, $Val extends TransferRequestBody>
    implements $TransferRequestBodyCopyWith<$Res> {
  _$TransferRequestBodyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? to = null,
  }) {
    return _then(_value.copyWith(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NativeTransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$NativeTransferRequestBodyImplCopyWith(
          _$NativeTransferRequestBodyImpl value,
          $Res Function(_$NativeTransferRequestBodyImpl) then) =
      __$$NativeTransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String to, String amount, String? memo});
}

/// @nodoc
class __$$NativeTransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$NativeTransferRequestBodyImpl>
    implements _$$NativeTransferRequestBodyImplCopyWith<$Res> {
  __$$NativeTransferRequestBodyImplCopyWithImpl(
      _$NativeTransferRequestBodyImpl _value,
      $Res Function(_$NativeTransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? to = null,
    Object? amount = null,
    Object? memo = freezed,
  }) {
    return _then(_$NativeTransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NativeTransferRequestBodyImpl implements NativeTransferRequestBody {
  const _$NativeTransferRequestBodyImpl(
      {required this.kind, required this.to, required this.amount, this.memo});

  factory _$NativeTransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$NativeTransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String to;
  @override
  final String amount;
  @override
  final String? memo;

  @override
  String toString() {
    return 'TransferRequestBody.native(kind: $kind, to: $to, amount: $amount, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NativeTransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.memo, memo) || other.memo == memo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, to, amount, memo);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NativeTransferRequestBodyImplCopyWith<_$NativeTransferRequestBodyImpl>
      get copyWith => __$$NativeTransferRequestBodyImplCopyWithImpl<
          _$NativeTransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return native(kind, to, amount, memo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return native?.call(kind, to, amount, memo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (native != null) {
      return native(kind, to, amount, memo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return native(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return native?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (native != null) {
      return native(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NativeTransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class NativeTransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory NativeTransferRequestBody(
      {required final String kind,
      required final String to,
      required final String amount,
      final String? memo}) = _$NativeTransferRequestBodyImpl;

  factory NativeTransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$NativeTransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  @override
  String get to;
  String get amount;
  String? get memo;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NativeTransferRequestBodyImplCopyWith<_$NativeTransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Erc721TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Erc721TransferRequestBodyImplCopyWith(
          _$Erc721TransferRequestBodyImpl value,
          $Res Function(_$Erc721TransferRequestBodyImpl) then) =
      __$$Erc721TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String contract, String to, String tokenId});
}

/// @nodoc
class __$$Erc721TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Erc721TransferRequestBodyImpl>
    implements _$$Erc721TransferRequestBodyImplCopyWith<$Res> {
  __$$Erc721TransferRequestBodyImplCopyWithImpl(
      _$Erc721TransferRequestBodyImpl _value,
      $Res Function(_$Erc721TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? contract = null,
    Object? to = null,
    Object? tokenId = null,
  }) {
    return _then(_$Erc721TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      contract: null == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      tokenId: null == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Erc721TransferRequestBodyImpl implements Erc721TransferRequestBody {
  const _$Erc721TransferRequestBodyImpl(
      {required this.kind,
      required this.contract,
      required this.to,
      required this.tokenId});

  factory _$Erc721TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Erc721TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String contract;
  @override
  final String to;
  @override
  final String tokenId;

  @override
  String toString() {
    return 'TransferRequestBody.erc721(kind: $kind, contract: $contract, to: $to, tokenId: $tokenId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Erc721TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, contract, to, tokenId);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Erc721TransferRequestBodyImplCopyWith<_$Erc721TransferRequestBodyImpl>
      get copyWith => __$$Erc721TransferRequestBodyImplCopyWithImpl<
          _$Erc721TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return erc721(kind, contract, to, tokenId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return erc721?.call(kind, contract, to, tokenId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (erc721 != null) {
      return erc721(kind, contract, to, tokenId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return erc721(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return erc721?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (erc721 != null) {
      return erc721(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Erc721TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Erc721TransferRequestBody implements TransferRequestBody {
  const factory Erc721TransferRequestBody(
      {required final String kind,
      required final String contract,
      required final String to,
      required final String tokenId}) = _$Erc721TransferRequestBodyImpl;

  factory Erc721TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Erc721TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get contract;
  @override
  String get to;
  String get tokenId;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Erc721TransferRequestBodyImplCopyWith<_$Erc721TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AsaTransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$AsaTransferRequestBodyImplCopyWith(
          _$AsaTransferRequestBodyImpl value,
          $Res Function(_$AsaTransferRequestBodyImpl) then) =
      __$$AsaTransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String assetId, String to, String amount});
}

/// @nodoc
class __$$AsaTransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$AsaTransferRequestBodyImpl>
    implements _$$AsaTransferRequestBodyImplCopyWith<$Res> {
  __$$AsaTransferRequestBodyImplCopyWithImpl(
      _$AsaTransferRequestBodyImpl _value,
      $Res Function(_$AsaTransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? assetId = null,
    Object? to = null,
    Object? amount = null,
  }) {
    return _then(_$AsaTransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      assetId: null == assetId
          ? _value.assetId
          : assetId // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AsaTransferRequestBodyImpl implements AsaTransferRequestBody {
  const _$AsaTransferRequestBodyImpl(
      {required this.kind,
      required this.assetId,
      required this.to,
      required this.amount});

  factory _$AsaTransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$AsaTransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String assetId;
  @override
  final String to;
  @override
  final String amount;

  @override
  String toString() {
    return 'TransferRequestBody.asa(kind: $kind, assetId: $assetId, to: $to, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AsaTransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, assetId, to, amount);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AsaTransferRequestBodyImplCopyWith<_$AsaTransferRequestBodyImpl>
      get copyWith => __$$AsaTransferRequestBodyImplCopyWithImpl<
          _$AsaTransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return asa(kind, assetId, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return asa?.call(kind, assetId, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (asa != null) {
      return asa(kind, assetId, to, amount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return asa(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return asa?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (asa != null) {
      return asa(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AsaTransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class AsaTransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory AsaTransferRequestBody(
      {required final String kind,
      required final String assetId,
      required final String to,
      required final String amount}) = _$AsaTransferRequestBodyImpl;

  factory AsaTransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$AsaTransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get assetId;
  @override
  String get to;
  String get amount;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AsaTransferRequestBodyImplCopyWith<_$AsaTransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Erc20TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Erc20TransferRequestBodyImplCopyWith(
          _$Erc20TransferRequestBodyImpl value,
          $Res Function(_$Erc20TransferRequestBodyImpl) then) =
      __$$Erc20TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String contract, String amount, String to});
}

/// @nodoc
class __$$Erc20TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Erc20TransferRequestBodyImpl>
    implements _$$Erc20TransferRequestBodyImplCopyWith<$Res> {
  __$$Erc20TransferRequestBodyImplCopyWithImpl(
      _$Erc20TransferRequestBodyImpl _value,
      $Res Function(_$Erc20TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? contract = null,
    Object? amount = null,
    Object? to = null,
  }) {
    return _then(_$Erc20TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      contract: null == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Erc20TransferRequestBodyImpl implements Erc20TransferRequestBody {
  const _$Erc20TransferRequestBodyImpl(
      {required this.kind,
      required this.contract,
      required this.amount,
      required this.to});

  factory _$Erc20TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Erc20TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String contract;
  @override
  final String amount;
  @override
  final String to;

  @override
  String toString() {
    return 'TransferRequestBody.erc20(kind: $kind, contract: $contract, amount: $amount, to: $to)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Erc20TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.to, to) || other.to == to));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, contract, amount, to);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Erc20TransferRequestBodyImplCopyWith<_$Erc20TransferRequestBodyImpl>
      get copyWith => __$$Erc20TransferRequestBodyImplCopyWithImpl<
          _$Erc20TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return erc20(kind, contract, amount, to);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return erc20?.call(kind, contract, amount, to);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (erc20 != null) {
      return erc20(kind, contract, amount, to);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return erc20(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return erc20?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (erc20 != null) {
      return erc20(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Erc20TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Erc20TransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory Erc20TransferRequestBody(
      {required final String kind,
      required final String contract,
      required final String amount,
      required final String to}) = _$Erc20TransferRequestBodyImpl;

  factory Erc20TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Erc20TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get contract;
  String get amount;
  @override
  String get to;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Erc20TransferRequestBodyImplCopyWith<_$Erc20TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SplTransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$SplTransferRequestBodyImplCopyWith(
          _$SplTransferRequestBodyImpl value,
          $Res Function(_$SplTransferRequestBodyImpl) then) =
      __$$SplTransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String mint, String to, String amount});
}

/// @nodoc
class __$$SplTransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$SplTransferRequestBodyImpl>
    implements _$$SplTransferRequestBodyImplCopyWith<$Res> {
  __$$SplTransferRequestBodyImplCopyWithImpl(
      _$SplTransferRequestBodyImpl _value,
      $Res Function(_$SplTransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? mint = null,
    Object? to = null,
    Object? amount = null,
  }) {
    return _then(_$SplTransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      mint: null == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SplTransferRequestBodyImpl implements SplTransferRequestBody {
  const _$SplTransferRequestBodyImpl(
      {required this.kind,
      required this.mint,
      required this.to,
      required this.amount});

  factory _$SplTransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$SplTransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String mint;
  @override
  final String to;
  @override
  final String amount;

  @override
  String toString() {
    return 'TransferRequestBody.spl(kind: $kind, mint: $mint, to: $to, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SplTransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, mint, to, amount);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SplTransferRequestBodyImplCopyWith<_$SplTransferRequestBodyImpl>
      get copyWith => __$$SplTransferRequestBodyImplCopyWithImpl<
          _$SplTransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return spl(kind, mint, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return spl?.call(kind, mint, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (spl != null) {
      return spl(kind, mint, to, amount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return spl(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return spl?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (spl != null) {
      return spl(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SplTransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class SplTransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory SplTransferRequestBody(
      {required final String kind,
      required final String mint,
      required final String to,
      required final String amount}) = _$SplTransferRequestBodyImpl;

  factory SplTransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$SplTransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get mint;
  @override
  String get to;
  String get amount;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SplTransferRequestBodyImplCopyWith<_$SplTransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Spl2022TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Spl2022TransferRequestBodyImplCopyWith(
          _$Spl2022TransferRequestBodyImpl value,
          $Res Function(_$Spl2022TransferRequestBodyImpl) then) =
      __$$Spl2022TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String mint, String to, String amount});
}

/// @nodoc
class __$$Spl2022TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Spl2022TransferRequestBodyImpl>
    implements _$$Spl2022TransferRequestBodyImplCopyWith<$Res> {
  __$$Spl2022TransferRequestBodyImplCopyWithImpl(
      _$Spl2022TransferRequestBodyImpl _value,
      $Res Function(_$Spl2022TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? mint = null,
    Object? to = null,
    Object? amount = null,
  }) {
    return _then(_$Spl2022TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      mint: null == mint
          ? _value.mint
          : mint // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Spl2022TransferRequestBodyImpl implements Spl2022TransferRequestBody {
  const _$Spl2022TransferRequestBodyImpl(
      {required this.kind,
      required this.mint,
      required this.to,
      required this.amount});

  factory _$Spl2022TransferRequestBodyImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$Spl2022TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String mint;
  @override
  final String to;
  @override
  final String amount;

  @override
  String toString() {
    return 'TransferRequestBody.spl2022(kind: $kind, mint: $mint, to: $to, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Spl2022TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, mint, to, amount);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Spl2022TransferRequestBodyImplCopyWith<_$Spl2022TransferRequestBodyImpl>
      get copyWith => __$$Spl2022TransferRequestBodyImplCopyWithImpl<
          _$Spl2022TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return spl2022(kind, mint, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return spl2022?.call(kind, mint, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (spl2022 != null) {
      return spl2022(kind, mint, to, amount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return spl2022(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return spl2022?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (spl2022 != null) {
      return spl2022(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Spl2022TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Spl2022TransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory Spl2022TransferRequestBody(
      {required final String kind,
      required final String mint,
      required final String to,
      required final String amount}) = _$Spl2022TransferRequestBodyImpl;

  factory Spl2022TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Spl2022TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get mint;
  @override
  String get to;
  String get amount;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Spl2022TransferRequestBodyImplCopyWith<_$Spl2022TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Sep41TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Sep41TransferRequestBodyImplCopyWith(
          _$Sep41TransferRequestBodyImpl value,
          $Res Function(_$Sep41TransferRequestBodyImpl) then) =
      __$$Sep41TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String kind, String issuer, String assetCode, String to, String amount, String? memo});
}

/// @nodoc
class __$$Sep41TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Sep41TransferRequestBodyImpl>
    implements _$$Sep41TransferRequestBodyImplCopyWith<$Res> {
  __$$Sep41TransferRequestBodyImplCopyWithImpl(
      _$Sep41TransferRequestBodyImpl _value,
      $Res Function(_$Sep41TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? issuer = null,
    Object? assetCode = null,
    Object? to = null,
    Object? amount = null,
    Object? memo = freezed,
  }) {
    return _then(_$Sep41TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      issuer: null == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String,
      assetCode: null == assetCode
          ? _value.assetCode
          : assetCode // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Sep41TransferRequestBodyImpl implements Sep41TransferRequestBody {
  const _$Sep41TransferRequestBodyImpl(
      {required this.kind,
      required this.issuer,
      required this.assetCode,
      required this.to,
      required this.amount,
      this.memo});

  factory _$Sep41TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Sep41TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String issuer;
  @override
  final String assetCode;
  @override
  final String to;
  @override
  final String amount;
  @override
  final String? memo;

  @override
  String toString() {
    return 'TransferRequestBody.sep41(kind: $kind, issuer: $issuer, assetCode: $assetCode, to: $to, amount: $amount, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Sep41TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.assetCode, assetCode) ||
                other.assetCode == assetCode) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.memo, memo) || other.memo == memo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, kind, issuer, assetCode, to, amount, memo);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Sep41TransferRequestBodyImplCopyWith<_$Sep41TransferRequestBodyImpl>
      get copyWith => __$$Sep41TransferRequestBodyImplCopyWithImpl<
          _$Sep41TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return sep41(kind, issuer, assetCode, to, amount, memo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return sep41?.call(kind, issuer, assetCode, to, amount, memo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (sep41 != null) {
      return sep41(kind, issuer, assetCode, to, amount, memo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return sep41(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return sep41?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (sep41 != null) {
      return sep41(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Sep41TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Sep41TransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory Sep41TransferRequestBody(
      {required final String kind,
      required final String issuer,
      required final String assetCode,
      required final String to,
      required final String amount,
      final String? memo}) = _$Sep41TransferRequestBodyImpl;

  factory Sep41TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Sep41TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get issuer;
  String get assetCode;
  @override
  String get to;
  String get amount;
  String? get memo;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Sep41TransferRequestBodyImplCopyWith<_$Sep41TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Tep74TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Tep74TransferRequestBodyImplCopyWith(
          _$Tep74TransferRequestBodyImpl value,
          $Res Function(_$Tep74TransferRequestBodyImpl) then) =
      __$$Tep74TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String master, String to, String amount});
}

/// @nodoc
class __$$Tep74TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Tep74TransferRequestBodyImpl>
    implements _$$Tep74TransferRequestBodyImplCopyWith<$Res> {
  __$$Tep74TransferRequestBodyImplCopyWithImpl(
      _$Tep74TransferRequestBodyImpl _value,
      $Res Function(_$Tep74TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? master = null,
    Object? to = null,
    Object? amount = null,
  }) {
    return _then(_$Tep74TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      master: null == master
          ? _value.master
          : master // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Tep74TransferRequestBodyImpl implements Tep74TransferRequestBody {
  const _$Tep74TransferRequestBodyImpl(
      {required this.kind,
      required this.master,
      required this.to,
      required this.amount});

  factory _$Tep74TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Tep74TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String master;
  @override
  final String to;
  @override
  final String amount;

  @override
  String toString() {
    return 'TransferRequestBody.tep74(kind: $kind, master: $master, to: $to, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Tep74TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.master, master) || other.master == master) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, master, to, amount);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Tep74TransferRequestBodyImplCopyWith<_$Tep74TransferRequestBodyImpl>
      get copyWith => __$$Tep74TransferRequestBodyImplCopyWithImpl<
          _$Tep74TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return tep74(kind, master, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return tep74?.call(kind, master, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (tep74 != null) {
      return tep74(kind, master, to, amount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return tep74(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return tep74?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (tep74 != null) {
      return tep74(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Tep74TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Tep74TransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory Tep74TransferRequestBody(
      {required final String kind,
      required final String master,
      required final String to,
      required final String amount}) = _$Tep74TransferRequestBodyImpl;

  factory Tep74TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Tep74TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get master;
  @override
  String get to;
  String get amount;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Tep74TransferRequestBodyImplCopyWith<_$Tep74TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Trc10TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Trc10TransferRequestBodyImplCopyWith(
          _$Trc10TransferRequestBodyImpl value,
          $Res Function(_$Trc10TransferRequestBodyImpl) then) =
      __$$Trc10TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String tokenId, String to, String amount});
}

/// @nodoc
class __$$Trc10TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Trc10TransferRequestBodyImpl>
    implements _$$Trc10TransferRequestBodyImplCopyWith<$Res> {
  __$$Trc10TransferRequestBodyImplCopyWithImpl(
      _$Trc10TransferRequestBodyImpl _value,
      $Res Function(_$Trc10TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? tokenId = null,
    Object? to = null,
    Object? amount = null,
  }) {
    return _then(_$Trc10TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      tokenId: null == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Trc10TransferRequestBodyImpl implements Trc10TransferRequestBody {
  const _$Trc10TransferRequestBodyImpl(
      {required this.kind,
      required this.tokenId,
      required this.to,
      required this.amount});

  factory _$Trc10TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Trc10TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String tokenId;
  @override
  final String to;
  @override
  final String amount;

  @override
  String toString() {
    return 'TransferRequestBody.trc10(kind: $kind, tokenId: $tokenId, to: $to, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Trc10TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, tokenId, to, amount);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Trc10TransferRequestBodyImplCopyWith<_$Trc10TransferRequestBodyImpl>
      get copyWith => __$$Trc10TransferRequestBodyImplCopyWithImpl<
          _$Trc10TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return trc10(kind, tokenId, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return trc10?.call(kind, tokenId, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (trc10 != null) {
      return trc10(kind, tokenId, to, amount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return trc10(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return trc10?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (trc10 != null) {
      return trc10(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Trc10TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Trc10TransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory Trc10TransferRequestBody(
      {required final String kind,
      required final String tokenId,
      required final String to,
      required final String amount}) = _$Trc10TransferRequestBodyImpl;

  factory Trc10TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Trc10TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get tokenId;
  @override
  String get to;
  String get amount;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Trc10TransferRequestBodyImplCopyWith<_$Trc10TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Trc20TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Trc20TransferRequestBodyImplCopyWith(
          _$Trc20TransferRequestBodyImpl value,
          $Res Function(_$Trc20TransferRequestBodyImpl) then) =
      __$$Trc20TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String contract, String to, String amount});
}

/// @nodoc
class __$$Trc20TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Trc20TransferRequestBodyImpl>
    implements _$$Trc20TransferRequestBodyImplCopyWith<$Res> {
  __$$Trc20TransferRequestBodyImplCopyWithImpl(
      _$Trc20TransferRequestBodyImpl _value,
      $Res Function(_$Trc20TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? contract = null,
    Object? to = null,
    Object? amount = null,
  }) {
    return _then(_$Trc20TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      contract: null == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Trc20TransferRequestBodyImpl implements Trc20TransferRequestBody {
  const _$Trc20TransferRequestBodyImpl(
      {required this.kind,
      required this.contract,
      required this.to,
      required this.amount});

  factory _$Trc20TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Trc20TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String contract;
  @override
  final String to;
  @override
  final String amount;

  @override
  String toString() {
    return 'TransferRequestBody.trc20(kind: $kind, contract: $contract, to: $to, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Trc20TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, contract, to, amount);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Trc20TransferRequestBodyImplCopyWith<_$Trc20TransferRequestBodyImpl>
      get copyWith => __$$Trc20TransferRequestBodyImplCopyWithImpl<
          _$Trc20TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return trc20(kind, contract, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return trc20?.call(kind, contract, to, amount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (trc20 != null) {
      return trc20(kind, contract, to, amount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return trc20(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return trc20?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (trc20 != null) {
      return trc20(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Trc20TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Trc20TransferRequestBody
    implements TransferRequestBody, CoinTransferRequestBody {
  const factory Trc20TransferRequestBody(
      {required final String kind,
      required final String contract,
      required final String to,
      required final String amount}) = _$Trc20TransferRequestBodyImpl;

  factory Trc20TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Trc20TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get contract;
  @override
  String get to;
  String get amount;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Trc20TransferRequestBodyImplCopyWith<_$Trc20TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Trc721TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Trc721TransferRequestBodyImplCopyWith(
          _$Trc721TransferRequestBodyImpl value,
          $Res Function(_$Trc721TransferRequestBodyImpl) then) =
      __$$Trc721TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String contract, String to, String tokenId});
}

/// @nodoc
class __$$Trc721TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Trc721TransferRequestBodyImpl>
    implements _$$Trc721TransferRequestBodyImplCopyWith<$Res> {
  __$$Trc721TransferRequestBodyImplCopyWithImpl(
      _$Trc721TransferRequestBodyImpl _value,
      $Res Function(_$Trc721TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? contract = null,
    Object? to = null,
    Object? tokenId = null,
  }) {
    return _then(_$Trc721TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      contract: null == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      tokenId: null == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Trc721TransferRequestBodyImpl implements Trc721TransferRequestBody {
  const _$Trc721TransferRequestBodyImpl(
      {required this.kind,
      required this.contract,
      required this.to,
      required this.tokenId});

  factory _$Trc721TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Trc721TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String contract;
  @override
  final String to;
  @override
  final String tokenId;

  @override
  String toString() {
    return 'TransferRequestBody.trc721(kind: $kind, contract: $contract, to: $to, tokenId: $tokenId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Trc721TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, contract, to, tokenId);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Trc721TransferRequestBodyImplCopyWith<_$Trc721TransferRequestBodyImpl>
      get copyWith => __$$Trc721TransferRequestBodyImplCopyWithImpl<
          _$Trc721TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return trc721(kind, contract, to, tokenId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return trc721?.call(kind, contract, to, tokenId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (trc721 != null) {
      return trc721(kind, contract, to, tokenId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return trc721(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return trc721?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (trc721 != null) {
      return trc721(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Trc721TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Trc721TransferRequestBody implements TransferRequestBody {
  const factory Trc721TransferRequestBody(
      {required final String kind,
      required final String contract,
      required final String to,
      required final String tokenId}) = _$Trc721TransferRequestBodyImpl;

  factory Trc721TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Trc721TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  String get contract;
  @override
  String get to;
  String get tokenId;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Trc721TransferRequestBodyImplCopyWith<_$Trc721TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Aip21TransferRequestBodyImplCopyWith<$Res>
    implements $TransferRequestBodyCopyWith<$Res> {
  factory _$$Aip21TransferRequestBodyImplCopyWith(
          _$Aip21TransferRequestBodyImpl value,
          $Res Function(_$Aip21TransferRequestBodyImpl) then) =
      __$$Aip21TransferRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String to, String amount, String metadata});
}

/// @nodoc
class __$$Aip21TransferRequestBodyImplCopyWithImpl<$Res>
    extends _$TransferRequestBodyCopyWithImpl<$Res,
        _$Aip21TransferRequestBodyImpl>
    implements _$$Aip21TransferRequestBodyImplCopyWith<$Res> {
  __$$Aip21TransferRequestBodyImplCopyWithImpl(
      _$Aip21TransferRequestBodyImpl _value,
      $Res Function(_$Aip21TransferRequestBodyImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? to = null,
    Object? amount = null,
    Object? metadata = null,
  }) {
    return _then(_$Aip21TransferRequestBodyImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Aip21TransferRequestBodyImpl implements Aip21TransferRequestBody {
  const _$Aip21TransferRequestBodyImpl(
      {required this.kind,
      required this.to,
      required this.amount,
      required this.metadata});

  factory _$Aip21TransferRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$Aip21TransferRequestBodyImplFromJson(json);

  @override
  final String kind;
  @override
  final String to;
  @override
  final String amount;
  @override
  final String metadata;

  @override
  String toString() {
    return 'TransferRequestBody.aip21(kind: $kind, to: $to, amount: $amount, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Aip21TransferRequestBodyImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, kind, to, amount, metadata);

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Aip21TransferRequestBodyImplCopyWith<_$Aip21TransferRequestBodyImpl>
      get copyWith => __$$Aip21TransferRequestBodyImplCopyWithImpl<
          _$Aip21TransferRequestBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String kind, String to, String amount, String? memo) native,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        erc721,
    required TResult Function(
            String kind, String assetId, String to, String amount)
        asa,
    required TResult Function(
            String kind, String contract, String amount, String to)
        erc20,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl,
    required TResult Function(
            String kind, String mint, String to, String amount)
        spl2022,
    required TResult Function(String kind, String issuer, String assetCode,
            String to, String amount, String? memo)
        sep41,
    required TResult Function(
            String kind, String master, String to, String amount)
        tep74,
    required TResult Function(
            String kind, String tokenId, String to, String amount)
        trc10,
    required TResult Function(
            String kind, String contract, String to, String amount)
        trc20,
    required TResult Function(
            String kind, String contract, String to, String tokenId)
        trc721,
    required TResult Function(
            String kind, String to, String amount, String metadata)
        aip21,
  }) {
    return aip21(kind, to, amount, metadata);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String to, String amount, String? memo)? native,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult? Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult? Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult? Function(String kind, String mint, String to, String amount)? spl,
    TResult? Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult? Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult? Function(String kind, String master, String to, String amount)?
        tep74,
    TResult? Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult? Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult? Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult? Function(String kind, String to, String amount, String metadata)?
        aip21,
  }) {
    return aip21?.call(kind, to, amount, metadata);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String to, String amount, String? memo)? native,
    TResult Function(String kind, String contract, String to, String tokenId)?
        erc721,
    TResult Function(String kind, String assetId, String to, String amount)?
        asa,
    TResult Function(String kind, String contract, String amount, String to)?
        erc20,
    TResult Function(String kind, String mint, String to, String amount)? spl,
    TResult Function(String kind, String mint, String to, String amount)?
        spl2022,
    TResult Function(String kind, String issuer, String assetCode, String to,
            String amount, String? memo)?
        sep41,
    TResult Function(String kind, String master, String to, String amount)?
        tep74,
    TResult Function(String kind, String tokenId, String to, String amount)?
        trc10,
    TResult Function(String kind, String contract, String to, String amount)?
        trc20,
    TResult Function(String kind, String contract, String to, String tokenId)?
        trc721,
    TResult Function(String kind, String to, String amount, String metadata)?
        aip21,
    required TResult orElse(),
  }) {
    if (aip21 != null) {
      return aip21(kind, to, amount, metadata);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NativeTransferRequestBody value) native,
    required TResult Function(Erc721TransferRequestBody value) erc721,
    required TResult Function(AsaTransferRequestBody value) asa,
    required TResult Function(Erc20TransferRequestBody value) erc20,
    required TResult Function(SplTransferRequestBody value) spl,
    required TResult Function(Spl2022TransferRequestBody value) spl2022,
    required TResult Function(Sep41TransferRequestBody value) sep41,
    required TResult Function(Tep74TransferRequestBody value) tep74,
    required TResult Function(Trc10TransferRequestBody value) trc10,
    required TResult Function(Trc20TransferRequestBody value) trc20,
    required TResult Function(Trc721TransferRequestBody value) trc721,
    required TResult Function(Aip21TransferRequestBody value) aip21,
  }) {
    return aip21(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NativeTransferRequestBody value)? native,
    TResult? Function(Erc721TransferRequestBody value)? erc721,
    TResult? Function(AsaTransferRequestBody value)? asa,
    TResult? Function(Erc20TransferRequestBody value)? erc20,
    TResult? Function(SplTransferRequestBody value)? spl,
    TResult? Function(Spl2022TransferRequestBody value)? spl2022,
    TResult? Function(Sep41TransferRequestBody value)? sep41,
    TResult? Function(Tep74TransferRequestBody value)? tep74,
    TResult? Function(Trc10TransferRequestBody value)? trc10,
    TResult? Function(Trc20TransferRequestBody value)? trc20,
    TResult? Function(Trc721TransferRequestBody value)? trc721,
    TResult? Function(Aip21TransferRequestBody value)? aip21,
  }) {
    return aip21?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NativeTransferRequestBody value)? native,
    TResult Function(Erc721TransferRequestBody value)? erc721,
    TResult Function(AsaTransferRequestBody value)? asa,
    TResult Function(Erc20TransferRequestBody value)? erc20,
    TResult Function(SplTransferRequestBody value)? spl,
    TResult Function(Spl2022TransferRequestBody value)? spl2022,
    TResult Function(Sep41TransferRequestBody value)? sep41,
    TResult Function(Tep74TransferRequestBody value)? tep74,
    TResult Function(Trc10TransferRequestBody value)? trc10,
    TResult Function(Trc20TransferRequestBody value)? trc20,
    TResult Function(Trc721TransferRequestBody value)? trc721,
    TResult Function(Aip21TransferRequestBody value)? aip21,
    required TResult orElse(),
  }) {
    if (aip21 != null) {
      return aip21(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$Aip21TransferRequestBodyImplToJson(
      this,
    );
  }
}

abstract class Aip21TransferRequestBody implements TransferRequestBody {
  const factory Aip21TransferRequestBody(
      {required final String kind,
      required final String to,
      required final String amount,
      required final String metadata}) = _$Aip21TransferRequestBodyImpl;

  factory Aip21TransferRequestBody.fromJson(Map<String, dynamic> json) =
      _$Aip21TransferRequestBodyImpl.fromJson;

  @override
  String get kind;
  @override
  String get to;
  String get amount;
  String get metadata;

  /// Create a copy of TransferRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Aip21TransferRequestBodyImplCopyWith<_$Aip21TransferRequestBodyImpl>
      get copyWith => throw _privateConstructorUsedError;
}
