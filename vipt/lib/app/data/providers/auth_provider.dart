import 'package:vipt/app/data/services/api_service.dart';

class AuthProvider {
  // Sign in with email and password using API
  Future<Map<String, dynamic>?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await ApiService.instance.login(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Note: This will need user profile data, should be called from AuthService
      // with full user data
      throw Exception('Use AuthService.register() instead with full user data');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ApiService.instance.logout();
  }

  // Check if user is signed in (check if token exists)
  Future<bool> isSignedIn() async {
    try {
      await ApiService.instance.getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}

