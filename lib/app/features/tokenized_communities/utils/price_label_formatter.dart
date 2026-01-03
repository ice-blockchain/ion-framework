// SPDX-License-Identifier: ice License 1.0

class PriceLabelParts {
  const PriceLabelParts({this.fullText, this.prefix, this.subscript, this.trailing});

  final String? fullText; // when not using compact format
  final String? prefix; // e.g. "-0.0"
  final String? subscript; // count of zeros when > 2
  final String? trailing; // next 2 significant digits after zeros
}

class PriceLabelFormatter {
  static PriceLabelParts format(double value) {
    final abs = value.abs();
    // Simple formatting when value is reasonably large or has no leading zeros
    if (abs >= 0.1) {
      return PriceLabelParts(fullText: value.toStringAsFixed(4));
    }

    // Use scientific notation to count leading fractional zeros robustly
    if (abs == 0) {
      return const PriceLabelParts(fullText: '0.0000');
    }

    final expStr = abs.toStringAsExponential(12); // e.g. 3.300000000000e-4
    final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
    if (match == null) {
      // Fallback to standard formatting if parsing fails
      return PriceLabelParts(fullText: value.toStringAsFixed(4));
    }

    final mantissaStr = match.group(1)!; // like 3.300000000000
    final exponent = int.parse(match.group(2)!); // e.g. -4

    // For numbers < 1, exponent is negative: n = m * 10^e
    // Leading zeros after decimal = -e - 1 when e < -1
    if (exponent >= -1) {
      return PriceLabelParts(fullText: value.toStringAsFixed(4));
    }

    final zeros = (-exponent) - 1;
    final digits = mantissaStr.replaceAll('.', '');
    final trailing = digits.isEmpty ? '0' : (digits.length >= 2 ? digits.substring(0, 2) : digits);

    final sign = value < 0 ? '-' : '';

    if (zeros <= 2) {
      return PriceLabelParts(
        prefix: '$sign' '0.' '${'0' * zeros}',
        trailing: trailing,
      );
    }

    return PriceLabelParts(
      prefix: '${sign}0.0',
      subscript: zeros.toString(),
      trailing: trailing,
    );
  }
}
