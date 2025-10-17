// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/users/models/identity_user_info.f.dart';
import 'package:ion_identity_client/src/users/search_users_social_profile/data_sources/search_users_social_profile_data_source.dart';
import 'package:ion_identity_client/src/users/search_users_social_profile/models/search_users_social_profile_type.dart';

class SearchUsersSocialProfileService {
  SearchUsersSocialProfileService(
    this.username,
    this._dataSource,
  );

  final String username;
  final SearchUsersSocialProfileDataSource _dataSource;

  Future<List<IdentityUserInfo>> searchForUsersByKeyword({
    required String keyword,
    required SearchUsersSocialProfileType searchType,
    required int limit,
    required int offset,
    String? followedBy,
    String? followerOf,
  }) async =>
      _dataSource.searchForUsersByKeyword(
        keyword: keyword,
        searchType: searchType,
        limit: limit,
        offset: offset,
        username: username,
        followedBy: followedBy,
        followerOf: followerOf,
      );
}
