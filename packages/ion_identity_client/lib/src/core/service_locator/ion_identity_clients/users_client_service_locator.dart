// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/auth_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_service_locator.dart';
import 'package:ion_identity_client/src/users/available_ion_connect_relays/available_ion_connect_relays_service.dart';
import 'package:ion_identity_client/src/users/available_ion_connect_relays/data_sources/available_ion_connect_relays_data_source.dart';
import 'package:ion_identity_client/src/users/get_content_creators/content_creators_service.dart';
import 'package:ion_identity_client/src/users/get_content_creators/data_sources/get_content_creators_data_source.dart';
import 'package:ion_identity_client/src/users/get_user_social_profile/data_sources/get_user_social_profile_data_source.dart';
import 'package:ion_identity_client/src/users/get_user_social_profile/get_user_social_profile_service.dart';
import 'package:ion_identity_client/src/users/ion_connect_indexers/data_sources/ion_connect_indexers_data_source.dart';
import 'package:ion_identity_client/src/users/ion_connect_indexers/get_user_connect_indexers_service.dart';
import 'package:ion_identity_client/src/users/ion_connect_relays/data_sources/ion_connect_relays_data_source.dart';
import 'package:ion_identity_client/src/users/ion_connect_relays/ion_connect_relays_service.dart';
import 'package:ion_identity_client/src/users/ion_identity_users.dart';
import 'package:ion_identity_client/src/users/search_users_social_profile/data_sources/search_users_social_profile_data_source.dart';
import 'package:ion_identity_client/src/users/search_users_social_profile/search_users_social_profile_service.dart';
import 'package:ion_identity_client/src/users/set_ion_connect_relays/data_sources/set_ion_connect_relays_data_source.dart';
import 'package:ion_identity_client/src/users/set_ion_connect_relays/set_ion_connect_relays_service.dart';
import 'package:ion_identity_client/src/users/update_user_social_profile/data_sources/update_user_social_profile_data_source.dart';
import 'package:ion_identity_client/src/users/update_user_social_profile/update_user_social_profile_service.dart';
import 'package:ion_identity_client/src/users/user_details/data_sources/user_details_data_source.dart';
import 'package:ion_identity_client/src/users/user_details/user_details_service.dart';
import 'package:ion_identity_client/src/users/verify_nickname_availability/data_sources/nickname_availability_data_source.dart';
import 'package:ion_identity_client/src/users/verify_nickname_availability/nickname_availability_service.dart';

class UsersClientServiceLocator {
  factory UsersClientServiceLocator() {
    return _instance;
  }

  UsersClientServiceLocator._internal();

  static final UsersClientServiceLocator _instance = UsersClientServiceLocator._internal();

  IONIdentityUsers users({
    required String username,
    required IONIdentityConfig config,
  }) =>
      IONIdentityUsers(
        username,
        _userDetails(
          username: username,
          config: config,
        ),
        _ionConnectRelays(
          username: username,
          config: config,
        ),
        _ionConnectIndexers(
          username: username,
          config: config,
        ),
        _setIONConnectRelays(
          username: username,
          config: config,
        ),
        _ionConnectContentCreators(
          username: username,
          config: config,
        ),
        _nicknameAvailability(
          username: username,
          config: config,
        ),
        _updateUserSocialProfile(
          username: username,
          config: config,
        ),
        _getUserSocialProfile(
          username: username,
          config: config,
        ),
        _searchUserSocialProfile(
          username: username,
          config: config,
        ),
        AuthClientServiceLocator().extractUserId(),
        _availableIonConnectRelays(
          username: username,
          config: config,
        ),
      );

  UserDetailsService _userDetails({
    required String username,
    required IONIdentityConfig config,
  }) =>
      UserDetailsService(
        username,
        UserDetailsDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  IONConnectRelaysService _ionConnectRelays({
    required String username,
    required IONIdentityConfig config,
  }) =>
      IONConnectRelaysService(
        username,
        IONConnectRelaysDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  IONConnectIndexersService _ionConnectIndexers({
    required String username,
    required IONIdentityConfig config,
  }) =>
      IONConnectIndexersService(
        username,
        IONConnectIndexersDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  IONConnectContentCreatorsService _ionConnectContentCreators({
    required String username,
    required IONIdentityConfig config,
  }) =>
      IONConnectContentCreatorsService(
        username,
        IONContentCreatorsDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  NicknameAvailabilityService _nicknameAvailability({
    required String username,
    required IONIdentityConfig config,
  }) =>
      NicknameAvailabilityService(
        username,
        NicknameAvailabilityDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  UpdateUserSocialProfileService _updateUserSocialProfile({
    required String username,
    required IONIdentityConfig config,
  }) =>
      UpdateUserSocialProfileService(
        username,
        UpdateUserSocialProfileDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  GetUserSocialProfileService _getUserSocialProfile({
    required String username,
    required IONIdentityConfig config,
  }) =>
      GetUserSocialProfileService(
        username,
        GetUserSocialProfileDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  SearchUsersSocialProfileService _searchUserSocialProfile({
    required String username,
    required IONIdentityConfig config,
  }) =>
      SearchUsersSocialProfileService(
        username,
        SearchUsersSocialProfileDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  SetIONConnectRelaysService _setIONConnectRelays({
    required String username,
    required IONIdentityConfig config,
  }) =>
      SetIONConnectRelaysService(
        username,
        SetIONConnectRelaysDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );

  AvailableIONConnectRelaysService _availableIonConnectRelays({
    required String username,
    required IONIdentityConfig config,
  }) =>
      AvailableIONConnectRelaysService(
        username,
        AvailableIONConnectRelaysDataSource(
          IONIdentityServiceLocator.networkClient(config: config),
          IONIdentityServiceLocator.tokenStorage(),
        ),
      );
}
