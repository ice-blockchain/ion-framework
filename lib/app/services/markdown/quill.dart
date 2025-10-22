// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final _mdToDelta = MarkdownToDelta(
  markdownDocument: _mdDocument,
  softLineBreak: true,
  customElementToEmbeddable: {
    'img': (attrs) {
      final imageUrl = attrs['src'] ?? '';
      return TextEditorSingleImageEmbed(imageUrl);
    },
  },
);

Delta plainTextToDelta(String text) {
  final matches = TextParser.allMatchers().parse(text.trim());
  final operations = <Operation>[];

  for (final match in matches) {
    operations.add(
      switch (match.matcher) {
        UrlMatcher() => Operation.insert(match.text, {Attribute.link.key: match.text}),
        HashtagMatcher() =>
          Operation.insert(match.text, {HashtagAttribute.attributeKey: match.text}),
        CashtagMatcher() =>
          Operation.insert(match.text, {CashtagAttribute.attributeKey: match.text}),
        _ => Operation.insert(match.text),
      },
    );
  }

  operations.add(Operation.insert('\n'));

  return Delta.fromOperations(operations);
}

final deltaToMd = DeltaToMarkdown(
  customEmbedHandlers: {
    'text-editor-single-image': (embed, out) {
      final imageUrl = embed.value.data;
      out.write('![image]($imageUrl)');
    },
    'text-editor-separator': (embed, out) {
      out.write('\n---\n');
    },
    'text-editor-code': (embed, out) {
      final content = embed.value.data;
      out.write('\n```\n$content\n```\n');
    },
  },
  visitLineHandleNewLine: (style, out) {
    out.write('\n');
  },
);

String deltaToMarkdown(Delta delta) {
  final processedDelta = Delta();
  for (final op in delta.toList()) {
    if (op.key == 'insert') {
      if (op.data is Map) {
        processedDelta.insert(op.data);
      } else if (op.attributes?.containsKey('text-editor-single-image') ?? false) {
        processedDelta.insert({
          'text-editor-single-image': op.attributes!['text-editor-single-image'],
        });
      } else {
        processedDelta.insert(op.data, op.attributes);
      }
    }
  }
  return deltaToMd.convert(processedDelta);
}

Delta markdownToDelta(String markdown) {
  final delta = _mdToDelta.convert(markdown);
  final processedDelta = Delta();

  for (final op in delta.toList()) {
    if (op.key == 'insert' && op.data is Map) {
      final data = op.data! as Map;
      if (data.containsKey('image')) {
        final imageUrl = data['image'] as String;
        processedDelta.insert({
          'text-editor-single-image': imageUrl,
        });
      } else if (data.containsKey('divider')) {
        processedDelta.insert({
          'text-editor-separator': '---',
        });
      } else {
        processedDelta.insert(op.data, op.attributes);
      }
    } else {
      processedDelta.insert(op.data, op.attributes);
    }
  }

  return withFullLinks(processedDelta);
}

void _processMatches(Operation op, Delta processedDelta) {
  if (op.data is Map) {
    processedDelta.insert(op.data, op.attributes);
    return;
  }

  final textParser = TextParser.tagsMatchers();
  final text = op.data.toString();
  final matches = textParser.parse(text);

  if (matches.isEmpty) {
    processedDelta.insert(op.data, op.attributes);
  } else {
    for (final match in matches) {
      processedDelta.insert(
        match.text,
        {
          ...?op.attributes,
          ...switch (match.matcher) {
            HashtagMatcher() => {HashtagAttribute.attributeKey: match.text},
            CashtagMatcher() => {CashtagAttribute.attributeKey: match.text},
            _ => {},
          },
        },
      );
    }
  }
}

Delta processDelta(Delta delta) {
  final newDelta = Delta();

  for (final op in delta.operations) {
    if (op.data is String && (op.attributes?.containsKey('text-editor-single-image') ?? false)) {
      final imageUrl = op.attributes!['text-editor-single-image'] as String;
      newDelta.insert({'text-editor-single-image': imageUrl});
    } else {
      newDelta.insert(op.data, op.attributes);
    }
  }

  return withFullLinks(newDelta);
}

Delta parseAndConvertDelta(String? deltaContent, String fallbackMarkdown) {
  Delta? delta;

  try {
    if (deltaContent != null) {
      delta = Delta.fromJson(jsonDecode(deltaContent) as List<dynamic>);
      delta = processDelta(delta);
      delta = processDeltaMatches(delta);
    }
  } catch (e) {
    delta = null;
  }

  // Fallback to markdown if delta parsing failed
  return delta ?? markdownToDelta(fallbackMarkdown);
}

Delta processDeltaMatches(Delta delta) {
  final newDelta = Delta();
  for (final op in delta.operations) {
    _processMatches(op, newDelta);
  }
  return newDelta;
}

Delta withFlattenLinks(Delta delta) {
  final out = Delta();
  for (final op in delta.toList()) {
    final href = op.attributes?[Attribute.link.key];
    if (href != null && op.value is String && op.value == href) {
      out.push(Operation.insert(' ', {Attribute.link.key: href}));
    } else {
      out.push(op);
    }
  }
  return out;
}

Delta withFullLinks(Delta delta) {
  final out = Delta();
  for (final op in delta.toList()) {
    final href = op.attributes?[Attribute.link.key];
    if (href != null && op.value is String && op.value == ' ') {
      out.push(Operation.insert(href, {Attribute.link.key: href}));
    } else {
      out.push(op);
    }
  }
  return out;
}
