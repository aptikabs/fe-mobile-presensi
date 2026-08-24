class AuthException implements Exception {
  final String message;
  final int? code;

  AuthException(this.message, [this.code]);

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

class DeviceMismatchException extends AuthException {
  final Map<String, dynamic>? data;
  DeviceMismatchException(super.message, {this.data});
}

class UserNotRegisteredException extends AuthException {
  final Map<String, dynamic>? data;
  UserNotRegisteredException(super.message, {this.data});
}

class ContactAdminException extends AuthException {
  ContactAdminException(super.message);
}

// New Exceptions for Change Device
class ChangeDeviceNotAllowedException extends AuthException {
  final String dateAllowed;
  ChangeDeviceNotAllowedException(super.message, this.dateAllowed);
}

class ChangeDeviceFailedException extends AuthException {
  ChangeDeviceFailedException(super.message);
}

class UserBlockedException extends AuthException {
  final Map<String, dynamic>? data;
  UserBlockedException(super.message, {this.data});
}
