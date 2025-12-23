// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bsc_network_provider.r.g.dart';

@riverpod
Future<NetworkData> bscNetworkData(Ref ref) async {
  final networks = await ref.watch(networksProvider.future);
  final bscNetwork = networks.firstWhereOrNull(
        (NetworkData n) => n.isBsc && !n.isTestnet,
      ) ??
      networks.firstWhereOrNull((NetworkData n) => n.isBsc);
  if (bscNetwork == null) {
    throw BscNetworkNotFoundException();
  }
  return bscNetwork;
}
