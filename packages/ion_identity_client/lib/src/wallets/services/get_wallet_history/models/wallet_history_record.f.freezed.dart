// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_history_record.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletHistoryRecord _$WalletHistoryRecordFromJson(Map<String, dynamic> json) {
  return _WalletHistoryRecord.fromJson(json);
}

/// @nodoc
mixin _$WalletHistoryRecord {
  String get walletId => throw _privateConstructorUsedError;
  String get network => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get direction => throw _privateConstructorUsedError;
  int get blockNumber => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get txHash => throw _privateConstructorUsedError;
  String? get externalHash => throw _privateConstructorUsedError;
  String? get index => throw _privateConstructorUsedError;
  String? get contract => throw _privateConstructorUsedError;
  String? get metadataAddress =>
      throw _privateConstructorUsedError; // the same as contract for specific types of transactions
  String? get tokenId => throw _privateConstructorUsedError;
  String? get from => throw _privateConstructorUsedError;
  String? get to => throw _privateConstructorUsedError;
  List<String>? get tos => throw _privateConstructorUsedError;
  List<String>? get froms => throw _privateConstructorUsedError;
  String? get value => throw _privateConstructorUsedError;
  String? get fee => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  WalletHistoryMetadata get metadata => throw _privateConstructorUsedError;

  /// Serializes this WalletHistoryRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletHistoryRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletHistoryRecordCopyWith<WalletHistoryRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletHistoryRecordCopyWith<$Res> {
  factory $WalletHistoryRecordCopyWith(
          WalletHistoryRecord value, $Res Function(WalletHistoryRecord) then) =
      _$WalletHistoryRecordCopyWithImpl<$Res, WalletHistoryRecord>;
  @useResult
  $Res call(
      {String walletId,
      String network,
      String kind,
      String direction,
      int blockNumber,
      DateTime timestamp,
      String txHash,
      String? externalHash,
      String? index,
      String? contract,
      String? metadataAddress,
      String? tokenId,
      String? from,
      String? to,
      List<String>? tos,
      List<String>? froms,
      String? value,
      String? fee,
      String? memo,
      WalletHistoryMetadata metadata});

  $WalletHistoryMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$WalletHistoryRecordCopyWithImpl<$Res, $Val extends WalletHistoryRecord>
    implements $WalletHistoryRecordCopyWith<$Res> {
  _$WalletHistoryRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletHistoryRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletId = null,
    Object? network = null,
    Object? kind = null,
    Object? direction = null,
    Object? blockNumber = null,
    Object? timestamp = null,
    Object? txHash = null,
    Object? externalHash = freezed,
    Object? index = freezed,
    Object? contract = freezed,
    Object? metadataAddress = freezed,
    Object? tokenId = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? tos = freezed,
    Object? froms = freezed,
    Object? value = freezed,
    Object? fee = freezed,
    Object? memo = freezed,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      walletId: null == walletId
          ? _value.walletId
          : walletId // ignore: cast_nullable_to_non_nullable
              as String,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String,
      blockNumber: null == blockNumber
          ? _value.blockNumber
          : blockNumber // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      txHash: null == txHash
          ? _value.txHash
          : txHash // ignore: cast_nullable_to_non_nullable
              as String,
      externalHash: freezed == externalHash
          ? _value.externalHash
          : externalHash // ignore: cast_nullable_to_non_nullable
              as String?,
      index: freezed == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as String?,
      contract: freezed == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String?,
      metadataAddress: freezed == metadataAddress
          ? _value.metadataAddress
          : metadataAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenId: freezed == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String?,
      from: freezed == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String?,
      to: freezed == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String?,
      tos: freezed == tos
          ? _value.tos
          : tos // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      froms: freezed == froms
          ? _value.froms
          : froms // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      fee: freezed == fee
          ? _value.fee
          : fee // ignore: cast_nullable_to_non_nullable
              as String?,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as WalletHistoryMetadata,
    ) as $Val);
  }

  /// Create a copy of WalletHistoryRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletHistoryMetadataCopyWith<$Res> get metadata {
    return $WalletHistoryMetadataCopyWith<$Res>(_value.metadata, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WalletHistoryRecordImplCopyWith<$Res>
    implements $WalletHistoryRecordCopyWith<$Res> {
  factory _$$WalletHistoryRecordImplCopyWith(_$WalletHistoryRecordImpl value,
          $Res Function(_$WalletHistoryRecordImpl) then) =
      __$$WalletHistoryRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String walletId,
      String network,
      String kind,
      String direction,
      int blockNumber,
      DateTime timestamp,
      String txHash,
      String? externalHash,
      String? index,
      String? contract,
      String? metadataAddress,
      String? tokenId,
      String? from,
      String? to,
      List<String>? tos,
      List<String>? froms,
      String? value,
      String? fee,
      String? memo,
      WalletHistoryMetadata metadata});

  @override
  $WalletHistoryMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$$WalletHistoryRecordImplCopyWithImpl<$Res>
    extends _$WalletHistoryRecordCopyWithImpl<$Res, _$WalletHistoryRecordImpl>
    implements _$$WalletHistoryRecordImplCopyWith<$Res> {
  __$$WalletHistoryRecordImplCopyWithImpl(_$WalletHistoryRecordImpl _value,
      $Res Function(_$WalletHistoryRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletHistoryRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletId = null,
    Object? network = null,
    Object? kind = null,
    Object? direction = null,
    Object? blockNumber = null,
    Object? timestamp = null,
    Object? txHash = null,
    Object? externalHash = freezed,
    Object? index = freezed,
    Object? contract = freezed,
    Object? metadataAddress = freezed,
    Object? tokenId = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? tos = freezed,
    Object? froms = freezed,
    Object? value = freezed,
    Object? fee = freezed,
    Object? memo = freezed,
    Object? metadata = null,
  }) {
    return _then(_$WalletHistoryRecordImpl(
      walletId: null == walletId
          ? _value.walletId
          : walletId // ignore: cast_nullable_to_non_nullable
              as String,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String,
      blockNumber: null == blockNumber
          ? _value.blockNumber
          : blockNumber // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      txHash: null == txHash
          ? _value.txHash
          : txHash // ignore: cast_nullable_to_non_nullable
              as String,
      externalHash: freezed == externalHash
          ? _value.externalHash
          : externalHash // ignore: cast_nullable_to_non_nullable
              as String?,
      index: freezed == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as String?,
      contract: freezed == contract
          ? _value.contract
          : contract // ignore: cast_nullable_to_non_nullable
              as String?,
      metadataAddress: freezed == metadataAddress
          ? _value.metadataAddress
          : metadataAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenId: freezed == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String?,
      from: freezed == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String?,
      to: freezed == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String?,
      tos: freezed == tos
          ? _value._tos
          : tos // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      froms: freezed == froms
          ? _value._froms
          : froms // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      fee: freezed == fee
          ? _value.fee
          : fee // ignore: cast_nullable_to_non_nullable
              as String?,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as WalletHistoryMetadata,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletHistoryRecordImpl implements _WalletHistoryRecord {
  const _$WalletHistoryRecordImpl(
      {required this.walletId,
      required this.network,
      required this.kind,
      required this.direction,
      required this.blockNumber,
      required this.timestamp,
      required this.txHash,
      required this.externalHash,
      required this.index,
      required this.contract,
      required this.metadataAddress,
      required this.tokenId,
      required this.from,
      required this.to,
      required final List<String>? tos,
      required final List<String>? froms,
      required this.value,
      required this.fee,
      required this.memo,
      required this.metadata})
      : _tos = tos,
        _froms = froms;

  factory _$WalletHistoryRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletHistoryRecordImplFromJson(json);

  @override
  final String walletId;
  @override
  final String network;
  @override
  final String kind;
  @override
  final String direction;
  @override
  final int blockNumber;
  @override
  final DateTime timestamp;
  @override
  final String txHash;
  @override
  final String? externalHash;
  @override
  final String? index;
  @override
  final String? contract;
  @override
  final String? metadataAddress;
// the same as contract for specific types of transactions
  @override
  final String? tokenId;
  @override
  final String? from;
  @override
  final String? to;
  final List<String>? _tos;
  @override
  List<String>? get tos {
    final value = _tos;
    if (value == null) return null;
    if (_tos is EqualUnmodifiableListView) return _tos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _froms;
  @override
  List<String>? get froms {
    final value = _froms;
    if (value == null) return null;
    if (_froms is EqualUnmodifiableListView) return _froms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? value;
  @override
  final String? fee;
  @override
  final String? memo;
  @override
  final WalletHistoryMetadata metadata;

  @override
  String toString() {
    return 'WalletHistoryRecord(walletId: $walletId, network: $network, kind: $kind, direction: $direction, blockNumber: $blockNumber, timestamp: $timestamp, txHash: $txHash, externalHash: $externalHash, index: $index, contract: $contract, metadataAddress: $metadataAddress, tokenId: $tokenId, from: $from, to: $to, tos: $tos, froms: $froms, value: $value, fee: $fee, memo: $memo, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletHistoryRecordImpl &&
            (identical(other.walletId, walletId) ||
                other.walletId == walletId) &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.blockNumber, blockNumber) ||
                other.blockNumber == blockNumber) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.txHash, txHash) || other.txHash == txHash) &&
            (identical(other.externalHash, externalHash) ||
                other.externalHash == externalHash) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.contract, contract) ||
                other.contract == contract) &&
            (identical(other.metadataAddress, metadataAddress) ||
                other.metadataAddress == metadataAddress) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            const DeepCollectionEquality().equals(other._tos, _tos) &&
            const DeepCollectionEquality().equals(other._froms, _froms) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.fee, fee) || other.fee == fee) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        walletId,
        network,
        kind,
        direction,
        blockNumber,
        timestamp,
        txHash,
        externalHash,
        index,
        contract,
        metadataAddress,
        tokenId,
        from,
        to,
        const DeepCollectionEquality().hash(_tos),
        const DeepCollectionEquality().hash(_froms),
        value,
        fee,
        memo,
        metadata
      ]);

  /// Create a copy of WalletHistoryRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletHistoryRecordImplCopyWith<_$WalletHistoryRecordImpl> get copyWith =>
      __$$WalletHistoryRecordImplCopyWithImpl<_$WalletHistoryRecordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletHistoryRecordImplToJson(
      this,
    );
  }
}

