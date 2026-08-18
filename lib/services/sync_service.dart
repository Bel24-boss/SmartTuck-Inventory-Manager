import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process the local sync queue and push events to Firestore
  static Future<void> processSyncQueue() async {
    final db = await DatabaseHelper.instance.database;
    
    // Get all pending operations
    final pendingOps = await db.query('sync_queue', where: 'syncStatus = ?', whereArgs: ['PENDING'], orderBy: 'id ASC');
    
    for (var op in pendingOps) {
      final String operationId = op['operationId'] as String;
      final String type = op['type'] as String;
      final String collection = op['collection_name'] as String;
      final Map<String, dynamic> data = jsonDecode(op['data'] as String);
      
      try {
        final globalId = data['global_id'] ?? data['id'].toString(); // fallback to local id if global_id not generated yet
        
        if (type == 'INSERT' || type == 'UPDATE') {
          // Push to Firestore using the global ID
          await _firestore.collection(collection).doc(globalId).set(data, SetOptions(merge: true));
        } else if (type == 'DELETE') {
          await _firestore.collection(collection).doc(globalId).delete();
        }
        
        // Acknowledge and mark synchronized
        await db.update('sync_queue', {'syncStatus': 'SYNCED'}, where: 'operationId = ?', whereArgs: [operationId]);
        
      } catch (e) {
        debugPrint("Error syncing operation $operationId: $e");
        // We break the loop because order matters in a queue. If one fails, we stop and retry next time.
        break; 
      }
    }
  }

  /// Listen for remote changes on specific collections to pull data down
  static void listenToRemoteChanges(String collectionName) {
    _firestore.collection(collectionName).snapshots().listen((snapshot) async {
      final db = await DatabaseHelper.instance.database;
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        
        final globalId = data['global_id'] ?? change.doc.id;
        
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
           // We need to map 'inventory' to 'products' table etc.
           String tableName = collectionName == 'inventory' ? 'products' : 
                              collectionName == 'transactions' ? 'sales' : collectionName;
                              
           // Check if it exists
           final existing = await db.query(tableName, where: 'global_id = ?', whereArgs: [globalId]);
           
           if (existing.isEmpty) {
              await db.insert(tableName, data);
           } else {
              await db.update(tableName, data, where: 'global_id = ?', whereArgs: [globalId]);
           }
        }
      }
    });
  }

  static Future<void> syncAll() async {
    await processSyncQueue();
  }
}
