// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ion_swap_client/models/chain_data.m.dart';

class ChainsIdsRepository {
  Future<List<ChainData>> getOkxChainsIds() async {
    final file = await rootBundle.loadString('packages/ion_swap_client/assets/json/okx_ids.json');
    final json = jsonDecode(file) as List<dynamic>;
    return json.map((json) => ChainData.fromJson(json as Map<String, dynamic>)).toList();
  }
}
