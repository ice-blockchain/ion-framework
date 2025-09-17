// SPDX-License-Identifier: ice License 1.0

///
/// FFmpeg scale filter argument that maintains aspect ratio while resizing:
/// - For portrait videos (height > width):
///   - Sets width to -2 (auto, rounding to nearest even integer) and height to min(1080, input_height)
/// - For landscape videos (width >= height):
///   - Sets height to -2 (auto, rounding to nearest even integer) and width to min(1080, input_width)
///
/// The escaped commas and backslashes are required for FFmpeg filter syntax.
/// Example: A 4K portrait video (3840x2160) would be scaled to 607x1080
///
enum FfmpegScaleArg {
  p80(
    name: '80p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(80\,iw)):h=if(gt(ih\,iw)\,min(80\,ih)\,-8)',
  ),
  p120(
    name: '120p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(120\,iw)):h=if(gt(ih\,iw)\,min(120\,ih)\,-8)',
  ),
  p180(
    name: '180p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(180\,iw)):h=if(gt(ih\,iw)\,min(180\,ih)\,-8)',
  ),
  p240(
    name: '240p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(240\,iw)):h=if(gt(ih\,iw)\,min(240\,ih)\,-8)',
  ),
  p480(
    name: '480p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(480\,iw)):h=if(gt(ih\,iw)\,min(480\,ih)\,-8)',
  ),
  p720(
    name: '720p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(720\,iw)):h=if(gt(ih\,iw)\,min(720\,ih)\,-8)',
  ),
  p1080(
    name: '1080p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(1080\,iw)):h=if(gt(ih\,iw)\,min(1080\,ih)\,-8)',
  ),
  p2160(
    name: '2160p',
    resolution: r'scale=w=if(gt(ih\,iw)\,-8\,min(2160\,iw)):h=if(gt(ih\,iw)\,min(2160\,ih)\,-8)',
  );

  const FfmpegScaleArg({
    required this.name,
    required this.resolution,
  });

  final String name;
  final String resolution;
}
