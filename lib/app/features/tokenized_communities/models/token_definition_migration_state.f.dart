// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_definition_migration_state.f.freezed.dart';
part 'token_definition_migration_state.f.g.dart';

@freezed
class TokenDefinitionMigrationState with _$TokenDefinitionMigrationState {
  const factory TokenDefinitionMigrationState({
    @Default(false) bool tokenizedCommunitiesLegacyContentMigrated,
  }) = _TokenDefinitionMigrationState;

  factory TokenDefinitionMigrationState.fromJson(Map<String, dynamic> json) =>
      _$TokenDefinitionMigrationStateFromJson(json);
}
