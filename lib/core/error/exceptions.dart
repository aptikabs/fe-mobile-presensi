class ServerException implements Exception {
  final String message;

  ServerException({this.message = 'Server Error'});
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

/// Types of network errors that can occur.
enum NetworkErrorType {
  /// No internet connection available.
  noConnection,

  /// The request timed out.
  timeout,

  /// An unknown network error occurred.
  unknown,
}

/// Exception thrown when a network error occurs during API calls.
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;

  NetworkException({
    required this.type,
    String? message,
  }) : message = message ?? _defaultMessage(type);

  static String _defaultMessage(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return 'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.';
      case NetworkErrorType.timeout:
        return 'Koneksi timeout. Server mungkin sibuk, coba beberapa saat lagi.';
      case NetworkErrorType.unknown:
        return 'Terjadi gangguan jaringan. Silakan coba lagi.';
    }
  }

  @override
  String toString() => 'NetworkException: $message (type: $type)';
}
