import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/relay_step_item.m.dart';

part 'relay_step.m.freezed.dart';
part 'relay_step.m.g.dart';

@freezed
// TODO(ice-erebus): maybe add signature step
class RelayStep with _$RelayStep {
  factory RelayStep({
    required String id,
    required List<RelayStepItem> items,
  }) = _RelayStep;

  factory RelayStep.fromJson(Map<String, dynamic> json) => _$RelayStepFromJson(json);
}
