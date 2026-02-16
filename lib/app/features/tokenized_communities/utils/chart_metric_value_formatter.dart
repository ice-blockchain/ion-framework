// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/utils/price_label_formatter.dart';
import 'package:ion/app/utils/num.dart';

class ChartMetricValueFormat {
  const ChartMetricValueFormat({
    required this.text,
    this.parts,
  });

  final String text;
  final PriceLabelParts? parts;

  bool get hasRichParts => parts != null && parts!.fullText == null;
}

/// Builds chart-ready formatting data for one numeric value.
///
/// Rules:
/// - `abs(value) >= 1000` -> grouped integer text (e.g. `6,380`)
/// - `abs(value) >= 100` -> grouped 2-decimal text (e.g. `914.73`)
/// - otherwise -> `PriceLabelFormatter` output:
///   - plain `fullText` for normal decimals, or
///   - split `parts` (`prefix/subscript/trailing`) for tiny values.
///
/// Tiny-value example:
/// `0.000000564` can be split into parts for subscript rendering.
ChartMetricValueFormat formatChartMetricValueData(double value) {
  final abs = value.abs();
  if (abs >= 1000) {
    return ChartMetricValueFormat(
      text: formatDouble(
        value,
        maximumFractionDigits: 0,
        minimumFractionDigits: 0,
      ),
    );
  }
  if (abs >= 100) {
    return ChartMetricValueFormat(
      text: formatDouble(
        value,
        // ignore: avoid_redundant_argument_values
        maximumFractionDigits: 2,
        // ignore: avoid_redundant_argument_values
        minimumFractionDigits: 2,
      ),
    );
  }

  final parts = PriceLabelFormatter.format(value);
  if (parts.fullText != null) {
    return ChartMetricValueFormat(text: parts.fullText!, parts: parts);
  }

  return ChartMetricValueFormat(
    text: '${parts.prefix ?? ''}${parts.subscript ?? ''}${parts.trailing ?? ''}',
    parts: parts,
  );
}

String formatChartMetricValue(double value) {
  return formatChartMetricValueData(value).text;
}
