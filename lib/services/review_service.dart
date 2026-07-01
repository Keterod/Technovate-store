import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Duration _timeout = Duration(seconds: 10);
  static const int _reviewLimit = 20;

  CollectionReference _reviewsRef(String productId) {
    return _firestore.collection('Reseñas').doc(productId).collection('items');
  }

  Future<List<ReviewModel>> getReviews(String productId) async {
    try {
      final snap = await _reviewsRef(productId)
          .orderBy('timestamp', descending: true)
          .limit(_reviewLimit)
          .get()
          .timeout(_timeout);
      return snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } on TimeoutException catch (e) {
      debugPrint(
        'DEBUG REVIEW: get reviews timeout productId=$productId error=$e',
      );
      return [];
    } catch (e) {
      debugPrint(
        'DEBUG REVIEW: get reviews error productId=$productId error=$e',
      );
      return [];
    }
  }

  Stream<List<ReviewModel>> watchReviews(String productId) {
    return _reviewsRef(productId)
        .orderBy('timestamp', descending: true)
        .limit(_reviewLimit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList(),
        );
  }

  Future<Map<String, dynamic>> getRatingStats(String productId) async {
    try {
      final snap = await _reviewsRef(productId)
          .orderBy('timestamp', descending: true)
          .limit(_reviewLimit)
          .get()
          .timeout(_timeout);
      final total = snap.docs.length;
      if (total == 0) return {'average': 0.0, 'count': 0};
      final sum = snap.docs.fold<int>(
        0,
        (acc, doc) =>
            acc + ((doc.data() as Map<String, dynamic>)['rating'] as int? ?? 5),
      );
      return {'average': sum / total, 'count': total};
    } on TimeoutException catch (e) {
      debugPrint('DEBUG REVIEW: stats timeout productId=$productId error=$e');
      return {'average': 0.0, 'count': 0};
    } catch (e) {
      debugPrint('DEBUG REVIEW: stats error productId=$productId error=$e');
      return {'average': 0.0, 'count': 0};
    }
  }

  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final userName = user.displayName ?? user.email ?? 'Usuario';
    await _reviewsRef(productId)
        .add(
          ReviewModel(
            id: '',
            productId: productId,
            userId: user.uid,
            userName: userName,
            rating: rating.clamp(1, 5),
            comment: comment,
            timestamp: DateTime.now(),
          ).toMap(),
        )
        .timeout(_timeout);
  }

  Future<bool> hasUserReviewed(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final snap = await _reviewsRef(
        productId,
      ).where('userId', isEqualTo: user.uid).limit(1).get().timeout(_timeout);
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint(
        'DEBUG REVIEW: has user reviewed error productId=$productId error=$e',
      );
      return false;
    }
  }
}
