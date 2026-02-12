// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';

// Formats a DateTime for chart date labels (e.g., "15/03").
String formatChartDate(DateTime date) {
  return DateFormat('dd/MM').format(date);
}

// Formats a DateTime for chart time labels (e.g., "14:30").
String formatChartTime(DateTime date) {
  return DateFormat('H:mm').format(date);
}

// Formats a DateTime for chart axis labels based on time range.
// Uses dd/MM for 1d interval, H:mm for all others.
String formatChartAxisLabel(DateTime date, ChartTimeRange range) {
  return range == ChartTimeRange.d1 ? formatChartDate(date) : formatChartTime(date);
}
