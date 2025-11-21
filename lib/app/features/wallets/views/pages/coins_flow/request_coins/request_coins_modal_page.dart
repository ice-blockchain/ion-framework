// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/payment_type.dart';
import 'package:ion/app/features/user/providers/request_coins_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/select_coin_modal_page.dart';

typedef SelectNetworkLocationRouteBuilder = String Function(PaymentType paymentType);

class RequestCoinsModalPage extends ConsumerWidget {
  const RequestCoinsModalPage({
    required this.selectNetworkLocationRouteBuilder,
    super.key,
  });

  final SelectNetworkLocationRouteBuilder selectNetworkLocationRouteBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactPubkey =
        ref.watch(requestCoinsFormControllerProvider.select((state) => state.contactPubkey));
    return SelectCoinModalPage(
      title: context.i18n.profile_request_funds,
      contactPubkey: contactPubkey,
      onCoinSelected: (value) {
        ref.read(requestCoinsFormControllerProvider.notifier).setCoin(value);
        context.push(selectNetworkLocationRouteBuilder(PaymentType.request));
      },
    );
  }
}
