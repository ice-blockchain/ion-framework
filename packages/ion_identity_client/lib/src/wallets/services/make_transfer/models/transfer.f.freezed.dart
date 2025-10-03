// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NativeTokenTransfer _$NativeTokenTransferFromJson(Map<String, dynamic> json) {
  return _NativeTokenTransfer.fromJson(json);
}

/// @nodoc
mixin _$NativeTokenTransfer {
  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of native tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Native'
  String get kind => throw _privateConstructorUsedError;

  /// The priority that determines the fees paid for the transfer
  @JsonKey(includeIfNull: false)
  TransferPriority? get priority => throw _privateConstructorUsedError;

  /// The memo or destination tag
  @JsonKey(includeIfNull: false)
  String? get memo => throw _privateConstructorUsedError;

  /// Serializes this NativeTokenTransfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NativeTokenTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NativeTokenTransferCopyWith<NativeTokenTransfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NativeTokenTransferCopyWith<$Res> {
  factory $NativeTokenTransferCopyWith(
          NativeTokenTransfer value, $Res Function(NativeTokenTransfer) then) =
      _$NativeTokenTransferCopyWithImpl<$Res, NativeTokenTransfer>;
  @useResult
  $Res call(
      {String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) TransferPriority? priority,
      @JsonKey(includeIfNull: false) String? memo});
}

/// @nodoc
class _$NativeTokenTransferCopyWithImpl<$Res, $Val extends NativeTokenTransfer>
    implements $NativeTokenTransferCopyWith<$Res> {
  _$NativeTokenTransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NativeTokenTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? priority = freezed,
    Object? memo = freezed,
  }) {
    return _then(_value.copyWith(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TransferPriority?,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NativeTokenTransferImplCopyWith<$Res>
    implements $NativeTokenTransferCopyWith<$Res> {
  factory _$$NativeTokenTransferImplCopyWith(_$NativeTokenTransferImpl value,
          $Res Function(_$NativeTokenTransferImpl) then) =
      __$$NativeTokenTransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) TransferPriority? priority,
      @JsonKey(includeIfNull: false) String? memo});
}

