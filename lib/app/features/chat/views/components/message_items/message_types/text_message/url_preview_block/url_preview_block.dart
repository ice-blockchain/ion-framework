// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/components/url_preview/url_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';

part 'components/meta_data_preview.dart';

class UrlPreviewBlock extends HookConsumerWidget {
  const UrlPreviewBlock({
    required this.url,
    required this.isMe,
    super.key,
  });

  final bool isMe;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheKey = useMemoized(() => normalizeUrl(url), [url]);
    final cachedMeta = ListCachedObjects.maybeObjectOf<OgpDataWithKey>(context, cacheKey)?.meta;

    return GestureDetector(
      onTap: () => openDeepLinkOrInAppBrowser(url, ref),
      child: IntrinsicHeight(
        child: UrlPreview(
          url: url,
          metaListener: (meta) {
            if (meta != null && cachedMeta != meta) {
              ListCachedObjects.updateObject<OgpDataWithKey>(
                context,
                (key: cacheKey, meta: meta),
              );
            }
          },
          builder: (meta, favIconUrl) {
            if (cachedMeta == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsetsDirectional.only(top: 8.0.s),
              child: _MetaDataPreview(
                meta: cachedMeta,
                favIconUrl: favIconUrl,
                url: url,
                isMe: isMe,
              ),
            );
          },
        ),
      ),
    );
  }
}
