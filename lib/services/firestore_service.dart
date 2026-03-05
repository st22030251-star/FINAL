import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Note>> getNotes(bool isPrivate, String userId) {
    return _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('isPrivate', isEqualTo: isPrivate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addNote(String content, bool isPrivate, String userId, {DateTime? date}) {
    return _db.collection('notes').add({
      'content': content,
      'isPrivate': isPrivate,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'date': Timestamp.fromDate(date ?? DateTime.now()),
    });
  }

  Future<void> deleteNote(String id) {
    return _db.collection('notes').doc(id).delete();
  }
}
