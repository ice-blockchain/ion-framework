// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_review_service.r.g.dart';

@Riverpod(keepAlive: true)
AppReviewService appReviewService(Ref ref) {
  final env = ref.watch(envProvider.notifier);

  final appId = env.get<String>(EnvVariable.ION_IOS_APP_ID);

  return AppReviewService(appStoreId: appId);
}

class AppReviewService {
  AppReviewService({this.appStoreId});

  final InAppReview _instance = InAppReview.instance;
  final String? appStoreId;

  Future<bool> isAvailable() => _instance.isAvailable();

  Future<void> requestReview() async {
    if (await isAvailable()) {
      await _instance.requestReview();
    } else {
      // Fallback to store page if native prompt is unavailable
      await openStore();
    }
  }

  Future<void> openStore() => _instance.openStoreListing(appStoreId: appStoreId);
}
