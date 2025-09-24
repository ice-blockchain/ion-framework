// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart' hide UserMetadata;
import 'package:ion/app/features/user/providers/user_social_profile_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
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
              .scaleImage(avatar, scaleResolution: FfmpegScaleArg.p120)
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

      final entitiesData = [...files, data];

      final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
      final additionalEvents = <EventMessage>[];
      final usernameChanged = currentUserMetadata?.data.name != data.name;
      final displayNameChanged = currentUserMetadata?.data.displayName != data.displayName;
      final bioChanged = currentUserMetadata?.data.about != data.about;
      final avatarChanged = currentUserMetadata?.data.picture != data.picture;
      if (currentUserMetadata != null &&
          (usernameChanged || displayNameChanged || avatarChanged || bioChanged)) {
        final updateUserSocialProfileResponse = await ref.read(
          updateUserSocialProfileProvider(
            data: UserSocialProfileData(
              username: usernameChanged ? data.name : null,
              displayName: displayNameChanged ? data.displayName : null,
              bio: bioChanged ? data.about : null,
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
