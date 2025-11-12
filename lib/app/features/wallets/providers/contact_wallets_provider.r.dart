// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_wallets_provider.r.g.dart';

class ContactWalletsAvailability {
  const ContactWalletsAvailability({
    required this.availableNetworkIds,
    required this.hasPublicWallets,
  });

  const ContactWalletsAvailability.unknown()
      : availableNetworkIds = const {},
        hasPublicWallets = false;

  final Set<String> availableNetworkIds;
  final bool hasPublicWallets;

  bool canReceiveOn(String networkId) =>
      !hasPublicWallets || availableNetworkIds.contains(networkId);
}

@riverpod
Future<ContactWalletsAvailability> contactWalletsAvailability(
  Ref ref,
  String? contactPubkey,
) async {
  if (contactPubkey == null) {
    return const ContactWalletsAvailability.unknown();
  }

  final metadata = await ref.watch(
    userMetadataProvider(
      contactPubkey,
      cache: false,
    ).future,
  );
  final wallets = metadata?.data.wallets;

  if (wallets == null) {
    return const ContactWalletsAvailability.unknown();
  }

  final availableNetworkIds =
      wallets.entries.where((entry) => entry.value.isNotEmpty).map((entry) => entry.key).toSet();

  return ContactWalletsAvailability(
    availableNetworkIds: availableNetworkIds,
    hasPublicWallets: true,
  );
}
