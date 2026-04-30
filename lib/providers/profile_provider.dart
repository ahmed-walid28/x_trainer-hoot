import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    } catch (e) {
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
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
