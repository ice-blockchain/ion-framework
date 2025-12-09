// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

enum UserCategory {
  aviation,
  blockchain,
  business,
  cars,
  cryptocurrency,
  dataScience,
  education,
  finance,
  gamer,
  style,
  restaurant,
  trading,
  technology,
  traveler,
  news;

  String get key {
    return switch (this) {
      UserCategory.aviation => 'aviation',
      UserCategory.blockchain => 'blockchain',
      UserCategory.business => 'business',
      UserCategory.cars => 'cars',
      UserCategory.cryptocurrency => 'cryptocurrency',
      UserCategory.dataScience => 'dataScience',
      UserCategory.education => 'education',
      UserCategory.finance => 'finance',
      UserCategory.gamer => 'gamer',
      UserCategory.style => 'style',
      UserCategory.restaurant => 'restaurant',
      UserCategory.trading => 'trading',
      UserCategory.technology => 'technology',
      UserCategory.traveler => 'traveler',
      UserCategory.news => 'news',
    };
  }

  String getName(BuildContext context) {
    return switch (this) {
      UserCategory.aviation => context.i18n.user_category_aviation,
      UserCategory.blockchain => context.i18n.user_category_blockchain,
      UserCategory.business => context.i18n.user_category_business,
      UserCategory.cars => context.i18n.user_category_cars,
      UserCategory.cryptocurrency => context.i18n.user_category_cryptocurrency,
      UserCategory.dataScience => context.i18n.user_category_data_science,
      UserCategory.education => context.i18n.user_category_education,
      UserCategory.finance => context.i18n.user_category_finance,
      UserCategory.gamer => context.i18n.user_category_gamer,
      UserCategory.style => context.i18n.user_category_style,
      UserCategory.restaurant => context.i18n.user_category_restaurant,
      UserCategory.trading => context.i18n.user_category_trading,
      UserCategory.technology => context.i18n.user_category_technology,
      UserCategory.traveler => context.i18n.user_category_traveler,
      UserCategory.news => context.i18n.user_category_news,
    };
  }

  static UserCategory? fromKey(String key) {
    return switch (key) {
      'aviation' => UserCategory.aviation,
      'blockchain' => UserCategory.blockchain,
      'business' => UserCategory.business,
      'cars' => UserCategory.cars,
      'cryptocurrency' => UserCategory.cryptocurrency,
      'dataScience' => UserCategory.dataScience,
      'education' => UserCategory.education,
      'finance' => UserCategory.finance,
      'gamer' => UserCategory.gamer,
      'style' => UserCategory.style,
      'restaurant' => UserCategory.restaurant,
      'trading' => UserCategory.trading,
      'technology' => UserCategory.technology,
      'traveler' => UserCategory.traveler,
      'news' => UserCategory.news,
      _ => null,
    };
  }
}
