// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/chat/community/models/create_group_form_data.f.dart';
import 'package:ion/app/features/chat/community/models/group_type.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_group_form_controller_provider.r.g.dart';

@riverpod
class CreateGroupFormController extends _$CreateGroupFormController {
  @override
  CreateGroupFormData build() => const CreateGroupFormData();

  set type(GroupType value) => state = state.copyWith(type: value);

  set title(String value) => state = state.copyWith(name: value);

  set members(Iterable<String> value) =>
      state = state.copyWith(participantsMasterPubkeys: value.toSet());

  set groupPicture(MediaFile? value) => state = state.copyWith(groupPicture: value);

  void toggleMember(String participant) {
    final updatedMembers = state.participantsMasterPubkeys.toSet();
    updatedMembers.contains(participant)
        ? updatedMembers.remove(participant)
        : updatedMembers.add(participant);

    state = state.copyWith(participantsMasterPubkeys: updatedMembers);
  }
}
