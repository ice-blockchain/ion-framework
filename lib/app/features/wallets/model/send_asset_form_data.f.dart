// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart';

part 'send_asset_form_data.f.freezed.dart';

@freezed
class SendAssetFormData with _$SendAssetFormData {
  const factory SendAssetFormData({
    required int arrivalDateTime,
    required String receiverAddress,
    required CryptoAssetToSendData assetData,
    WalletViewData? walletView,
    NetworkData? network,
    Wallet? senderWallet,
    String? contactPubkey,
    String? memo,
    WalletAsset? networkNativeToken,
    NetworkFeeOption? selectedNetworkFeeOption,
    FundsRequestEntity? request,
    @Default(true) bool canCoverNetworkFee,
    @Default([]) List<NetworkFeeOption> networkFeeOptions,
    @Default(false) bool isContactPreselected,
    @Default(false) bool exceedsMaxAmount,
  }) = _SendAssetFormData;
}
