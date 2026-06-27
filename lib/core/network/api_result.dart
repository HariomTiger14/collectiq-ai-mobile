/// Typed wrapper for API responses.
sealed class ApiResult<T> {
  /// Creates an API result.
  const ApiResult();
}

/// Successful API response with typed data.
class ApiSuccess<T> extends ApiResult<T> {
  /// Creates a successful API result.
  const ApiSuccess(this.data);

  /// Response data.
  final T data;
}

/// Failed API response with a user-safe message.
class ApiFailure<T> extends ApiResult<T> {
  /// Creates a failed API result.
  const ApiFailure({required this.message, this.code});

  /// User-safe failure message.
  final String message;

  /// Optional machine-readable failure code.
  final String? code;
}
