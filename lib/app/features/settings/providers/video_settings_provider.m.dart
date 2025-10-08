// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_settings_provider.m.freezed.dart';
part 'video_settings_provider.m.g.dart';

@freezed
class VideoSettingsState with _$VideoSettingsState {
  const factory VideoSettingsState({
    required bool autoplay,
  }) = _VideoSettingsState;

  factory VideoSettingsState.initial() {
    return const VideoSettingsState(
      autoplay: true,
    );
  }

  factory VideoSettingsState.fromJson(Map<String, dynamic> json) =>
      _$VideoSettingsStateFromJson(json);
}

@riverpod
class VideoSettings extends _$VideoSettings {
  static const _videoSettingsKey = '_VideoSettings';

  @override
  VideoSettingsState build() {
    _listenChanges();

    final savedState = _loadSavedState();

    return savedState;
  }

  set autoplay(bool value) {
    state = state.copyWith(autoplay: value);
  }

  void _listenChanges() {
    listenSelf((_, next) => _saveState(next));
  }

  void _saveState(VideoSettingsState state) {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider) ?? '';
    ref
        .read(userPreferencesServiceProvider(identityKeyName: identityKeyName))
        .setValue(_videoSettingsKey, jsonEncode(state.toJson()));
  }

  VideoSettingsState _loadSavedState() {
    final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider) ?? '';
    final userPreferencesService =
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));

    final savedStateJson = userPreferencesService.getValue<String>(_videoSettingsKey);

    if (savedStateJson != null) {
      try {
        return VideoSettingsState.fromJson(jsonDecode(savedStateJson) as Map<String, dynamic>);
      } catch (error, stackTrace) {
        Logger.error(error, stackTrace: stackTrace);
      }
    }

    return VideoSettingsState.initial();
  }
}
