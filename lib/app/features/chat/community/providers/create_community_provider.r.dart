// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/enum.dart';
import 'package:ion/app/features/chat/community/models/community_admin_type.dart';
import 'package:ion/app/features/chat/community/models/community_visibility_type.dart';
import 'package:ion/app/features/chat/community/models/entities/community_definition_data.f.dart';
import 'package:ion/app/features/chat/community/providers/community_admins_provider.r.dart';
import 'package:ion/app/features/chat/community/providers/invite_to_community_provider.r.dart';
import 'package:ion/app/features/chat/community/providers/join_community_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_setting.f.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_community_provider.r.g.dart';

@riverpod
class CreateCommunityNotifier extends _$CreateCommunityNotifier {
  @override
  FutureOr<CommunityDefinitionData?> build() {
    return null;
  }

  Future<void> createCommunity(
    String name,
    String? description,
    CommunityVisibilityType communityVisibilityType,
    RoleRequiredForPosting? roleRequiredForPosting,
  ) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final avatar = await _uploadAvatar();
      final communityAdmins = ref.read(communityAdminsProvider);

      final communityDefinitionData = CommunityDefinitionData.fromData(
        name: name,
        description: description,
        isPublic: communityVisibilityType == CommunityVisibilityType.public,
        isOpen: communityVisibilityType == CommunityVisibilityType.public,
        commentsEnabled: true,
        avatar: avatar?.mediaAttachment,
        roleRequiredForPosting: roleRequiredForPosting,
        moderators: communityAdmins.entries
            .where((entry) => entry.value == CommunityAdminType.moderator)
            .map((entry) => entry.key)
            .toList(),
        admins: communityAdmins.entries
            .where((entry) => entry.value == CommunityAdminType.admin)
            .map((entry) => entry.key)
            .toList(),
      );

      if (avatar != null) {
        unawaited(
          ref.read(ionConnectNotifierProvider.notifier).sendEntityData(avatar.fileMetadata),
        );
      }

      final communityEntity = await ref
          .read(ionConnectNotifierProvider.notifier)
          .sendEntityData<CommunityDefinitionEntity>(communityDefinitionData);

      if (communityEntity == null) {
        throw FailedToCreateCommunityException();
      }

      // join community as owner and invite moderators/admins
      ref.read(joinCommunityNotifierProvider.notifier).joinCommunity(communityEntity.data.uuid);

      communityAdmins.entries.map(
        (admin) => ref.read(inviteToCommunityNotifierProvider.notifier).inviteToCommunity(
              communityEntity.data.uuid,
              admin.key,
            ),
      );

      await ref.read(conversationDaoProvider).addCommunityConversation(communityEntity.data.uuid);

      return communityEntity.data;
    });
  }

  Future<UploadResult?> _uploadAvatar() async {
    final avatarFile =
        ref.read(imageProcessorNotifierProvider(ImageProcessingType.avatar)).whenOrNull(
              processed: (file) => file,
            );

    if (avatarFile == null) {
      return null;
    }
    final uploadAvatarResult = await ref
        .read(ionConnectUploadNotifierProvider.notifier)
        .upload(avatarFile, alt: FileAlt.avatar.toShortString());

    return uploadAvatarResult;
  }
}
