import 'package:cloud_firestore/cloud_firestore.dart';

class ConceptService {
  static Future<void> saveConcepts({
    required String classId,
    required List<String> concepts,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('concepts');

    for (int i = 0; i < concepts.length; i++) {
      final doc = ref.doc();
      await doc.set({
        'conceptId': doc.id,
        'name': concepts[i],
        'order': i + 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}


// class ConceptService {
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> saveConcepts({
//     required String classId,
//     required List<String> concepts,
//   }) async {
//     final ref = _firestore
//         .collection('classes')
//         .doc(classId)
//         .collection('concepts');
//
//     final existing = await ref.limit(1).get();
//     if(existing.docs.isNotEmpty){
//       return;
//     }
//
//     final batch = _firestore.batch();
//
//     for (int i = 0; i < concepts.length; i++) {
//       final doc = ref.doc();
//         batch.set(doc, {
//         'conceptId': doc.id,
//         'name': concepts[i],
//         'order': i + 1,
//         'createdAt': FieldValue.serverTimestamp(),
//           'quizGenerated' : false,
//       });
//     }
//     await batch.commit();
//   }
// }
