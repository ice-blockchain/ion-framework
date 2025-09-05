// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ion_connect_cache_database.d.dart';

// ignore_for_file: type=lint
class $EventMessagesTableTable extends EventMessagesTable
    with TableInfo<$EventMessagesTableTable, EventMessageCacheDbModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventMessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _insertedAtMeta = const VerificationMeta(
    'insertedAt',
  );
  @override
  late final GeneratedColumn<int> insertedAt = GeneratedColumn<int>(
    'inserted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masterPubkeyMeta = const VerificationMeta(
    'masterPubkey',
  );
  @override
  late final GeneratedColumn<String> masterPubkey = GeneratedColumn<String>(
    'master_pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<List<String>>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<List<String>>>(
        $EventMessagesTableTable.$convertertags,
      );
  static const VerificationMeta _sigMeta = const VerificationMeta('sig');
  @override
  late final GeneratedColumn<String> sig = GeneratedColumn<String>(
    'sig',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    kind,
    createdAt,
    insertedAt,
    masterPubkey,
    content,
    tags,
    sig,
    id,
    pubkey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_messages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventMessageCacheDbModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('inserted_at')) {
      context.handle(
        _insertedAtMeta,
        insertedAt.isAcceptableOrUnknown(data['inserted_at']!, _insertedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_insertedAtMeta);
    }
    if (data.containsKey('master_pubkey')) {
      context.handle(
        _masterPubkeyMeta,
        masterPubkey.isAcceptableOrUnknown(
          data['master_pubkey']!,
          _masterPubkeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_masterPubkeyMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sig')) {
      context.handle(
        _sigMeta,
        sig.isAcceptableOrUnknown(data['sig']!, _sigMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  EventMessageCacheDbModel map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventMessageCacheDbModel(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      insertedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}inserted_at'],
      )!,
      masterPubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}master_pubkey'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tags: $EventMessagesTableTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      sig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sig'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      )!,
    );
  }

  @override
  $EventMessagesTableTable createAlias(String alias) {
    return $EventMessagesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<List<String>>, String, List<List<String>>>
  $convertertags = const EventTagsConverter();
}

class EventMessageCacheDbModel extends DataClass
    implements Insertable<EventMessageCacheDbModel> {
  final String cacheKey;
  final int kind;
  final int createdAt;
  final int insertedAt;
  final String masterPubkey;
  final String content;
  final List<List<String>> tags;
  final String? sig;
  final String id;
  final String pubkey;
  const EventMessageCacheDbModel({
    required this.cacheKey,
    required this.kind,
    required this.createdAt,
    required this.insertedAt,
    required this.masterPubkey,
    required this.content,
    required this.tags,
    this.sig,
    required this.id,
    required this.pubkey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['kind'] = Variable<int>(kind);
    map['created_at'] = Variable<int>(createdAt);
    map['inserted_at'] = Variable<int>(insertedAt);
    map['master_pubkey'] = Variable<String>(masterPubkey);
    map['content'] = Variable<String>(content);
    {
      map['tags'] = Variable<String>(
        $EventMessagesTableTable.$convertertags.toSql(tags),
      );
    }
    if (!nullToAbsent || sig != null) {
      map['sig'] = Variable<String>(sig);
    }
    map['id'] = Variable<String>(id);
    map['pubkey'] = Variable<String>(pubkey);
    return map;
  }

  EventMessagesTableCompanion toCompanion(bool nullToAbsent) {
    return EventMessagesTableCompanion(
      cacheKey: Value(cacheKey),
      kind: Value(kind),
      createdAt: Value(createdAt),
      insertedAt: Value(insertedAt),
      masterPubkey: Value(masterPubkey),
      content: Value(content),
      tags: Value(tags),
      sig: sig == null && nullToAbsent ? const Value.absent() : Value(sig),
      id: Value(id),
      pubkey: Value(pubkey),
    );
  }

  factory EventMessageCacheDbModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventMessageCacheDbModel(
      cacheKey: serializer.fromJson<String>(json['cache_key']),
      kind: serializer.fromJson<int>(json['kind']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      insertedAt: serializer.fromJson<int>(json['inserted_at']),
      masterPubkey: serializer.fromJson<String>(json['master_pubkey']),
      content: serializer.fromJson<String>(json['content']),
      tags: $EventMessagesTableTable.$convertertags.fromJson(
        serializer.fromJson<List<List<String>>>(json['tags']),
      ),
      sig: serializer.fromJson<String?>(json['sig']),
      id: serializer.fromJson<String>(json['id']),
      pubkey: serializer.fromJson<String>(json['pubkey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cache_key': serializer.toJson<String>(cacheKey),
      'kind': serializer.toJson<int>(kind),
      'created_at': serializer.toJson<int>(createdAt),
      'inserted_at': serializer.toJson<int>(insertedAt),
      'master_pubkey': serializer.toJson<String>(masterPubkey),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<List<List<String>>>(
        $EventMessagesTableTable.$convertertags.toJson(tags),
      ),
      'sig': serializer.toJson<String?>(sig),
      'id': serializer.toJson<String>(id),
      'pubkey': serializer.toJson<String>(pubkey),
    };
  }

  EventMessageCacheDbModel copyWith({
    String? cacheKey,
    int? kind,
    int? createdAt,
    int? insertedAt,
    String? masterPubkey,
    String? content,
    List<List<String>>? tags,
    Value<String?> sig = const Value.absent(),
    String? id,
    String? pubkey,
  }) => EventMessageCacheDbModel(
    cacheKey: cacheKey ?? this.cacheKey,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    insertedAt: insertedAt ?? this.insertedAt,
    masterPubkey: masterPubkey ?? this.masterPubkey,
    content: content ?? this.content,
    tags: tags ?? this.tags,
    sig: sig.present ? sig.value : this.sig,
    id: id ?? this.id,
    pubkey: pubkey ?? this.pubkey,
  );
  EventMessageCacheDbModel copyWithCompanion(EventMessagesTableCompanion data) {
    return EventMessageCacheDbModel(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      insertedAt: data.insertedAt.present
          ? data.insertedAt.value
          : this.insertedAt,
      masterPubkey: data.masterPubkey.present
          ? data.masterPubkey.value
          : this.masterPubkey,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      sig: data.sig.present ? data.sig.value : this.sig,
      id: data.id.present ? data.id.value : this.id,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventMessageCacheDbModel(')
          ..write('cacheKey: $cacheKey, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('insertedAt: $insertedAt, ')
          ..write('masterPubkey: $masterPubkey, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('sig: $sig, ')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    kind,
    createdAt,
    insertedAt,
    masterPubkey,
    content,
    tags,
    sig,
    id,
    pubkey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventMessageCacheDbModel &&
          other.cacheKey == this.cacheKey &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.insertedAt == this.insertedAt &&
          other.masterPubkey == this.masterPubkey &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.sig == this.sig &&
          other.id == this.id &&
          other.pubkey == this.pubkey);
}

class EventMessagesTableCompanion
    extends UpdateCompanion<EventMessageCacheDbModel> {
  final Value<String> cacheKey;
  final Value<int> kind;
  final Value<int> createdAt;
  final Value<int> insertedAt;
  final Value<String> masterPubkey;
  final Value<String> content;
  final Value<List<List<String>>> tags;
  final Value<String?> sig;
  final Value<String> id;
  final Value<String> pubkey;
  final Value<int> rowid;
  const EventMessagesTableCompanion({
    this.cacheKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.insertedAt = const Value.absent(),
    this.masterPubkey = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.sig = const Value.absent(),
    this.id = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventMessagesTableCompanion.insert({
    required String cacheKey,
    required int kind,
    required int createdAt,
    required int insertedAt,
    required String masterPubkey,
    required String content,
    required List<List<String>> tags,
    this.sig = const Value.absent(),
    required String id,
    required String pubkey,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       kind = Value(kind),
       createdAt = Value(createdAt),
       insertedAt = Value(insertedAt),
       masterPubkey = Value(masterPubkey),
       content = Value(content),
       tags = Value(tags),
       id = Value(id),
       pubkey = Value(pubkey);
  static Insertable<EventMessageCacheDbModel> custom({
    Expression<String>? cacheKey,
    Expression<int>? kind,
    Expression<int>? createdAt,
    Expression<int>? insertedAt,
    Expression<String>? masterPubkey,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<String>? sig,
    Expression<String>? id,
    Expression<String>? pubkey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (insertedAt != null) 'inserted_at': insertedAt,
      if (masterPubkey != null) 'master_pubkey': masterPubkey,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (sig != null) 'sig': sig,
      if (id != null) 'id': id,
      if (pubkey != null) 'pubkey': pubkey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventMessagesTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<int>? kind,
    Value<int>? createdAt,
    Value<int>? insertedAt,
    Value<String>? masterPubkey,
    Value<String>? content,
    Value<List<List<String>>>? tags,
    Value<String?>? sig,
    Value<String>? id,
    Value<String>? pubkey,
    Value<int>? rowid,
  }) {
    return EventMessagesTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      insertedAt: insertedAt ?? this.insertedAt,
      masterPubkey: masterPubkey ?? this.masterPubkey,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      sig: sig ?? this.sig,
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (insertedAt.present) {
      map['inserted_at'] = Variable<int>(insertedAt.value);
    }
    if (masterPubkey.present) {
      map['master_pubkey'] = Variable<String>(masterPubkey.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $EventMessagesTableTable.$convertertags.toSql(tags.value),
      );
    }
    if (sig.present) {
      map['sig'] = Variable<String>(sig.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventMessagesTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('insertedAt: $insertedAt, ')
          ..write('masterPubkey: $masterPubkey, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('sig: $sig, ')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$IONConnectCacheDatabase extends GeneratedDatabase {
  _$IONConnectCacheDatabase(QueryExecutor e) : super(e);
  $IONConnectCacheDatabaseManager get managers =>
      $IONConnectCacheDatabaseManager(this);
  late final $EventMessagesTableTable eventMessagesTable =
      $EventMessagesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [eventMessagesTable];
}

typedef $$EventMessagesTableTableCreateCompanionBuilder =
    EventMessagesTableCompanion Function({
      required String cacheKey,
      required int kind,
      required int createdAt,
      required int insertedAt,
      required String masterPubkey,
      required String content,
      required List<List<String>> tags,
      Value<String?> sig,
      required String id,
      required String pubkey,
      Value<int> rowid,
    });
typedef $$EventMessagesTableTableUpdateCompanionBuilder =
    EventMessagesTableCompanion Function({
      Value<String> cacheKey,
      Value<int> kind,
      Value<int> createdAt,
      Value<int> insertedAt,
      Value<String> masterPubkey,
      Value<String> content,
      Value<List<List<String>>> tags,
      Value<String?> sig,
      Value<String> id,
      Value<String> pubkey,
      Value<int> rowid,
    });

class $$EventMessagesTableTableFilterComposer
    extends Composer<_$IONConnectCacheDatabase, $EventMessagesTableTable> {
  $$EventMessagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get insertedAt => $composableBuilder(
    column: $table.insertedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get masterPubkey => $composableBuilder(
    column: $table.masterPubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<List<String>>, List<List<String>>, String>
  get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sig => $composableBuilder(
    column: $table.sig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventMessagesTableTableOrderingComposer
    extends Composer<_$IONConnectCacheDatabase, $EventMessagesTableTable> {
  $$EventMessagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get insertedAt => $composableBuilder(
    column: $table.insertedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get masterPubkey => $composableBuilder(
    column: $table.masterPubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sig => $composableBuilder(
    column: $table.sig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventMessagesTableTableAnnotationComposer
    extends Composer<_$IONConnectCacheDatabase, $EventMessagesTableTable> {
  $$EventMessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get insertedAt => $composableBuilder(
    column: $table.insertedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get masterPubkey => $composableBuilder(
    column: $table.masterPubkey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<List<String>>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get sig =>
      $composableBuilder(column: $table.sig, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);
}

class $$EventMessagesTableTableTableManager
    extends
        RootTableManager<
          _$IONConnectCacheDatabase,
          $EventMessagesTableTable,
          EventMessageCacheDbModel,
          $$EventMessagesTableTableFilterComposer,
          $$EventMessagesTableTableOrderingComposer,
          $$EventMessagesTableTableAnnotationComposer,
          $$EventMessagesTableTableCreateCompanionBuilder,
          $$EventMessagesTableTableUpdateCompanionBuilder,
          (
            EventMessageCacheDbModel,
            BaseReferences<
              _$IONConnectCacheDatabase,
              $EventMessagesTableTable,
              EventMessageCacheDbModel
            >,
          ),
          EventMessageCacheDbModel,
          PrefetchHooks Function()
        > {
  $$EventMessagesTableTableTableManager(
    _$IONConnectCacheDatabase db,
    $EventMessagesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventMessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventMessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventMessagesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> insertedAt = const Value.absent(),
                Value<String> masterPubkey = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<List<List<String>>> tags = const Value.absent(),
                Value<String?> sig = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> pubkey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventMessagesTableCompanion(
                cacheKey: cacheKey,
                kind: kind,
                createdAt: createdAt,
                insertedAt: insertedAt,
                masterPubkey: masterPubkey,
                content: content,
                tags: tags,
                sig: sig,
                id: id,
                pubkey: pubkey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required int kind,
                required int createdAt,
                required int insertedAt,
                required String masterPubkey,
                required String content,
                required List<List<String>> tags,
                Value<String?> sig = const Value.absent(),
                required String id,
                required String pubkey,
                Value<int> rowid = const Value.absent(),
              }) => EventMessagesTableCompanion.insert(
                cacheKey: cacheKey,
                kind: kind,
                createdAt: createdAt,
                insertedAt: insertedAt,
                masterPubkey: masterPubkey,
                content: content,
                tags: tags,
                sig: sig,
                id: id,
                pubkey: pubkey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventMessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$IONConnectCacheDatabase,
      $EventMessagesTableTable,
      EventMessageCacheDbModel,
      $$EventMessagesTableTableFilterComposer,
      $$EventMessagesTableTableOrderingComposer,
      $$EventMessagesTableTableAnnotationComposer,
      $$EventMessagesTableTableCreateCompanionBuilder,
      $$EventMessagesTableTableUpdateCompanionBuilder,
      (
        EventMessageCacheDbModel,
        BaseReferences<
          _$IONConnectCacheDatabase,
          $EventMessagesTableTable,
          EventMessageCacheDbModel
        >,
      ),
      EventMessageCacheDbModel,
      PrefetchHooks Function()
    >;

class $IONConnectCacheDatabaseManager {
  final _$IONConnectCacheDatabase _db;
  $IONConnectCacheDatabaseManager(this._db);
  $$EventMessagesTableTableTableManager get eventMessagesTable =>
      $$EventMessagesTableTableTableManager(_db, _db.eventMessagesTable);
}
