// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';

part 'event_setting.f.freezed.dart';

abstract class EventSetting {
  factory EventSetting.fromTag(List<String> tag) {
    if (tag[0] != EventSetting.settingTagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: settingTagName);
    }
    if (tag.length < 4) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    switch (tag[1]) {
      case WhoCanReplyEventSetting.tagName:
        return WhoCanReplyEventSetting.fromTag(tag);
      case PinEnabledEventSetting.tagName:
        return PinEnabledEventSetting.fromTag(tag);
      default:
        throw IncorrectEventTagException(tag: tag.toString());
    }
  }

  List<String> toTag();

  static const String settingTagName = 'settings';
}

@freezed
class WhoCanReplyEventSetting with _$WhoCanReplyEventSetting implements EventSetting {
  const factory WhoCanReplyEventSetting({
    required Set<WhoCanReplySettingsOption> values,
    @Default(0) int timestamp,
  }) = _WhoCanReplyEventSetting;

  const WhoCanReplyEventSetting._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-4000.md#settings-tag
  factory WhoCanReplyEventSetting.fromTag(List<String> tag) {
    if (tag[0] != EventSetting.settingTagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: EventSetting.settingTagName);
    }
    if (tag.length < 4) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    final values = tag[2].split(',').map(WhoCanReplySettingsOption.fromTagValue).toSet();
    final timestamp = int.parse(tag[3]);
    return WhoCanReplyEventSetting(values: values, timestamp: timestamp);
  }

  @override
  List<String> toTag() {
    final timestampValue =
        timestamp > 0 ? timestamp.toString() : DateTime.now().microsecondsSinceEpoch.toString();

    return [
      EventSetting.settingTagName,
      tagName,
      values.map((value) => value.tagValue).nonNulls.join(','),
      timestampValue,
    ];
  }

  static const String tagName = 'who_can_reply';
}

@freezed
class CommentsEnabledEventSetting with _$CommentsEnabledEventSetting implements EventSetting {
  const factory CommentsEnabledEventSetting({
    required bool isEnabled,
  }) = _CommentsEnabledEventSetting;

  const CommentsEnabledEventSetting._();

  factory CommentsEnabledEventSetting.fromTags(List<List<String>> tags) {
    final tag =
        tags.firstWhere((tag) => tag[0] == EventSetting.settingTagName && tag[1] == tagName);

    if (tag[0] != EventSetting.settingTagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: EventSetting.settingTagName);
    }

    return CommentsEnabledEventSetting(isEnabled: tag[2] == 'true');
  }

  @override
  List<String> toTag() {
    return [
      EventSetting.settingTagName,
      tagName,
      isEnabled.toString(),
      DateTime.now().microsecondsSinceEpoch.toString(),
    ];
  }

  static const String tagName = 'comments_enabled';
}

@freezed
class RoleRequiredForPostingEventSetting
    with _$RoleRequiredForPostingEventSetting
    implements EventSetting {
  const factory RoleRequiredForPostingEventSetting({
    required RoleRequiredForPosting role,
  }) = _RoleRequiredForPostingEventSetting;

  const RoleRequiredForPostingEventSetting._();

  factory RoleRequiredForPostingEventSetting.fromTags(List<List<String>> tags) {
    final tag =
        tags.firstWhere((tag) => tag[0] == EventSetting.settingTagName && tag[1] == tagName);

    if (tag[0] != EventSetting.settingTagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: EventSetting.settingTagName);
    }

    return RoleRequiredForPostingEventSetting(role: RoleRequiredForPosting.values.byName(tag[2]));
  }

  static const String tagName = 'role_required_for_posting';

  @override
  List<String> toTag() {
    return [
      EventSetting.settingTagName,
      tagName,
      role.name,
      DateTime.now().microsecondsSinceEpoch.toString(),
    ];
  }
}

enum RoleRequiredForPosting {
  admin,
  moderator,
}

@freezed
class PinEnabledEventSetting with _$PinEnabledEventSetting implements EventSetting {
  const factory PinEnabledEventSetting({
    required bool isPined,
  }) = _PinEnabledEventSetting;

  const PinEnabledEventSetting._();

  factory PinEnabledEventSetting.fromTag(List<String> tag) {
    if (tag[0] != EventSetting.settingTagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: EventSetting.settingTagName);
    }
    if (tag.length < 4) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return PinEnabledEventSetting(isPined: tag[2] == 'true');
  }

  @override
  List<String> toTag() {
    return [
      EventSetting.settingTagName,
      tagName,
      isPined.toString(),
      DateTime.now().microsecondsSinceEpoch.toString(),
    ];
  }

  static const String tagName = 'pin_enabled';
}