abstract class _WalletHistoryRecord implements WalletHistoryRecord {
  const factory _WalletHistoryRecord(
          {required final String walletId,
          required final String network,
          required final String kind,
          required final String direction,
          required final int blockNumber,
          required final DateTime timestamp,
          required final String txHash,
          required final String? externalHash,
          required final String? index,
          required final String? contract,
          required final String? metadataAddress,
          required final String? tokenId,
          required final String? from,
          required final String? to,
          required final List<String>? tos,
          required final List<String>? froms,
          required final String? value,
          required final String? fee,
          required final String? memo,
          required final WalletHistoryMetadata metadata}) =
      _$WalletHistoryRecordImpl;

  factory _WalletHistoryRecord.fromJson(Map<String, dynamic> json) =
      _$WalletHistoryRecordImpl.fromJson;

  @override
  String get walletId;
  @override
  String get network;
  @override
  String get kind;
  @override
  String get direction;
  @override
  int get blockNumber;
  @override
  DateTime get timestamp;
  @override
  String get txHash;
  @override
  String? get externalHash;
  @override
  String? get index;
  @override
  String? get contract;
  @override
  String?
      get metadataAddress; // the same as contract for specific types of transactions
  @override
  String? get tokenId;
  @override
  String? get from;
  @override
  String? get to;
  @override
  List<String>? get tos;
  @override
  List<String>? get froms;
  @override
  String? get value;
  @override
  String? get fee;
  @override
  String? get memo;
  @override
  WalletHistoryMetadata get metadata;

  /// Create a copy of WalletHistoryRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletHistoryRecordImplCopyWith<_$WalletHistoryRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
