import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Note: Google Sign-In disabled on Web due to People API requirement
// Use Email/Password or run on Android/iOS instead

class ProfileProvider with ChangeNotifier {
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // بيانات البروفايل
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _height = '';
  String _weight = '';
  String _age = '';
  String _goal = '';
  String _gender = '';
  String _profileImageUrl = '';

  // Getters
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get height => _height;
  String get weight => _weight;
  String get age => _age;
  String get goal => _goal;
  String get gender => _gender;
  String get fullName => '$_firstName $_lastName';
  String get profileImageUrl => _profileImageUrl;

  ProfileProvider() {
    _initAuth();
  }

  void _initAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      print('👤 Auth state changed: ${user?.email ?? "No user"}');
      _currentUser = user;
      if (user != null) {
        await loadUserProfile();
      } else {
        _clearProfile();
      }
      notifyListeners();
    });
  }

  Future<void> loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _setLoading(true);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _firstName = (data['firstName'] ?? '') as String;
        _lastName = (data['lastName'] ?? '') as String;
        _email = (data['email'] ?? '') as String;
        _height = (data['height'] ?? '') as String;
        _weight = (data['weight'] ?? '') as String;
        _age = (data['age'] ?? '') as String;
        _goal = (data['goal'] ?? '') as String;
        _gender = (data['gender'] ?? '') as String;
        _profileImageUrl = (data['profileImageUrl'] ?? '') as String;
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await FirebaseAuth.instance.signOut();
      _currentUser = null;
      _clearProfile();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      notifyListeners();

      print('Starting Google Sign-In...');

      // On Web, Google Sign-In requires People API which needs billing
      // Show error and suggest alternative
      if (kIsWeb) {
        _setLoading(false);
        _errorMessage = 'Google Sign-In is disabled on Web. Please use Email/Password or run the app on Android/iOS. To enable Google Sign-In on Web, you need to enable People API in Google Cloud Console (requires billing).';
        notifyListeners();
        throw Exception(_errorMessage!);
      }

      // For mobile (Android/iOS), use Firebase's built-in Google Sign-In
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithProvider(googleProvider);

      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      final User? user = userCredential.user;

      if (user != null) {
        print('Firebase sign-in successful: ${user.uid}');
        _currentUser = user;

        if (isNewUser) {
          print('Creating new user in Firestore...');
          final nameParts = user.displayName?.split(' ') ?? ['', ''];
          final firstName = nameParts.first;
          final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'firstName': firstName,
            'lastName': lastName,
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'profileCompleted': false,
          });

          print('New user created in Firestore');
        } else {
          print('Existing user signed in');
        }

        await loadUserProfile();
        _setLoading(false);
        notifyListeners();
        print('Google Sign-In complete, isNewUser: $isNewUser');
        return isNewUser;
      }

      _setLoading(false);
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      _setLoading(false);
      _errorMessage = e.message ?? 'Google sign-in failed';
      notifyListeners();
      rethrow;
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _clearProfile() {
    _firstName = '';
    _lastName = '';
    _email = '';
    _height = '';
    _weight = '';
    _age = '';
    _goal = '';
    _gender = '';
    _profileImageUrl = '';
  }

  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String height,
    required String weight,
    required String age,
    required String gender,
    required String goal,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _setLoading(true);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'height': height,
        'weight': weight,
        'age': age,
        'gender': gender,
        'goal': goal,
      }, SetOptions(merge: true));

      _firstName = firstName;
      _lastName = lastName;
      _email = email;
      _height = height;
      _weight = weight;
      _age = age;
      _gender = gender;
      _goal = goal;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      _setLoading(true);
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('ERROR: User is null');
        _setLoading(false);
        return null;
      }

      print('Starting image upload for user: ${user.uid}');

      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      String downloadUrl;

      // Upload file - use putData for web, putFile for mobile
      if (kIsWeb) {
        print('Reading image bytes for web...');
        final bytes = await imageFile.readAsBytes();
        print('Image size: ${bytes.length} bytes');

        print('Starting upload to Firebase Storage...');
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Listen to upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('Upload progress: ${progress.toStringAsFixed(1)}%');
        });

        final snapshot = await uploadTask;
        print('Upload completed!');

        downloadUrl = await snapshot.ref.getDownloadURL();
        print('Got download URL: $downloadUrl');
      } else {
        print('Uploading file from path: ${imageFile.path}');
        final file = File(imageFile.path);
        final uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('Upload progress: ${progress.toStringAsFixed(1)}%');
        });

        final snapshot = await uploadTask;
        print('Upload completed!');

        downloadUrl = await snapshot.ref.getDownloadURL();
        print('Got download URL: $downloadUrl');
      }

      // Update Firestore with new image URL
      print('Updating Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': downloadUrl});
      print('Firestore updated!');

      _profileImageUrl = downloadUrl;
      _setLoading(false);
      notifyListeners();
      print('Upload complete! URL: $downloadUrl');
      return _profileImageUrl;
    } catch (e, stackTrace) {
      print('ERROR uploading image: $e');
      print('Stack trace: $stackTrace');
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
