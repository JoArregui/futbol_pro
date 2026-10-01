// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatRoomIsarCollection on Isar {
  IsarCollection<ChatRoomIsar> get chatRoomIsars => this.collection();
}

const ChatRoomIsarSchema = CollectionSchema(
  name: r'ChatRoomIsar',
  id: 8836662456861686332,
  properties: {
    r'avatarUrl': PropertySchema(
      id: 0,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'isMuted': PropertySchema(id: 1, name: r'isMuted', type: IsarType.bool),
    r'isPinned': PropertySchema(id: 2, name: r'isPinned', type: IsarType.bool),
    r'lastActive': PropertySchema(
      id: 3,
      name: r'lastActive',
      type: IsarType.dateTime,
    ),
    r'lastMessageJson': PropertySchema(
      id: 4,
      name: r'lastMessageJson',
      type: IsarType.string,
    ),
    r'memberIds': PropertySchema(
      id: 5,
      name: r'memberIds',
      type: IsarType.stringList,
    ),
    r'ownerId': PropertySchema(id: 6, name: r'ownerId', type: IsarType.string),
    r'relatedEntityId': PropertySchema(
      id: 7,
      name: r'relatedEntityId',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 8,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 9, name: r'title', type: IsarType.string),
    r'type': PropertySchema(id: 10, name: r'type', type: IsarType.string),
    r'unreadCount': PropertySchema(
      id: 11,
      name: r'unreadCount',
      type: IsarType.long,
    ),
  },
  estimateSize: _chatRoomIsarEstimateSize,
  serialize: _chatRoomIsarSerialize,
  deserialize: _chatRoomIsarDeserialize,
  deserializeProp: _chatRoomIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteId': IndexSchema(
      id: 6301175856541681032,
      name: r'remoteId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'remoteId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'ownerId': IndexSchema(
      id: -7594796109721319539,
      name: r'ownerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _chatRoomIsarGetId,
  getLinks: _chatRoomIsarGetLinks,
  attach: _chatRoomIsarAttach,
  version: '3.1.0+1',
);

int _chatRoomIsarEstimateSize(
  ChatRoomIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastMessageJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.memberIds.length * 3;
  {
    for (var i = 0; i < object.memberIds.length; i++) {
      final value = object.memberIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.ownerId.length * 3;
  {
    final value = object.relatedEntityId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.remoteId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _chatRoomIsarSerialize(
  ChatRoomIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarUrl);
  writer.writeBool(offsets[1], object.isMuted);
  writer.writeBool(offsets[2], object.isPinned);
  writer.writeDateTime(offsets[3], object.lastActive);
  writer.writeString(offsets[4], object.lastMessageJson);
  writer.writeStringList(offsets[5], object.memberIds);
  writer.writeString(offsets[6], object.ownerId);
  writer.writeString(offsets[7], object.relatedEntityId);
  writer.writeString(offsets[8], object.remoteId);
  writer.writeString(offsets[9], object.title);
  writer.writeString(offsets[10], object.type);
  writer.writeLong(offsets[11], object.unreadCount);
}

ChatRoomIsar _chatRoomIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ChatRoomIsar();
  object.avatarUrl = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.isMuted = reader.readBool(offsets[1]);
  object.isPinned = reader.readBool(offsets[2]);
  object.lastActive = reader.readDateTimeOrNull(offsets[3]);
  object.lastMessageJson = reader.readStringOrNull(offsets[4]);
  object.memberIds = reader.readStringList(offsets[5]) ?? [];
  object.ownerId = reader.readString(offsets[6]);
  object.relatedEntityId = reader.readStringOrNull(offsets[7]);
  object.remoteId = reader.readString(offsets[8]);
  object.title = reader.readString(offsets[9]);
  object.type = reader.readString(offsets[10]);
  object.unreadCount = reader.readLong(offsets[11]);
  return object;
}

P _chatRoomIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatRoomIsarGetId(ChatRoomIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _chatRoomIsarGetLinks(ChatRoomIsar object) {
  return [];
}

void _chatRoomIsarAttach(
  IsarCollection<dynamic> col,
  Id id,
  ChatRoomIsar object,
) {
  object.id = id;
}

extension ChatRoomIsarByIndex on IsarCollection<ChatRoomIsar> {
  Future<ChatRoomIsar?> getByRemoteId(String remoteId) {
    return getByIndex(r'remoteId', [remoteId]);
  }

  ChatRoomIsar? getByRemoteIdSync(String remoteId) {
    return getByIndexSync(r'remoteId', [remoteId]);
  }

  Future<bool> deleteByRemoteId(String remoteId) {
    return deleteByIndex(r'remoteId', [remoteId]);
  }

  bool deleteByRemoteIdSync(String remoteId) {
    return deleteByIndexSync(r'remoteId', [remoteId]);
  }

  Future<List<ChatRoomIsar?>> getAllByRemoteId(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'remoteId', values);
  }

  List<ChatRoomIsar?> getAllByRemoteIdSync(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'remoteId', values);
  }

  Future<int> deleteAllByRemoteId(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'remoteId', values);
  }

  int deleteAllByRemoteIdSync(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'remoteId', values);
  }

  Future<Id> putByRemoteId(ChatRoomIsar object) {
    return putByIndex(r'remoteId', object);
  }

  Id putByRemoteIdSync(ChatRoomIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'remoteId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteId(List<ChatRoomIsar> objects) {
    return putAllByIndex(r'remoteId', objects);
  }

  List<Id> putAllByRemoteIdSync(
    List<ChatRoomIsar> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'remoteId', objects, saveLinks: saveLinks);
  }
}

