import 'package:freezed_annotation/freezed_annotation.dart';

part 'chain_data.m.freezed.dart';
part 'chain_data.m.g.dart';

@freezed
class ChainData with _$ChainData {
  factory ChainData({
    required String name,
    required int networkId,
  }) = _ChainData;

  factory ChainData.fromJson(Map<String, dynamic> json) => _$ChainDataFromJson(json);
}
