// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/components/url_preview/url_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';

part 'components/meta_data_preview.dart';

class UrlPreviewBlock extends HookWidget {
  const UrlPreviewBlock({
    required this.url,
    required this.isMe,
    super.key,
  });

  final bool isMe;
  final String url;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    return GestureDetector(
      onTap: () => openUrlInAppBrowser(url),
      child: IntrinsicHeight(
        child: UrlPreview(
          url: url,
          builder: (meta, favIconUrl) {
            if (meta == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsetsDirectional.only(top: 8.0.s),
              child: _MetaDataPreview(
                meta: meta,
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
