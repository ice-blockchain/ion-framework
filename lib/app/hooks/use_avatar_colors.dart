// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:palette_generator/palette_generator.dart';

const Color _useAvatarFallbackColor1 = Color(0xFFB43C4B);
const Color _useAvatarFallbackColor2 = Color(0xFF3EB0FF);

/// Hook to extract two colors from the user's avatar using PaletteGenerator
/// Returns null colors while loading, then returns extracted colors
(Color?, Color?) useAvatarColors(String? avatarUrl) {
  final paletteState = useState<PaletteGenerator?>(null);
  final isLoadingState = useState<bool>(false);

  useEffect(
    () {
      if (avatarUrl == null || avatarUrl.isEmpty) {
        paletteState.value = null;
        isLoadingState.value = false;
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

  final palette = paletteState.value;

  // Return null while loading to show skeleton
  if (isLoadingState.value || palette == null) {
    return (null, null);
  }

  // Extract two visually distinct colors that work well for gradients
  // Strategy: Pick a vibrant/dominant color and pair it with a contrasting color
  final color1 = palette.vibrantColor?.color ??
      palette.dominantColor?.color ??
      palette.lightVibrantColor?.color ??
      _useAvatarFallbackColor1;

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

  color2 ??= _useAvatarFallbackColor2;

  return (color1, color2);
}