extension ChatRoomIsarQueryWhereSort
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QWhere> {
  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatRoomIsarQueryWhere
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QWhereClause> {
  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> remoteIdEqualTo(
    String remoteId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remoteId', value: [remoteId]),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause>
  remoteIdNotEqualTo(String remoteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [],
                upper: [remoteId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [remoteId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [remoteId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [],
                upper: [remoteId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> ownerIdEqualTo(
    String ownerId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'ownerId', value: [ownerId]),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterWhereClause> ownerIdNotEqualTo(
    String ownerId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ChatRoomIsarQueryFilter
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QFilterCondition> {
  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'avatarUrl'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'avatarUrl'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'avatarUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'avatarUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'avatarUrl', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'avatarUrl', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  isMutedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMuted', value: value),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isPinned', value: value),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastActiveIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastActive'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastActiveIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastActive'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastActiveEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastActive', value: value),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastActiveGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastActive',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastActiveLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastActive',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastActiveBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastActive',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastMessageJson'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastMessageJson'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastMessageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastMessageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastMessageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastMessageJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastMessageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastMessageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastMessageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastMessageJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastMessageJson', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  lastMessageJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastMessageJson', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'memberIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'memberIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'memberIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'memberIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'memberIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'memberIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'memberIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'memberIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'memberIds', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'memberIds', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'memberIds', length, true, length, true);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'memberIds', 0, true, 0, true);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'memberIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'memberIds', 0, true, length, include);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'memberIds', length, include, 999999, true);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  memberIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memberIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'relatedEntityId'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'relatedEntityId'),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'relatedEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'relatedEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'relatedEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'relatedEntityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'relatedEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'relatedEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'relatedEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'relatedEntityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relatedEntityId', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  relatedEntityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'relatedEntityId', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteId', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteId', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> typeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition> typeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  unreadCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unreadCount', value: value),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  unreadCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unreadCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  unreadCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unreadCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterFilterCondition>
  unreadCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unreadCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ChatRoomIsarQueryObject
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QFilterCondition> {}

extension ChatRoomIsarQueryLinks
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QFilterCondition> {}

extension ChatRoomIsarQuerySortBy
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QSortBy> {
  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByIsMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMuted', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByIsMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMuted', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByLastActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActive', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  sortByLastActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActive', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  sortByLastMessageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageJson', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  sortByLastMessageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageJson', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  sortByRelatedEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedEntityId', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  sortByRelatedEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedEntityId', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> sortByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  sortByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }
}

extension ChatRoomIsarQuerySortThenBy
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QSortThenBy> {
  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByIsMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMuted', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByIsMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMuted', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByLastActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActive', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  thenByLastActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActive', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  thenByLastMessageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageJson', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  thenByLastMessageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageJson', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  thenByRelatedEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedEntityId', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  thenByRelatedEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedEntityId', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy> thenByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QAfterSortBy>
  thenByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }
}

extension ChatRoomIsarQueryWhereDistinct
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> {
  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByAvatarUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByIsMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMuted');
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByLastActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastActive');
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct>
  distinctByLastMessageJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastMessageJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByMemberIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memberIds');
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByOwnerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct>
  distinctByRelatedEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'relatedEntityId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByRemoteId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatRoomIsar, ChatRoomIsar, QDistinct> distinctByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unreadCount');
    });
  }
}

extension ChatRoomIsarQueryProperty
    on QueryBuilder<ChatRoomIsar, ChatRoomIsar, QQueryProperty> {
  QueryBuilder<ChatRoomIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ChatRoomIsar, String?, QQueryOperations> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarUrl');
    });
  }

  QueryBuilder<ChatRoomIsar, bool, QQueryOperations> isMutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMuted');
    });
  }

  QueryBuilder<ChatRoomIsar, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<ChatRoomIsar, DateTime?, QQueryOperations> lastActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastActive');
    });
  }

  QueryBuilder<ChatRoomIsar, String?, QQueryOperations>
  lastMessageJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageJson');
    });
  }

  QueryBuilder<ChatRoomIsar, List<String>, QQueryOperations>
  memberIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memberIds');
    });
  }

  QueryBuilder<ChatRoomIsar, String, QQueryOperations> ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<ChatRoomIsar, String?, QQueryOperations>
  relatedEntityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relatedEntityId');
    });
  }

  QueryBuilder<ChatRoomIsar, String, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<ChatRoomIsar, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ChatRoomIsar, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<ChatRoomIsar, int, QQueryOperations> unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unreadCount');
    });
  }
}
