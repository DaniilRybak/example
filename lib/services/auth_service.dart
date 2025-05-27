import 'package:flutter/material.dart';
import 'package:yandex_mapkit_example/models/models.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  List<User> _users = [];
  bool _isSignedIn = false;
  bool _isAdmin = false;

  Future<bool> signIn(String email, String password) async {
    if (email == 'user@test.com' && password == 'test123') {
      _currentUser = testUser;
      _isSignedIn = true;
      _isAdmin = false;
      notifyListeners();
      return true;
    }

    if (email == 'admin@test.com' && password == 'test123') {
      _currentUser = testAdmin;
      _isSignedIn = true;
      _isAdmin = true;
      notifyListeners();
      return true;
    }

    await Future.delayed(const Duration(seconds: 1));
    final user = _users.firstWhere(
      (u) => u.email == email && password == '${u.role}123',
      orElse: () => User.empty(),
    );

    if (user.id.isNotEmpty) {
      _currentUser = user;
      _isSignedIn = true;
      _isAdmin = user.role == 'admin';
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> registerCompany(String name, String email, String password, String companyName) async {
    await Future.delayed(const Duration(seconds: 1));
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: name,
      email: email,
      role: 'admin',
      company: Company(id: '1', name: companyName),
      status: 'active',
      stats: UserStats(containersCollected: 0, kilometersDriven: 0, rating: 0),
    );
    
    _users.add(newUser);
    _currentUser = newUser;
    _isSignedIn = true;
    _isAdmin = true;
    notifyListeners();
    return true;
  }

  Future<List<User>> getCompanyUsers() async {
    await Future.delayed(const Duration(seconds: 1));
    return _users.where((u) => u.company?.id == _currentUser?.company?.id).toList();
  }

  Future<void> deleteUser(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  Future<void> addUser(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _users.add(User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: name,
      email: email,
      role: 'user',
      company: _currentUser?.company,
      status: 'active',
      stats: UserStats(containersCollected: 0, kilometersDriven: 0, rating: 0),
    ));
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    _isSignedIn = false;
    _isAdmin = false;
    notifyListeners();
  }

  bool get isAdmin => _isAdmin;
  bool get isSignedIn => _isSignedIn;
  User? get currentUser => _currentUser;
}