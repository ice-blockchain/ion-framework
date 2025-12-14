// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evm_broadcast_request.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EvmBroadcastRequest _$EvmBroadcastRequestFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'transactionHex':
      return EvmTransactionHexBroadcastRequest.fromJson(json);
    case 'transactionJson':
      return EvmTransactionJsonBroadcastRequest.fromJson(json);
    case 'userOperations':
      return EvmUserOperationsBroadcastRequest.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'EvmBroadcastRequest',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$EvmBroadcastRequest {
  /// The kind, should be 'Transaction'
  String get kind => throw _privateConstructorUsedError;

  /// Optional idempotency key
  @JsonKey(includeIfNull: false)
  String? get externalId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionHex,
    required TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionJson,
    required TResult Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        userOperations,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult? Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult? Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult Function(List<EvmUserOperation> userOperations, String feeSponsorId,
            String kind, @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EvmTransactionHexBroadcastRequest value)
        transactionHex,
    required TResult Function(EvmTransactionJsonBroadcastRequest value)
        transactionJson,
    required TResult Function(EvmUserOperationsBroadcastRequest value)
        userOperations,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult? Function(EvmTransactionJsonBroadcastRequest value)?
        transactionJson,
    TResult? Function(EvmUserOperationsBroadcastRequest value)? userOperations,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult Function(EvmTransactionJsonBroadcastRequest value)? transactionJson,
    TResult Function(EvmUserOperationsBroadcastRequest value)? userOperations,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this EvmBroadcastRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvmBroadcastRequestCopyWith<EvmBroadcastRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvmBroadcastRequestCopyWith<$Res> {
  factory $EvmBroadcastRequestCopyWith(
          EvmBroadcastRequest value, $Res Function(EvmBroadcastRequest) then) =
      _$EvmBroadcastRequestCopyWithImpl<$Res, EvmBroadcastRequest>;
  @useResult
  $Res call({String kind, @JsonKey(includeIfNull: false) String? externalId});
}

/// @nodoc
class _$EvmBroadcastRequestCopyWithImpl<$Res, $Val extends EvmBroadcastRequest>
    implements $EvmBroadcastRequestCopyWith<$Res> {
  _$EvmBroadcastRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? externalId = freezed,
  }) {
    return _then(_value.copyWith(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvmTransactionHexBroadcastRequestImplCopyWith<$Res>
    implements $EvmBroadcastRequestCopyWith<$Res> {
  factory _$$EvmTransactionHexBroadcastRequestImplCopyWith(
          _$EvmTransactionHexBroadcastRequestImpl value,
          $Res Function(_$EvmTransactionHexBroadcastRequestImpl) then) =
      __$$EvmTransactionHexBroadcastRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String transaction,
      String kind,
      @JsonKey(includeIfNull: false) String? externalId});
}

/// @nodoc
class __$$EvmTransactionHexBroadcastRequestImplCopyWithImpl<$Res>
    extends _$EvmBroadcastRequestCopyWithImpl<$Res,
        _$EvmTransactionHexBroadcastRequestImpl>
    implements _$$EvmTransactionHexBroadcastRequestImplCopyWith<$Res> {
  __$$EvmTransactionHexBroadcastRequestImplCopyWithImpl(
      _$EvmTransactionHexBroadcastRequestImpl _value,
      $Res Function(_$EvmTransactionHexBroadcastRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transaction = null,
    Object? kind = null,
    Object? externalId = freezed,
  }) {
    return _then(_$EvmTransactionHexBroadcastRequestImpl(
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvmTransactionHexBroadcastRequestImpl
    implements EvmTransactionHexBroadcastRequest {
  const _$EvmTransactionHexBroadcastRequestImpl(
      {required this.transaction,
      this.kind = 'Transaction',
      @JsonKey(includeIfNull: false) this.externalId,
      final String? $type})
      : $type = $type ?? 'transactionHex';

  factory _$EvmTransactionHexBroadcastRequestImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$EvmTransactionHexBroadcastRequestImplFromJson(json);

  /// Unsigned transaction as hex string
  @override
  final String transaction;

  /// The kind, should be 'Transaction'
  @override
  @JsonKey()
  final String kind;

  /// Optional idempotency key
  @override
  @JsonKey(includeIfNull: false)
  final String? externalId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'EvmBroadcastRequest.transactionHex(transaction: $transaction, kind: $kind, externalId: $externalId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvmTransactionHexBroadcastRequestImpl &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, transaction, kind, externalId);

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvmTransactionHexBroadcastRequestImplCopyWith<
          _$EvmTransactionHexBroadcastRequestImpl>
      get copyWith => __$$EvmTransactionHexBroadcastRequestImplCopyWithImpl<
          _$EvmTransactionHexBroadcastRequestImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionHex,
    required TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionJson,
    required TResult Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        userOperations,
  }) {
    return transactionHex(transaction, kind, externalId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult? Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult? Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
  }) {
    return transactionHex?.call(transaction, kind, externalId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult Function(List<EvmUserOperation> userOperations, String feeSponsorId,
            String kind, @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
    required TResult orElse(),
  }) {
    if (transactionHex != null) {
      return transactionHex(transaction, kind, externalId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EvmTransactionHexBroadcastRequest value)
        transactionHex,
    required TResult Function(EvmTransactionJsonBroadcastRequest value)
        transactionJson,
    required TResult Function(EvmUserOperationsBroadcastRequest value)
        userOperations,
  }) {
    return transactionHex(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult? Function(EvmTransactionJsonBroadcastRequest value)?
        transactionJson,
    TResult? Function(EvmUserOperationsBroadcastRequest value)? userOperations,
  }) {
    return transactionHex?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult Function(EvmTransactionJsonBroadcastRequest value)? transactionJson,
    TResult Function(EvmUserOperationsBroadcastRequest value)? userOperations,
    required TResult orElse(),
  }) {
    if (transactionHex != null) {
      return transactionHex(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$EvmTransactionHexBroadcastRequestImplToJson(
      this,
    );
  }
}

abstract class EvmTransactionHexBroadcastRequest
    implements EvmBroadcastRequest {
  const factory EvmTransactionHexBroadcastRequest(
          {required final String transaction,
          final String kind,
          @JsonKey(includeIfNull: false) final String? externalId}) =
      _$EvmTransactionHexBroadcastRequestImpl;

  factory EvmTransactionHexBroadcastRequest.fromJson(
          Map<String, dynamic> json) =
      _$EvmTransactionHexBroadcastRequestImpl.fromJson;

  /// Unsigned transaction as hex string
  String get transaction;

  /// The kind, should be 'Transaction'
  @override
  String get kind;

  /// Optional idempotency key
  @override
  @JsonKey(includeIfNull: false)
  String? get externalId;

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvmTransactionHexBroadcastRequestImplCopyWith<
          _$EvmTransactionHexBroadcastRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EvmTransactionJsonBroadcastRequestImplCopyWith<$Res>
    implements $EvmBroadcastRequestCopyWith<$Res> {
  factory _$$EvmTransactionJsonBroadcastRequestImplCopyWith(
          _$EvmTransactionJsonBroadcastRequestImpl value,
          $Res Function(_$EvmTransactionJsonBroadcastRequestImpl) then) =
      __$$EvmTransactionJsonBroadcastRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {EvmTransactionJson transaction,
      String kind,
      @JsonKey(includeIfNull: false) String? externalId});

  $EvmTransactionJsonCopyWith<$Res> get transaction;
}

/// @nodoc
class __$$EvmTransactionJsonBroadcastRequestImplCopyWithImpl<$Res>
    extends _$EvmBroadcastRequestCopyWithImpl<$Res,
        _$EvmTransactionJsonBroadcastRequestImpl>
    implements _$$EvmTransactionJsonBroadcastRequestImplCopyWith<$Res> {
  __$$EvmTransactionJsonBroadcastRequestImplCopyWithImpl(
      _$EvmTransactionJsonBroadcastRequestImpl _value,
      $Res Function(_$EvmTransactionJsonBroadcastRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transaction = null,
    Object? kind = null,
    Object? externalId = freezed,
  }) {
    return _then(_$EvmTransactionJsonBroadcastRequestImpl(
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as EvmTransactionJson,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EvmTransactionJsonCopyWith<$Res> get transaction {
    return $EvmTransactionJsonCopyWith<$Res>(_value.transaction, (value) {
      return _then(_value.copyWith(transaction: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$EvmTransactionJsonBroadcastRequestImpl
    implements EvmTransactionJsonBroadcastRequest {
  const _$EvmTransactionJsonBroadcastRequestImpl(
      {required this.transaction,
      this.kind = 'Transaction',
      @JsonKey(includeIfNull: false) this.externalId,
      final String? $type})
      : $type = $type ?? 'transactionJson';

  factory _$EvmTransactionJsonBroadcastRequestImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$EvmTransactionJsonBroadcastRequestImplFromJson(json);

  /// Unsigned transaction as EvmTransactionJson object
  @override
  final EvmTransactionJson transaction;

  /// The kind, should be 'Transaction'
  @override
  @JsonKey()
  final String kind;

  /// Optional idempotency key
  @override
  @JsonKey(includeIfNull: false)
  final String? externalId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'EvmBroadcastRequest.transactionJson(transaction: $transaction, kind: $kind, externalId: $externalId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvmTransactionJsonBroadcastRequestImpl &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, transaction, kind, externalId);

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvmTransactionJsonBroadcastRequestImplCopyWith<
          _$EvmTransactionJsonBroadcastRequestImpl>
      get copyWith => __$$EvmTransactionJsonBroadcastRequestImplCopyWithImpl<
          _$EvmTransactionJsonBroadcastRequestImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionHex,
    required TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionJson,
    required TResult Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        userOperations,
  }) {
    return transactionJson(transaction, kind, externalId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult? Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult? Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
  }) {
    return transactionJson?.call(transaction, kind, externalId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult Function(List<EvmUserOperation> userOperations, String feeSponsorId,
            String kind, @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
    required TResult orElse(),
  }) {
    if (transactionJson != null) {
      return transactionJson(transaction, kind, externalId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EvmTransactionHexBroadcastRequest value)
        transactionHex,
    required TResult Function(EvmTransactionJsonBroadcastRequest value)
        transactionJson,
    required TResult Function(EvmUserOperationsBroadcastRequest value)
        userOperations,
  }) {
    return transactionJson(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult? Function(EvmTransactionJsonBroadcastRequest value)?
        transactionJson,
    TResult? Function(EvmUserOperationsBroadcastRequest value)? userOperations,
  }) {
    return transactionJson?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult Function(EvmTransactionJsonBroadcastRequest value)? transactionJson,
    TResult Function(EvmUserOperationsBroadcastRequest value)? userOperations,
    required TResult orElse(),
  }) {
    if (transactionJson != null) {
      return transactionJson(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$EvmTransactionJsonBroadcastRequestImplToJson(
      this,
    );
  }
}

abstract class EvmTransactionJsonBroadcastRequest
    implements EvmBroadcastRequest {
  const factory EvmTransactionJsonBroadcastRequest(
          {required final EvmTransactionJson transaction,
          final String kind,
          @JsonKey(includeIfNull: false) final String? externalId}) =
      _$EvmTransactionJsonBroadcastRequestImpl;

  factory EvmTransactionJsonBroadcastRequest.fromJson(
          Map<String, dynamic> json) =
      _$EvmTransactionJsonBroadcastRequestImpl.fromJson;

  /// Unsigned transaction as EvmTransactionJson object
  EvmTransactionJson get transaction;

  /// The kind, should be 'Transaction'
  @override
  String get kind;

  /// Optional idempotency key
  @override
  @JsonKey(includeIfNull: false)
  String? get externalId;

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvmTransactionJsonBroadcastRequestImplCopyWith<
          _$EvmTransactionJsonBroadcastRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EvmUserOperationsBroadcastRequestImplCopyWith<$Res>
    implements $EvmBroadcastRequestCopyWith<$Res> {
  factory _$$EvmUserOperationsBroadcastRequestImplCopyWith(
          _$EvmUserOperationsBroadcastRequestImpl value,
          $Res Function(_$EvmUserOperationsBroadcastRequestImpl) then) =
      __$$EvmUserOperationsBroadcastRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<EvmUserOperation> userOperations,
      String feeSponsorId,
      String kind,
      @JsonKey(includeIfNull: false) String? externalId});
}

/// @nodoc
class __$$EvmUserOperationsBroadcastRequestImplCopyWithImpl<$Res>
    extends _$EvmBroadcastRequestCopyWithImpl<$Res,
        _$EvmUserOperationsBroadcastRequestImpl>
    implements _$$EvmUserOperationsBroadcastRequestImplCopyWith<$Res> {
  __$$EvmUserOperationsBroadcastRequestImplCopyWithImpl(
      _$EvmUserOperationsBroadcastRequestImpl _value,
      $Res Function(_$EvmUserOperationsBroadcastRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userOperations = null,
    Object? feeSponsorId = null,
    Object? kind = null,
    Object? externalId = freezed,
  }) {
    return _then(_$EvmUserOperationsBroadcastRequestImpl(
      userOperations: null == userOperations
          ? _value._userOperations
          : userOperations // ignore: cast_nullable_to_non_nullable
              as List<EvmUserOperation>,
      feeSponsorId: null == feeSponsorId
          ? _value.feeSponsorId
          : feeSponsorId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvmUserOperationsBroadcastRequestImpl
    implements EvmUserOperationsBroadcastRequest {
  const _$EvmUserOperationsBroadcastRequestImpl(
      {required final List<EvmUserOperation> userOperations,
      required this.feeSponsorId,
      this.kind = 'UserOperations',
      @JsonKey(includeIfNull: false) this.externalId,
      final String? $type})
      : _userOperations = userOperations,
        $type = $type ?? 'userOperations';

  factory _$EvmUserOperationsBroadcastRequestImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$EvmUserOperationsBroadcastRequestImplFromJson(json);

  /// Array of user operation objects
  final List<EvmUserOperation> _userOperations;

  /// Array of user operation objects
  @override
  List<EvmUserOperation> get userOperations {
    if (_userOperations is EqualUnmodifiableListView) return _userOperations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userOperations);
  }

  /// Fee sponsor identifier (required for UserOperations)
  @override
  final String feeSponsorId;

  /// The kind, should be 'UserOperations'
  @override
  @JsonKey()
  final String kind;

  /// Optional idempotency key
  @override
  @JsonKey(includeIfNull: false)
  final String? externalId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'EvmBroadcastRequest.userOperations(userOperations: $userOperations, feeSponsorId: $feeSponsorId, kind: $kind, externalId: $externalId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvmUserOperationsBroadcastRequestImpl &&
            const DeepCollectionEquality()
                .equals(other._userOperations, _userOperations) &&
            (identical(other.feeSponsorId, feeSponsorId) ||
                other.feeSponsorId == feeSponsorId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_userOperations),
      feeSponsorId,
      kind,
      externalId);

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvmUserOperationsBroadcastRequestImplCopyWith<
          _$EvmUserOperationsBroadcastRequestImpl>
      get copyWith => __$$EvmUserOperationsBroadcastRequestImplCopyWithImpl<
          _$EvmUserOperationsBroadcastRequestImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionHex,
    required TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        transactionJson,
    required TResult Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)
        userOperations,
  }) {
    return userOperations(this.userOperations, feeSponsorId, kind, externalId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult? Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult? Function(
            List<EvmUserOperation> userOperations,
            String feeSponsorId,
            String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
  }) {
    return userOperations?.call(
        this.userOperations, feeSponsorId, kind, externalId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionHex,
    TResult Function(EvmTransactionJson transaction, String kind,
            @JsonKey(includeIfNull: false) String? externalId)?
        transactionJson,
    TResult Function(List<EvmUserOperation> userOperations, String feeSponsorId,
            String kind, @JsonKey(includeIfNull: false) String? externalId)?
        userOperations,
    required TResult orElse(),
  }) {
    if (userOperations != null) {
      return userOperations(
          this.userOperations, feeSponsorId, kind, externalId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EvmTransactionHexBroadcastRequest value)
        transactionHex,
    required TResult Function(EvmTransactionJsonBroadcastRequest value)
        transactionJson,
    required TResult Function(EvmUserOperationsBroadcastRequest value)
        userOperations,
  }) {
    return userOperations(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult? Function(EvmTransactionJsonBroadcastRequest value)?
        transactionJson,
    TResult? Function(EvmUserOperationsBroadcastRequest value)? userOperations,
  }) {
    return userOperations?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EvmTransactionHexBroadcastRequest value)? transactionHex,
    TResult Function(EvmTransactionJsonBroadcastRequest value)? transactionJson,
    TResult Function(EvmUserOperationsBroadcastRequest value)? userOperations,
    required TResult orElse(),
  }) {
    if (userOperations != null) {
      return userOperations(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$EvmUserOperationsBroadcastRequestImplToJson(
      this,
    );
  }
}

abstract class EvmUserOperationsBroadcastRequest
    implements EvmBroadcastRequest {
  const factory EvmUserOperationsBroadcastRequest(
          {required final List<EvmUserOperation> userOperations,
          required final String feeSponsorId,
          final String kind,
          @JsonKey(includeIfNull: false) final String? externalId}) =
      _$EvmUserOperationsBroadcastRequestImpl;

  factory EvmUserOperationsBroadcastRequest.fromJson(
          Map<String, dynamic> json) =
      _$EvmUserOperationsBroadcastRequestImpl.fromJson;

  /// Array of user operation objects
  List<EvmUserOperation> get userOperations;

  /// Fee sponsor identifier (required for UserOperations)
  String get feeSponsorId;

  /// The kind, should be 'UserOperations'
  @override
  String get kind;

  /// Optional idempotency key
  @override
  @JsonKey(includeIfNull: false)
  String? get externalId;

  /// Create a copy of EvmBroadcastRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvmUserOperationsBroadcastRequestImplCopyWith<
          _$EvmUserOperationsBroadcastRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

EvmTransactionJson _$EvmTransactionJsonFromJson(Map<String, dynamic> json) {
  return _EvmTransactionJson.fromJson(json);
}

/// @nodoc
mixin _$EvmTransactionJson {
  /// Address or target contract
  String get to => throw _privateConstructorUsedError;

  /// Transaction type: 0 = legacy, 2 = EIP-1559 (default), 4 = EIP-7702
  int get type => throw _privateConstructorUsedError;

  /// Amount in wei
  @JsonKey(includeIfNull: false)
  String? get value => throw _privateConstructorUsedError;

  /// ABI-encoded calldata
  @JsonKey(includeIfNull: false)
  String? get data => throw _privateConstructorUsedError;

  /// Optional nonce (auto by default)
  @JsonKey(includeIfNull: false)
  int? get nonce => throw _privateConstructorUsedError;

  /// Optional gas limit (auto)
  @JsonKey(includeIfNull: false)
  String? get gasLimit => throw _privateConstructorUsedError;

  /// Gas price (only for type 0)
  @JsonKey(includeIfNull: false)
  String? get gasPrice => throw _privateConstructorUsedError;

  /// Max fee per gas (for type 2/4)
  @JsonKey(includeIfNull: false)
  String? get maxFeePerGas => throw _privateConstructorUsedError;

  /// Max priority fee per gas (for type 2/4)
  @JsonKey(includeIfNull: false)
  String? get maxPriorityFeePerGas => throw _privateConstructorUsedError;

  /// Authorization list (only for type 4 / EIP-7702)
  @JsonKey(includeIfNull: false)
  List<EvmAuthorization>? get authorizationList =>
      throw _privateConstructorUsedError;

  /// Serializes this EvmTransactionJson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvmTransactionJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvmTransactionJsonCopyWith<EvmTransactionJson> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvmTransactionJsonCopyWith<$Res> {
  factory $EvmTransactionJsonCopyWith(
          EvmTransactionJson value, $Res Function(EvmTransactionJson) then) =
      _$EvmTransactionJsonCopyWithImpl<$Res, EvmTransactionJson>;
  @useResult
  $Res call(
      {String to,
      int type,
      @JsonKey(includeIfNull: false) String? value,
      @JsonKey(includeIfNull: false) String? data,
      @JsonKey(includeIfNull: false) int? nonce,
      @JsonKey(includeIfNull: false) String? gasLimit,
      @JsonKey(includeIfNull: false) String? gasPrice,
      @JsonKey(includeIfNull: false) String? maxFeePerGas,
      @JsonKey(includeIfNull: false) String? maxPriorityFeePerGas,
      @JsonKey(includeIfNull: false)
      List<EvmAuthorization>? authorizationList});
}

/// @nodoc
class _$EvmTransactionJsonCopyWithImpl<$Res, $Val extends EvmTransactionJson>
    implements $EvmTransactionJsonCopyWith<$Res> {
  _$EvmTransactionJsonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvmTransactionJson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? type = null,
    Object? value = freezed,
    Object? data = freezed,
    Object? nonce = freezed,
    Object? gasLimit = freezed,
    Object? gasPrice = freezed,
    Object? maxFeePerGas = freezed,
    Object? maxPriorityFeePerGas = freezed,
    Object? authorizationList = freezed,
  }) {
    return _then(_value.copyWith(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as int,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String?,
      nonce: freezed == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as int?,
      gasLimit: freezed == gasLimit
          ? _value.gasLimit
          : gasLimit // ignore: cast_nullable_to_non_nullable
              as String?,
      gasPrice: freezed == gasPrice
          ? _value.gasPrice
          : gasPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      maxFeePerGas: freezed == maxFeePerGas
          ? _value.maxFeePerGas
          : maxFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      maxPriorityFeePerGas: freezed == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      authorizationList: freezed == authorizationList
          ? _value.authorizationList
          : authorizationList // ignore: cast_nullable_to_non_nullable
              as List<EvmAuthorization>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvmTransactionJsonImplCopyWith<$Res>
    implements $EvmTransactionJsonCopyWith<$Res> {
  factory _$$EvmTransactionJsonImplCopyWith(_$EvmTransactionJsonImpl value,
          $Res Function(_$EvmTransactionJsonImpl) then) =
      __$$EvmTransactionJsonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String to,
      int type,
      @JsonKey(includeIfNull: false) String? value,
      @JsonKey(includeIfNull: false) String? data,
      @JsonKey(includeIfNull: false) int? nonce,
      @JsonKey(includeIfNull: false) String? gasLimit,
      @JsonKey(includeIfNull: false) String? gasPrice,
      @JsonKey(includeIfNull: false) String? maxFeePerGas,
      @JsonKey(includeIfNull: false) String? maxPriorityFeePerGas,
      @JsonKey(includeIfNull: false)
      List<EvmAuthorization>? authorizationList});
}

/// @nodoc
class __$$EvmTransactionJsonImplCopyWithImpl<$Res>
    extends _$EvmTransactionJsonCopyWithImpl<$Res, _$EvmTransactionJsonImpl>
    implements _$$EvmTransactionJsonImplCopyWith<$Res> {
  __$$EvmTransactionJsonImplCopyWithImpl(_$EvmTransactionJsonImpl _value,
      $Res Function(_$EvmTransactionJsonImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvmTransactionJson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? type = null,
    Object? value = freezed,
    Object? data = freezed,
    Object? nonce = freezed,
    Object? gasLimit = freezed,
    Object? gasPrice = freezed,
    Object? maxFeePerGas = freezed,
    Object? maxPriorityFeePerGas = freezed,
    Object? authorizationList = freezed,
  }) {
    return _then(_$EvmTransactionJsonImpl(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as int,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String?,
      nonce: freezed == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as int?,
      gasLimit: freezed == gasLimit
          ? _value.gasLimit
          : gasLimit // ignore: cast_nullable_to_non_nullable
              as String?,
      gasPrice: freezed == gasPrice
          ? _value.gasPrice
          : gasPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      maxFeePerGas: freezed == maxFeePerGas
          ? _value.maxFeePerGas
          : maxFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      maxPriorityFeePerGas: freezed == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      authorizationList: freezed == authorizationList
          ? _value._authorizationList
          : authorizationList // ignore: cast_nullable_to_non_nullable
              as List<EvmAuthorization>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvmTransactionJsonImpl implements _EvmTransactionJson {
  const _$EvmTransactionJsonImpl(
      {required this.to,
      this.type = 2,
      @JsonKey(includeIfNull: false) this.value,
      @JsonKey(includeIfNull: false) this.data,
      @JsonKey(includeIfNull: false) this.nonce,
      @JsonKey(includeIfNull: false) this.gasLimit,
      @JsonKey(includeIfNull: false) this.gasPrice,
      @JsonKey(includeIfNull: false) this.maxFeePerGas,
      @JsonKey(includeIfNull: false) this.maxPriorityFeePerGas,
      @JsonKey(includeIfNull: false)
      final List<EvmAuthorization>? authorizationList})
      : _authorizationList = authorizationList;

  factory _$EvmTransactionJsonImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvmTransactionJsonImplFromJson(json);

  /// Address or target contract
  @override
  final String to;

  /// Transaction type: 0 = legacy, 2 = EIP-1559 (default), 4 = EIP-7702
  @override
  @JsonKey()
  final int type;

  /// Amount in wei
  @override
  @JsonKey(includeIfNull: false)
  final String? value;

  /// ABI-encoded calldata
  @override
  @JsonKey(includeIfNull: false)
  final String? data;

  /// Optional nonce (auto by default)
  @override
  @JsonKey(includeIfNull: false)
  final int? nonce;

  /// Optional gas limit (auto)
  @override
  @JsonKey(includeIfNull: false)
  final String? gasLimit;

  /// Gas price (only for type 0)
  @override
  @JsonKey(includeIfNull: false)
  final String? gasPrice;

  /// Max fee per gas (for type 2/4)
  @override
  @JsonKey(includeIfNull: false)
  final String? maxFeePerGas;

  /// Max priority fee per gas (for type 2/4)
  @override
  @JsonKey(includeIfNull: false)
  final String? maxPriorityFeePerGas;

  /// Authorization list (only for type 4 / EIP-7702)
  final List<EvmAuthorization>? _authorizationList;

  /// Authorization list (only for type 4 / EIP-7702)
  @override
  @JsonKey(includeIfNull: false)
  List<EvmAuthorization>? get authorizationList {
    final value = _authorizationList;
    if (value == null) return null;
    if (_authorizationList is EqualUnmodifiableListView)
      return _authorizationList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'EvmTransactionJson(to: $to, type: $type, value: $value, data: $data, nonce: $nonce, gasLimit: $gasLimit, gasPrice: $gasPrice, maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas, authorizationList: $authorizationList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvmTransactionJsonImpl &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.gasLimit, gasLimit) ||
                other.gasLimit == gasLimit) &&
            (identical(other.gasPrice, gasPrice) ||
                other.gasPrice == gasPrice) &&
            (identical(other.maxFeePerGas, maxFeePerGas) ||
                other.maxFeePerGas == maxFeePerGas) &&
            (identical(other.maxPriorityFeePerGas, maxPriorityFeePerGas) ||
                other.maxPriorityFeePerGas == maxPriorityFeePerGas) &&
            const DeepCollectionEquality()
                .equals(other._authorizationList, _authorizationList));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      to,
      type,
      value,
      data,
      nonce,
      gasLimit,
      gasPrice,
      maxFeePerGas,
      maxPriorityFeePerGas,
      const DeepCollectionEquality().hash(_authorizationList));

  /// Create a copy of EvmTransactionJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvmTransactionJsonImplCopyWith<_$EvmTransactionJsonImpl> get copyWith =>
      __$$EvmTransactionJsonImplCopyWithImpl<_$EvmTransactionJsonImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvmTransactionJsonImplToJson(
      this,
    );
  }
}

abstract class _EvmTransactionJson implements EvmTransactionJson {
  const factory _EvmTransactionJson(
          {required final String to,
          final int type,
          @JsonKey(includeIfNull: false) final String? value,
          @JsonKey(includeIfNull: false) final String? data,
          @JsonKey(includeIfNull: false) final int? nonce,
          @JsonKey(includeIfNull: false) final String? gasLimit,
          @JsonKey(includeIfNull: false) final String? gasPrice,
          @JsonKey(includeIfNull: false) final String? maxFeePerGas,
          @JsonKey(includeIfNull: false) final String? maxPriorityFeePerGas,
          @JsonKey(includeIfNull: false)
          final List<EvmAuthorization>? authorizationList}) =
      _$EvmTransactionJsonImpl;

  factory _EvmTransactionJson.fromJson(Map<String, dynamic> json) =
      _$EvmTransactionJsonImpl.fromJson;

  /// Address or target contract
  @override
  String get to;

  /// Transaction type: 0 = legacy, 2 = EIP-1559 (default), 4 = EIP-7702
  @override
  int get type;

  /// Amount in wei
  @override
  @JsonKey(includeIfNull: false)
  String? get value;

  /// ABI-encoded calldata
  @override
  @JsonKey(includeIfNull: false)
  String? get data;

  /// Optional nonce (auto by default)
  @override
  @JsonKey(includeIfNull: false)
  int? get nonce;

  /// Optional gas limit (auto)
  @override
  @JsonKey(includeIfNull: false)
  String? get gasLimit;

  /// Gas price (only for type 0)
  @override
  @JsonKey(includeIfNull: false)
  String? get gasPrice;

  /// Max fee per gas (for type 2/4)
  @override
  @JsonKey(includeIfNull: false)
  String? get maxFeePerGas;

  /// Max priority fee per gas (for type 2/4)
  @override
  @JsonKey(includeIfNull: false)
  String? get maxPriorityFeePerGas;

  /// Authorization list (only for type 4 / EIP-7702)
  @override
  @JsonKey(includeIfNull: false)
  List<EvmAuthorization>? get authorizationList;

  /// Create a copy of EvmTransactionJson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvmTransactionJsonImplCopyWith<_$EvmTransactionJsonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EvmUserOperation _$EvmUserOperationFromJson(Map<String, dynamic> json) {
  return _EvmUserOperation.fromJson(json);
}

/// @nodoc
mixin _$EvmUserOperation {
  /// Target address
  String get to => throw _privateConstructorUsedError;

  /// Value in wei (optional)
  @JsonKey(includeIfNull: false)
  String? get value => throw _privateConstructorUsedError;

  /// ABI-encoded calldata (optional)
  @JsonKey(includeIfNull: false)
  String? get data => throw _privateConstructorUsedError;

  /// Serializes this EvmUserOperation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvmUserOperation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvmUserOperationCopyWith<EvmUserOperation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvmUserOperationCopyWith<$Res> {
  factory $EvmUserOperationCopyWith(
          EvmUserOperation value, $Res Function(EvmUserOperation) then) =
      _$EvmUserOperationCopyWithImpl<$Res, EvmUserOperation>;
  @useResult
  $Res call(
      {String to,
      @JsonKey(includeIfNull: false) String? value,
      @JsonKey(includeIfNull: false) String? data});
}

/// @nodoc
class _$EvmUserOperationCopyWithImpl<$Res, $Val extends EvmUserOperation>
    implements $EvmUserOperationCopyWith<$Res> {
  _$EvmUserOperationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvmUserOperation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? value = freezed,
    Object? data = freezed,
  }) {
    return _then(_value.copyWith(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvmUserOperationImplCopyWith<$Res>
    implements $EvmUserOperationCopyWith<$Res> {
  factory _$$EvmUserOperationImplCopyWith(_$EvmUserOperationImpl value,
          $Res Function(_$EvmUserOperationImpl) then) =
      __$$EvmUserOperationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String to,
      @JsonKey(includeIfNull: false) String? value,
      @JsonKey(includeIfNull: false) String? data});
}

/// @nodoc
class __$$EvmUserOperationImplCopyWithImpl<$Res>
    extends _$EvmUserOperationCopyWithImpl<$Res, _$EvmUserOperationImpl>
    implements _$$EvmUserOperationImplCopyWith<$Res> {
  __$$EvmUserOperationImplCopyWithImpl(_$EvmUserOperationImpl _value,
      $Res Function(_$EvmUserOperationImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvmUserOperation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? value = freezed,
    Object? data = freezed,
  }) {
    return _then(_$EvmUserOperationImpl(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvmUserOperationImpl implements _EvmUserOperation {
  const _$EvmUserOperationImpl(
      {required this.to,
      @JsonKey(includeIfNull: false) this.value,
      @JsonKey(includeIfNull: false) this.data});

  factory _$EvmUserOperationImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvmUserOperationImplFromJson(json);

  /// Target address
  @override
  final String to;

  /// Value in wei (optional)
  @override
  @JsonKey(includeIfNull: false)
  final String? value;

  /// ABI-encoded calldata (optional)
  @override
  @JsonKey(includeIfNull: false)
  final String? data;

  @override
  String toString() {
    return 'EvmUserOperation(to: $to, value: $value, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvmUserOperationImpl &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, to, value, data);

  /// Create a copy of EvmUserOperation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvmUserOperationImplCopyWith<_$EvmUserOperationImpl> get copyWith =>
      __$$EvmUserOperationImplCopyWithImpl<_$EvmUserOperationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvmUserOperationImplToJson(
      this,
    );
  }
}

abstract class _EvmUserOperation implements EvmUserOperation {
  const factory _EvmUserOperation(
          {required final String to,
          @JsonKey(includeIfNull: false) final String? value,
          @JsonKey(includeIfNull: false) final String? data}) =
      _$EvmUserOperationImpl;

  factory _EvmUserOperation.fromJson(Map<String, dynamic> json) =
      _$EvmUserOperationImpl.fromJson;

  /// Target address
  @override
  String get to;

  /// Value in wei (optional)
  @override
  @JsonKey(includeIfNull: false)
  String? get value;

  /// ABI-encoded calldata (optional)
  @override
  @JsonKey(includeIfNull: false)
  String? get data;

  /// Create a copy of EvmUserOperation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvmUserOperationImplCopyWith<_$EvmUserOperationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EvmAuthorization _$EvmAuthorizationFromJson(Map<String, dynamic> json) {
  return _EvmAuthorization.fromJson(json);
}

/// @nodoc
mixin _$EvmAuthorization {
  /// Chain ID
  int get chainId => throw _privateConstructorUsedError;

  /// Contract the EOA will delegate to
  String get address => throw _privateConstructorUsedError;

  /// EOA nonce
  int get nonce => throw _privateConstructorUsedError;

  /// Signature
  String get signature => throw _privateConstructorUsedError;

  /// Serializes this EvmAuthorization to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvmAuthorization
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvmAuthorizationCopyWith<EvmAuthorization> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvmAuthorizationCopyWith<$Res> {
  factory $EvmAuthorizationCopyWith(
          EvmAuthorization value, $Res Function(EvmAuthorization) then) =
      _$EvmAuthorizationCopyWithImpl<$Res, EvmAuthorization>;
  @useResult
  $Res call({int chainId, String address, int nonce, String signature});
}

/// @nodoc
class _$EvmAuthorizationCopyWithImpl<$Res, $Val extends EvmAuthorization>
    implements $EvmAuthorizationCopyWith<$Res> {
  _$EvmAuthorizationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvmAuthorization
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainId = null,
    Object? address = null,
    Object? nonce = null,
    Object? signature = null,
  }) {
    return _then(_value.copyWith(
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as int,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as int,
      signature: null == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvmAuthorizationImplCopyWith<$Res>
    implements $EvmAuthorizationCopyWith<$Res> {
  factory _$$EvmAuthorizationImplCopyWith(_$EvmAuthorizationImpl value,
          $Res Function(_$EvmAuthorizationImpl) then) =
      __$$EvmAuthorizationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int chainId, String address, int nonce, String signature});
}

/// @nodoc
class __$$EvmAuthorizationImplCopyWithImpl<$Res>
    extends _$EvmAuthorizationCopyWithImpl<$Res, _$EvmAuthorizationImpl>
    implements _$$EvmAuthorizationImplCopyWith<$Res> {
  __$$EvmAuthorizationImplCopyWithImpl(_$EvmAuthorizationImpl _value,
      $Res Function(_$EvmAuthorizationImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvmAuthorization
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainId = null,
    Object? address = null,
    Object? nonce = null,
    Object? signature = null,
  }) {
    return _then(_$EvmAuthorizationImpl(
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as int,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as int,
      signature: null == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvmAuthorizationImpl implements _EvmAuthorization {
  const _$EvmAuthorizationImpl(
      {required this.chainId,
      required this.address,
      required this.nonce,
      required this.signature});

  factory _$EvmAuthorizationImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvmAuthorizationImplFromJson(json);

  /// Chain ID
  @override
  final int chainId;

  /// Contract the EOA will delegate to
  @override
  final String address;

  /// EOA nonce
  @override
  final int nonce;

  /// Signature
  @override
  final String signature;

  @override
  String toString() {
    return 'EvmAuthorization(chainId: $chainId, address: $address, nonce: $nonce, signature: $signature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvmAuthorizationImpl &&
            (identical(other.chainId, chainId) || other.chainId == chainId) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.signature, signature) ||
                other.signature == signature));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, chainId, address, nonce, signature);

  /// Create a copy of EvmAuthorization
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvmAuthorizationImplCopyWith<_$EvmAuthorizationImpl> get copyWith =>
      __$$EvmAuthorizationImplCopyWithImpl<_$EvmAuthorizationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvmAuthorizationImplToJson(
      this,
    );
  }
}

abstract class _EvmAuthorization implements EvmAuthorization {
  const factory _EvmAuthorization(
      {required final int chainId,
      required final String address,
      required final int nonce,
      required final String signature}) = _$EvmAuthorizationImpl;

  factory _EvmAuthorization.fromJson(Map<String, dynamic> json) =
      _$EvmAuthorizationImpl.fromJson;

  /// Chain ID
  @override
  int get chainId;

  /// Contract the EOA will delegate to
  @override
  String get address;

  /// EOA nonce
  @override
  int get nonce;

  /// Signature
  @override
  String get signature;

  /// Create a copy of EvmAuthorization
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvmAuthorizationImplCopyWith<_$EvmAuthorizationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
