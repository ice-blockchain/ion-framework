// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/config/data/models/app_config_with_version.dart';
import 'package:ion/app/features/feed/data/models/feed_interests_interaction.dart';

part 'feed_interests.f.freezed.dart';
part 'feed_interests.f.g.dart';

@Freezed(toJson: false)
class FeedInterests with _$FeedInterests implements AppConfigWithVersion {
  const factory FeedInterests({
    required int version,
    required Map<String, FeedInterestsCategory> categories,
  }) = _FeedInterests;

  factory FeedInterests.fromJson(Map<String, dynamic> json) => _$FeedInterestsFromJson(
        {'version': json['_version'] ?? 0, 'categories': json..remove('_version')},
      );

  const FeedInterests._();

  Map<String, dynamic> toJson() => {
        '_version': version,
        ...categories.map((key, value) => MapEntry(key, value.toJson())),
      };

  /// Returns a copy of the interest with updated weights based on the interaction.
  ///
  /// The interaction's score is added to both category and subcategory levels.
  /// Adding score to subcategories also increases the weight of the parent category.
  FeedInterests applyInteraction(
    FeedInterestInteraction interaction,
    List<String> interactionCategories,
  ) {
    final updatedCategories = <String, FeedInterestsCategory>{};

    for (final MapEntry(key: categoryKey, value: category) in categories.entries) {
      var updatedCategoryWeight = interactionCategories.contains(categoryKey)
          ? category.weight + interaction.score
          : category.weight;
      final updatedSubcategories = <String, FeedInterestsSubcategory>{};

      for (final MapEntry(key: subcategoryKey, value: subcategory) in category.children.entries) {
        if (interactionCategories.contains(subcategoryKey)) {
          if (updatedCategoryWeight == category.weight) {
            updatedCategoryWeight += interaction.score;
          }
          updatedSubcategories[subcategoryKey] = subcategory.copyWith(
            weight: subcategory.weight + interaction.score,
          );
        } else {
          updatedSubcategories[subcategoryKey] = subcategory;
        }
      }

      updatedCategories[categoryKey] = category.copyWith(
        weight: updatedCategoryWeight,
        children: updatedSubcategories,
      );
    }

    return copyWith(categories: updatedCategories);
  }

  Map<String, FeedInterestsSubcategory> get subcategories => Map.fromEntries([
        for (final category in categories.values) ...category.children.entries,
      ]);

  String? parentFor(String subcategoryKey) {
    for (final category in categories.entries) {
      if (category.value.children.containsKey(subcategoryKey)) {
        return category.key;
      }
    }
    return null;
  }

  static const unclassified = 'unclassified';
}

abstract class CategoryWithWeight {
  int get weight;
}

abstract class CategoryWithDisplayName {
  String get display;
}

@freezed
class FeedInterestsCategory
    with _$FeedInterestsCategory
    implements CategoryWithWeight, CategoryWithDisplayName {
  const factory FeedInterestsCategory({
    required int weight,
    required String display,
    required Map<String, FeedInterestsSubcategory> children,
    String? iconUrl,
  }) = _FeedInterestsCategory;

  factory FeedInterestsCategory.fromJson(Map<String, dynamic> json) =>
      _$FeedInterestsCategoryFromJson(json);
}

@freezed
class FeedInterestsSubcategory
    with _$FeedInterestsSubcategory
    implements CategoryWithWeight, CategoryWithDisplayName {
  const factory FeedInterestsSubcategory({
    required String display,
    required int weight,
    String? iconUrl,
  }) = _FeedInterestsSubcategory;

  factory FeedInterestsSubcategory.fromJson(Map<String, dynamic> json) =>
      _$FeedInterestsSubcategoryFromJson(json);
}
