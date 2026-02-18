// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/chart_data.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_metric_preference_provider.m.g.dart';

@riverpod
class ChartMetricPreference extends _$ChartMetricPreference {
  static const _chartMetricKey = 'chart_selected_metric';

  @override
  ChartMetric build() {
    _listenChanges();

    return _loadSavedState();
  }

  set metric(ChartMetric value) => state = value;

  void _listenChanges() {
    listenSelf((_, next) => _saveState(next));
  }

  void _saveState(ChartMetric state) {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);

    if (identityKeyName == null) {
      return;
    }

    ref
        .read(userPreferencesServiceProvider(identityKeyName: identityKeyName))
        .setEnum(_chartMetricKey, state);
  }

  ChartMetric _loadSavedState() {
    final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);

    if (identityKeyName == null) {
      return ChartMetric.marketCap;
    }

    final userPreferencesService =
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));

    return userPreferencesService.getEnum(_chartMetricKey, ChartMetric.values) ??
        ChartMetric.marketCap;
  }
}
