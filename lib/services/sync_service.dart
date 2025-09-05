import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';

/// Optional Firebase sync + shared lists. App works without this.
class SyncService {
  static bool enabled = false; // toggled in Settings
  static String? listId;

  static Future<void> ensureSignedInAnonymously() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  static CollectionReference<Map<String,dynamic>> _col(String uid, String listId) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('lists').doc(listId).collection('items');

  static Future<void> pushAll(List<ItemModel> items) async {
    if (!enabled) return;
    await ensureSignedInAnonymously();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final col = _col(uid, listId ?? 'default');
    final batch = FirebaseFirestore.instance.batch();
    for (final it in items) {
      batch.set(col.doc(it.id), it.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Stream<List<ItemModel>> stream() async* {
    if (!enabled) {
      yield [];
      return;
    }
    await ensureSignedInAnonymously();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    yield* _col(uid, listId ?? 'default').snapshots().map((snap) =>
        snap.docs.map((d) => ItemModel.fromJson(d.data())).toList());
  }
}
