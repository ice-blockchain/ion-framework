// SPDX-License-Identifier: ice License 1.0

enum FfmpegBitrateArg {
  lowest(name: 'Lowest', bitrate: 500),
  low(name: 'Low', bitrate: 1000),
  medium(name: 'Medium', bitrate: 2000),
  high(name: 'High', bitrate: 4000),
  highest(name: 'Highest', bitrate: 8000);

  const FfmpegBitrateArg({
    required this.name,
    required this.bitrate,
  });

  final String name;
  final int bitrate;

  String get bitrateString => '${bitrate}k';
}
