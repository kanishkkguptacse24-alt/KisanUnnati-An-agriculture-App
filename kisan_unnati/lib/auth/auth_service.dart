import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to register a new user
  Future<String> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String address,
    String? aadhar, // Optional
  }) async {
    try {
      // 1. Check if Phone Number already exists
      var phoneCheck = await _firestore.collection('users').where('phone', isEqualTo: phone).get();
      if (phoneCheck.docs.isNotEmpty) {
        return "This Phone Number is already registered.";
      }

      // 2. Check if Aadhar already exists (if they provided one)
      if (aadhar != null && aadhar.trim().isNotEmpty) {
        var aadharCheck = await _firestore.collection('users').where('aadhar', isEqualTo: aadhar).get();
        if (aadharCheck.docs.isNotEmpty) {
          return "This Aadhar Number is already registered.";
        }
      }

      // 3. Create the account securely in Firebase Authentication
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Save their full profile in the Firestore Database
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'aadhar': aadhar ?? "Not Provided",
        'role': role, // Kisan, Vyapari, or Grahak
        'createdAt': DateTime.now(),
      });

      return "Success";
    } on FirebaseAuthException catch (e) {
      // Handle Firebase errors (like weak password or bad email format)
      if (e.code == 'email-already-in-use') {
        return "This Email is already registered.";
      } else if (e.code == 'weak-password') {
        return "The password is too weak.";
      }
      return e.message ?? "An unknown error occurred.";
    } catch (e) {
      return e.toString();
    }
  }
  // Function to Login
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "Invalid Email or Password.";
      }
      return e.message ?? "An unknown error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Function to get the User's Role from Firestore
  Future<String> getUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snap = await _firestore.collection('users').doc(user.uid).get();
        return snap['role'] ?? 'Kisan'; // Default to Kisan just in case
      }
    } catch (e) {
      print("Error getting role: $e");
    }
    return 'Kisan';
  }
  Future<DocumentSnapshot> getUserProfile() async {
    User? user = _auth.currentUser;
    return await _firestore.collection('users').doc(user!.uid).get();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
