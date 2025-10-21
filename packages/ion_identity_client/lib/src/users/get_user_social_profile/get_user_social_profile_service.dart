// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/users/get_user_social_profile/data_sources/get_user_social_profile_data_source.dart';
import 'package:ion_identity_client/src/users/update_user_social_profile/models/user_social_profile_data.f.dart';

class GetUserSocialProfileService {
  GetUserSocialProfileService(
    this.username,
    this._dataSource,
  );

  final String username;
  final GetUserSocialProfileDataSource _dataSource;

  Future<UserSocialProfileData> getUserSocialProfile({
    required String userIdOrMasterKey,
  }) async =>
      _dataSource.getUserSocialProfile(
        username: username,
        userIdOrMasterKey: userIdOrMasterKey,
      );
}
