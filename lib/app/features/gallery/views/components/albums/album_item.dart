// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/gallery/views/components/albums/album_thumbnail.dart';
import 'package:ion/generated/assets.gen.dart';

class AlbumItem extends StatelessWidget {
  const AlbumItem({
    required this.albumId,
    required this.name,
    required this.assetCount,
    required this.isAll,
    required this.isSelected,
    required this.onTap,
    required this.isNeedFilterVideoByFormat,
    super.key,
  });

  final String albumId;
  final String name;
  final int assetCount;
  final bool isAll;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNeedFilterVideoByFormat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ScreenSideOffset.small(
        child: Padding(
          padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
          child: Row(
            children: [
              AlbumThumbnail(
                albumId: albumId,
                isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
              ),
              SizedBox(width: 12.0.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAll ? context.i18n.core_all : name,
                      style: context.theme.appTextThemes.subtitle3,
                    ),
                    Text(
                      '$assetCount',
                      style: context.theme.appTextThemes.caption2.copyWith(
                        color: context.theme.appColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Assets.svg.iconBlockCheckboxOn.icon()
              else
                Assets.svg.iconBlockCheckboxOff.icon(color: context.theme.appColors.onTertiaryFill),
            ],
          ),
        ),
      ),
    );
  }
}
