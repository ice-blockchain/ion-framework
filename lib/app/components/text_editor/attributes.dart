// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';

class HashtagAttribute extends Attribute<String?> {
  const HashtagAttribute(String? hashtagValue)
      : super(attributeKey, AttributeScope.inline, hashtagValue);

  const HashtagAttribute.withValue(String value) : this(value);

  const HashtagAttribute.unset() : this(null);

  static const String attributeKey = 'hashtag';
}

class CashtagAttribute extends Attribute<String?> {
  const CashtagAttribute(String? cashtagValue)
      : super(attributeKey, AttributeScope.inline, cashtagValue);

  const CashtagAttribute.withValue(String value) : this(value);

  const CashtagAttribute.unset() : this(null);

  static const String attributeKey = 'cashtag';
  static const String showMarketCapKey = 'showMarketCap';
}

class MentionAttribute extends Attribute<String?> {
  const MentionAttribute(String? mentionValue)
      : super(attributeKey, AttributeScope.inline, mentionValue);

  const MentionAttribute.withValue(String value) : this(value);

  const MentionAttribute.unset() : this(null);

  static const String attributeKey = 'mention';
  static const String showMarketCapKey = 'showMarketCap';
}
