// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/views/components/content_scaler.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Test harness wrapper: providers, router, MaterialApp setup
/// Eliminates test setup duplication and provides consistent environment
class RobotTestHarness extends StatelessWidget {
  const RobotTestHarness({
    required this.childBuilder,
    this.overrides = const [],
    this.router,
    this.localizationsDelegates,
    this.supportedLocales,
    this.locale,
    super.key,
  });

  final Widget Function(WidgetRef ref) childBuilder;
  final List<Override> overrides;
  final GoRouter? router;
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final List<Locale>? supportedLocales;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: ContentScaler(
        child: Consumer(
          builder: (context, ref, _) {
            final app = router != null
                ? MaterialApp.router(
                    routerConfig: router,
                    localizationsDelegates: localizationsDelegates,
                    supportedLocales: supportedLocales ?? [const Locale('en')],
                    locale: locale,
                    builder: (context, child) {
                      if (child == null) return const SizedBox.shrink();
                      return SheetViewport(
                        child: PagedSheet(
                          navigator: child,
                        ),
                      );
                    },
                  )
                : MaterialApp(
                    home: childBuilder(ref),
                    localizationsDelegates: localizationsDelegates,
                    supportedLocales: supportedLocales ?? [const Locale('en')],
                    locale: locale,
                    builder: (context, child) {
                      if (child == null) return const SizedBox.shrink();
                      return SheetViewport(
                        child: PagedSheet(
                          navigator: child,
                        ),
                      );
                    },
                  );
            return app;
          },
        ),
      ),
    );
  }
}

/// Extension method for convenient pumping with RobotTestHarness
extension RobotTestHarnessExtension on WidgetTester {
  Future<void> pumpWithHarness({
    required Widget Function(WidgetRef ref) childBuilder,
    List<Override> overrides = const [],
    GoRouter? router,
    List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    List<Locale>? supportedLocales,
    Locale? locale,
  }) async {
    await pumpWidget(
      RobotTestHarness(
        childBuilder: childBuilder,
        overrides: overrides,
        router: router,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        locale: locale,
      ),
    );
  }
}
