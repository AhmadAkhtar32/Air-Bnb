import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(fullName);

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'createdAt': DateTime.now(),
          'isHost': false,
          'profileImageUrl': '',
        });

        return user;
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (fullName != null) {
        updateData['fullName'] = fullName;
      }
      if (email != null) {
        updateData['email'] = email;
      }
      if (phoneNumber != null) {
        updateData['phoneNumber'] = phoneNumber;
      }
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      updateData['updatedAt'] = DateTime.now();

      await _firestore.collection('users').doc(uid).update(updateData);

      if (fullName != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(fullName);
      }

      print('User profile updated successfully');
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  Future<void> updateProfileImage({
    required String uid,
    required String profileImageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': profileImageUrl,
        'updatedAt': DateTime.now(),
      });
      print('Profile image updated successfully');
    } catch (e) {
      print('Update profile image error: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    });
  }

  Future<void> saveBooking({
    required String userId,
    required String propertyTitle,
    required String price,
    required int stayDays,
    required String imageUrl,
    required String description,
    required String totalCost,
  }) async {
    try {
      String bookingId = _firestore.collection('bookings').doc().id;

      await _firestore.collection('bookings').doc(bookingId).set({
        'bookingId': bookingId,
        'userId': userId,
        'propertyTitle': propertyTitle,
        'price': price,
        'stayDays': stayDays,
        'imageUrl': imageUrl,
        'description': description,
        'totalCost': totalCost,
        'bookingDate': DateTime.now(),
        'status': 'confirmed',
        'checkIn': DateTime.now().add(const Duration(days: 1)),
        'checkOut': DateTime.now().add(Duration(days: stayDays + 1)),
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingId)
          .set({
        'bookingId': bookingId,
        'propertyTitle': propertyTitle,
        'price': price,
        'stayDays': stayDays,
        'imageUrl': imageUrl,
        'description': description,
        'totalCost': totalCost,
        'bookingDate': DateTime.now(),
        'status': 'confirmed',
        'checkIn': DateTime.now().add(const Duration(days: 1)),
        'checkOut': DateTime.now().add(Duration(days: stayDays + 1)),
      });

      print('Booking saved successfully with ID: $bookingId');
    } catch (e) {
      print('Save booking error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .orderBy('bookingDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Get user bookings error: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  Future<void> cancelBooking(String userId, String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now(),
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now(),
      });

      print('Booking cancelled successfully');
    } catch (e) {
      print('Cancel booking error: $e');
      rethrow;
    }
  }
}
