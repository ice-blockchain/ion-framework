// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/ion_signature.m.dart';
import 'package:ion_swap_client/utils/crypto_amount_converter.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';

// TODO(ice-erebus): move to separate package
class IonIdentityTransactionApi {
  IonIdentityTransactionApi({
    required IONIdentityClient ionIdentityClient,
  }) : _ionIdentityClient = ionIdentityClient;

  final IONIdentityClient _ionIdentityClient;

  Future<IonSignature> sign({
    required String walletId,
    required String message,
    required UserActionSignerNew userActionSigner,
  }) async {
    final wallet = await _resolveWallet(_ionIdentityClient, walletId);
    final response = await _ionIdentityClient.wallets.sign(wallet, message, userActionSigner);
    return IonSignature.fromJson(
      response['signature'] as Map<String, dynamic>,
    );
  }

  Future<String> signAndBroadcast({
    required String walletId,
    required EvmTransaction transaction,
    required UserActionSignerNew userActionSigner,
  }) async {
    final wallet = await _resolveWallet(_ionIdentityClient, walletId);

    final broadcastRequest = EvmBroadcastRequest.transactionJson(
      transaction: EvmTransactionJson(
        to: transaction.to,
        data: transaction.data.isNotEmpty ? transaction.data : null,
        value: _encodeQuantity(transaction.value),
      ),
    );

    final response = await _ionIdentityClient.wallets.signAndBroadcast(
      wallet,
      broadcastRequest,
      userActionSigner,
    );

    return _extractTransactionIdentifier(response);
  }

  Future<Map<String, dynamic>> getFeesOnBsc() async {
    /// Bsc always must be wit big first symbol
    return _ionIdentityClient.wallets.getFees(['Bsc']);
  }

  Future<Wallet> _resolveWallet(IONIdentityClient client, String walletId) async {
    final wallets = await client.wallets.getWallets();
    final wallet = wallets.firstWhere(
      (candidate) => candidate.id == walletId,
      orElse: () => throw const IonSwapException('Wallet not found'),
    );
    return wallet;
  }

  String _extractTransactionIdentifier(Map<String, dynamic> response) {
    final txHash = response['txHash'] as String?;
    final id = response['id'] as String?;
    final transferId = response['transferId'] as String?;
    return txHash ??
        id ??
        transferId ??
        (throw StateError('Ion Identity response did not include a transaction identifier'));
  }

  String _encodeQuantity(BigInt value) {
    if (value == BigInt.zero) {
      return '0x0';
    }
    final encoded = value.toRadixString(16);
    return '0x$encoded';
  }

  Future<String> makeTransfer({
    required String walletId,
    required UserActionSignerNew userActionSigner,
    required String to,
    required double amount,
    required WalletAsset sendableAsset,
  }) async {
    final wallet = await _resolveWallet(_ionIdentityClient, walletId);
    final response = await _ionIdentityClient.wallets.makeTransferWithSigner(
      wallet,
      _TransferFactory().create(
        receiverAddress: to,
        amountValue: amount,
        sendableAsset: sendableAsset,
      ),
      userActionSigner,
    );
    return _extractTransactionIdentifier(response);
  }
}

class _TransferFactory {
  Transfer create({
    required String receiverAddress,
    required double amountValue,
    required WalletAsset sendableAsset,
    String? memo,
  }) {
    final amount = toBlockchainUnits(amountValue.toString(), sendableAsset.decimals);
    const priority = TransferPriority.standard;
    return sendableAsset.map(
      native: (asset) => NativeTokenTransfer(
        to: receiverAddress,
        amount: amount,
        priority: priority,
        memo: memo,
      ),
      erc20: (asset) => Erc20Transfer(
        contract: asset.contract!,
        to: receiverAddress,
        amount: amount,
        priority: priority,
      ),
      asa: (asset) => AsaTransfer(
        assetId: asset.assetId,
        to: receiverAddress,
        amount: amount,
      ),
      spl: (asset) => SplTransfer(
        mint: asset.mint,
        to: receiverAddress,
        amount: amount,
        createDestinationAccount: true,
      ),
      spl2022: (asset) => Spl2022Transfer(
        mint: asset.mint,
        to: receiverAddress,
        amount: amount,
        createDestinationAccount: true,
      ),
      sep41: (asset) => Sep41Transfer(
        amount: amount,
        to: receiverAddress,
        assetCode: asset.symbol,
        issuer: asset.issuer,
        memo: memo,
      ),
      tep74: (asset) => Tep74Transfer(
        amount: amount,
        to: receiverAddress,
        master: asset.master,
      ),
      trc10: (asset) => Trc10Transfer(
        amount: amount,
        to: receiverAddress,
        tokenId: asset.tokenId,
      ),
      trc20: (asset) => Trc20Transfer(
        amount: amount,
        to: receiverAddress,
        contract: asset.contract,
      ),
      aip21: (asset) => Aip21Transfer(
        amount: amount,
        to: receiverAddress,
        metadata: asset.metadata,
      ),
      unknown: (_) => throw IonSwapException(
        'Cannot build transfer for unknown asset kind: ${sendableAsset.kind}',
      ),
    );
  }
}
