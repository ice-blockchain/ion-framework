// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'relay_info.f.freezed.dart';
part 'relay_info.f.g.dart';

/// https://github.com/nostr-protocol/nips/blob/master/11.md
@freezed
class RelayInfo with _$RelayInfo {
  const factory RelayInfo({
    required String name,
    String? description,
    String? icon,
    String? pubkey,
    String? contact,
    @JsonKey(name: 'supported_nips') List<int>? supportedNips,
    String? software,
    String? version,
    @JsonKey(name: 'fcm_android_configs') List<FirebaseConfig>? firebaseAndroidConfigs,
    @JsonKey(name: 'fcm_ios_configs') List<FirebaseConfig>? firebaseIosConfigs,
    @JsonKey(name: 'fcm_web_configs') List<FirebaseConfig>? firebaseWebConfigs,
    @JsonKey(name: 'system_status') List<RelaySystemStatuses>? systemStatuses,
  }) = _RelayInfo;

  const RelayInfo._();

  factory RelayInfo.fromJson(Map<String, dynamic> json) => _$RelayInfoFromJson(json);

  List<FirebaseConfig>? getFirebaseConfigsForPlatform() {
    if (kIsWeb) {
      return firebaseWebConfigs;
    } else if (Platform.isAndroid) {
      return firebaseAndroidConfigs;
    } else if (Platform.isIOS) {
      return firebaseIosConfigs;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}

/// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-8000.md#fcm-client-configuration
@freezed
class FirebaseConfig with _$FirebaseConfig {
  const factory FirebaseConfig({
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
  }) = _RelayFirebaseConfig;

  factory FirebaseConfig.fromJson(Map<String, dynamic> json) => _$FirebaseConfigFromJson(json);
}

@freezed
class RelaySystemStatuses with _$RelaySystemStatuses {
  const factory RelaySystemStatuses({
    @JsonKey(name: 'publishing_events') required RelaySystemStatus publishingEvents,
    @JsonKey(name: 'subscribing_for_events') required RelaySystemStatus subscribingForEvents,
    required RelaySystemStatus dvm,
    @JsonKey(name: 'uploading_files') required RelaySystemStatus uploadingFiles,
    @JsonKey(name: 'reading_files') required RelaySystemStatus readingFiles,
    @JsonKey(name: 'sending_push_notifications')
    required RelaySystemStatus sendingPushNotifications,
  }) = _RelaySystemStatuses;

  factory RelaySystemStatuses.fromJson(Map<String, dynamic> json) =>
      _$RelaySystemStatusesFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum RelaySystemStatus {
  up,
  down,
  maintenance,
}
