import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final LocalDatabase _db = LocalDatabase.instance;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;

  // Stream to notify listeners about sync status
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncService._init();

  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      // If we have any connection, attempt to sync
      if (result != ConnectivityResult.none) {
        syncPendingStores();
      }
    });

    // Initial sync attempt
    syncPendingStores();
  }

  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncPendingStores() async {
    if (_isSyncing) return;

    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final pendingStores = await _db.getPendingStores();

      if (pendingStores.isEmpty) {
        _syncStatusController.add(SyncStatus.idle);
        _isSyncing = false;
        return;
      }

      int successCount = 0;
      int failedCount = 0;

      for (final store in pendingStores) {
        try {
          // Prepare data for Supabase
          final storeData = {
            'store_name': store['store_name'],
            'date': store['date'],
            'purchaser_owner': store['purchaser_owner'],
            'contact_number': store['contact_number'],
            'complete_address': store['complete_address'],
            'territory': store['territory'],
            'store_classification': store['store_classification'],
            'tin': store['tin'],
            'payment_term': store['payment_term'],
            'price_level': store['price_level'],
            'agent_code': store['agent_code'],
            'sales_person': store['sales_person'],
            'store_picture_url': store['store_picture_url'],
            'business_permit_url': store['business_permit_url'],
            'map_latitude': store['map_latitude'],
            'map_longitude': store['map_longitude'],
            'agent_id': store['agent_id'],
            'status': 1, // Pending approval
          };

          // Insert to Supabase
          await Supabase.instance.client
              .from('store_information')
              .insert(storeData);

          // Mark as synced
          await _db.updateSyncStatus(store['local_id'], 'synced');
          successCount++;
        } catch (e) {
          // Mark as failed with error message
          await _db.updateSyncStatus(
            store['local_id'],
            'failed',
            errorMessage: e.toString(),
          );
          failedCount++;
        }
      }

      // Optionally clean up synced stores after some time
      // await _db.clearSyncedStores();

      _syncStatusController.add(
        failedCount > 0 ? SyncStatus.error : SyncStatus.success,
      );
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> saveStoreOffline(Map<String, dynamic> storeData) async {
    await _db.insertStore(storeData);

    // Try to sync immediately if online
    if (await hasInternetConnection()) {
      syncPendingStores();
    }
  }

  Future<int> getPendingCount() async {
    return await _db.getPendingCount();
  }

  Future<List<Map<String, dynamic>>> getAllLocalStores() async {
    return await _db.getAllStores();
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

enum SyncStatus { idle, syncing, success, error }
