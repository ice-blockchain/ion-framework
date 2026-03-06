// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/top_holder_extensions.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

void main() {
  group('TopHolderListSorting.sortedByPriority', () {
    const bondingCurveAddress = '0xBondingCurve';
    const burnAddress = '0x0000000000000000000000000000000000696f6e';

    test('sorts by priority: bonding curve, burn, then regular', () {
      final regular = _holder(name: 'regular', rank: 1, ionConnect: '0xRegular');
      final burning = _holder(name: 'burn', rank: 10, ionConnect: burnAddress);
      final bonding = _holder(name: 'bonding', rank: 99, ionConnect: bondingCurveAddress);

      final sorted = [regular, burning, bonding].sortedByPriority(
        bondingCurveAddress: bondingCurveAddress,
      );

      expect(
        sorted.map((holder) => holder.position.holder?.name).toList(),
        ['bonding', 'burn', 'regular'],
      );
    });

    test('sorts by rank inside same priority group', () {
      final third = _holder(name: 'third', rank: 3, ionConnect: '0x3');
      final first = _holder(name: 'first', rank: 1, ionConnect: '0x1');
      final second = _holder(name: 'second', rank: 2, ionConnect: '0x2');

      final sorted = [third, first, second].sortedByPriority(
        bondingCurveAddress: bondingCurveAddress,
      );

      expect(
        sorted.map((holder) => holder.position.holder?.name).toList(),
        ['first', 'second', 'third'],
      );
    });

    test('keeps original order for fully equal keys (stable sort)', () {
      final first = _holder(name: 'first', rank: 5, ionConnect: '0xA');
      final second = _holder(name: 'second', rank: 5, ionConnect: '0xB');
      final third = _holder(name: 'third', rank: 5, ionConnect: '0xC');
      final fourth = _holder(name: 'fourth', rank: 5, ionConnect: '0xD');
      final fifth = _holder(name: 'fifth', rank: 5, ionConnect: '0xE');

      final input = [third, first, fifth, second, fourth];
      final sorted = input.sortedByPriority(
        bondingCurveAddress: bondingCurveAddress,
      );

      expect(
        sorted.map((holder) => holder.position.holder?.name).toList(),
        ['third', 'first', 'fifth', 'second', 'fourth'],
      );
    });
  });
}

TopHolder _holder({
  required String name,
  required int rank,
  required String ionConnect,
}) {
  return TopHolder(
    creator: const Creator(),
    position: TopHolderPosition(
      rank: rank,
      amount: '1000000',
      amountUSD: 1,
      supplyShare: 0.1,
      holder: Creator(
        name: name,
        display: name,
        addresses: Addresses(
          blockchain: '0x${name}Blockchain',
          ionConnect: ionConnect,
        ),
      ),
    ),
  );
}
