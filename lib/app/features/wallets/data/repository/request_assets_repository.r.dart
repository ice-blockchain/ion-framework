// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/funds_requests_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_dao.m.dart';
import 'package:ion/app/features/wallets/data/mappers/funds_request_mapper.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'request_assets_repository.r.g.dart';

@Riverpod(keepAlive: true)
RequestAssetsRepository requestAssetsRepository(Ref ref) => RequestAssetsRepository(
      ref.watch(fundsRequestsDaoProvider),
      FundsRequestMapper(),
      ref.watch(transactionsDaoProvider),
    );

class RequestAssetsRepository {
  RequestAssetsRepository(
    this._fundsRequestDao,
    this._mapper,
    this._transactionsDao,
  );

  final FundsRequestsDao _fundsRequestDao;
  final FundsRequestMapper _mapper;
  final TransactionsDao _transactionsDao;

  Future<DateTime?> getLastCreatedAt() => _fundsRequestDao.getLastCreatedAt();

  Future<DateTime?> firstCreatedAt({DateTime? after}) async {
    return _fundsRequestDao.getFirstCreatedAt(after: after);
  }

  Stream<FundsRequestEntity?> watchRequestAssetById(String id) async* {
    final requestStream = _fundsRequestDao.watchFundsRequestById(id);

    final transactionStream =
        requestStream.map((request) => request?.transactionId).whereNotNull().asyncMap(
              (transactionId) => _transactionsDao
                  .getTransactions(txHashes: [transactionId]).then((list) => list.firstOrNull),
            );

    yield* requestStream.combineLatest(
      transactionStream,
      (request, transaction) => request == null ? null : _mapper.toDomain(request, transaction),
    );
  }

  Future<void> saveRequestAsset(FundsRequestEntity entity) async {
    final request = _mapper.toDatabase(entity);
    await _fundsRequestDao.saveFundsRequest(request);
  }

  Future<void> saveRequestAssets(List<FundsRequestEntity> entities) async {
    final requests = _mapper.listToDatabase(entities);
    await _fundsRequestDao.saveFundsRequests(requests);
  }

  Future<bool> markRequestAsPaid(String requestId, String transactionId) {
    return _fundsRequestDao.markRequestAsPaid(requestId, transactionId);
  }

  Future<bool> markRequestAsDeleted(String requestId) {
    return _fundsRequestDao.markRequestAsDeleted(requestId);
  }
}
