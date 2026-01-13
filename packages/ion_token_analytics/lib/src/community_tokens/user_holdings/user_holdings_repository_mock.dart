// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token_type.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/user_holdings/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/user_holdings/user_holdings_repository.dart';

class UserHoldingsRepositoryMock implements UserHoldingsRepository {
  static final List<CommunityToken> _mockHoldings = [
    const CommunityToken(
      type: CommunityTokenType.profile,
      title: 'Stephanie Chan',
      imageUrl: 'https://i.pravatar.cc/150?u=stephanie',
      addresses: Addresses(
        blockchain: '0xD76b5c2A23ef78368d8E34288B5b65D616B746aE',
        ionConnect: null,
        twitter: 'stephchan',
      ),
      creator: Creator(
        name: 'stephchan',
        display: 'Stephanie Chan',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?u=stephanie',
        addresses: Addresses(blockchain: null, ionConnect: 'npub1steph...', twitter: 'stephchan'),
      ),
      marketData: MarketData(
        marketCap: 43230000,
        volume: 990,
        holders: 1100,
        priceUSD: 0.1,
        ticker: 'STEPH_CHAN',
        position: Position(
          rank: 1,
          amount: '43230000000000000000000000',
          amountUSD: 5980,
          pnl: 113000,
          pnlPercentage: 17.34,
        ),
      ),
    ),
    const CommunityToken(
      type: CommunityTokenType.profile,
      title: 'Michael Reyes',
      imageUrl: 'https://i.pravatar.cc/150?u=michael',
      addresses: Addresses(
        blockchain: '0xA23ef78368d8E34288B5b65D616B746aE123456',
        ionConnect: 'npub1michael...',
      ),
      creator: Creator(
        name: 'michaelreyes',
        display: 'Michael Reyes',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?u=michael',
        addresses: Addresses(blockchain: null, ionConnect: 'npub1michael...'),
      ),
      marketData: MarketData(
        marketCap: 38100000,
        volume: 850,
        holders: 980,
        priceUSD: 0.08,
        ticker: 'MICH_REYES',
        position: Position(
          rank: 2,
          amount: '38100000000000000000000000',
          amountUSD: 1980,
          pnl: -1000,
          pnlPercentage: -5.2,
        ),
      ),
    ),
    const CommunityToken(
      type: CommunityTokenType.profile,
      title: 'David Lee',
      imageUrl: 'https://i.pravatar.cc/150?u=david',
      addresses: Addresses(
        blockchain: '0xB5b65D616B746aE123456789ABCDEF',
        ionConnect: 'npub1david...',
      ),
      creator: Creator(
        name: 'davidlee',
        display: 'David Lee',
        verified: false,
        avatar: 'https://i.pravatar.cc/150?u=david',
        addresses: Addresses(blockchain: null, ionConnect: 'npub1david...'),
      ),
      marketData: MarketData(
        marketCap: 25000000,
        volume: 720,
        holders: 650,
        priceUSD: 0.15,
        ticker: 'DAVID_LEE',
        position: Position(
          rank: 6,
          amount: '43230000000000000000000000',
          amountUSD: 7340,
          pnl: 113000,
          pnlPercentage: 22.5,
        ),
      ),
    ),
    const CommunityToken(
      type: CommunityTokenType.profile,
      title: 'Henry Patel',
      imageUrl: 'https://i.pravatar.cc/150?u=henry',
      addresses: Addresses(
        blockchain: '0xC616B746aE123456789ABCDEF012345',
        ionConnect: 'npub1henry...',
      ),
      creator: Creator(
        name: 'henrypatel',
        display: 'Henry Patel',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?u=henry',
        addresses: Addresses(blockchain: null, ionConnect: 'npub1henry...'),
      ),
      marketData: MarketData(
        marketCap: 18000000,
        volume: 450,
        holders: 420,
        priceUSD: 0.05,
        ticker: 'HENRY_P',
        position: Position(
          rank: 10,
          amount: '43230000000000000000000000',
          amountUSD: 1330,
          pnl: 113000,
          pnlPercentage: 8.7,
        ),
      ),
    ),
    const CommunityToken(
      type: CommunityTokenType.profile,
      title: 'Fatima Ahmed',
      imageUrl: 'https://i.pravatar.cc/150?u=fatima',
      addresses: Addresses(blockchain: '0xD746aE123456789ABCDEF0123456789', ionConnect: null),
      creator: Creator(
        name: 'fatimaahmed',
        display: 'Fatima Ahmed',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?u=fatima',
        addresses: Addresses(blockchain: null, ionConnect: 'npub1fatima...'),
      ),
      marketData: MarketData(
        marketCap: 22000000,
        volume: 580,
        holders: 530,
        priceUSD: 0.12,
        ticker: 'FATIMA_A',
        position: Position(
          rank: 3,
          amount: '43230000000000000000000000',
          amountUSD: 2000,
          pnl: 113000,
          pnlPercentage: 15.3,
        ),
      ),
    ),
  ];

  @override
  Future<UserHoldingsData> getUserHoldings({
    required String holder,
    int limit = 20,
    int offset = 0,
  }) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final totalHoldings = _mockHoldings.length;
    final endIndex = (offset + limit).clamp(0, totalHoldings);
    final items = _mockHoldings.sublist(offset.clamp(0, totalHoldings), endIndex);
    final hasMore = endIndex < totalHoldings;

    return UserHoldingsData(
      items: items,
      totalHoldings: totalHoldings,
      nextOffset: endIndex,
      hasMore: hasMore,
    );
  }
}
