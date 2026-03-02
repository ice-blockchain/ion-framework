// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';

class PmoCashtagEnrichmentService {
  PmoCashtagEnrichmentService({
    required Future<String?> Function(String externalAddress) resolveTokenDefinitionAddress,
  }) : _resolveTokenDefinitionAddress = resolveTokenDefinitionAddress;

  final Future<String?> Function(String externalAddress) _resolveTokenDefinitionAddress;

  Future<Delta> prepareContentForPmo(Delta content) async {
    final out = Delta();
    final tokenDefinitionAddressByExternalAddress = <String, String>{};

    for (final op in content.operations) {
      final data = op.data;
      final attrs = op.attributes;

      if (data is! String || attrs == null || !attrs.containsKey(CashtagAttribute.attributeKey)) {
        out.push(op);
        continue;
      }

      final showMarketCap = attrs[CashtagAttribute.showMarketCapKey] == true;
      final externalAddressRaw = attrs[CashtagAttribute.attributeKey];
      final externalAddress = externalAddressRaw is String ? externalAddressRaw.trim() : '';

      if (!showMarketCap || externalAddress.isEmpty || externalAddress == r'$') {
        out.push(op);
        continue;
      }

      var tokenDefinitionAddress = tokenDefinitionAddressByExternalAddress[externalAddress];
      if (tokenDefinitionAddress == null) {
        tokenDefinitionAddress = await _resolveTokenDefinitionAddress(externalAddress);
        tokenDefinitionAddressByExternalAddress[externalAddress] = tokenDefinitionAddress ?? '';
      }

      if (tokenDefinitionAddress == null || tokenDefinitionAddress.isEmpty) {
        out.push(op);
        continue;
      }

      final normalizedData = data.trimRight();
      final enrichedText = normalizedData.contains(tokenDefinitionAddress)
          ? data
          : '$normalizedData $tokenDefinitionAddress';

      out.insert(enrichedText, attrs);
    }

    return out;
  }
}
