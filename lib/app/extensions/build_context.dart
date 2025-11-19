// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/generated/app_localizations.dart';

extension ThemeGetter on BuildContext {
  /// Usage example: `context.theme`
  ThemeData get theme => Theme.of(this);
}

extension I18nGetter on BuildContext {
  I18n get i18n => I18n.of(this)!;
}

extension NavigatorExt on BuildContext {
  bool get isCurrentRoute => ModalRoute.of(this)?.isCurrent ?? false;
}

extension MaybePopExtension on BuildContext {
  void maybePop<T extends Object?>([T? result]) {
    if (canPop()) {
      pop(result);
    }
  }
}

extension GoRouterPopUntilExtension on BuildContext {
  void popUntil(bool Function(GoRoute route) predicate) {
    final delegate = GoRouter.of(this).routerDelegate;
    var config = delegate.currentConfiguration;
    var routes = config.routes.whereType<GoRoute>();

    while (routes.length > 1 && !predicate(config.last.route)) {
      config = config.remove(config.last);
      routes = config.routes.whereType<GoRoute>();
    }

    delegate.setNewRoutePath(config);
  }
}
