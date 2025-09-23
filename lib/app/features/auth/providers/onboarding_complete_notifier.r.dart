// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/providers/onboarding_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/user/model/badges/profile_badges.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/interest_set.f.dart';
import 'package:ion/app/features/user/model/interests.f.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/features/user/providers/device_identification_proofs.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/features/user/providers/user_social_profile_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_complete_notifier.r.g.dart';

@riverpod
class OnboardingCompleteNotifier extends _$OnboardingCompleteNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> finish(OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        final userDelegationEvent = await _sendUserDelegation(onVerifyIdentity);
        if (userDelegationEvent == null) {
          return;
        }

        final uploadedAvatar = await _uploadAvatar();

        final userMetadata =
            await _buildUserMetadata(avatarAttachment: uploadedAvatar?.mediaAttachment);

        final (:interestSetData, :interestsData) = _buildUserLanguages();

        final updateUserSocialProfileResponse =
            await _updateUserSocialProfile(userMetadata: userMetadata);

        final usernameProofsEvents = _buildUsernameProofsEvents(updateUserSocialProfileResponse);
        final deviceIdentificationProofsEvents =
            await _getDeviceIdentificationProofsEvents(userDelegationEvent: userDelegationEvent);

        final updatedProfileBadges = await _buildProfileBadges(
          proofsEvents: [...usernameProofsEvents, ...deviceIdentificationProofsEvents],
        );

        final followList = _buildFollowList(updateUserSocialProfileResponse.referralMasterKey);

        await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData(
          [
            userMetadata,
            followList,
            interestSetData,
            interestsData,
            if (uploadedAvatar != null) uploadedAvatar.fileMetadata,
            if (updatedProfileBadges != null) updatedProfileBadges,
          ],
          additionalEvents: [...usernameProofsEvents, ...deviceIdentificationProofsEvents],
        );
      },
    );
  }

  Future<void> addDelegation(OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        final isDelegationComplete = await ref.read(delegationCompleteProvider.future);
        if (!isDelegationComplete) {
          try {
            final userDelegationEvent =
                await _buildUserDelegation(onVerifyIdentity: onVerifyIdentity);
            final deviceIdentificationProofsEvents = await _getDeviceIdentificationProofsEvents(
              userDelegationEvent: userDelegationEvent,
            );
            final updatedProfileBadges = await _buildProfileBadges(
              proofsEvents: deviceIdentificationProofsEvents,
            );

            final events = [userDelegationEvent, ...deviceIdentificationProofsEvents];
            if (updatedProfileBadges != null) {
              events.add(
                await ref.read(ionConnectNotifierProvider.notifier).sign(updatedProfileBadges),
              );
            }

            await ref.read(ionConnectNotifierProvider.notifier).sendEvents(events);
          } on PasskeyCancelledException {
            return;
          }
        }
      },
    );
  }

  Future<EventMessage?> _sendUserDelegation(
    OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity,
  ) async {
    final userRelays = await _assignUserRelays();
    // BE requires sending user relays alongside the user delegation event
    final userRelaysEvent = await _buildUserRelaysEvent(userRelays: userRelays);

    try {
      final userDelegationEvent = await ref.read(delegationCompleteProvider.future)
          ? null
          : await _buildUserDelegation(onVerifyIdentity: onVerifyIdentity);

      // Set delay to attach published 10100 and 10002 during the connection authorization
      ref.read(relaysReplicaDelayProvider.notifier).setDelay();

      await ref.read(ionConnectNotifierProvider.notifier).sendEvents([
        // Do not attach / update user delegation event if delegation for the current device is already complete
        if (userDelegationEvent != null) userDelegationEvent,
        // User relays still might be updated if user selected different content creators
        userRelaysEvent,
      ]);

      return userDelegationEvent;
    } on PasskeyCancelledException {
      return null;
    }
  }

  Future<List<UserRelay>> _assignUserRelays() async {
    final ionConnectRelays = await ref.read(currentUserIdentityConnectRelaysProvider.future);
    if (ionConnectRelays != null && ionConnectRelays.isNotEmpty) {
      return ionConnectRelays;
    }
    final followees = ref.read(onboardingDataProvider).followees;

    return ref.read(currentUserIdentityProvider.notifier).assignUserRelays(followees: followees);
  }

  Future<EventMessage> _buildUserRelaysEvent({
    required List<UserRelay> userRelays,
  }) async {
    if (userRelays.isEmpty) {
      throw RequiredFieldIsEmptyException(field: 'userRelays');
    }

    final userRelaysData = UserRelaysData(list: userRelays);

    return ref.read(ionConnectNotifierProvider.notifier).sign(userRelaysData);
  }

  Future<UserMetadata> _buildUserMetadata({MediaAttachment? avatarAttachment}) async {
    final OnboardingState(:name, :displayName) = ref.read(onboardingDataProvider);

    if (name == null) {
      throw RequiredFieldIsEmptyException(field: 'name');
    }

    if (displayName == null) {
      throw RequiredFieldIsEmptyException(field: 'displayName');
    }

    final wallets = await _buildUserWallets();

    return UserMetadata(
      name: name,
      displayName: displayName,
      registeredAt: DateTime.now().microsecondsSinceEpoch,
      picture: avatarAttachment?.url,
      media: avatarAttachment != null ? {avatarAttachment.url: avatarAttachment} : {},
      wallets: wallets,
    );
  }

  Future<UpdateUserSocialProfileResponse> _updateUserSocialProfile({
    required UserMetadata userMetadata,
  }) {
    return ref.read(
      updateUserSocialProfileProvider(
        data: UserSocialProfileData(
          username: userMetadata.name,
          displayName: userMetadata.displayName,
          bio: userMetadata.about,
          avatar: userMetadata.picture,
          referral: ref.read(onboardingDataProvider).referralName,
        ),
      ).future,
    );
  }

  List<EventMessage> _buildUsernameProofsEvents(
    UpdateUserSocialProfileResponse updateUserSocialProfileResponse,
  ) {
    final usernameProofsJsonPayloads = updateUserSocialProfileResponse.usernameProof ?? [];

    return usernameProofsJsonPayloads.map(EventMessage.fromPayloadJson).toList();
  }

  Future<ProfileBadgesData?> _buildProfileBadges({
    required List<EventMessage> proofsEvents,
  }) {
    return ref.read(updateProfileBadgesWithProofsProvider(proofsEvents).future);
  }

  Future<List<EventMessage>> _getDeviceIdentificationProofsEvents({
    required EventMessage userDelegationEvent,
  }) {
    return ref.read(
      deviceIdentificationProofsProvider(
        delegationEvent: userDelegationEvent,
      ).future,
    );
  }

  Future<Map<String, String>> _buildUserWallets() async {
    final cryptoWallets = await ref.read(mainCryptoWalletsProvider.future);
    return Map.fromEntries(
      cryptoWallets.map((wallet) {
        if (wallet.address == null) return null;
        return MapEntry(wallet.network, wallet.address!);
      }).nonNulls,
    );
  }

  ({InterestSetData interestSetData, InterestsData interestsData}) _buildUserLanguages() {
    final OnboardingState(:languages) = ref.read(onboardingDataProvider);

    final currentPubkey = ref.read(currentPubkeySelectorProvider);

    if (languages == null || languages.isEmpty) {
      throw RequiredFieldIsEmptyException(field: 'languages');
    }

    if (currentPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final interestSetData = InterestSetData(
      type: InterestSetType.languages,
      hashtags: languages,
    );

    final interestsData = InterestsData(
      hashtags: [],
      interestSetRefs: [interestSetData.toReplaceableEventReference(currentPubkey)],
    );

    return (interestSetData: interestSetData, interestsData: interestsData);
  }

  Future<EventMessage> _buildUserDelegation({
    required OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity,
  }) async {
    final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

    if (eventSigner == null) {
      throw EventSignerNotFoundException();
    }

    final userDelegationData = await ref
        .read(userDelegationManagerProvider.notifier)
        .buildCurrentUserDelegationDataWith(pubkey: eventSigner.publicKey);

    return ref.read(ionConnectNotifierProvider.notifier).buildEventFromTagsAndSignWithMasterKey(
          onVerifyIdentity: onVerifyIdentity,
          kind: UserDelegationEntity.kind,
          tags: userDelegationData.tags,
        );
  }

  FollowListData _buildFollowList(String? referralPubkey) {
    final OnboardingState(:followees) = ref.read(onboardingDataProvider);
    final pubkeys = {
      if (followees != null) ...followees,
      if (referralPubkey != null) referralPubkey,
    };
    final followeeList = pubkeys.map((pubkey) => Followee(pubkey: pubkey)).toList();

    return FollowListData(list: followeeList);
  }

  Future<({FileMetadata fileMetadata, MediaAttachment mediaAttachment})?> _uploadAvatar() async {
    try {
      final avatar = ref.read(onboardingDataProvider).avatar;
      if (avatar != null) {
        return await ref
            .read(ionConnectUploadNotifierProvider.notifier)
            .upload(avatar, alt: FileAlt.avatar.toShortString());
      }
    } catch (error, stackTrace) {
      // intentionally ignore upload avatar exceptions
      Logger.log('Upload avatar exception', error: error, stackTrace: stackTrace);
    }
    return null;
  }
}
