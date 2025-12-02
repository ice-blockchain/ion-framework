// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/theme/app_colors.dart';
import 'package:palette_generator/palette_generator.dart';

typedef AvatarColors = ({Color first, Color second});

AvatarColors useAvatarFallbackColors = (
  first: AppColorsExtension.defaultColors().raspberry,
  second: AppColorsExtension.defaultColors().anakiwa,
);

/// Global cache for avatar colors to prevent expensive palette generation during scroll
/// Key: avatar URL, Value: (color1, color2)
final Map<String, AvatarColors> _avatarColorsCache = {};

/// Hook to extract two colors from the user's avatar using PaletteGenerator
/// Returns null colors while loading, then returns extracted colors
AvatarColors? useImageColors(String? avatarUrl) {
  final paletteState = useState<PaletteGenerator?>(null);
  final isLoadingState = useState<bool>(false);

  useEffect(
    () {
      if (avatarUrl == null || avatarUrl.isEmpty) {
        paletteState.value = null;
        isLoadingState.value = false;
        return null;
      }

      // Check cache first
      if (_avatarColorsCache.containsKey(avatarUrl)) {
        isLoadingState.value = false;
        // Cache hit - no need to generate palette, will use cached colors below
        return null;
      }

      var isMounted = true;
      isLoadingState.value = true;

      Future<void> extractColors() async {
        try {
          final imageProvider = NetworkImage(avatarUrl);
          final palette = await PaletteGenerator.fromImageProvider(
            imageProvider,
            maximumColorCount: 20,
          );
          if (isMounted) {
            paletteState.value = palette;
          }
        } catch (e) {
          if (isMounted) {
            paletteState.value = null;
          }
        } finally {
          if (isMounted) {
            isLoadingState.value = false;
          }
        }
      }

      extractColors();

      return () {
        isMounted = false;
      };
    },
    [avatarUrl],
  );

  // Check cache first for instant return
  if (avatarUrl != null && _avatarColorsCache.containsKey(avatarUrl)) {
    return _avatarColorsCache[avatarUrl];
  }

  final palette = paletteState.value;

  // Return fallback while loading
  if (isLoadingState.value || palette == null) {
    return useAvatarFallbackColors;
  }

  // Extract two visually distinct colors that work well for gradients
  // Strategy: Pick a vibrant/dominant color and pair it with a contrasting color
  final color1 = palette.vibrantColor?.color ??
      palette.dominantColor?.color ??
      palette.lightVibrantColor?.color ??
      useAvatarFallbackColors.first;

  Color? color2;

  if (palette.vibrantColor != null) {
    // Pair vibrant with dark muted or dark vibrant for contrast
    color2 = palette.darkMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.mutedColor?.color;
  } else if (palette.lightVibrantColor != null) {
    // Pair light vibrant with dark vibrant for good contrast
    color2 =
        palette.darkVibrantColor?.color ?? palette.vibrantColor?.color ?? palette.mutedColor?.color;
  } else {
    // Fallback: use complementary palette colors
    color2 = palette.lightMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.mutedColor?.color;
  }

  color2 ??= useAvatarFallbackColors.second;

  final result = (first: color1, second: color2);

  // Cache the result for future use
  if (avatarUrl != null) {
    _avatarColorsCache[avatarUrl] = result;
  }

  return result;
}
