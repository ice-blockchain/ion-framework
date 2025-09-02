// SPDX-License-Identifier: ice License 1.0

part of 'coins_service.r.dart';

class _TransferFactory {
  Transfer create({
    required String receiverAddress,
    required double amountValue,
    required WalletAsset sendableAsset,
    NetworkFeeType? networkFeeType,
    String? memo,
  }) {
    final amount = BigInt.from(amountValue * BigInt.from(10).pow(sendableAsset.decimals).toDouble())
        .toString();
    final priority = switch (networkFeeType) {
      NetworkFeeType.fast => TransferPriority.fast,
      NetworkFeeType.standard => TransferPriority.standard,
      NetworkFeeType.slow => TransferPriority.slow,
      _ => null,
    };
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
        issuer: asset.mint,
        memo: memo,
      ),
      tep74: (asset) => Tep74Transfer(
        amount: amount,
        to: receiverAddress,
        master: asset.mint,
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
      unknown: (_) => throw CannotBuildTransferForUnknownAssetException(
        sendableAsset.kind,
      ),
    );
  }
}
