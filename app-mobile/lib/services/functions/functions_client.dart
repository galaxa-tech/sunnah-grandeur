import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around FirebaseFunctions.
/// All Cloud Function calls go through here so error handling is centralised.
class FunctionsClient {
  static final FirebaseFunctions _fn = FirebaseFunctions.instance;

  /// Calls a named Cloud Function and returns the response data as a Map.
  /// Throws [FunctionException] on HttpsError or network failure.
  static Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _fn.httpsCallable(name).call(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsClient] $name → ${e.code}: ${e.message}');
      throw FunctionException(code: e.code, message: e.message ?? 'Unknown error');
    } catch (e) {
      debugPrint('[FunctionsClient] $name → unexpected: $e');
      throw FunctionException(code: 'internal', message: e.toString());
    }
  }
}

class FunctionException implements Exception {
  final String code;
  final String message;
  const FunctionException({required this.code, required this.message});

  @override
  String toString() => 'FunctionException($code): $message';
}
