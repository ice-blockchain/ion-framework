// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/static/nsfw_isolate_messages.dart';
import 'package:ion/app/features/nsfw/static/nsfw_isolate_worker.dart';

/// Manages a pool of isolate workers for parallel NSFW detection.
/// This pool creates multiple background isolates
/// and does NSFW detection tasks across them for maximum performance.
class NsfwIsolatePool {
  NsfwIsolatePool._({
    required this.poolSize,
    required this.modelPath,
    required this.blockThreshold,
  });

  final int poolSize;
  final String modelPath;
  final double blockThreshold;

  final List<_WorkerInfo> _workers = [];
  bool _isInitialized = false;
  bool _isShutdown = false;

  int _nextRequestId = 0;
  final Map<String, Completer<NsfwResult>> _pendingRequests = {};

  static Future<NsfwIsolatePool> create({
    required String modelPath,
    required double blockThreshold,
    int? poolSize,
  }) async {
    final effectivePoolSize = poolSize ?? Platform.numberOfProcessors;

    final pool = NsfwIsolatePool._(
      poolSize: effectivePoolSize,
      modelPath: modelPath,
      blockThreshold: blockThreshold,
    );

    await pool._initialize();

    return pool;
  }

  /// Initializes all worker isolates in the pool.
  Future<void> _initialize() async {
    if (_isInitialized) return;

    final workerFutures = <Future<void>>[];

    // Spawn all workers in parallel
    for (var i = 0; i < poolSize; i++) {
      workerFutures.add(_spawnWorker(i));
    }

    // Wait for all workers to initialize
    await Future.wait(workerFutures);

    _isInitialized = true;
  }

  Future<void> _spawnWorker(int workerId) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    final isolate = await Isolate.spawn(
      NsfwIsolateWorker.run,
      receivePort.sendPort,
      debugName: 'NsfwWorker-$workerId',
      onError: errorPort.sendPort,
    );

    final completer = Completer<SendPort>();
    // ignore: cancel_subscriptions
    final subscription = receivePort.listen((message) {
      if (message is SendPort && !completer.isCompleted) {
        completer.complete(message);
      } else if (message is NsfwCheckResponse) {
        _handleResponse(message);
      } else if (message is String) {}
    });

    final workerSendPort = await completer.future;

    // Create worker info
    final worker = _WorkerInfo(
      id: workerId,
      isolate: isolate,
      sendPort: workerSendPort,
      receivePort: receivePort,
      errorPort: errorPort,
      subscription: subscription,
    );

    _workers.add(worker);

    // Listen for errors
    errorPort.listen((dynamic error) {});

    // Initialize the worker
    workerSendPort.send(
      NsfwInitMessage(
        modelPath: modelPath,
        blockThreshold: blockThreshold,
      ),
    );
  }

  /// Processes a single image and returns NSFW result.
  /// This method automatically selects the least busy worker from the pool.
  Future<NsfwResult> checkImage(Uint8List imageBytes) async {
    _ensureNotShutdown();

    final requestId = 'req_${_nextRequestId++}';
    final completer = Completer<NsfwResult>();
    _pendingRequests[requestId] = completer;

    // Select least busy worker and send check request
    final worker = _selectWorker()..incrementLoad();
    worker.sendPort.send(
      NsfwCheckRequest(
        id: requestId,
        imageBytes: imageBytes,
      ),
    );

    try {
      return await completer.future;
    } finally {
      worker.decrementLoad();
      _pendingRequests.remove(requestId);
    }
  }

  /// Processes multiple images in parallel and returns results.
  /// Images are automatically distributed across all workers for maximum performance.
  Future<List<NsfwResult>> checkImages(List<Uint8List> imageBytesList) async {
    _ensureNotShutdown();

    if (imageBytesList.isEmpty) return [];

    // Process all images in parallel
    final futures = imageBytesList.map(checkImage).toList();
    final results = await Future.wait(futures);

    return results;
  }

  /// Handles response from worker isolate.
  void _handleResponse(NsfwCheckResponse response) {
    final completer = _pendingRequests[response.id];
    if (completer == null) return;

    if (response.hasError) {
      completer.completeError(Exception(response.error));
    } else if (response.result != null) {
      completer.complete(response.result!);
    } else {
      completer.completeError(Exception('Invalid response: no result or error'));
    }
  }

  /// Selects the worker with the lowest current load.
  _WorkerInfo _selectWorker() {
    if (_workers.isEmpty) {
      throw StateError('No workers available');
    }

    // Find worker with minimum load
    return _workers.reduce((a, b) => a.currentLoad < b.currentLoad ? a : b);
  }

  /// Ensures pool is not shutdown.
  void _ensureNotShutdown() {
    if (_isShutdown) {
      throw StateError('Pool is shutdown');
    }
    if (!_isInitialized) {
      throw StateError('Pool not initialized');
    }
  }

  /// Shuts down all workers and cleans up resources.
  Future<void> shutdown() async {
    if (_isShutdown) return;

    _isShutdown = true;

    // Send shutdown message to all workers
    for (final worker in _workers) {
      worker.sendPort.send(const NsfwShutdownMessage());
    }

    // Clean up all workers
    for (final worker in _workers) {
      await worker.subscription.cancel();
      worker.receivePort.close();
      worker.errorPort.close();
      worker.isolate.kill(priority: Isolate.immediate);
    }

    _workers.clear();
    _pendingRequests.clear();
  }
}

class _WorkerInfo {
  _WorkerInfo({
    required this.id,
    required this.isolate,
    required this.sendPort,
    required this.receivePort,
    required this.errorPort,
    required this.subscription,
  });

  final int id;
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  final ReceivePort errorPort;
  final StreamSubscription<dynamic> subscription;

  int currentLoad = 0;

  void incrementLoad() => currentLoad++;
  void decrementLoad() => currentLoad = (currentLoad - 1).clamp(0, 99);
}
