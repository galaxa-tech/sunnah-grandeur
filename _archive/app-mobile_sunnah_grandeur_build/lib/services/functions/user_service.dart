import 'functions_client.dart';

/// All user profile mutations go through Cloud Functions.
/// Direct Firestore reads of /users/{uid} are still done in AuthProvider
/// because Firestore rules allow owner reads and the data is non-sensitive.
class UserService {
  /// Called once after Firebase Auth registration.
  /// Sets role: 'user' server-side — never trust the client for this.
  static Future<void> createUserMetadata({
    required String name,
    required String email,
    String phone = '',
  }) async {
    await FunctionsClient.call('createUserMetadata', {
      'name':  name,
      'email': email,
      'phone': phone,
    });
  }

  /// Whitelisted update — only name and phone.
  /// Email changes must go through FirebaseAuth.updateEmail separately.
  static Future<void> updateUserProfile({
    String? name,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    if (name  != null) data['name']  = name;
    if (phone != null) data['phone'] = phone;
    if (data.isEmpty) return;

    await FunctionsClient.call('updateUserProfile', data);
  }

  /// Deletes Firestore profile + Firebase Auth account in one server-side call.
  static Future<void> deleteAccount() async {
    await FunctionsClient.call('deleteAccount', {});
  }
}
