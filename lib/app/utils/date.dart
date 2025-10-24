// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/l10n/timeago_locales.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Converts a timestamp (in milliseconds) into a human-readable string such as
/// "today", "yesterday", or a formatted date (MMM d yyyy).
///
/// If the [timestamp] falls on today's date, returns a localized "today".
/// If it falls on yesterday's date, returns a localized "yesterday".
/// Otherwise, it formats the date as 'MMM d yyyy' (or localized equivalent).
///
/// If [dateFormat] is provided, it will be used to format the date.
/// Otherwise, the default formatter will be used.
String toPastDateDisplayValue(
  int timestamp,
  BuildContext context, {
  Locale? locale,
  DateFormat? dateFormat,
}) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  if (isSameDay(date, today)) {
    return context.i18n.date_today;
  } else if (isSameDay(date, yesterday)) {
    return context.i18n.date_yesterday;
  }

  return dateFormat?.format(date) ?? DateFormat.yMMMd(locale?.languageCode).format(date);
}

/// Converts a timestamp (in milliseconds) into a time string in the 'HH:mm' format.
/// Honors the [locale] if provided.
///
/// Returns a string representing the time in 'HH:mm', e.g., "14:30".
String toTimeDisplayValue(int timestamp, {Locale? locale}) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat.Hm(locale?.languageCode).format(date);
}

/// Formats a [Duration] into a string of the format 'mm:ss'.
///
/// For example, a duration of 125 seconds would be formatted as "02:05".
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  return '$minutes:$seconds';
}

/// Formats a [DateTime] for message timestamps based on how far in the past
/// the given time is.
///
/// - If [dateTime] is today, returns "HH:mm".
/// - If it is within the past week, returns the day of the week (e.g., "Mon").
/// - If it is within the current year but older than a week, returns "dd/MM".
/// - Otherwise, returns "dd/MM/yyyy".
String formatMessageTimestamp(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (messageDate == today) {
    return DateFormat.Hm().format(dateTime);
  }

  if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
    return DateFormat.E().format(dateTime);
  }

  if (messageDate.year == today.year) {
    return DateFormat('dd/MM').format(dateTime);
  }

  return DateFormat('dd/MM/yyyy').format(dateTime);
}

/// Formats a [DateTime] into the "MMMM d, yyyy" format (e.g., "January 5, 2024").
String formatDateToMonthDayYear(DateTime date, {Locale? locale}) {
  return DateFormat('MMMM d, yyyy', locale?.languageCode).format(date);
}

/// Formats a [DateTime] into the "MMMM yyyy" format (e.g., "January 2024").
String formatDateToMonthYear(DateTime date, {Locale? locale}) {
  return DateFormat('MMMM yyyy', locale?.languageCode).format(date);
}

/// Returns a random DateTime object before the current time.
///
/// [maxDuration]: The maximum duration before the current time.
/// Example:
/// ```dart
/// DateTime randomDate = randomDateBefore();
/// ```
///
DateTime randomDateBefore({Duration? maxDuration}) {
  final duration = maxDuration ?? const Duration(days: 2);
  final now = DateTime.now();
  final differenceInMilliseconds = now.difference(now.subtract(duration)).inMilliseconds;
  final randomMilliseconds = Random().nextInt(differenceInMilliseconds);
  return now.subtract(Duration(milliseconds: randomMilliseconds));
}

/// Converts a Flutter [Locale] (e.g., 'de') to the equivalent short locale key
/// for timeago (e.g., 'de_short'). If not found, falls back to 'en_short'.
String toTimeagoShortLocale(Locale locale) {
  final code = locale.languageCode.toLowerCase();
  final shortCode = '${code}_short';
  if (shortLocalesMap.containsKey(shortCode)) {
    return shortCode;
  }
  return 'en_short';
}

/// Generates a short relative time for feed items. If the difference from [now]
/// is less than 8 days, uses timeago with a short locale (e.g., "3h", "2d").
/// Otherwise, returns either "Jan 10" or "Jan 10, 2024" depending on whether
/// it's under or over 12 months old.
///
/// **Important**: If the post is newer than 1 minute (i.e. < 60 seconds),
/// we show "just now" localized.
String formatShortTimestamp(DateTime dateTime, {Locale? locale, BuildContext? context}) {
  locale ??= const Locale('en');
  final now = DateTime.now();
  final diff = now.difference(dateTime.toLocal());

  // If less than 60 seconds, show "Just now"
  if (diff.inSeconds < 60 && context != null) {
    return context.i18n.date_just_now;
  }

  final diffInDays = diff.inDays;
  // If under 8 days, use timeago short.
  if (diffInDays < 8) {
    final shortLocale = toTimeagoShortLocale(locale);
    return timeago.format(dateTime, locale: shortLocale);
  }
  // If under 1 year, show "Jan 10".
  if (diffInDays < 365) {
    return DateFormat.MMMd(locale.languageCode).format(dateTime);
  }
  // Otherwise, "Jan 10, 2024".
  return DateFormat.yMMMd(locale.languageCode).format(dateTime);
}

/// Formats a [DateTime] in a detailed style for post details:
/// "Jan 1, 2024, 08:45 PM" (month-day-year, hh:mm AM/PM).
String formatDetailedTimestamp(DateTime dateTime, {Locale? locale}) {
  locale ??= const Locale('en');
  final localDateTime = dateTime.toLocal();
  final dateFormat = DateFormat('MMM d, yyyy, hh:mm a', locale.languageCode);
  return dateFormat.format(localDateTime);
}

/// Returns a compact HODL duration string for a start [DateTime].
///
/// Examples:
/// - 1 hour 23 minutes -> "1h23m"
/// - 3 days 4 hours -> "3d4h"
/// - 45 minutes -> "45m"
///
/// If [start] is in the future, returns "0m".
String formatCompactHodlSince(DateTime start) {
  final now = DateTime.now();
  final diff = now.difference(start.toLocal());

  if (diff.isNegative) return '0m';

  final days = diff.inDays;
  final hours = diff.inHours.remainder(24);
  final minutes = diff.inMinutes.remainder(60);

  if (days > 0) {
    if (hours > 0) return '${days}d${hours}h';
    return '${days}d';
  }

  if (hours > 0) {
    if (minutes > 0) return '${hours}h${minutes}m';
    return '${hours}h';
  }

  if (minutes > 0) return '${minutes}m';

  return '0m';
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}
