// SPDX-License-Identifier: ice License 1.0

enum FfmpegCrfArg {
  lossless(name: 'Lossless', value: '0'),
  visuallyLossless(name: 'Visually Lossless', value: '18'),
  standard(name: 'Standard', value: '23'),
  balanced(name: 'Balanced', value: '28'),
  max(name: 'Max', value: '51');

  const FfmpegCrfArg({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}
