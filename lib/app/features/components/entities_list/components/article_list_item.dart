// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/views/components/article/article.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ArticleListItem extends ConsumerWidget {
  const ArticleListItem({
    required this.article,
    this.showNotInterested = true,
    super.key,
  });

  final ArticleEntity article;
  final bool showNotInterested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventReference = article.toEventReference();

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 12.0.s),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            ArticleDetailsRoute(eventReference: eventReference.encode()).push<void>(context),
        child: Article(
          eventReference: eventReference,
          showNotInterested: showNotInterested,
        ),
      ),
    );
  }
}
