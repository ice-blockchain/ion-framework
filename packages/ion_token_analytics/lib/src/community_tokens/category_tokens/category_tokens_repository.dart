// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';

abstract class CategoryTokensRepository {
  Future<ViewingSession> createViewingSession(TokenCategoryType type);
}
