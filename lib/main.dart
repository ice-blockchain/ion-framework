// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/providers/template_provider.r.dart';
import 'package:ion/app/features/core/providers/theme_mode_provider.r.dart';
import 'package:ion/app/features/core/views/components/app_lifecycle_observer.dart';
import 'package:ion/app/features/core/views/components/content_scaler.dart';
import 'package:ion/app/router/components/app_router_builder.dart';
import 'package:ion/app/router/components/modal_wrapper/sheet_scope.dart';
import 'package:ion/app/router/providers/go_router_provider.r.dart';
import 'package:ion/app/services/riverpod/container.dart';
import 'package:ion/app/theme/theme.dart';
import 'package:ion/generated/app_localizations.dart';

void main() async {
  runApp(TestApp());
  return;
  runApp(
    UncontrolledProviderScope(
      container: riverpodContainer,
      child: const IONApp(),
    ),
  );
}

class TestApp extends StatefulWidget {
  const TestApp({super.key});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
            child: Column(
          children: [
            SizedBox(
              height: 100,
            ),
            ElevatedButton(onPressed: () {}, child: Text("INIT DBS")),
          ],
        )),
      ),
    );
  }
}

class IONApp extends ConsumerWidget {
  const IONApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(appThemeModeProvider);
    final template = ref.watch(appTemplateProvider);
    final goRouter = ref.watch(goRouterProvider);
    final appLocale = ref.watch(appLocaleProvider);

    return ContentScaler(
      child: AppLifecycleObserver(
        child: SheetScope(
          child: MaterialApp.router(
            localizationsDelegates: const [
              ...I18n.localizationsDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: I18n.supportedLocales,
            locale: appLocale,
            theme: template.whenOrNull(data: (data) => buildLightTheme(data.theme)),
            darkTheme: template.whenOrNull(data: (data) => buildDarkTheme(data.theme)),
            themeMode: appThemeMode,
            routerConfig: goRouter,
            builder: (context, child) => AppRouterBuilder(child: child),
          ),
        ),
      ),
    );
  }
}
