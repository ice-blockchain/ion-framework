//  final isMigrated = (jsonDecode(contents)
//         as Map<String, dynamic>)['tokenizedCommunitiesLegacyContentMigrated'] as bool;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_definition_migration_state.f.freezed.dart';

@Freezed(copyWith: false)
class TokenDefinitionMigrationState with _$TokenDefinitionMigrationState {
  const factory TokenDefinitionMigrationState({
    @Default(false) bool tokenizedCommunitiesLegacyContentMigrated,
  }) = _TokenDefinitionMigrationState;

  factory TokenDefinitionMigrationState.fromJson(Map<String, dynamic> json) =>
      _$TokenDefinitionMigrationStateFromJson(json);
}
