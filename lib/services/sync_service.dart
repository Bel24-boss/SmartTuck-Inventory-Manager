import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Writes data to Firestore. The native SDK automatically caches this if offline
  /// and synchronizes it flawlessly when connectivity returns.
  static void write(String collectionName, String globalId, Map<String, dynamic> data) {
    _firestore.collection(collectionName).doc(globalId).set(data, SetOptions(merge: true));
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
           String tableName = collectionName == 'inventory' ? 'products' : 
                              collectionName == 'transactions' ? 'sales' : collectionName;
                              
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
}
