// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'evm_broadcast_request.f.freezed.dart';
part 'evm_broadcast_request.f.g.dart';

/// Request for broadcasting EVM transactions.
/// Supports both standard transactions and fee-sponsored user operations.
@freezed
class EvmBroadcastRequest with _$EvmBroadcastRequest {
  /// Standard EVM transaction (sign & broadcast) with hex string
  const factory EvmBroadcastRequest.transactionHex({
    /// Unsigned transaction as hex string
    required String transaction,

    /// The kind, should be 'Transaction'
    @Default('Transaction') String kind,

    /// Optional idempotency key
    @JsonKey(includeIfNull: false) String? externalId,
  }) = EvmTransactionHexBroadcastRequest;

  /// Standard EVM transaction (sign & broadcast) with JSON object
  const factory EvmBroadcastRequest.transactionJson({
    /// Unsigned transaction as EvmTransactionJson object
    required EvmTransactionJson transaction,

    /// The kind, should be 'Transaction'
    @Default('Transaction') String kind,

    /// Optional idempotency key
    @JsonKey(includeIfNull: false) String? externalId,
  }) = EvmTransactionJsonBroadcastRequest;

  /// Fee-sponsored smart-contract calls (ERC-4337 style)
  const factory EvmBroadcastRequest.userOperations({
    /// Array of user operation objects
    required List<EvmUserOperation> userOperations,

    /// Fee sponsor identifier (required for UserOperations)
    required String feeSponsorId,

    /// The kind, should be 'UserOperations'
    @Default('UserOperations') String kind,

    /// Optional idempotency key
    @JsonKey(includeIfNull: false) String? externalId,
  }) = EvmUserOperationsBroadcastRequest;

  factory EvmBroadcastRequest.fromJson(Map<String, dynamic> json) =>
      _$EvmBroadcastRequestFromJson(json);
}

/// EVM transaction JSON format (EIP-1559, legacy, or EIP-7702)
@freezed
class EvmTransactionJson with _$EvmTransactionJson {
  const factory EvmTransactionJson({
    /// Address or target contract
    required String to,

    /// Transaction type: 0 = legacy, 2 = EIP-1559 (default), 4 = EIP-7702
    @Default(2) int type,

    /// Amount in wei
    @JsonKey(includeIfNull: false) String? value,

    /// ABI-encoded calldata
    @JsonKey(includeIfNull: false) String? data,

    /// Optional nonce (auto by default)
    @JsonKey(includeIfNull: false) int? nonce,

    /// Optional gas limit (auto)
    @JsonKey(includeIfNull: false) String? gasLimit,

    /// Gas price (only for type 0)
    @JsonKey(includeIfNull: false) String? gasPrice,

    /// Max fee per gas (for type 2/4)
    @JsonKey(includeIfNull: false) String? maxFeePerGas,

    /// Max priority fee per gas (for type 2/4)
    @JsonKey(includeIfNull: false) String? maxPriorityFeePerGas,

    /// Authorization list (only for type 4 / EIP-7702)
    @JsonKey(includeIfNull: false) List<EvmAuthorization>? authorizationList,
  }) = _EvmTransactionJson;

  factory EvmTransactionJson.fromJson(Map<String, dynamic> json) =>
      _$EvmTransactionJsonFromJson(json);
}

/// User operation for fee-sponsored execution
@freezed
class EvmUserOperation with _$EvmUserOperation {
  const factory EvmUserOperation({
    /// Target address
    required String to,

    /// Value in wei (optional)
    @JsonKey(includeIfNull: false) String? value,

    /// ABI-encoded calldata (optional)
    @JsonKey(includeIfNull: false) String? data,
  }) = _EvmUserOperation;

  factory EvmUserOperation.fromJson(Map<String, dynamic> json) => _$EvmUserOperationFromJson(json);
}

/// Authorization for EIP-7702 (type 4 transactions)
@freezed
class EvmAuthorization with _$EvmAuthorization {
  const factory EvmAuthorization({
    /// Chain ID
    required int chainId,

    /// Contract the EOA will delegate to
    required String address,

    /// EOA nonce
    required int nonce,

    /// Signature
    required String signature,
  }) = _EvmAuthorization;

  factory EvmAuthorization.fromJson(Map<String, dynamic> json) => _$EvmAuthorizationFromJson(json);
}
