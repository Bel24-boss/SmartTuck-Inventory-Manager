import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();

  /// Synchronize a specific table with Firestore
  static Future<void> syncTable(String tableName) async {
    try {
      await pushPendingRecords(tableName);
      await pullRemoteRecords(tableName);
    } catch (e) {
      debugPrint("Error syncing table $tableName: $e");
    }
  }

  /// Synchronize all main tables
  static Future<void> syncAll() async {
    final tables = [
      'products',
      'sales',
      'sale_items',
      'expenses',
      'change_register',
      'cash_operations'
    ];
    for (var table in tables) {
      await syncTable(table);
    }
    debugPrint("Full sync completed.");
  }

  /// Push local records marked as PENDING_SYNC to Firestore
  static Future<void> pushPendingRecords(String tableName) async {
    final db = await DatabaseHelper.instance.database;
    final pendingRecords = await db.query(tableName, where: 'sync_status = ?', whereArgs: ['PENDING_SYNC']);

    for (var record in pendingRecords) {
      final mutableRecord = Map<String, dynamic>.from(record);
      
      // Generate global_id if it doesn't exist
      String? globalId = mutableRecord['global_id'] as String?;
      if (globalId == null || globalId.isEmpty) {
        globalId = _uuid.v4();
        mutableRecord['global_id'] = globalId;
        // Update local DB with the new global_id
        await db.update(tableName, {'global_id': globalId}, where: 'id = ?', whereArgs: [mutableRecord['id']]);
      }

      // Remove the local SQLite auto-increment ID to prevent collisions on other devices
      mutableRecord.remove('id');
      mutableRecord['sync_status'] = 'SYNCED';

      // Push to Firestore
      await _firestore.collection(tableName).doc(globalId).set(mutableRecord, SetOptions(merge: true));

      // Mark local as synced
      await db.update(tableName, {'sync_status': 'SYNCED'}, where: 'global_id = ?', whereArgs: [globalId]);
    }
  }

  /// Pull remote records from Firestore and insert/update local SQLite
  static Future<void> pullRemoteRecords(String tableName) async {
    final db = await DatabaseHelper.instance.database;
    final snapshot = await _firestore.collection(tableName).get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String globalId = doc.id;
      data['global_id'] = globalId;
      data['sync_status'] = 'SYNCED'; // Mark as synced so we don't push it back

      // Check if this record already exists locally
      final existing = await db.query(tableName, where: 'global_id = ?', whereArgs: [globalId]);

      if (existing.isEmpty) {
        // Insert new record from cloud
        await db.insert(tableName, data);
      } else {
        // Update existing local record
        await db.update(tableName, data, where: 'global_id = ?', whereArgs: [globalId]);
      }
    }
  }
}
