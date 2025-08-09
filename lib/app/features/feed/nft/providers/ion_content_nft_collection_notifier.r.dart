// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/nft/model/nft_collection_data.f.dart';
import 'package:ion/app/features/feed/nft/sync/nft_collection_sync_controller.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_content_nft_collection_notifier.r.g.dart';

@riverpod
class IonContentNftCollectionNotifier extends _$IonContentNftCollectionNotifier {
  @override
  void build() {}

  Future<void> updateUserMetadata(NftCollectionData data) async {
    final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
    if (currentUserMetadata == null) {
      throw CurrentUserMetadataNotFoundException();
    }

    final newCollection = IonContentNftCollection(
      createdBy: data.creatorAddress,
      address: data.collectionAddress,
    );

    final updatedMetadata = currentUserMetadata.data.copyWith(
      ionContentNftCollections: {
        ...currentUserMetadata.data.ionContentNftCollections ?? {},
        data.name: newCollection,
      },
    );

    await ref.read(updateUserMetadataNotifierProvider.notifier).publish(updatedMetadata);
    ref.invalidate(hasIonContentNftCollectionProvider);
  }
}
