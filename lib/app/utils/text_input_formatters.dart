// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/services/logger/logger.dart';

TextInputFormatter decimalInputFormatter({required int maxDecimals}) {
  return FilteringTextInputFormatter.allow(RegExp('^\\d*\\,?\\d{0,$maxDecimals}'));
}

TextInputFormatter emojiRestrictionFormatter() {
  return FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9\-._~:/?#@!$&()*+,;=%]'),
  );
}

class CoinInputFormatter extends TextInputFormatter {
  CoinInputFormatter({
    this.maxDecimals = maxDecimalsNumber,
  });

  static const int maxDecimalsNumber = 18;
  final _numberFormat = NumberFormat('#,###', 'en_US');
  final _commasRegex = RegExp('[^,]');
  final _validationRegex = RegExp(r'^[0-9.,]+$');

  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length < oldValue.text.length) {
      return _handleDeletion(oldValue, newValue);
    }

    if ((newValue.text.length - oldValue.text.length) > 1) {
      return _handlePaste(oldValue, newValue);
    }

    // Handle entering symbol by symbol
    final enteredSymbol = _getEnteredSymbol(oldValue, newValue);
    if (enteredSymbol == null) return oldValue;

    if (_isDecimalSeparator(enteredSymbol.newSymbol)) {
      return _handleDecimalSeparator(oldValue, newValue, enteredSymbol.index);
    }

    return _handleDigitInput(oldValue, newValue);
  }

  TextEditingValue _handleDeletion(TextEditingValue oldValue, TextEditingValue newValue) {
    final cursorPos = newValue.selection.end;
    final normalized = _normalizeInput(newValue.text);

    if (_isSpecialDecimalDeletion(oldValue, newValue)) return newValue;

    if (normalized.isEmpty) {
      return TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: cursorPos),
      );
    }

    return _formatNumberWithCursor(oldValue, normalized, cursorPos);
  }

  TextEditingValue _handlePaste(TextEditingValue oldValue, TextEditingValue newValue) {
    // Validate pasted content
    final isValid = _validationRegex.hasMatch(newValue.text);
    if (!isValid) return oldValue;

    try {
      final oldText = oldValue.text;
      final cursorPosition = oldValue.selection.baseOffset;
      final pastedValue = _getPastedValue(oldValue, newValue);

      // If no decimal separator in old value, treat as regular input
      if (!oldText.contains('.')) {
        var normalized = newValue.text;
        // Find the last decimal separator in the new value
        final lastDotIndex = normalized.lastIndexOf('.');
        final lastCommaIndex = normalized.lastIndexOf(',');
        final lastSeparatorIndex = max(lastDotIndex, lastCommaIndex);

        if (lastSeparatorIndex != -1) {
          // Split at the last separator
          final intPart =
              newValue.text.substring(0, lastSeparatorIndex > 0 ? lastSeparatorIndex : 0);
          final decimalPart = newValue.text.substring(lastSeparatorIndex + 1);

          // Normalize both parts separately
          final normalizedIntPart = _normalizeInput(intPart).replaceAll('.', '');
          final normalizedDecimalPart = _normalizeInput(decimalPart).replaceAll('.', '');

          normalized = '$normalizedIntPart.$normalizedDecimalPart';
        }

        return _formatNumberWithCursor(
          oldValue,
          normalized,
          newValue.selection.end,
        );
      }

      final dotIndex = oldText.indexOf('.');
      final isPastingAfterDot = cursorPosition > dotIndex;

      // If pasting after dot, insert as the decimal part
      if (isPastingAfterDot) {
        final intPart = oldText.substring(0, dotIndex);
        final oldDecimalPart = oldText.substring(dotIndex + 1);

        // Calculate where to insert in decimal part
        final decimalInsertPos = cursorPosition - dotIndex - 1;
        final normalizedPaste = _normalizeInput(pastedValue).replaceAll('.', '');

        final newDecimalPart = oldDecimalPart.substring(0, decimalInsertPos) +
            normalizedPaste +
            oldDecimalPart.substring(decimalInsertPos);

        final limitedDecimalPart = newDecimalPart.length > maxDecimals
            ? newDecimalPart.substring(0, maxDecimals)
            : newDecimalPart;

        final formatted = '$intPart.$limitedDecimalPart';

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: min(
              formatted.length,
              dotIndex + 1 + decimalInsertPos + normalizedPaste.length,
            ),
          ),
        );
      }

      // If pasting before dot, insert and format normally
      final beforePaste = oldText.substring(0, cursorPosition);
      final afterPaste = oldText.substring(cursorPosition);

      // Normalize pasted value by removing all separators
      final normalizedPaste = _normalizeInput(pastedValue).replaceAll('.', '');

      final newText = beforePaste + normalizedPaste + afterPaste;
      final normalized = _normalizeInput(newText);

      // Calculate new cursor position after paste
      final newCursorPos = cursorPosition + normalizedPaste.length;

      return _formatNumberWithCursor(oldValue, normalized, newCursorPos);
    } catch (e) {
      Logger.error('Caught error during handling paste. Exception: $e');
      return oldValue;
    }
  }

  String _getPastedValue(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.text.substring(oldValue.selection.start, newValue.selection.end);

  bool _isSpecialDecimalDeletion(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!oldValue.text.contains('.') || !newValue.text.contains('.')) return false;

    final oldDecimalPart = oldValue.text.split('.')[1];
    final newDecimalPart = newValue.text.split('.')[1];
    final decimalsNumber = _countDecimals(newValue.text);

    return newDecimalPart.length < oldDecimalPart.length &&
        (decimalsNumber > 0 || newValue.text.endsWith('.'));
  }

  TextEditingValue _handleDecimalSeparator(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    int index,
  ) {
    if (oldValue.text.contains('.')) return oldValue;

    final normalized = _normalizeInput(newValue.text).replaceAll('.', '');
    final isAppending = index == newValue.text.length - 1;

    try {
      if (isAppending) {
        // Handle appending decimal at the end
        final beforeDecimal = normalized.substring(0, normalized.length);
        final formatted = '${_formatIntegerPart(beforeDecimal)}.';
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }

      // If inserting at position with a comma in formatted text,
      // we need to adjust the split position
      final formattedBeforeInsertion = _formatIntegerPart(normalized);
      var adjustedIndex = index;
      var commaCount = 0;
      for (var i = 0; i < formattedBeforeInsertion.length && i < index; i++) {
        if (formattedBeforeInsertion[i] == ',') {
          commaCount++;
        }
      }
      adjustedIndex -= commaCount;

      // Split the normalized number at the adjusted position
      final beforePart = normalized.substring(0, adjustedIndex);
      final afterPart = normalized.substring(adjustedIndex);
      final formatted = '${_formatIntegerPart(beforePart)}.$afterPart';
      final decimalPos = formatted.indexOf('.');

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: decimalPos + 1),
      );
    } catch (e) {
      Logger.error('Caught error during handling entered decimal separator. Exception: $e');
      return oldValue;
    }
  }

  TextEditingValue _handleDigitInput(TextEditingValue oldValue, TextEditingValue newValue) {
    final normalized = _normalizeInput(newValue.text);
    return _formatNumberWithCursor(oldValue, normalized, newValue.selection.end);
  }

  String _normalizeInput(String text) => text.replaceAll(',', '');

  bool _isDecimalSeparator(String symbol) => symbol == ',' || symbol == '.';

  String _formatIntegerPart(String input) {
    var inputToParse = input;
    if (inputToParse.isEmpty || inputToParse == '0') return '0';

    // Limit integer part to 16 digits (max safe integer has 16 digits)
    if (inputToParse.length > 16) {
      inputToParse = inputToParse.substring(0, 16);
    }

    try {
      return _numberFormat.format(int.parse(inputToParse));
    } catch (e) {
      Logger.error('Error during parsing $input to int.');
      return '0';
    }
  }

  TextEditingValue _formatNumberWithCursor(
    TextEditingValue oldValue,
    String normalized,
    int cursorPos,
  ) {
    try {
      final parts = normalized.split('.');
      final intPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      final limitedDecimalPart =
          decimalPart.length > maxDecimals ? decimalPart.substring(0, maxDecimals) : decimalPart;

      final formattedIntPart = _formatIntegerPart(intPart);
      final toDisplay =
          decimalPart.isNotEmpty ? '$formattedIntPart.$limitedDecimalPart' : formattedIntPart;

      final newCursorPos = _calculateCursorPosition(
        oldValue: oldValue,
        newText: toDisplay,
        oldCursorPos: cursorPos,
        hasLimitedDecimals: decimalPart.length > maxDecimals,
      );

      return TextEditingValue(
        text: toDisplay,
        selection: TextSelection.collapsed(
          offset: min(toDisplay.length, max(0, newCursorPos)),
        ),
      );
    } catch (e) {
      Logger.error('Caught error during formatting number. Exception: $e');
      return oldValue;
    }
  }

  int _calculateCursorPosition({
    required TextEditingValue oldValue,
    required String newText,
    required int oldCursorPos,
    required bool hasLimitedDecimals,
  }) {
    var newPos = oldCursorPos;

    final oldCommaCount = oldValue.text
        .substring(0, min(oldValue.text.length, oldCursorPos - 1 < 0 ? 0 : oldCursorPos - 1))
        .replaceAll(_commasRegex, '')
        .length;

    final newCommaCount =
        newText.substring(0, min(newText.length, oldCursorPos)).replaceAll(_commasRegex, '').length;

    newPos += newCommaCount - oldCommaCount;

    if (hasLimitedDecimals && newPos > newText.length) {
      newPos = newText.length;
    }

    return newPos;
  }

  ({int index, String newSymbol})? _getEnteredSymbol(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length != oldValue.text.length + 1) return null;

    for (var i = 0; i < newValue.text.length; i++) {
      if (i >= oldValue.text.length || oldValue.text[i] != newValue.text[i]) {
        return (index: i, newSymbol: newValue.text[i]);
      }
    }
    return null;
  }

  int _countDecimals(String value) {
    final dotIndex = value.indexOf('.');
    return dotIndex == -1 ? 0 : value.length - dotIndex - 1;
  }
}
