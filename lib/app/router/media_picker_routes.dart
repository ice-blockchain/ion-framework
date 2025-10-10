// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class MediaPickerRoutes {
  static const routesPrefix = '/media-picker';
}

@TypedGoRoute<MediaPickerRoute>(path: MediaPickerRoutes.routesPrefix)
class MediaPickerRoute extends BaseRouteData with _$MediaPickerRoute {
  MediaPickerRoute({
    required this.isNeedFilterVideoByFormat,
    this.maxSelection,
    this.mediaPickerType = MediaPickerType.common,
    this.maxVideoDurationInSeconds,
    this.showCameraCell = true,
  }) : super(
          child: MediaPickerPage(
            maxSelection: maxSelection ?? 5,
            type: mediaPickerType,
            maxVideoDurationInSeconds: maxVideoDurationInSeconds,
            showCameraCell: showCameraCell,
            isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
          ),
          type: IceRouteType.simpleModalSheet,
        );

  final int? maxSelection;
  final MediaPickerType mediaPickerType;
  final int? maxVideoDurationInSeconds;
  final bool showCameraCell;
  final bool isNeedFilterVideoByFormat;
}

@TypedGoRoute<AlbumSelectionRoute>(path: '${MediaPickerRoutes.routesPrefix}/album-selection')
class AlbumSelectionRoute extends BaseRouteData with _$AlbumSelectionRoute {
  AlbumSelectionRoute({
    required this.mediaPickerType,
    required this.isNeedFilterVideoByFormat,
  }) : super(
          child: AlbumSelectionPage(
            type: mediaPickerType,
            isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
          ),
          type: IceRouteType.simpleModalSheet,
        );

  final MediaPickerType mediaPickerType;
  final bool isNeedFilterVideoByFormat;
}

@TypedGoRoute<GalleryCameraRoute>(path: '${MediaPickerRoutes.routesPrefix}/camera')
class GalleryCameraRoute extends BaseRouteData with _$GalleryCameraRoute {
  GalleryCameraRoute({
    required this.mediaPickerType,
  }) : super(
          child: GalleryCameraPage(type: mediaPickerType),
        );

  final MediaPickerType mediaPickerType;
}
