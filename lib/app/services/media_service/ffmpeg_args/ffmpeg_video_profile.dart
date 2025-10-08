// SPDX-License-Identifier: ice License 1.0

enum FfmpegProfileArg {
  baseline(name: 'Baseline', value: 'baseline'),
  main(name: 'Main', value: 'main'),
  high(name: 'High', value: 'high'),
  high10(name: 'High 10', value: 'high10'),
  high422(name: 'High 4:2:2', value: 'high422'),
  high444(name: 'High 4:4:4', value: 'high444');

  const FfmpegProfileArg({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}
