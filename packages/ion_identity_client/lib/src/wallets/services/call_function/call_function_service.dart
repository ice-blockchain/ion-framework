// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/wallets/services/call_function/data_sources/call_function_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/call_function/models/call_function_request.dart';

class CallFunctionService {
  const CallFunctionService({
    required CallFunctionDataSource callFunctionDataSource,
  }) : _callFunctionDataSource = callFunctionDataSource;

  final CallFunctionDataSource _callFunctionDataSource;

  Future<dynamic> callFunction({
    required String network,
    required CallFunctionRequest request,
  }) async {
    return _callFunctionDataSource.callFunction(
      network: network,
      request: request,
    );
  }
}
