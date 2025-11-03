// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/verify_identity/hooks/use_on_get_password.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';

const excludedPasskeyExceptions = {
  PasskeyCancelledException,
  PlatformException,
};

Future<void> guardPasskeyDialog(
  BuildContext context,
  Widget Function(Widget child) passkeyRequestBuilder, {
  String? identityKeyName,
}) async {
  return showSimpleBottomSheet<void>(
    context: context,
    child: passkeyRequestBuilder(
      VerifyIdentityPromptDialog(
        identityKeyName: identityKeyName,
      ),
    ),
  );
}

class RiverpodLoginConfigRequestBuilder<T> extends HookConsumerWidget {
  const RiverpodLoginConfigRequestBuilder({
    required this.child,
    required this.request,
    this.identityKeyName,
    this.onPasswordCaptured,
    super.key,
  });

  final Widget child;
  final Future<void> Function(LoginAuthConfig config) request;
  final String? identityKeyName;
  final void Function(String password)? onPasswordCaptured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onGetPassword = useOnGetPassword<String>();

    useOnInit(
      () async {
        try {
          await _executeRequest(context, ref, onGetPassword);
        } finally {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      <Object>[onGetPassword],
    );

    return child;
  }

  Future<void> _executeRequest(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function(OnPasswordFlow<String> onPasswordFlow) onGetPassword,
  ) async {
    final locale = context.i18n;

    final config = LoginAuthConfig(
      localisedReasonForBiometrics: locale.verify_with_biometrics_title,
      localisedCancelForBiometrics: locale.button_cancel,
      getPassword: () => onGetPassword(({required String password}) async {
        onPasswordCaptured?.call(password);
        return password;
      }),
    );

    await request(config);
  }
}

class RiverpodUserActionSignerRequestBuilder<T> extends HookConsumerWidget {
  const RiverpodUserActionSignerRequestBuilder({
    required this.child,
    required this.provider,
    required this.request,
    this.identityKeyName,
    this.onPasswordCaptured,
    super.key,
  });

  final Widget child;
  final ProviderListenable<AsyncValue<T>> provider;
  final Future<void> Function(UserActionSignerNew signer) request;
  final String? identityKeyName;
  final void Function(String password)? onPasswordCaptured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(provider, (prev, next) {
      if (!next.isLoading && context.mounted) {
        Navigator.of(context).pop();
      }
    });

    final onGetPassword = useOnGetPassword<String>();

    useOnInit(
      () {
        _executeRequest(context, ref, onGetPassword);
      },
      <Object>[onGetPassword],
    );

    return child;
  }

  Future<void> _executeRequest(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function(OnPasswordFlow<String> onPasswordFlow) onGetPassword,
  ) async {
    final locale = context.i18n;

    final username = identityKeyName ?? ref.read(currentIdentityKeyNameSelectorProvider)!;
    final ionIdentity = await ref.read(ionIdentityProvider.future);
    final ionIdentityClient = ionIdentity(username: username);
    final signerFactory = ionIdentityClient.userActionSignerFactory;

    final signer = await signerFactory.createSigner(
      localisedReasonForBiometrics: locale.verify_with_biometrics_title,
      localisedCancelForBiometrics: locale.button_cancel,
      getPassword: () => onGetPassword(({required String password}) async {
        onPasswordCaptured?.call(password);
        return password;
      }),
    );

    await request(signer);
  }
}

class RiverpodVerifyIdentityRequestBuilder<T, P> extends HookConsumerWidget {
  const RiverpodVerifyIdentityRequestBuilder({
    required this.child,
    required this.provider,
    required this.requestWithVerifyIdentity,
    this.identityKeyName,
    super.key,
  });

  final Widget child;
  final ProviderListenable<AsyncValue<T>> provider;
  final WithVerifyIdentity<P> requestWithVerifyIdentity;
  final String? identityKeyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(provider, (prev, next) {
      if (!next.isLoading && context.mounted) {
        Navigator.of(context).pop();
      }
    });

    final onGetPassword = useOnGetPassword<P>();

    useOnInit(
      () {
        requestWithVerifyIdentity(({
          required OnPasswordFlow<P> onPasswordFlow,
          required OnPasskeyFlow<P> onPasskeyFlow,
          required OnBiometricsFlow<P> onBiometricsFlow,
        }) {
          return ref.read(
            verifyUserIdentityProvider(
              onGetPassword: onGetPassword,
              onPasswordFlow: onPasswordFlow,
              onPasskeyFlow: onPasskeyFlow,
              onBiometricsFlow: onBiometricsFlow,
              localisedReasonForBiometricsDialog: context.i18n.verify_with_biometrics_title,
              localisedCancelForBiometricsDialog: context.i18n.button_cancel,
              identityKeyName: identityKeyName,
            ).future,
          );
        });
      },
      <Object>[onGetPassword],
    );

    return child;
  }
}

class HookVerifyIdentityRequestBuilder<P> extends HookConsumerWidget {
  const HookVerifyIdentityRequestBuilder({
    required this.child,
    required this.requestWithVerifyIdentity,
    super.key,
  });

  final Widget child;
  final WithVerifyIdentity<P> requestWithVerifyIdentity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onGetPassword = useOnGetPassword<P>();
    useOnInit(
      () {
        requestWithVerifyIdentity(({
          required OnPasswordFlow<P> onPasswordFlow,
          required OnPasskeyFlow<P> onPasskeyFlow,
          required OnBiometricsFlow<P> onBiometricsFlow,
        }) async {
          try {
            return await ref.read(
              verifyUserIdentityProvider(
                onGetPassword: onGetPassword,
                onPasswordFlow: onPasswordFlow,
                onPasskeyFlow: onPasskeyFlow,
                onBiometricsFlow: onBiometricsFlow,
                localisedReasonForBiometricsDialog: context.i18n.verify_with_biometrics_title,
                localisedCancelForBiometricsDialog: context.i18n.button_cancel,
              ).future,
            );
          } finally {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        });
      },
      <Object>[onGetPassword],
    );

    return child;
  }
}
