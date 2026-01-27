// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/tokenized_communities/providers/fat_address_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart' hide UserMetadata;
import 'package:ion/app/features/user/providers/user_social_profile_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_scale_arg.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_user_metadata_notifier.r.g.dart';

@riverpod
class UpdateUserMetadataNotifier extends _$UpdateUserMetadataNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> publish(UserMetadata userMetadata, {MediaFile? avatar, MediaFile? banner}) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      var data = userMetadata.copyWith(
        website: userMetadata.website != null
            ? normalizeUrl(userMetadata.website!)
            : userMetadata.website,
      );
      final avatarThumb = avatar != null
          ? await ref
              .read(imageCompressorProvider)
              .scaleImage(avatar, scaleResolution: FfmpegScaleArg.p480)
          : null;

      final (uploadedAvatar, uploadedBanner, uploadedAvatarThumb) = await (
        _upload(avatar, alt: FileAlt.avatar),
        _upload(banner, alt: FileAlt.banner),
        _upload(avatarThumb, alt: FileAlt.avatar)
      ).wait;

      final files = [uploadedAvatar, uploadedBanner, uploadedAvatarThumb]
          .whereType<UploadResult>()
          .map((result) => result.fileMetadata);

      if (uploadedAvatar != null) {
        final attachment = uploadedAvatar.mediaAttachment;
        final uploadedAvatarThumbAttachment = uploadedAvatarThumb?.mediaAttachment;

        data = data.copyWith(
          picture: attachment.url,
          media: {
            ...data.media,
            attachment.url: attachment.copyWith(thumb: uploadedAvatarThumbAttachment?.url),
          },
        );
      }

      if (uploadedBanner != null) {
        final attachment = uploadedBanner.mediaAttachment;
        data = data.copyWith(
          banner: attachment.url,
          media: {...data.media, attachment.url: attachment},
        );
      }

      if (data.about != null) {
        data = data.copyWith(
          about: QuillTextUtils.trimBioDeltaJson(data.about),
        );
      }

      final entitiesData = [...files, data];

      final trimmedDisplayName = data.trimmedDisplayName;
      final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
      final additionalEvents = <EventMessage>[];
      final usernameChanged = currentUserMetadata?.data.name != data.name;
      final displayNameChanged = currentUserMetadata?.data.displayName != trimmedDisplayName;
      final bioChanged = currentUserMetadata?.data.about != data.about;
      final avatarChanged = currentUserMetadata?.data.picture != data.picture;
      if (currentUserMetadata != null &&
          (usernameChanged || displayNameChanged || avatarChanged || bioChanged)) {
        final trimmedBio = bioChanged && data.about != null
            ? QuillTextUtils.bioDeltaJsonToTrimmedPlainText(data.about)
            : null;

        final updateUserSocialProfileResponse = await ref.read(
          updateUserSocialProfileProvider(
            data: UserSocialProfileData(
              username: usernameChanged ? data.name : null,
              displayName: displayNameChanged ? trimmedDisplayName : null,
              bio: bioChanged ? trimmedBio : null,
              avatar: avatarChanged ? data.picture : null,
            ),
          ).future,
        );
        final usernameProofsJsonPayloads = updateUserSocialProfileResponse.usernameProof ?? [];
        if (usernameChanged && usernameProofsJsonPayloads.isNotEmpty) {
          final usernameProofsEvents =
              usernameProofsJsonPayloads.map(EventMessage.fromPayloadJson).toList();
          additionalEvents.addAll(usernameProofsEvents);
          final updatedProfileBadges =
              await ref.read(updateProfileBadgesWithProofsProvider(usernameProofsEvents).future);
          if (updatedProfileBadges != null) {
            entitiesData.add(updatedProfileBadges);
          }
        }
      }

      await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData(
            entitiesData,
            additionalEvents: additionalEvents,
          );
    });
  }

  Future<void> publishWithVerifyIdentity(
    UserMetadata userMetadata, {
    required OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity,
    MediaFile? avatar,
    MediaFile? banner,
  }) async {
    await ref.read(ionConnectNotifierProvider.notifier).buildEventFromTagsAndSignWithMasterKey(
      tags: const [],
      kind: UserMetadataEntity.kind,
      onVerifyIdentity: onVerifyIdentity,
    );
    await publish(userMetadata, avatar: avatar, banner: banner);
  }

  Future<void> publishWithUserActionSigner(
    UserMetadata userMetadata, {
    required UserActionSignerNew userActionSigner,
    MediaFile? avatar,
    MediaFile? banner,
  }) async {
    await _tryUpdateCreatorTokenMetadata(
      userMetadata: userMetadata,
      userActionSigner: userActionSigner,
    );
    await publish(userMetadata, avatar: avatar, banner: banner);
  }

  Future<void> _tryUpdateCreatorTokenMetadata({
    required UserMetadata userMetadata,
    required UserActionSignerNew userActionSigner,
  }) async {
    try {
      final currentMetadata = await ref.read(currentUserMetadataProvider.future);
      if (currentMetadata == null) return;

      final externalAddress = currentMetadata.externalAddress;
      if (externalAddress == null || externalAddress.isEmpty) return;

      final fatAddressData = await _buildUpdatedCreatorFatAddressData(
        currentMetadata: currentMetadata,
        userMetadata: userMetadata,
        externalAddress: externalAddress,
      );
      if (fatAddressData == null) return;

      final wallets = await ref.read(mainCryptoWalletsProvider.future);
      final bscWallet = CreatorTokenUtils.findBscWallet(wallets);
      if (bscWallet == null || bscWallet.id.isEmpty) return;

      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      await service.updateTokenMetadata(
        externalAddress: externalAddress,
        walletId: bscWallet.id,
        userActionSigner: userActionSigner,
        fatAddressData: fatAddressData,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to update creator token metadata',
      );
    }
  }

  Future<FatAddressV2Data?> _buildUpdatedCreatorFatAddressData({
    required UserMetadataEntity currentMetadata,
    required UserMetadata userMetadata,
    required String externalAddress,
  }) async {
    FatAddressV2Data? fatAddressData;
    try {
      fatAddressData = await ref.read(
        fatAddressDataProvider(
          externalAddress: externalAddress,
          externalAddressType: const ExternalAddressType.ionConnectUser(),
          eventReference: currentMetadata.toEventReference(),
        ).future,
      );
    } catch (_) {
      fatAddressData = null;
    }
    if (fatAddressData == null || fatAddressData.tokens.isEmpty) {
      return null;
    }

    final username = userMetadata.name.trim();
    final displayName = userMetadata.trimmedDisplayName.trim();
    final fallbackPubkey = currentMetadata.masterPubkey.isNotEmpty
        ? currentMetadata.masterPubkey
        : currentMetadata.pubkey;
    final symbol = username.isNotEmpty ? username : fallbackPubkey;
    final name = displayName.isNotEmpty ? displayName : symbol;

    final token = fatAddressData.tokens.first;
    final updatedToken = FatAddressV2TokenRecord(
      name: name,
      symbol: symbol,
      externalAddress: token.externalAddress,
      externalType: token.externalType,
      bondingAddress: token.bondingAddress,
      bondingBegin: token.bondingBegin,
      bondingEnd: token.bondingEnd,
      bondingSupply: token.bondingSupply,
    );

    return FatAddressV2Data(
      tokens: [updatedToken],
      creatorAddress: fatAddressData.creatorAddress,
      affiliateAddress: fatAddressData.affiliateAddress,
    );
  }

  Future<void> publishWallets(WalletAddressPrivacyOption option) async {
    Map<String, String>? wallets;
    if (option == WalletAddressPrivacyOption.public) {
      final cryptoWallets = await ref.read(mainCryptoWalletsProvider.future);
      wallets = Map.fromEntries(
        cryptoWallets.map((wallet) {
          if (wallet.address == null) return null;
          return MapEntry(wallet.network, wallet.address!);
        }).nonNulls,
      );
    }
    final userMetadata = await ref.read(currentUserMetadataProvider.future);
    if (userMetadata != null) {
      // Compare the current wallets with the newly computed wallets.
      final currentWallets = userMetadata.data.wallets;
      const equality = DeepCollectionEquality();
      if (equality.equals(currentWallets, wallets)) {
        return;
      }
      final updatedMetadata = userMetadata.data.copyWith(wallets: wallets);
      await publish(updatedMetadata);
    }
  }

  Future<UploadResult?> _upload(MediaFile? file, {required FileAlt alt}) {
    return file != null
        ? ref.read(ionConnectUploadNotifierProvider.notifier).upload(file, alt: alt.toShortString())
        : Future<UploadResult?>.value();
  }
}
