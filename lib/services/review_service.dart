import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference _reviewsRef(String productId) {
    return _firestore.collection('Reseñas').doc(productId).collection('items');
  }

  Future<List<ReviewModel>> getReviews(String productId) async {
    final snap = await _reviewsRef(productId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  Stream<List<ReviewModel>> watchReviews(String productId) {
    return _reviewsRef(productId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  Future<Map<String, dynamic>> getRatingStats(String productId) async {
    final snap = await _reviewsRef(productId).get();
    final total = snap.docs.length;
    if (total == 0) return {'average': 0.0, 'count': 0};
    final sum = snap.docs.fold<int>(
      0,
      (acc, doc) =>
          acc + ((doc.data() as Map<String, dynamic>)['rating'] as int? ?? 5),
    );
    return {
      'average': sum / total,
      'count': total,
    };
  }

  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final userName = user.displayName ?? user.email ?? 'Usuario';
    await _reviewsRef(productId).add(ReviewModel(
      id: '',
      productId: productId,
      userId: user.uid,
      userName: userName,
      rating: rating.clamp(1, 5),
      comment: comment,
      timestamp: DateTime.now(),
    ).toMap());
  }

  Future<bool> hasUserReviewed(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final snap = await _reviewsRef(productId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
