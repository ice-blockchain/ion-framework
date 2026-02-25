// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_push_categories_provider.m.g.dart';
part 'selected_push_categories_provider.m.freezed.dart';

@Riverpod(keepAlive: true)
class SelectedPushCategories extends _$SelectedPushCategories {
  @override
  SelectedPushCategoriesState build() {
    listenSelf((_, next) => _saveState(next));
    return _loadSavedState();
  }

  void toggleCategory(PushNotificationCategory category) {
    state = state.categories.contains(category)
        ? state.copyWith(categories: [...state.categories]..remove(category))
        : state.copyWith(categories: [...state.categories, category]);
  }

  void toggleSuspended() {
    state = state.copyWith(suspended: !state.suspended);
  }

  void _saveState(SelectedPushCategoriesState? state) {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);
    if (identityKeyName == null || state == null) {
      return;
    }
    ref
        .read(userPreferencesServiceProvider(identityKeyName: identityKeyName))
        .setValue(_selectedPushCategoriesKey, jsonEncode(state.toJson()));
  }

  SelectedPushCategoriesState _loadSavedState() {
    final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);

    if (identityKeyName == null) {
      return _defaultState;
    }

    final userPreferencesService =
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));
    final encodedSavedState = userPreferencesService.getValue<String>(_selectedPushCategoriesKey);

    if (encodedSavedState == null) {
      return _defaultState;
    }

    try {
      final savedState = SelectedPushCategoriesState.fromJson(
        jsonDecode(encodedSavedState) as Map<String, dynamic>,
      );
      if (savedState.requiresTokenizedCommunitiesMigration) {
        return _migrateTokenizedCommunitiesCategories(currentState: savedState);
      }
      return savedState;
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to load selected push categories',
      );
      return _defaultState;
    }
  }

  SelectedPushCategoriesState _migrateTokenizedCommunitiesCategories({
    required SelectedPushCategoriesState currentState,
  }) {
    return currentState.copyWith(
      requiresTokenizedCommunitiesMigration: false,
      categories: [
        ...currentState.categories,
        PushNotificationCategory.creatorToken,
        PushNotificationCategory.contentToken,
        PushNotificationCategory.creatorTokenTrades,
        PushNotificationCategory.contentTokenTrades,
        PushNotificationCategory.tokenUpdates,
      ],
    );
  }

  static const _defaultState = SelectedPushCategoriesState(
    categories: PushNotificationCategory.values,
    suspended: false,
    requiresTokenizedCommunitiesMigration:
        false, // By default all the categories are enabled, so no need to migrate
  );

  static const _selectedPushCategoriesKey = 'selected_push_categories';
}

@freezed
class SelectedPushCategoriesState with _$SelectedPushCategoriesState {
  const factory SelectedPushCategoriesState({
    /// List of selected categories
    required List<PushNotificationCategory> categories,

    /// If push notifications can't be received
    required bool suspended,

    /// All the saved states require the migration
    @Default(true) bool requiresTokenizedCommunitiesMigration,
  }) = _SelectedPushCategoriesState;

  const SelectedPushCategoriesState._();

  factory SelectedPushCategoriesState.fromJson(Map<String, dynamic> json) =>
      _$SelectedPushCategoriesStateFromJson(json);

  List<PushNotificationCategory> get enabledCategories => suspended ? [] : categories;
}
