// SPDX-License-Identifier: ice License 1.0

class CallFunctionRequest {
  const CallFunctionRequest({
    required this.contract,
    required this.abi,
    this.calldata,
  });

  final String contract;
  final CallFunctionAbi abi;
  final Map<String, dynamic>? calldata;

  Map<String, dynamic> toJson() => {
        'contract': contract,
        'abi': abi.toJson(),
        if (calldata != null) 'calldata': calldata,
      };
}

class CallFunctionAbi {
  const CallFunctionAbi({
    required this.name,
    required this.inputs,
    required this.outputs,
    this.type = 'function',
    this.stateMutability = 'view',
  });

  final String type;
  final String name;
  final String stateMutability;
  final List<CallFunctionAbiParam> inputs;
  final List<CallFunctionAbiParam> outputs;

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'stateMutability': stateMutability,
        'inputs': inputs.map((i) => i.toJson()).toList(),
        'outputs': outputs.map((o) => o.toJson()).toList(),
      };
}

class CallFunctionAbiParam {
  const CallFunctionAbiParam({
    required this.name,
    required this.type,
    this.components,
  });

  final String name;
  final String type;
  final List<CallFunctionAbiParam>? components;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (components != null) 'components': components!.map((c) => c.toJson()).toList(),
      };
}
