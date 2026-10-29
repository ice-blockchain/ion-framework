// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/auth/flows/return_to_existing_account_login.dart';

void main() {
  testWidgets('returns to sign-in without starting password registration', (tester) async {
    bool? signUpResult;
    var passwordRegistrationStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                signUpResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => returnToExistingAccountLogin(context),
                        child: const Text('Existing account'),
                      ),
                    ),
                  ),
                );
                passwordRegistrationStarted = signUpResult == false;
              },
              child: const Text('Sign-in screen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sign-in screen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existing account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign-in screen'), findsOneWidget);
    expect(find.text('Existing account'), findsNothing);
    expect(signUpResult, isTrue);
    expect(passwordRegistrationStarted, isFalse);
  });
}
