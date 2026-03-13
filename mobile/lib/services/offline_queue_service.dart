import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:safe_alert/models/sos_models.dart';
import 'package:safe_alert/services/api_service.dart';
import 'package:safe_alert/services/storage_service.dart';

class OfflineQueueService {
  final ApiService _apiService;
  final StorageService _storageService;
  StreamSubscription? _connectivitySubscription;

  OfflineQueueService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  void startListening() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _processQueue();
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  Future<void> enqueue(SOSRequest request) async {
    await _storageService.addToOfflineQueue(request.toJson());
  }

  Future<void> _processQueue() async {
    final queue = await _storageService.getOfflineQueue();
    if (queue.isEmpty) return;

    for (int i = 0; i < queue.length; i++) {
      try {
        final request = SOSRequest(
          message: queue[i]['message'],
          latitude: queue[i]['latitude'],
          longitude: queue[i]['longitude'],
          timestamp: queue[i]['timestamp'],
        );
        await _apiService.sendSOS(request);
        await _storageService.removeFromOfflineQueue(0);
      } catch (e) {
        break; // Stop processing if still offline
      }
    }
  }

  Future<bool> hasQueuedItems() async {
    final queue = await _storageService.getOfflineQueue();
    return queue.isNotEmpty;
  }
}
