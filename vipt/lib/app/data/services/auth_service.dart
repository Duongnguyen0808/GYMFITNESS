import 'package:vipt/app/data/models/vipt_user.dart';
import 'package:vipt/app/data/providers/auth_provider.dart' as vipt_auth;
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/enums/app_enums.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final vipt_auth.AuthProvider _authProvider = vipt_auth.AuthProvider();

  SignInType _loginType = SignInType.none;
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLogin => _currentUser != null;
  SignInType get loginType => _loginType;

  // Setter để cập nhật currentUser từ bên ngoài (ví dụ: sau khi verify OTP)
  void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
    _loginType = SignInType.withEmail;
  }

  Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _loginType = SignInType.withEmail;

    try {
      final result = await _authProvider.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (result != null && result['success'] == true) {
        _currentUser = result['data']?['user'];
        return result['data'];
      } else {
        return (result?['message'] as String?) ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Invalid credentials')) {
        return 'Email hoặc mật khẩu không đúng';
      } else if (errorMsg.contains('chưa được xác thực')) {
        return 'Email chưa được xác thực. Vui lòng đăng ký lại.';
      }
      return errorMsg;
    }
  }

  Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    num? currentWeight,
    num? currentHeight,
    num? goalWeight,
    String? activeFrequency,
    String? weightUnit,
    String? heightUnit,
    Map<String, dynamic>? otherFields,
  }) async {
    _loginType = SignInType.withEmail;

    try {
      final result = await ApiService.instance.register(
        email: email,
        password: password,
        name: name,
        gender: gender,
        dateOfBirth: dateOfBirth,
        currentWeight: currentWeight,
        currentHeight: currentHeight,
        goalWeight: goalWeight,
        activeFrequency: activeFrequency,
        weightUnit: weightUnit,
        heightUnit: heightUnit,
        otherFields: otherFields,
      );

      if (result['success'] == true) {
        _currentUser = result['data']?['user'];
        return result['data'];
      } else {
        return result['message'] as String? ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('already exists') ||
          errorMsg.contains('duplicate')) {
        return 'Email này đã được sử dụng';
      } else if (errorMsg.contains('weak') || errorMsg.contains('password')) {
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      } else if (errorMsg.contains('invalid') && errorMsg.contains('email')) {
        return 'Email không hợp lệ';
      }
      return errorMsg;
    }
  }

  Future<void> signOut() async {
    await _authProvider.signOut();
    _currentUser = null;
  }

  Future<bool> isHasData() async {
    if (_currentUser == null) return false;
    try {
      final userData = await ApiService.instance.getCurrentUser();
      return userData['success'] == true && userData['data'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkIfUserExist(String userId) async {
    try {
      final userData = await ApiService.instance.getUser(userId);
      return userData['success'] == true && userData['data'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<ViPTUser> createViPTUser(ViPTUser user) async {
    // User is created during registration, this is for updating profile
    final userMap = user.toMap();
    userMap.remove('id'); // Remove id, backend will use auth user id

    if (user.id == null) {
      throw Exception('User ID is required');
    }

    final result = await ApiService.instance.updateUser(
      user.id!,
      userMap,
    );

    if (result['success'] == true) {
      return ViPTUser.fromMap(result['data']);
    } else {
      throw Exception(result['message'] ?? 'Failed to create user');
    }
  }

  // Load current user from API (restore session from token)
  Future<void> loadCurrentUser() async {
    try {
      final result = await ApiService.instance.getCurrentUser();
      if (result['success'] == true && result['data'] != null) {
        _currentUser = result['data'];
        // Set login type to email since we're restoring from token (currently only email auth is supported)
        _loginType = SignInType.withEmail;
      } else {
        _currentUser = null;
        _loginType = SignInType.none;
      }
    } catch (e) {
      _currentUser = null;
      _loginType = SignInType.none;
    }
  }
}
