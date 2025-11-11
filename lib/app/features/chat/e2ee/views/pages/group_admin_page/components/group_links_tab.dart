// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/url_preview/url_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/group_links_provider.r.dart'
    show GroupLinkItem, groupLinksProvider;
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/url.dart';

class GroupLinksTab extends ConsumerWidget {
  const GroupLinksTab({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch<AsyncValue<List<GroupLinkItem>>>(
      groupLinksProvider(conversationId),
    );

    return linksAsync.when(
      data: (List<GroupLinkItem> links) {
        if (links.isEmpty) {
          return Center(
            child: Text(
              context.i18n.common_links,
              style: context.theme.appTextThemes.body,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsetsDirectional.only(
            start: 16.0.s,
            end: 16.0.s,
            top: 18.0.s,
          ),
          itemCount: links.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.0.s),
          itemBuilder: (context, int index) {
            final linkItem = links[index];
            return _GroupLinkCell(
              url: linkItem.url,
              onTap: () => openDeepLinkOrInAppBrowser(linkItem.url, ref),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stack) => Center(
        child: Text(
          context.i18n.common_error,
          style: context.theme.appTextThemes.body,
        ),
      ),
    );
  }
}

class _GroupLinkCell extends ConsumerWidget {
  const _GroupLinkCell({
    required this.url,
    required this.onTap,
  });

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: UrlPreview(
        url: url,
        builder: (meta, favIconUrl) {
          return Container(
            padding: EdgeInsets.all(16.0.s),
            decoration: BoxDecoration(
              color: context.theme.appColors.tertiaryBackground,
              borderRadius: BorderRadius.circular(16.0.s),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta?.title != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: 8.0.s),
                    child: Text(
                      meta!.title!,
                      style: context.theme.appTextThemes.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 8.0.s),
                  child: Text(
                    normalizeUrl(url),
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.primaryAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (meta?.description != null)
                  Text(
                    meta!.description!,
                    style: context.theme.appTextThemes.body2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
