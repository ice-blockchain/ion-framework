// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/coins/ion_identity_coins.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/user_action_signer_service_locator.dart';
import 'package:ion_identity_client/src/deeplinks/ion_identity_deeplinks.dart';
import 'package:ion_identity_client/src/keys/ion_identity_keys.dart';
import 'package:ion_identity_client/src/networks/ion_identity_networks.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';
import 'package:ion_identity_client/src/signer/user_action_signer.dart';
import 'package:ion_identity_client/src/statistics/ion_identity_statistics.dart';
import 'package:ion_identity_client/src/users/ion_identity_users.dart';
import 'package:ion_identity_client/src/wallets/ion_identity_wallets.dart';

/// A user-specific API client that provides access to authentication and wallet services
/// for a specific user. This client is designed to perform operations on behalf of the user
/// represented by this instance.
final class IONIdentityClient {
  /// Creates an instance of [IONIdentityClient] with the specified [auth] and [wallets] services.
  /// Both [auth] and [wallets] are required to interact with the respective user-related APIs.
  const IONIdentityClient({
    required this.username,
    required this.config,
    required this.identitySigner,
    required this.auth,
    required this.wallets,
    required this.users,
    required this.coins,
    required this.networks,
    required this.statistics,
    required this.keys,
    required this.deeplinks,
  });

  final String username;
  final IONIdentityConfig config;
  final IdentitySigner identitySigner;

  /// Provides access to authentication-related operations for the user, such as registering
  /// or logging in.
  final IONIdentityAuth auth;

  /// Provides access to wallet-related operations for the user, such as listing and managing
  /// the user's wallets.
  final IONIdentityWallets wallets;

  /// Provides access to user-related operations for the user, such as getting user details.
  final IONIdentityUsers users;

  /// Provides access to coins-related operations, such as getting coins information.
  final IONIdentityCoins coins;

  /// Provides access to networks-related operations, such as getting estimate transaction fees.
  final IONIdentityNetworks networks;

  /// Provides access to statistics-related operations, such as getting hashtags.
  final IONIdentityStatistics statistics;

  /// Provides access to keys-related operations, such as create new key, delete and others.
  final IONIdentityKeys keys;

  /// Provides access to deeplinks-related operations, such as sending deeplinks to backend.
  final IONIdentityDeeplinks deeplinks;

  /// Provides access to the UserActionSigner for advanced signing operations
  UserActionSigner get userActionSigner {
    return UserActionSignerServiceLocator().userActionSigner(
      config: config,
      identitySigner: identitySigner,
    );
  }

  /// Creates a factory for UserActionSignerNew implementations
  UserActionSignerFactory get userActionSignerFactory {
    return UserActionSignerFactory(
      userActionSigner: userActionSigner,
      ionIdentityAuth: auth,
    );
  }
}
