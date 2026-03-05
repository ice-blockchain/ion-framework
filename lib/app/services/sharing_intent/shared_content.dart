// SPDX-License-Identifier: ice License 1.0

sealed class SharedContent {
  const SharedContent();
}

class SharedText extends SharedContent {
  const SharedText(this.text);

  final String text;
}

class SharedImage extends SharedContent {
  const SharedImage(this.paths);

  final List<String> paths;
}
