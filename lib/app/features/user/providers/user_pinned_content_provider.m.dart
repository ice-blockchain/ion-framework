// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_pinned_content_provider.m.freezed.dart';
part 'user_pinned_content_provider.m.g.dart';

@freezed
class PinnedContentState with _$PinnedContentState {
  const factory PinnedContentState({
    required Map<String, String> data,
  }) = _PinnedContentState;

  factory PinnedContentState.initial() {
    return const PinnedContentState(data: {});
  }

  factory PinnedContentState.fromJson(Map<String, dynamic> json) =>
      _$PinnedContentStateFromJson(json);
}

@riverpod
String? pinnedContentKey(Ref ref, String contentType) {
  final pinnedContentData = ref.watch(pinnedContentProvider).data;

  return pinnedContentData[contentType];
}

@riverpod
class TogglePinnedNotifier extends _$TogglePinnedNotifier {
  @override
  Future<bool> build(EventReference eventReference, String? contentType) async {
    final pinnedContentData = ref.watch(pinnedContentProvider).data;
    final isPinned = pinnedContentData[contentType] == eventReference.toString();

    return isPinned;
  }

  Future<void> toggle() async {
    final pinnedContentNotifier = ref.read(pinnedContentProvider.notifier);
    final contentTypeName = contentType ?? 'post';

    final isPinned =
        pinnedContentNotifier.pinnedContentKey(contentTypeName) == eventReference.toString();
    Logger.log(
      'toggle contentType:$contentTypeName, isPinned:$isPinned, masterPubkey:$eventReference',
    );
    pinnedContentNotifier.updatePinnedContent(
      contentTypeName,
      isPinned ? null : eventReference.toString(),
    );
  }
}

@riverpod
class PinnedContent extends _$PinnedContent {
  static const _pinnedContentKey = '_PinnedContent';

  @override
  PinnedContentState build() {
    _listenChanges();

    final savedState = _loadSavedState();

    return savedState;
  }

  void updatePinnedContent(String type, String? pubKey) {
    final updatedPinnedData = Map<String, String>.from(state.data);
    pubKey == null ? updatedPinnedData.remove(type) : updatedPinnedData[type] = pubKey;

    state = state.copyWith(data: updatedPinnedData);
  }

  String? pinnedContentKey(String type) => state.data[type];

  String? pinnedContentType(String pubkey) =>
      state.data.entries.firstWhereOrNull((element) => element.value == pubkey)?.key;

  void _listenChanges() {
    listenSelf((_, next) => _saveState(next));
  }

  void _saveState(PinnedContentState state) {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider) ?? '';
    ref
        .read(userPreferencesServiceProvider(identityKeyName: identityKeyName))
        .setValue(_pinnedContentKey, jsonEncode(state.toJson()));
  }

  PinnedContentState _loadSavedState() {
    final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider) ?? '';
    final userPreferencesService =
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));

    final savedStateJson = userPreferencesService.getValue<String>(_pinnedContentKey);

    if (savedStateJson != null) {
      try {
        return PinnedContentState.fromJson(jsonDecode(savedStateJson) as Map<String, dynamic>);
      } catch (error, stackTrace) {
        Logger.error(error, stackTrace: stackTrace);
      }
    }

    return PinnedContentState.initial();
  }
}
