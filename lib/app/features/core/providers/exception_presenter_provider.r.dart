// SPDX-License-Identifier: ice License 1.0

// Presentation class holds display info
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exception_presenter_provider.r.g.dart';

@Riverpod(keepAlive: true)
ExceptionPresenter exceptionPresenter(Ref ref) {
  return ExceptionPresenter(
    showDebugInfo: ref.watch(envProvider.notifier).get<bool>(EnvVariable.SHOW_DEBUG_INFO),
  );
}

class ExceptionPresentation {
  const ExceptionPresentation({
    required this.title,
    required this.description,
    required this.iconPath,
  });

  final String title;
  final String description;
  final String iconPath;
}

class ExceptionPresenter {
  ExceptionPresenter({required this.showDebugInfo});

  final bool showDebugInfo;

  ExceptionPresentation getPresentation(BuildContext context, Object error) {
    return ExceptionPresentation(
      title: _getTitle(context, error),
      description: _getDescription(context, error),
      iconPath: _getIconPath(error),
    );
  }

  String _getTitle(BuildContext context, Object error) {
    final locale = context.i18n;
    return switch (error) {
      PaymentNoDestinationException() => locale.error_payment_no_destination_title,
      TokenBelowMinimumException() => locale.error_token_below_minimum_title,
      InsufficientAmountException() => locale.error_token_below_minimum_title,
      SolanaInsufficientBalanceException() => locale.error_solana_insufficient_balance_title,
      SolanaInvalidRecipientException() => locale.error_solana_invalid_recipient_title,
      final IONIdentityException identityException => identityException.title(context),
      SendEventException => locale.error_network_sync_failed_title,
      _ => locale.error_general_title,
    };
  }

  String _getDescription(BuildContext context, Object error) {
    final locale = context.i18n;
    return switch (error) {
      InsufficientAmountException() => locale.error_insufficient_amount_description,
      final PaymentNoDestinationException ex =>
        locale.error_payment_no_destination_description(ex.abbreviation),
      final TokenBelowMinimumException ex =>
        locale.error_token_below_minimum_description(ex.abbreviation, ex.minAmount),
      SolanaInsufficientBalanceException() => locale.error_solana_insufficient_balance_description,
      SolanaInvalidRecipientException() => locale.error_solana_invalid_recipient_description,
      final IONIdentityException identityException => identityException.description(context),
      Object _ when showDebugInfo => error.toString(),
      IONException(code: final int code) =>
        context.i18n.error_general_description(context.i18n.error_general_error_code(code)),
      SendEventException => locale.error_network_sync_failed_description,
      _ => context.i18n.error_general_description('')
    };
  }

  String _getIconPath(Object error) => switch (error) {
        _ => Assets.svg.actionWalletKeyserror,
      };
}
