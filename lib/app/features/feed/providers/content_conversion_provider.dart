// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';
import 'package:ion/app/services/markdown/quill.dart';

/// Converts Delta JSON to plain text and PMO tags.
///
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertDeltaToPmoTags(
  List<dynamic> deltaJson,
) async {
  try {
    final result = await DeltaMarkdownConverter.mapDeltaToPmo(deltaJson);
    final contentToSign = result.text;
    final pmoTags = result.tags.map((t) => t.toTag()).toList();
    return (contentToSign: contentToSign, pmoTags: pmoTags);
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'Delta to PMO tags');
  }
}

/// Converts Delta to plain text and PMO tags.
///
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertDeltaToPmoTagsFromDelta(
  Delta delta,
) async {
  return convertDeltaToPmoTags(delta.toJson());
}

/// Converts Delta to markdown content.
///
/// Throws [ContentConversionException] if conversion fails.
String convertDeltaToMarkdown(Delta delta) {
  try {
    return deltaToMarkdown(delta);
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'Delta to markdown');
  }
}

/// Converts markdown content to Delta and then to plain text and PMO tags.
///
/// This is for backward compatibility when content is markdown instead of Delta.
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertMarkdownToPmoTags(
  String markdownContent,
) async {
  try {
    // Convert markdown → Delta → plain text + PMO tags
    final delta = markdownToDelta(markdownContent);
    final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());
    // Trim trailing newline that markdownToDelta adds
    final contentToSign = result.text.trimRight();
    final pmoTags = result.tags.map((t) => t.toTag()).toList();
    return (contentToSign: contentToSign, pmoTags: pmoTags);
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'markdown to PMO tags');
  }
}
