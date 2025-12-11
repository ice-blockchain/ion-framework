// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/model/user_category.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_categories_provider.r.g.dart';

@riverpod
Map<String, UserCategory> userCategories(Ref ref) {
  return {for (final category in UserCategory.values) category.key: category};
}
