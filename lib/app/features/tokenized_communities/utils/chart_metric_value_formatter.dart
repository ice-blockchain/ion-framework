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
