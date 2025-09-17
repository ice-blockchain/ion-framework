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
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,80):h=if(gt(ih\,iw)\,80\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p120(
    name: '120p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,120):h=if(gt(ih\,iw)\,120\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p180(
    name: '180p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,180):h=if(gt(ih\,iw)\,180\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p240(
    name: '240p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,240):h=if(gt(ih\,iw)\,240\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p480(
    name: '480p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,480):h=if(gt(ih\,iw)\,480\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p720(
    name: '720p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,720):h=if(gt(ih\,iw)\,720\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p1080(
    name: '1080p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,1080):h=if(gt(ih\,iw)\,1080\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  ),
  p2160(
    name: '2160p',
    resolution:
        r'scale=w=if(gt(ih\,iw)\,-16\,2160):h=if(gt(ih\,iw)\,2160\,-16),crop=trunc(iw/16)*16:trunc(ih/16)*16',
  );

  const FfmpegScaleArg({
    required this.name,
    required this.resolution,
  });

  final String name;
  final String resolution;
}
