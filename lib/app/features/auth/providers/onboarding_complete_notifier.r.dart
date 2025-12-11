// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/providers/onboarding_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_builder_provider.r.dart';
import 'package:ion/app/features/user/model/badges/profile_badges.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/interest_set.f.dart';
import 'package:ion/app/features/user/model/interests.f.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/relevant_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
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
        final userRelays = await _assignUserRelays();

        // BE requires sending user relays alongside the user delegation event
        final userRelaysEvent = await _buildUserRelaysEvent(userRelays: userRelays);

        EventMessage? userDelegationEvent;

        // Send user delegation event in advance so all subsequent events pass delegation attestation
        try {
          userDelegationEvent = await ref.read(delegationCompleteProvider.future)
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
        } on PasskeyCancelledException {
          return;
        }

        final uploadedAvatar = await _uploadAvatar();

        final userMetadata =
            await _buildUserMetadata(avatarAttachment: uploadedAvatar?.mediaAttachment);

        final (:interestSetData, :interestsData) = _buildUserLanguages();

        final updateUserSocialProfileResponse =
            await _updateUserSocialProfile(userMetadata: userMetadata);

        final usernameProofsEvents = _buildUsernameProofsEvents(updateUserSocialProfileResponse);

        final updatedProfileBadges =
            await _buildProfileBadges(usernameProofsEvents: usernameProofsEvents);

        final followList = _buildFollowList(updateUserSocialProfileResponse.referralMasterKey);

        final userTokenDefinition = await _buildUserTokenDefinition();

        await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData(
          [
            userMetadata,
            userTokenDefinition,
            followList,
            interestSetData,
            interestsData,
            if (uploadedAvatar != null) uploadedAvatar.fileMetadata,
            if (updatedProfileBadges != null) updatedProfileBadges,
          ],
          additionalEvents: usernameProofsEvents,
        );

        await _sendFollowListToFollowees(
          followList: followList,
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
            await ref.read(ionConnectNotifierProvider.notifier).sendEvents([userDelegationEvent]);
          } on PasskeyCancelledException {
            return;
          }
        }
      },
    );
  }

  Future<List<UserRelay>> _assignUserRelays() async {
    final ionConnectRelays = await ref.read(currentUserIdentityConnectRelaysProvider.future);
    if (ionConnectRelays != null && ionConnectRelays.isNotEmpty) {
      return ionConnectRelays;
    }
    final followees = ref.read(onboardingDataProvider).followees;

    final relays =
        await ref.read(currentUserIdentityProvider.notifier).assignUserRelays(followees: followees);

    // Invalidate all relay providers so they rebuild with new relays
    ref
      ..invalidate(rankedCurrentUserRelaysProvider)
      ..invalidate(rankedRelevantCurrentUserRelaysUrlsProvider)
      ..invalidate(relevantCurrentUserRelaysProvider);

    return relays;
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
    required List<EventMessage> usernameProofsEvents,
  }) {
    return ref.read(updateProfileBadgesWithProofsProvider(usernameProofsEvents).future);
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

  Future<CommunityTokenDefinition> _buildUserTokenDefinition() async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final communityTokenDefinitionBuilder = ref.read(communityTokenDefinitionBuilderProvider);
    return communityTokenDefinitionBuilder.build(
      origEventReference:
          ReplaceableEventReference(masterPubkey: currentPubkey, kind: UserMetadataEntity.kind),
      type: CommunityTokenDefinitionType.original,
    );
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

  Future<void> _sendFollowListToFollowees({
    required FollowListData followList,
  }) async {
    if (followList.list.isEmpty) {
      return;
    }

    final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);
    final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);
    await Future.wait(
      followList.list.map(
        (followee) => ionNotifier.sendEntityData(
          followList,
          actionSource: ActionSourceUser(followee.pubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        ),
      ),
    );
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
