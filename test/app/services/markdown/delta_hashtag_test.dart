// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/services/markdown/quill.dart';

void main() {
  group('DeltaHashTagConverter', () {
    test('fill delta attributes with hashtag and cashtag correctly', () async {
      final delta = Delta()
        ..insert('Normal one ')
        ..insert('#ion', {'hashtag': '#'})
        ..insert(' and ')
        ..insert('#orangecat', {'hashtag': '#'})
        ..insert(' with base on ')
        ..insert(r'$IONUSDT', {'cashtag': r'$'})
        ..insert(' and ')
        ..insert(r'$TION', {'cashtag': r'$'})
        ..insert(' or ')
        ..insert(' coins\n');

      final result = withFullTags(delta);
      final operations = result.operations;

      // Assertions to verify correct attribute transformation
      expect(operations[1].data, '#ion');
      expect(operations[1].attributes, {'hashtag': '#ion'});

      expect(operations[3].data, '#orangecat');
      expect(operations[3].attributes, {'hashtag': '#orangecat'});

      expect(operations[5].data, r'$IONUSDT');
      expect(operations[5].attributes, {'cashtag': r'$IONUSDT'});

      expect(operations[7].data, r'$TION');
      expect(operations[7].attributes, {'cashtag': r'$TION'});
    });

    test('handles mixed content including mentions/embeds', () async {
      // Delta simulating a mention embed
      final mentionEmbed = {
        'mention': {'pubkey': 'pk', 'username': 'xmen'},
      };

      final delta = Delta()
        ..insert('Start with ')
        ..insert('#tag1', {'hashtag': '#'})
        ..insert(' and a ')
        ..insert(mentionEmbed) // Embed without attributes
        ..insert(' and finally ')
        ..insert(r'$CASH', {'cashtag': r'$'})
        ..insert('\n');

      final result = withFullTags(delta);
      final operations = result.operations;

      expect(operations.length, 7);

      // Check first hashtag
      expect(operations[1].data, '#tag1');
      expect(operations[1].attributes, {'hashtag': '#tag1'});

      // Check embed (should remain unchanged)
      expect(operations[3].data, mentionEmbed);
      expect(operations[3].attributes, isNull);

      // Check cashtag
      expect(operations[5].data, r'$CASH');
      expect(operations[5].attributes, {'cashtag': r'$CASH'});
    });

    test('does not modify existing attributes if they are already full tags', () async {
      // Simulate input where attributes are already correct (e.g., from loading saved data)
      final delta = Delta()
        ..insert('Pre-processed ')
        ..insert('#TagA', {HashtagAttribute.attributeKey: '#TagA'})
        ..insert(' and ')
        ..insert(r'$StockB', {CashtagAttribute.attributeKey: r'$StockB'});

      final result = withFullTags(delta);
      final operations = result.operations;

      // Check hashtag (should still be #TagA, not modified to '#TagA' based on the prefix check logic)
      expect(operations[1].attributes, {HashtagAttribute.attributeKey: '#TagA'});

      // Check cashtag
      expect(operations[3].attributes, {CashtagAttribute.attributeKey: r'$StockB'});
    });

    test('does not modify non-string insert operations', () async {
      final embed = {'image': 'url'};
      final delta = Delta()..insert(embed, {HashtagAttribute.attributeKey: '#'});

      final result = withFullTags(delta);
      final operations = result.operations;

      // The operation should be inserted as is, regardless of the attributes,
      // because op.value is not a String.
      expect(operations.first.data, embed);
      expect(operations.first.attributes, {HashtagAttribute.attributeKey: '#'});
    });
  });
}
