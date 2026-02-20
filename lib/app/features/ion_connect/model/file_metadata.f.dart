// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'file_metadata.f.freezed.dart';

@Freezed(equal: false)
class FileMetadataEntity
    with _$FileMetadataEntity, IonConnectEntity, ImmutableEntity, CacheableEntity
    implements EntityEventSerializable {
  const factory FileMetadataEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required FileMetadata data,
    EventMessage? eventMessage,
  }) = _FileMetadataEntity;

  const FileMetadataEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/94.md
  factory FileMetadataEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return FileMetadataEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: FileMetadata.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 1063;

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);
}

@freezed
class FileMetadata with _$FileMetadata implements EventSerializable {
  const factory FileMetadata({
    required String url,
    required String mimeType,
    required String fileHash,
    required String originalFileHash,
    required String torrentInfoHash,
    @Default('') String caption,
    int? size,
    String? dimension,
    String? magnet,
    String? blurhash,
    String? thumb,
    String? image,
    String? summary,
    String? alt,
    String? originalMimeType,
  }) = _FileMetadata;

  factory FileMetadata.fromUploadResponseTags(
    List<List<String>> tags, {
    String? mimeType,
    String? originalMimeType,
  }) {
    final values = tags.fold(<String, String>{}, (res, tags) {
      return {...res, tags[0]: tags[1]};
    });

    // Only "url" and "ox" are required
    // https://github.com/nostr-protocol/nips/blob/master/96.md#response-codes
    return FileMetadata(
      url: values['url']!,
      mimeType: values['m'] ?? mimeType ?? '',
      fileHash: values['x'] ?? values['ox']!,
      originalFileHash: values['ox']!,
      size: values['size'] != null ? int.parse(values['size']!) : null,
      dimension: values['dim'],
      magnet: values['magnet'],
      torrentInfoHash: values['i']!,
      blurhash: values['blurhash'],
      thumb: values['thumb'],
      image: values['image'],
      summary: values['summary'],
      alt: values['alt'],
      originalMimeType: values['om'] ?? originalMimeType,
    );
  }

  factory FileMetadata.fromEventMessage(EventMessage eventMessage) {
    String? url;
    String? mimeType;
    String? fileHash;
    String? originalFileHash;
    int? size;
    String? dimension;
    String? magnet;
    String? torrentInfoHash;
    String? blurhash;
    String? thumb;
    String? image;
    String? summary;
    String? alt;
    String? originalMimeType;

    for (final tag in eventMessage.tags) {
      switch (tag[0]) {
        case 'url':
          url = tag[1];
        case 'm':
          mimeType = tag[1];
        case 'x':
          fileHash = tag[1];
        case 'ox':
          originalFileHash = tag[1];
        case 'size':
          size = int.tryParse(tag[1]);
        case 'dim':
          dimension = tag[1];
        case 'magnet':
          magnet = tag[1];
        case 'i':
          torrentInfoHash = tag[1];
        case 'blurhash':
          blurhash = tag[1];
        case 'thumb':
          thumb = tag[1];
        case 'image':
          image = tag[1];
        case 'summary':
          summary = tag[1];
        case 'alt':
          alt = tag[1];
        case 'om':
          originalMimeType = tag[1];
      }
    }

    if (url == null ||
        mimeType == null ||
        fileHash == null ||
        originalFileHash == null ||
        torrentInfoHash == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return FileMetadata(
      url: url,
      mimeType: mimeType,
      fileHash: fileHash,
      originalFileHash: originalFileHash,
      caption: eventMessage.id,
      size: size,
      dimension: dimension,
      magnet: magnet,
      torrentInfoHash: torrentInfoHash,
      blurhash: blurhash,
      thumb: thumb,
      image: image,
      summary: summary,
      alt: alt,
      originalMimeType: originalMimeType,
    );
  }

  const FileMetadata._();

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: FileMetadataEntity.kind,
      tags: [
        ...tags,
        ['url', url],
        ['m', mimeType],
        ['x', fileHash],
        ['ox', originalFileHash],
        if (size != null) ['size', size.toString()],
        if (dimension != null) ['dim', dimension!],
        if (magnet != null) ['magnet', magnet!],
        ['i', torrentInfoHash],
        if (blurhash != null) ['blurhash', blurhash!],
        if (thumb != null) ['thumb', thumb!],
        if (image != null) ['image', image!],
        if (summary != null) ['summary', summary!],
        if (alt != null) ['alt', alt!],
        if (originalMimeType != null) ['om', originalMimeType!],
      ],
      content: caption,
    );
  }
}