/// @nodoc
class __$$NativeTokenTransferImplCopyWithImpl<$Res>
    extends _$NativeTokenTransferCopyWithImpl<$Res, _$NativeTokenTransferImpl>
    implements _$$NativeTokenTransferImplCopyWith<$Res> {
  __$$NativeTokenTransferImplCopyWithImpl(_$NativeTokenTransferImpl _value,
      $Res Function(_$NativeTokenTransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of NativeTokenTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? priority = freezed,
    Object? memo = freezed,
  }) {
    return _then(_$NativeTokenTransferImpl(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TransferPriority?,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NativeTokenTransferImpl implements _NativeTokenTransfer {
  const _$NativeTokenTransferImpl(
      {required this.to,
      required this.amount,
      this.kind = 'Native',
      @JsonKey(includeIfNull: false) this.priority,
      @JsonKey(includeIfNull: false) this.memo});

  factory _$NativeTokenTransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$NativeTokenTransferImplFromJson(json);

  /// The destination address
  @override
  final String to;

  /// The amount of native tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Native'
  @override
  @JsonKey()
  final String kind;

  /// The priority that determines the fees paid for the transfer
  @override
  @JsonKey(includeIfNull: false)
  final TransferPriority? priority;

  /// The memo or destination tag
  @override
  @JsonKey(includeIfNull: false)
  final String? memo;

  @override
  String toString() {
    return 'NativeTokenTransfer(to: $to, amount: $amount, kind: $kind, priority: $priority, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NativeTokenTransferImpl &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.memo, memo) || other.memo == memo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, to, amount, kind, priority, memo);

  /// Create a copy of NativeTokenTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NativeTokenTransferImplCopyWith<_$NativeTokenTransferImpl> get copyWith =>
      __$$NativeTokenTransferImplCopyWithImpl<_$NativeTokenTransferImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NativeTokenTransferImplToJson(
      this,
    );
  }
}

abstract class _NativeTokenTransfer implements NativeTokenTransfer {
  const factory _NativeTokenTransfer(
          {required final String to,
          required final String amount,
          final String kind,
          @JsonKey(includeIfNull: false) final TransferPriority? priority,
          @JsonKey(includeIfNull: false) final String? memo}) =
      _$NativeTokenTransferImpl;

  factory _NativeTokenTransfer.fromJson(Map<String, dynamic> json) =
      _$NativeTokenTransferImpl.fromJson;

  /// The destination address
  @override
  String get to;

  /// The amount of native tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Native'
  @override
  String get kind;

  /// The priority that determines the fees paid for the transfer
  @override
  @JsonKey(includeIfNull: false)
  TransferPriority? get priority;

  /// The memo or destination tag
  @override
  @JsonKey(includeIfNull: false)
  String? get memo;

  /// Create a copy of NativeTokenTransfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NativeTokenTransferImplCopyWith<_$NativeTokenTransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AsaTransfer _$AsaTransferFromJson(Map<String, dynamic> json) {
  return _AsaTransfer.fromJson(json);
}

/// @nodoc
mixin _$AsaTransfer {
  /// The asset ID of the token
  String get assetId => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Asa'
  String get kind => throw _privateConstructorUsedError;

  /// Serializes this AsaTransfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AsaTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AsaTransferCopyWith<AsaTransfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AsaTransferCopyWith<$Res> {
  factory $AsaTransferCopyWith(
          AsaTransfer value, $Res Function(AsaTransfer) then) =
      _$AsaTransferCopyWithImpl<$Res, AsaTransfer>;
  @useResult
  $Res call({String assetId, String to, String amount, String kind});
}

/// @nodoc
class _$AsaTransferCopyWithImpl<$Res, $Val extends AsaTransfer>
    implements $AsaTransferCopyWith<$Res> {
  _$AsaTransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AsaTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assetId = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AsaTransferImplCopyWith<$Res>
    implements $AsaTransferCopyWith<$Res> {
  factory _$$AsaTransferImplCopyWith(
          _$AsaTransferImpl value, $Res Function(_$AsaTransferImpl) then) =
      __$$AsaTransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String assetId, String to, String amount, String kind});
}

/// @nodoc
class __$$AsaTransferImplCopyWithImpl<$Res>
    extends _$AsaTransferCopyWithImpl<$Res, _$AsaTransferImpl>
    implements _$$AsaTransferImplCopyWith<$Res> {
  __$$AsaTransferImplCopyWithImpl(
      _$AsaTransferImpl _value, $Res Function(_$AsaTransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of AsaTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assetId = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_$AsaTransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AsaTransferImpl implements _AsaTransfer {
  const _$AsaTransferImpl(
      {required this.assetId,
      required this.to,
      required this.amount,
      this.kind = 'Asa'});

  factory _$AsaTransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$AsaTransferImplFromJson(json);

  /// The asset ID of the token
  @override
  final String assetId;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Asa'
  @override
  @JsonKey()
  final String kind;

  @override
  String toString() {
    return 'AsaTransfer(assetId: $assetId, to: $to, amount: $amount, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AsaTransferImpl &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, assetId, to, amount, kind);

  /// Create a copy of AsaTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AsaTransferImplCopyWith<_$AsaTransferImpl> get copyWith =>
      __$$AsaTransferImplCopyWithImpl<_$AsaTransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AsaTransferImplToJson(
      this,
    );
  }
}

abstract class _AsaTransfer implements AsaTransfer {
  const factory _AsaTransfer(
      {required final String assetId,
      required final String to,
      required final String amount,
      final String kind}) = _$AsaTransferImpl;

  factory _AsaTransfer.fromJson(Map<String, dynamic> json) =
      _$AsaTransferImpl.fromJson;

  /// The asset ID of the token
  @override
  String get assetId;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Asa'
  @override
  String get kind;

  /// Create a copy of AsaTransfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AsaTransferImplCopyWith<_$AsaTransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Erc20Transfer _$Erc20TransferFromJson(Map<String, dynamic> json) {
  return _Erc20Transfer.fromJson(json);
}

/// @nodoc
mixin _$Erc20Transfer {
  /// The ERC20 contract address
  String get contract => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Erc20'
  String get kind => throw _privateConstructorUsedError;

  /// The priority that determines the fees paid for the transfer
  @JsonKey(includeIfNull: false)
  TransferPriority? get priority => throw _privateConstructorUsedError;

  /// Serializes this Erc20Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Erc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Erc20TransferCopyWith<Erc20Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Erc20TransferCopyWith<$Res> {
  factory $Erc20TransferCopyWith(
          Erc20Transfer value, $Res Function(Erc20Transfer) then) =
      _$Erc20TransferCopyWithImpl<$Res, Erc20Transfer>;
  @useResult
  $Res call(
      {String contract,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) TransferPriority? priority});
}

/// @nodoc
class _$Erc20TransferCopyWithImpl<$Res, $Val extends Erc20Transfer>
    implements $Erc20TransferCopyWith<$Res> {
  _$Erc20TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Erc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? priority = freezed,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TransferPriority?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Erc20TransferImplCopyWith<$Res>
    implements $Erc20TransferCopyWith<$Res> {
  factory _$$Erc20TransferImplCopyWith(
          _$Erc20TransferImpl value, $Res Function(_$Erc20TransferImpl) then) =
      __$$Erc20TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String contract,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) TransferPriority? priority});
}

/// @nodoc
class __$$Erc20TransferImplCopyWithImpl<$Res>
    extends _$Erc20TransferCopyWithImpl<$Res, _$Erc20TransferImpl>
    implements _$$Erc20TransferImplCopyWith<$Res> {
  __$$Erc20TransferImplCopyWithImpl(
      _$Erc20TransferImpl _value, $Res Function(_$Erc20TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Erc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? priority = freezed,
  }) {
    return _then(_$Erc20TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TransferPriority?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Erc20TransferImpl implements _Erc20Transfer {
  const _$Erc20TransferImpl(
      {required this.contract,
      required this.to,
      required this.amount,
      this.kind = 'Erc20',
      @JsonKey(includeIfNull: false) this.priority});

  factory _$Erc20TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Erc20TransferImplFromJson(json);

  /// The ERC20 contract address
  @override
  final String contract;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Erc20'
  @override
  @JsonKey()
  final String kind;

  /// The priority that determines the fees paid for the transfer
  @override
  @JsonKey(includeIfNull: false)
  final TransferPriority? priority;

  @override
  String toString() {
    return 'Erc20Transfer(contract: $contract, to: $to, amount: $amount, kind: $kind, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Erc20TransferImpl &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, contract, to, amount, kind, priority);

  /// Create a copy of Erc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Erc20TransferImplCopyWith<_$Erc20TransferImpl> get copyWith =>
      __$$Erc20TransferImplCopyWithImpl<_$Erc20TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Erc20TransferImplToJson(
      this,
    );
  }
}

abstract class _Erc20Transfer implements Erc20Transfer {
  const factory _Erc20Transfer(
          {required final String contract,
          required final String to,
          required final String amount,
          final String kind,
          @JsonKey(includeIfNull: false) final TransferPriority? priority}) =
      _$Erc20TransferImpl;

  factory _Erc20Transfer.fromJson(Map<String, dynamic> json) =
      _$Erc20TransferImpl.fromJson;

  /// The ERC20 contract address
  @override
  String get contract;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Erc20'
  @override
  String get kind;

  /// The priority that determines the fees paid for the transfer
  @override
  @JsonKey(includeIfNull: false)
  TransferPriority? get priority;

  /// Create a copy of Erc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Erc20TransferImplCopyWith<_$Erc20TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Erc721Transfer _$Erc721TransferFromJson(Map<String, dynamic> json) {
  return _Erc721Transfer.fromJson(json);
}

/// @nodoc
mixin _$Erc721Transfer {
  /// The ERC721 contract address
  String get contract => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The token to transfer
  String get tokenId => throw _privateConstructorUsedError;

  /// The kind, should be 'Erc721'
  String get kind => throw _privateConstructorUsedError;

  /// The priority that determines the fees paid for the transfer
  @JsonKey(includeIfNull: false)
  TransferPriority? get priority => throw _privateConstructorUsedError;

  /// Serializes this Erc721Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Erc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Erc721TransferCopyWith<Erc721Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Erc721TransferCopyWith<$Res> {
  factory $Erc721TransferCopyWith(
          Erc721Transfer value, $Res Function(Erc721Transfer) then) =
      _$Erc721TransferCopyWithImpl<$Res, Erc721Transfer>;
  @useResult
  $Res call(
      {String contract,
      String to,
      String tokenId,
      String kind,
      @JsonKey(includeIfNull: false) TransferPriority? priority});
}

/// @nodoc
class _$Erc721TransferCopyWithImpl<$Res, $Val extends Erc721Transfer>
    implements $Erc721TransferCopyWith<$Res> {
  _$Erc721TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Erc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? tokenId = null,
    Object? kind = null,
    Object? priority = freezed,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TransferPriority?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Erc721TransferImplCopyWith<$Res>
    implements $Erc721TransferCopyWith<$Res> {
  factory _$$Erc721TransferImplCopyWith(_$Erc721TransferImpl value,
          $Res Function(_$Erc721TransferImpl) then) =
      __$$Erc721TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String contract,
      String to,
      String tokenId,
      String kind,
      @JsonKey(includeIfNull: false) TransferPriority? priority});
}

/// @nodoc
class __$$Erc721TransferImplCopyWithImpl<$Res>
    extends _$Erc721TransferCopyWithImpl<$Res, _$Erc721TransferImpl>
    implements _$$Erc721TransferImplCopyWith<$Res> {
  __$$Erc721TransferImplCopyWithImpl(
      _$Erc721TransferImpl _value, $Res Function(_$Erc721TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Erc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? tokenId = null,
    Object? kind = null,
    Object? priority = freezed,
  }) {
    return _then(_$Erc721TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TransferPriority?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Erc721TransferImpl implements _Erc721Transfer {
  const _$Erc721TransferImpl(
      {required this.contract,
      required this.to,
      required this.tokenId,
      this.kind = 'Erc721',
      @JsonKey(includeIfNull: false) this.priority});

  factory _$Erc721TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Erc721TransferImplFromJson(json);

  /// The ERC721 contract address
  @override
  final String contract;

  /// The destination address
  @override
  final String to;

  /// The token to transfer
  @override
  final String tokenId;

  /// The kind, should be 'Erc721'
  @override
  @JsonKey()
  final String kind;

  /// The priority that determines the fees paid for the transfer
  @override
  @JsonKey(includeIfNull: false)
  final TransferPriority? priority;

  @override
  String toString() {
    return 'Erc721Transfer(contract: $contract, to: $to, tokenId: $tokenId, kind: $kind, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Erc721TransferImpl &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, contract, to, tokenId, kind, priority);

  /// Create a copy of Erc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Erc721TransferImplCopyWith<_$Erc721TransferImpl> get copyWith =>
      __$$Erc721TransferImplCopyWithImpl<_$Erc721TransferImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Erc721TransferImplToJson(
      this,
    );
  }
}

abstract class _Erc721Transfer implements Erc721Transfer {
  const factory _Erc721Transfer(
          {required final String contract,
          required final String to,
          required final String tokenId,
          final String kind,
          @JsonKey(includeIfNull: false) final TransferPriority? priority}) =
      _$Erc721TransferImpl;

  factory _Erc721Transfer.fromJson(Map<String, dynamic> json) =
      _$Erc721TransferImpl.fromJson;

  /// The ERC721 contract address
  @override
  String get contract;

  /// The destination address
  @override
  String get to;

  /// The token to transfer
  @override
  String get tokenId;

  /// The kind, should be 'Erc721'
  @override
  String get kind;

  /// The priority that determines the fees paid for the transfer
  @override
  @JsonKey(includeIfNull: false)
  TransferPriority? get priority;

  /// Create a copy of Erc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Erc721TransferImplCopyWith<_$Erc721TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SplTransfer _$SplTransferFromJson(Map<String, dynamic> json) {
  return _SplTransfer.fromJson(json);
}

/// @nodoc
mixin _$SplTransfer {
  /// The mint account address
  String get mint => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Spl'
  String get kind => throw _privateConstructorUsedError;

  /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
  @JsonKey(includeIfNull: false)
  bool? get createDestinationAccount => throw _privateConstructorUsedError;

  /// Serializes this SplTransfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SplTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SplTransferCopyWith<SplTransfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SplTransferCopyWith<$Res> {
  factory $SplTransferCopyWith(
          SplTransfer value, $Res Function(SplTransfer) then) =
      _$SplTransferCopyWithImpl<$Res, SplTransfer>;
  @useResult
  $Res call(
      {String mint,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) bool? createDestinationAccount});
}

/// @nodoc
class _$SplTransferCopyWithImpl<$Res, $Val extends SplTransfer>
    implements $SplTransferCopyWith<$Res> {
  _$SplTransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SplTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? createDestinationAccount = freezed,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      createDestinationAccount: freezed == createDestinationAccount
          ? _value.createDestinationAccount
          : createDestinationAccount // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SplTransferImplCopyWith<$Res>
    implements $SplTransferCopyWith<$Res> {
  factory _$$SplTransferImplCopyWith(
          _$SplTransferImpl value, $Res Function(_$SplTransferImpl) then) =
      __$$SplTransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String mint,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) bool? createDestinationAccount});
}

/// @nodoc
class __$$SplTransferImplCopyWithImpl<$Res>
    extends _$SplTransferCopyWithImpl<$Res, _$SplTransferImpl>
    implements _$$SplTransferImplCopyWith<$Res> {
  __$$SplTransferImplCopyWithImpl(
      _$SplTransferImpl _value, $Res Function(_$SplTransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of SplTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? createDestinationAccount = freezed,
  }) {
    return _then(_$SplTransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      createDestinationAccount: freezed == createDestinationAccount
          ? _value.createDestinationAccount
          : createDestinationAccount // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SplTransferImpl implements _SplTransfer {
  const _$SplTransferImpl(
      {required this.mint,
      required this.to,
      required this.amount,
      this.kind = 'Spl',
      @JsonKey(includeIfNull: false) this.createDestinationAccount});

  factory _$SplTransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$SplTransferImplFromJson(json);

  /// The mint account address
  @override
  final String mint;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Spl'
  @override
  @JsonKey()
  final String kind;

  /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
  @override
  @JsonKey(includeIfNull: false)
  final bool? createDestinationAccount;

  @override
  String toString() {
    return 'SplTransfer(mint: $mint, to: $to, amount: $amount, kind: $kind, createDestinationAccount: $createDestinationAccount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SplTransferImpl &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(
                    other.createDestinationAccount, createDestinationAccount) ||
                other.createDestinationAccount == createDestinationAccount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, mint, to, amount, kind, createDestinationAccount);

  /// Create a copy of SplTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SplTransferImplCopyWith<_$SplTransferImpl> get copyWith =>
      __$$SplTransferImplCopyWithImpl<_$SplTransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SplTransferImplToJson(
      this,
    );
  }
}

abstract class _SplTransfer implements SplTransfer {
  const factory _SplTransfer(
      {required final String mint,
      required final String to,
      required final String amount,
      final String kind,
      @JsonKey(includeIfNull: false)
      final bool? createDestinationAccount}) = _$SplTransferImpl;

  factory _SplTransfer.fromJson(Map<String, dynamic> json) =
      _$SplTransferImpl.fromJson;

  /// The mint account address
  @override
  String get mint;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Spl'
  @override
  String get kind;

  /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
  @override
  @JsonKey(includeIfNull: false)
  bool? get createDestinationAccount;

  /// Create a copy of SplTransfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SplTransferImplCopyWith<_$SplTransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Spl2022Transfer _$Spl2022TransferFromJson(Map<String, dynamic> json) {
  return _Spl2022Transfer.fromJson(json);
}

/// @nodoc
mixin _$Spl2022Transfer {
  /// The mint account address
  String get mint => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Spl2022'
  String get kind => throw _privateConstructorUsedError;

  /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
  @JsonKey(includeIfNull: false)
  bool? get createDestinationAccount => throw _privateConstructorUsedError;

  /// Serializes this Spl2022Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Spl2022Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Spl2022TransferCopyWith<Spl2022Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Spl2022TransferCopyWith<$Res> {
  factory $Spl2022TransferCopyWith(
          Spl2022Transfer value, $Res Function(Spl2022Transfer) then) =
      _$Spl2022TransferCopyWithImpl<$Res, Spl2022Transfer>;
  @useResult
  $Res call(
      {String mint,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) bool? createDestinationAccount});
}

/// @nodoc
class _$Spl2022TransferCopyWithImpl<$Res, $Val extends Spl2022Transfer>
    implements $Spl2022TransferCopyWith<$Res> {
  _$Spl2022TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Spl2022Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? createDestinationAccount = freezed,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      createDestinationAccount: freezed == createDestinationAccount
          ? _value.createDestinationAccount
          : createDestinationAccount // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Spl2022TransferImplCopyWith<$Res>
    implements $Spl2022TransferCopyWith<$Res> {
  factory _$$Spl2022TransferImplCopyWith(_$Spl2022TransferImpl value,
          $Res Function(_$Spl2022TransferImpl) then) =
      __$$Spl2022TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String mint,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) bool? createDestinationAccount});
}

/// @nodoc
class __$$Spl2022TransferImplCopyWithImpl<$Res>
    extends _$Spl2022TransferCopyWithImpl<$Res, _$Spl2022TransferImpl>
    implements _$$Spl2022TransferImplCopyWith<$Res> {
  __$$Spl2022TransferImplCopyWithImpl(
      _$Spl2022TransferImpl _value, $Res Function(_$Spl2022TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Spl2022Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mint = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? createDestinationAccount = freezed,
  }) {
    return _then(_$Spl2022TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      createDestinationAccount: freezed == createDestinationAccount
          ? _value.createDestinationAccount
          : createDestinationAccount // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Spl2022TransferImpl implements _Spl2022Transfer {
  const _$Spl2022TransferImpl(
      {required this.mint,
      required this.to,
      required this.amount,
      this.kind = 'Spl2022',
      @JsonKey(includeIfNull: false) this.createDestinationAccount});

  factory _$Spl2022TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Spl2022TransferImplFromJson(json);

  /// The mint account address
  @override
  final String mint;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Spl2022'
  @override
  @JsonKey()
  final String kind;

  /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
  @override
  @JsonKey(includeIfNull: false)
  final bool? createDestinationAccount;

  @override
  String toString() {
    return 'Spl2022Transfer(mint: $mint, to: $to, amount: $amount, kind: $kind, createDestinationAccount: $createDestinationAccount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Spl2022TransferImpl &&
            (identical(other.mint, mint) || other.mint == mint) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(
                    other.createDestinationAccount, createDestinationAccount) ||
                other.createDestinationAccount == createDestinationAccount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, mint, to, amount, kind, createDestinationAccount);

  /// Create a copy of Spl2022Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Spl2022TransferImplCopyWith<_$Spl2022TransferImpl> get copyWith =>
      __$$Spl2022TransferImplCopyWithImpl<_$Spl2022TransferImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Spl2022TransferImplToJson(
      this,
    );
  }
}

abstract class _Spl2022Transfer implements Spl2022Transfer {
  const factory _Spl2022Transfer(
      {required final String mint,
      required final String to,
      required final String amount,
      final String kind,
      @JsonKey(includeIfNull: false)
      final bool? createDestinationAccount}) = _$Spl2022TransferImpl;

  factory _Spl2022Transfer.fromJson(Map<String, dynamic> json) =
      _$Spl2022TransferImpl.fromJson;

  /// The mint account address
  @override
  String get mint;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Spl2022'
  @override
  String get kind;

  /// If True, pay to create the associated token account of the recipient if it doesn't exist. Defaults to False.
  @override
  @JsonKey(includeIfNull: false)
  bool? get createDestinationAccount;

  /// Create a copy of Spl2022Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Spl2022TransferImplCopyWith<_$Spl2022TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Sep41Transfer _$Sep41TransferFromJson(Map<String, dynamic> json) {
  return _Sep41Transfer.fromJson(json);
}

/// @nodoc
mixin _$Sep41Transfer {
  /// The asset issuer address
  String get issuer => throw _privateConstructorUsedError;

  /// The asset code
  String get assetCode => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Sep41'
  String get kind => throw _privateConstructorUsedError;

  /// The memo
  @JsonKey(includeIfNull: false)
  String? get memo => throw _privateConstructorUsedError;

  /// Serializes this Sep41Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Sep41Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Sep41TransferCopyWith<Sep41Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Sep41TransferCopyWith<$Res> {
  factory $Sep41TransferCopyWith(
          Sep41Transfer value, $Res Function(Sep41Transfer) then) =
      _$Sep41TransferCopyWithImpl<$Res, Sep41Transfer>;
  @useResult
  $Res call(
      {String issuer,
      String assetCode,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) String? memo});
}

/// @nodoc
class _$Sep41TransferCopyWithImpl<$Res, $Val extends Sep41Transfer>
    implements $Sep41TransferCopyWith<$Res> {
  _$Sep41TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Sep41Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? issuer = null,
    Object? assetCode = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? memo = freezed,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Sep41TransferImplCopyWith<$Res>
    implements $Sep41TransferCopyWith<$Res> {
  factory _$$Sep41TransferImplCopyWith(
          _$Sep41TransferImpl value, $Res Function(_$Sep41TransferImpl) then) =
      __$$Sep41TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String issuer,
      String assetCode,
      String to,
      String amount,
      String kind,
      @JsonKey(includeIfNull: false) String? memo});
}

/// @nodoc
class __$$Sep41TransferImplCopyWithImpl<$Res>
    extends _$Sep41TransferCopyWithImpl<$Res, _$Sep41TransferImpl>
    implements _$$Sep41TransferImplCopyWith<$Res> {
  __$$Sep41TransferImplCopyWithImpl(
      _$Sep41TransferImpl _value, $Res Function(_$Sep41TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Sep41Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? issuer = null,
    Object? assetCode = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? memo = freezed,
  }) {
    return _then(_$Sep41TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
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
class _$Sep41TransferImpl implements _Sep41Transfer {
  const _$Sep41TransferImpl(
      {required this.issuer,
      required this.assetCode,
      required this.to,
      required this.amount,
      this.kind = 'Sep41',
      @JsonKey(includeIfNull: false) this.memo});

  factory _$Sep41TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Sep41TransferImplFromJson(json);

  /// The asset issuer address
  @override
  final String issuer;

  /// The asset code
  @override
  final String assetCode;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Sep41'
  @override
  @JsonKey()
  final String kind;

  /// The memo
  @override
  @JsonKey(includeIfNull: false)
  final String? memo;

  @override
  String toString() {
    return 'Sep41Transfer(issuer: $issuer, assetCode: $assetCode, to: $to, amount: $amount, kind: $kind, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Sep41TransferImpl &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.assetCode, assetCode) ||
                other.assetCode == assetCode) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.memo, memo) || other.memo == memo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, issuer, assetCode, to, amount, kind, memo);

  /// Create a copy of Sep41Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Sep41TransferImplCopyWith<_$Sep41TransferImpl> get copyWith =>
      __$$Sep41TransferImplCopyWithImpl<_$Sep41TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Sep41TransferImplToJson(
      this,
    );
  }
}

abstract class _Sep41Transfer implements Sep41Transfer {
  const factory _Sep41Transfer(
      {required final String issuer,
      required final String assetCode,
      required final String to,
      required final String amount,
      final String kind,
      @JsonKey(includeIfNull: false) final String? memo}) = _$Sep41TransferImpl;

  factory _Sep41Transfer.fromJson(Map<String, dynamic> json) =
      _$Sep41TransferImpl.fromJson;

  /// The asset issuer address
  @override
  String get issuer;

  /// The asset code
  @override
  String get assetCode;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Sep41'
  @override
  String get kind;

  /// The memo
  @override
  @JsonKey(includeIfNull: false)
  String? get memo;

  /// Create a copy of Sep41Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Sep41TransferImplCopyWith<_$Sep41TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Tep74Transfer _$Tep74TransferFromJson(Map<String, dynamic> json) {
  return _Tep74Transfer.fromJson(json);
}

/// @nodoc
mixin _$Tep74Transfer {
  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Tep74'
  String get kind => throw _privateConstructorUsedError;

  /// The jetton master address
  String? get master => throw _privateConstructorUsedError;

  /// Serializes this Tep74Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Tep74Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Tep74TransferCopyWith<Tep74Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Tep74TransferCopyWith<$Res> {
  factory $Tep74TransferCopyWith(
          Tep74Transfer value, $Res Function(Tep74Transfer) then) =
      _$Tep74TransferCopyWithImpl<$Res, Tep74Transfer>;
  @useResult
  $Res call({String to, String amount, String kind, String? master});
}

/// @nodoc
class _$Tep74TransferCopyWithImpl<$Res, $Val extends Tep74Transfer>
    implements $Tep74TransferCopyWith<$Res> {
  _$Tep74TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Tep74Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? master = freezed,
  }) {
    return _then(_value.copyWith(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      master: freezed == master
          ? _value.master
          : master // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Tep74TransferImplCopyWith<$Res>
    implements $Tep74TransferCopyWith<$Res> {
  factory _$$Tep74TransferImplCopyWith(
          _$Tep74TransferImpl value, $Res Function(_$Tep74TransferImpl) then) =
      __$$Tep74TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String to, String amount, String kind, String? master});
}

/// @nodoc
class __$$Tep74TransferImplCopyWithImpl<$Res>
    extends _$Tep74TransferCopyWithImpl<$Res, _$Tep74TransferImpl>
    implements _$$Tep74TransferImplCopyWith<$Res> {
  __$$Tep74TransferImplCopyWithImpl(
      _$Tep74TransferImpl _value, $Res Function(_$Tep74TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Tep74Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
    Object? master = freezed,
  }) {
    return _then(_$Tep74TransferImpl(
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      master: freezed == master
          ? _value.master
          : master // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Tep74TransferImpl implements _Tep74Transfer {
  const _$Tep74TransferImpl(
      {required this.to,
      required this.amount,
      this.kind = 'Tep74',
      this.master});

  factory _$Tep74TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Tep74TransferImplFromJson(json);

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Tep74'
  @override
  @JsonKey()
  final String kind;

  /// The jetton master address
  @override
  final String? master;

  @override
  String toString() {
    return 'Tep74Transfer(to: $to, amount: $amount, kind: $kind, master: $master)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Tep74TransferImpl &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.master, master) || other.master == master));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, to, amount, kind, master);

  /// Create a copy of Tep74Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Tep74TransferImplCopyWith<_$Tep74TransferImpl> get copyWith =>
      __$$Tep74TransferImplCopyWithImpl<_$Tep74TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Tep74TransferImplToJson(
      this,
    );
  }
}

abstract class _Tep74Transfer implements Tep74Transfer {
  const factory _Tep74Transfer(
      {required final String to,
      required final String amount,
      final String kind,
      final String? master}) = _$Tep74TransferImpl;

  factory _Tep74Transfer.fromJson(Map<String, dynamic> json) =
      _$Tep74TransferImpl.fromJson;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Tep74'
  @override
  String get kind;

  /// The jetton master address
  @override
  String? get master;

  /// Create a copy of Tep74Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Tep74TransferImplCopyWith<_$Tep74TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Trc10Transfer _$Trc10TransferFromJson(Map<String, dynamic> json) {
  return _Trc10Transfer.fromJson(json);
}

/// @nodoc
mixin _$Trc10Transfer {
  /// The token ID
  String get tokenId => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Trc10'
  String get kind => throw _privateConstructorUsedError;

  /// Serializes this Trc10Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Trc10Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Trc10TransferCopyWith<Trc10Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Trc10TransferCopyWith<$Res> {
  factory $Trc10TransferCopyWith(
          Trc10Transfer value, $Res Function(Trc10Transfer) then) =
      _$Trc10TransferCopyWithImpl<$Res, Trc10Transfer>;
  @useResult
  $Res call({String tokenId, String to, String amount, String kind});
}

/// @nodoc
class _$Trc10TransferCopyWithImpl<$Res, $Val extends Trc10Transfer>
    implements $Trc10TransferCopyWith<$Res> {
  _$Trc10TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trc10Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tokenId = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Trc10TransferImplCopyWith<$Res>
    implements $Trc10TransferCopyWith<$Res> {
  factory _$$Trc10TransferImplCopyWith(
          _$Trc10TransferImpl value, $Res Function(_$Trc10TransferImpl) then) =
      __$$Trc10TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String tokenId, String to, String amount, String kind});
}

/// @nodoc
class __$$Trc10TransferImplCopyWithImpl<$Res>
    extends _$Trc10TransferCopyWithImpl<$Res, _$Trc10TransferImpl>
    implements _$$Trc10TransferImplCopyWith<$Res> {
  __$$Trc10TransferImplCopyWithImpl(
      _$Trc10TransferImpl _value, $Res Function(_$Trc10TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trc10Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tokenId = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_$Trc10TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Trc10TransferImpl implements _Trc10Transfer {
  const _$Trc10TransferImpl(
      {required this.tokenId,
      required this.to,
      required this.amount,
      this.kind = 'Trc10'});

  factory _$Trc10TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Trc10TransferImplFromJson(json);

  /// The token ID
  @override
  final String tokenId;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Trc10'
  @override
  @JsonKey()
  final String kind;

  @override
  String toString() {
    return 'Trc10Transfer(tokenId: $tokenId, to: $to, amount: $amount, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Trc10TransferImpl &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tokenId, to, amount, kind);

  /// Create a copy of Trc10Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Trc10TransferImplCopyWith<_$Trc10TransferImpl> get copyWith =>
      __$$Trc10TransferImplCopyWithImpl<_$Trc10TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Trc10TransferImplToJson(
      this,
    );
  }
}

abstract class _Trc10Transfer implements Trc10Transfer {
  const factory _Trc10Transfer(
      {required final String tokenId,
      required final String to,
      required final String amount,
      final String kind}) = _$Trc10TransferImpl;

  factory _Trc10Transfer.fromJson(Map<String, dynamic> json) =
      _$Trc10TransferImpl.fromJson;

  /// The token ID
  @override
  String get tokenId;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Trc10'
  @override
  String get kind;

  /// Create a copy of Trc10Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Trc10TransferImplCopyWith<_$Trc10TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Trc20Transfer _$Trc20TransferFromJson(Map<String, dynamic> json) {
  return _Trc20Transfer.fromJson(json);
}

/// @nodoc
mixin _$Trc20Transfer {
  /// The smart contract address
  String get contract => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The amount of tokens to transfer in minimum denomination
  String get amount => throw _privateConstructorUsedError;

  /// The kind, should be 'Trc20'
  String get kind => throw _privateConstructorUsedError;

  /// Serializes this Trc20Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Trc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Trc20TransferCopyWith<Trc20Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Trc20TransferCopyWith<$Res> {
  factory $Trc20TransferCopyWith(
          Trc20Transfer value, $Res Function(Trc20Transfer) then) =
      _$Trc20TransferCopyWithImpl<$Res, Trc20Transfer>;
  @useResult
  $Res call({String contract, String to, String amount, String kind});
}

/// @nodoc
class _$Trc20TransferCopyWithImpl<$Res, $Val extends Trc20Transfer>
    implements $Trc20TransferCopyWith<$Res> {
  _$Trc20TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Trc20TransferImplCopyWith<$Res>
    implements $Trc20TransferCopyWith<$Res> {
  factory _$$Trc20TransferImplCopyWith(
          _$Trc20TransferImpl value, $Res Function(_$Trc20TransferImpl) then) =
      __$$Trc20TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String contract, String to, String amount, String kind});
}

/// @nodoc
class __$$Trc20TransferImplCopyWithImpl<$Res>
    extends _$Trc20TransferCopyWithImpl<$Res, _$Trc20TransferImpl>
    implements _$$Trc20TransferImplCopyWith<$Res> {
  __$$Trc20TransferImplCopyWithImpl(
      _$Trc20TransferImpl _value, $Res Function(_$Trc20TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_$Trc20TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Trc20TransferImpl implements _Trc20Transfer {
  const _$Trc20TransferImpl(
      {required this.contract,
      required this.to,
      required this.amount,
      this.kind = 'Trc20'});

  factory _$Trc20TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Trc20TransferImplFromJson(json);

  /// The smart contract address
  @override
  final String contract;

  /// The destination address
  @override
  final String to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  final String amount;

  /// The kind, should be 'Trc20'
  @override
  @JsonKey()
  final String kind;

  @override
  String toString() {
    return 'Trc20Transfer(contract: $contract, to: $to, amount: $amount, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Trc20TransferImpl &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, contract, to, amount, kind);

  /// Create a copy of Trc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Trc20TransferImplCopyWith<_$Trc20TransferImpl> get copyWith =>
      __$$Trc20TransferImplCopyWithImpl<_$Trc20TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Trc20TransferImplToJson(
      this,
    );
  }
}

abstract class _Trc20Transfer implements Trc20Transfer {
  const factory _Trc20Transfer(
      {required final String contract,
      required final String to,
      required final String amount,
      final String kind}) = _$Trc20TransferImpl;

  factory _Trc20Transfer.fromJson(Map<String, dynamic> json) =
      _$Trc20TransferImpl.fromJson;

  /// The smart contract address
  @override
  String get contract;

  /// The destination address
  @override
  String get to;

  /// The amount of tokens to transfer in minimum denomination
  @override
  String get amount;

  /// The kind, should be 'Trc20'
  @override
  String get kind;

  /// Create a copy of Trc20Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Trc20TransferImplCopyWith<_$Trc20TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Trc721Transfer _$Trc721TransferFromJson(Map<String, dynamic> json) {
  return _Trc721Transfer.fromJson(json);
}

/// @nodoc
mixin _$Trc721Transfer {
  /// The smart contract address
  String get contract => throw _privateConstructorUsedError;

  /// The destination address
  String get to => throw _privateConstructorUsedError;

  /// The token to transfer
  String get tokenId => throw _privateConstructorUsedError;

  /// The kind, should be 'Trc721'
  String get kind => throw _privateConstructorUsedError;

  /// Serializes this Trc721Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Trc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Trc721TransferCopyWith<Trc721Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Trc721TransferCopyWith<$Res> {
  factory $Trc721TransferCopyWith(
          Trc721Transfer value, $Res Function(Trc721Transfer) then) =
      _$Trc721TransferCopyWithImpl<$Res, Trc721Transfer>;
  @useResult
  $Res call({String contract, String to, String tokenId, String kind});
}

/// @nodoc
class _$Trc721TransferCopyWithImpl<$Res, $Val extends Trc721Transfer>
    implements $Trc721TransferCopyWith<$Res> {
  _$Trc721TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? tokenId = null,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Trc721TransferImplCopyWith<$Res>
    implements $Trc721TransferCopyWith<$Res> {
  factory _$$Trc721TransferImplCopyWith(_$Trc721TransferImpl value,
          $Res Function(_$Trc721TransferImpl) then) =
      __$$Trc721TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String contract, String to, String tokenId, String kind});
}

/// @nodoc
class __$$Trc721TransferImplCopyWithImpl<$Res>
    extends _$Trc721TransferCopyWithImpl<$Res, _$Trc721TransferImpl>
    implements _$$Trc721TransferImplCopyWith<$Res> {
  __$$Trc721TransferImplCopyWithImpl(
      _$Trc721TransferImpl _value, $Res Function(_$Trc721TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contract = null,
    Object? to = null,
    Object? tokenId = null,
    Object? kind = null,
  }) {
    return _then(_$Trc721TransferImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Trc721TransferImpl implements _Trc721Transfer {
  const _$Trc721TransferImpl(
      {required this.contract,
      required this.to,
      required this.tokenId,
      this.kind = 'Trc721'});

  factory _$Trc721TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Trc721TransferImplFromJson(json);

  /// The smart contract address
  @override
  final String contract;

  /// The destination address
  @override
  final String to;

  /// The token to transfer
  @override
  final String tokenId;

  /// The kind, should be 'Trc721'
  @override
  @JsonKey()
  final String kind;

  @override
  String toString() {
    return 'Trc721Transfer(contract: $contract, to: $to, tokenId: $tokenId, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Trc721TransferImpl &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, contract, to, tokenId, kind);

  /// Create a copy of Trc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Trc721TransferImplCopyWith<_$Trc721TransferImpl> get copyWith =>
      __$$Trc721TransferImplCopyWithImpl<_$Trc721TransferImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Trc721TransferImplToJson(
      this,
    );
  }
}

abstract class _Trc721Transfer implements Trc721Transfer {
  const factory _Trc721Transfer(
      {required final String contract,
      required final String to,
      required final String tokenId,
      final String kind}) = _$Trc721TransferImpl;

  factory _Trc721Transfer.fromJson(Map<String, dynamic> json) =
      _$Trc721TransferImpl.fromJson;

  /// The smart contract address
  @override
  String get contract;

  /// The destination address
  @override
  String get to;

  /// The token to transfer
  @override
  String get tokenId;

  /// The kind, should be 'Trc721'
  @override
  String get kind;

  /// Create a copy of Trc721Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Trc721TransferImplCopyWith<_$Trc721TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Aip21Transfer _$Aip21TransferFromJson(Map<String, dynamic> json) {
  return _Aip21Transfer.fromJson(json);
}

/// @nodoc
mixin _$Aip21Transfer {
  String get metadata => throw _privateConstructorUsedError;
  String get to => throw _privateConstructorUsedError;
  String get amount => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;

  /// Serializes this Aip21Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Aip21Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Aip21TransferCopyWith<Aip21Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Aip21TransferCopyWith<$Res> {
  factory $Aip21TransferCopyWith(
          Aip21Transfer value, $Res Function(Aip21Transfer) then) =
      _$Aip21TransferCopyWithImpl<$Res, Aip21Transfer>;
  @useResult
  $Res call({String metadata, String to, String amount, String kind});
}

/// @nodoc
class _$Aip21TransferCopyWithImpl<$Res, $Val extends Aip21Transfer>
    implements $Aip21TransferCopyWith<$Res> {
  _$Aip21TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Aip21Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Aip21TransferImplCopyWith<$Res>
    implements $Aip21TransferCopyWith<$Res> {
  factory _$$Aip21TransferImplCopyWith(
          _$Aip21TransferImpl value, $Res Function(_$Aip21TransferImpl) then) =
      __$$Aip21TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String metadata, String to, String amount, String kind});
}

/// @nodoc
class __$$Aip21TransferImplCopyWithImpl<$Res>
    extends _$Aip21TransferCopyWithImpl<$Res, _$Aip21TransferImpl>
    implements _$$Aip21TransferImplCopyWith<$Res> {
  __$$Aip21TransferImplCopyWithImpl(
      _$Aip21TransferImpl _value, $Res Function(_$Aip21TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Aip21Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? to = null,
    Object? amount = null,
    Object? kind = null,
  }) {
    return _then(_$Aip21TransferImpl(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Aip21TransferImpl implements _Aip21Transfer {
  const _$Aip21TransferImpl(
      {required this.metadata,
      required this.to,
      required this.amount,
      this.kind = 'Aip21'});

  factory _$Aip21TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$Aip21TransferImplFromJson(json);

  @override
  final String metadata;
  @override
  final String to;
  @override
  final String amount;
  @override
  @JsonKey()
  final String kind;

  @override
  String toString() {
    return 'Aip21Transfer(metadata: $metadata, to: $to, amount: $amount, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Aip21TransferImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, metadata, to, amount, kind);

  /// Create a copy of Aip21Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Aip21TransferImplCopyWith<_$Aip21TransferImpl> get copyWith =>
      __$$Aip21TransferImplCopyWithImpl<_$Aip21TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Aip21TransferImplToJson(
      this,
    );
  }
}

abstract class _Aip21Transfer implements Aip21Transfer {
  const factory _Aip21Transfer(
      {required final String metadata,
      required final String to,
      required final String amount,
      final String kind}) = _$Aip21TransferImpl;

  factory _Aip21Transfer.fromJson(Map<String, dynamic> json) =
      _$Aip21TransferImpl.fromJson;

  @override
  String get metadata;
  @override
  String get to;
  @override
  String get amount;
  @override
  String get kind;

  /// Create a copy of Aip21Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Aip21TransferImplCopyWith<_$Aip21TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
