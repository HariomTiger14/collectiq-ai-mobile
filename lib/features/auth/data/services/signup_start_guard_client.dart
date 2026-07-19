import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final signupStartGuardClientProvider = Provider<SignupStartGuardClient>((ref) {
  return HttpSignupStartGuardClient(apiClient: ref.watch(apiClientProvider));
});

abstract interface class SignupStartGuardClient {
  Future<SignupStartGuardResult> start({required String email});
}

class SignupStartGuardResult {
  const SignupStartGuardResult({
    required this.safeForAccountCreation,
    this.cooldownRemaining = const Duration(seconds: 30),
  });

  final bool safeForAccountCreation;
  final Duration cooldownRemaining;
}

class HttpSignupStartGuardClient implements SignupStartGuardClient {
  const HttpSignupStartGuardClient({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<SignupStartGuardResult> start({required String email}) async {
    try {
      final response = await apiClient.post(
        ApiConstants.authSignupStartPath,
        data: {'email': email.trim().toLowerCase()},
      );
      final body = response.data;
      if (body is! Map) {
        throw const AuthException('Network connection failed.');
      }
      return SignupStartGuardResult(
        safeForAccountCreation: body['safeForAccountCreation'] == true,
        cooldownRemaining: Duration(
          seconds: _intFrom(body['cooldownSeconds'], fallback: 30),
        ),
      );
    } on NetworkException catch (error) {
      if (error.statusCode == 429) {
        throw const AuthException('Too many signup start requests.');
      }
      throw const AuthException('Network connection failed.');
    }
  }

  int _intFrom(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }
}
