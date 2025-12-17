// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'transaction_amount.f.freezed.dart';

@freezed
class TransactionAmount with _$TransactionAmount {
  const factory TransactionAmount({
    required double value,
    required String currency,
  }) = _TransactionAmount;

  factory TransactionAmount.usd({
    required double value,
  }) {
    return TransactionAmount(value: value, currency: usdCurrency);
  }

  const TransactionAmount._();

  factory TransactionAmount.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length < 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    final value = double.tryParse(tag[1]);

    if (value == null) {
      throw IncorrectEventTagException(tag: tag[1]);
    }

    return TransactionAmount(value: value, currency: tag[2]);
  }

  List<String> toTag() {
    return [tagName, value.toString(), currency];
  }

  static const String tagName = 'tx_amount';

  static const String usdCurrency = 'USD';
}
