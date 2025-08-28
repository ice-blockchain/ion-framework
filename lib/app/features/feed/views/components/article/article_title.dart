// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/article/components/article_footer/article_footer.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class ArticleTitle extends ConsumerWidget {
  const ArticleTitle({required this.eventReference, this.accentTheme = false, super.key});

  final EventReference eventReference;
  final bool accentTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(ionConnectEntityWithCountersProvider(eventReference: eventReference));

    if (entity is! ArticleEntity) {
      return const SizedBox.shrink();
    }
    return ArticleFooter(
      text: entity.data.title ?? '',
      color:
          accentTheme ? context.theme.appColors.onPrimaryAccent : context.theme.appColors.sharkText,
    );
  }
}
