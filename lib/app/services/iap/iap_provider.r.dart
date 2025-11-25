// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/iap/iap_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iap_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<IAPService> iapService(Ref ref) async {
  final service = IAPService();
  await service.initialize();
  ref.onDispose(service.dispose);
  return service;
}
