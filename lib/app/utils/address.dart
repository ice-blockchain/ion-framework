// SPDX-License-Identifier: ice License 1.0

// For address like 0xb38c367c51800f066f61d9206a38023e876680c4a96ceedcb79935c46bf66eac
// returns short form 0xb38c3...f66eac
String shortenAddress(String address) {
  final value = address.trim();
  if (value.isEmpty) {
    return value;
  }

  const headLength = 7; // `0x` + 5 chars
  const tailLength = 6;

  if (value.length <= headLength + tailLength + 3) {
    return value;
  }

  return '${value.substring(0, headLength)}...${value.substring(value.length - tailLength)}';
}
