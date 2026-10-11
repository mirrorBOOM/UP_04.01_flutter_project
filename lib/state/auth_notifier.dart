import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Role {
  client(1, 'Клиент'),
  trainer(2, 'Тренер'),
  admin(3, 'Администратор');

  final int level;
  final String label;
  const Role(this.level, this.label);

  static Role fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'admin' => Role.admin,
      'trainer' => Role.trainer,
      _ => Role.client,
    };
  }
}

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': role.name,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    username: json['username'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    role: Role.fromString(json['role'] as String?),
  );
}

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'pb_access_token';
  static const _kUser = 'pb_user_data';
  static const _kSessionStart = 'pb_session_start_time';
  static const _kUsersDb = 'pb_registered_users_database_v3';
  static const int _maxSessionDurationMs = 2 * 60 * 60 * 1000;

  final SharedPreferences _prefs;
  AppUser? _user;
  String? _accessToken;
  bool _isInitialized = false;

  List<Map<String, dynamic>> _usersDatabase = [
    {'id': 'usr_admin', 'username': 'admin', 'pass': 'Admin@123', 'name': 'Главный Администратор', 'role': 'admin'},
    {'id': 'usr_trainer', 'username': 'trainer', 'pass': 'Trainer@123', 'name': 'Александр Ковалёв', 'role': 'trainer'},
    {'id': 'usr_client', 'username': 'client', 'pass': 'Client@123', 'name': 'Иван Иванов', 'role': 'client'},
  ];

  AuthNotifier(this._prefs) {
    _loadUsersDatabase();
  }

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get allUsers => List.unmodifiable(_usersDatabase);

  bool hasRole(Role role) => _user != null && _user!.role.level >= role.level;

  void _loadUsersDatabase() {
    final raw = _prefs.getString(_kUsersDb);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _usersDatabase = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
  }

  Future<void> _saveUsersDatabase() async {
    await _prefs.setString(_kUsersDb, jsonEncode(_usersDatabase));
  }

  Future<void> restore() async {
    _accessToken = _prefs.getString(_kAccess);
    final userRaw = _prefs.getString(_kUser);
    final sessionStartTime = _prefs.getInt(_kSessionStart) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (sessionStartTime > 0 && (now - sessionStartTime > _maxSessionDurationMs)) {
      await logout();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    if (_accessToken != null && userRaw != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      } catch (_) {
        await logout();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _loadUsersDatabase();
    final inputUser = username.trim().toLowerCase();

    final matched = _usersDatabase.firstWhere(
      (u) => (u['username'] ?? '').toString().toLowerCase() == inputUser && u['pass'] == password,
      orElse: () => {},
    );

    if (matched.isNotEmpty) {
      final role = Role.fromString(matched['role'] as String?);
      _user = AppUser(
        id: matched['id'] as String? ?? 'usr_$inputUser',
        username: matched['username'] as String,
        fullName: matched['name'] as String,
        role: role,
      );
      _accessToken = 'pb_token_${role.name}_${DateTime.now().millisecondsSinceEpoch}';

      final now = DateTime.now().millisecondsSinceEpoch;
      await _prefs.setString(_kAccess, _accessToken!);
      await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
      await _prefs.setInt(_kSessionStart, now);

      notifyListeners();
      return;
    }

    throw Exception('Неверный логин или пароль');
  }

  Future<void> register(String username, String fullName, String password, Role role) async {
    _loadUsersDatabase();
    final cleanUsername = username.trim().toLowerCase();

    final exists = _usersDatabase.any(
      (u) => (u['username'] ?? '').toString().toLowerCase() == cleanUsername,
    );
    if (exists) {
      throw Exception('Логин "$username" уже занят. Придумайте другой.');
    }

    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final newUserMap = {
      'id': newId,
      'username': username.trim(),
      'name': fullName.trim(),
      'pass': password,
      'role': role.name,
    };

    _usersDatabase.add(newUserMap);
    await _saveUsersDatabase();

    _user = AppUser(
      id: newId,
      username: username.trim(),
      fullName: fullName.trim(),
      role: role,
    );
    _accessToken = 'pb_token_${role.name}_${DateTime.now().millisecondsSinceEpoch}';

    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    await _prefs.setInt(_kSessionStart, now);

    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kSessionStart);
    notifyListeners();
  }
}