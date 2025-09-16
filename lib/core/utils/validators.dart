// lib/core/utils/validators.dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }

    value = value.trim();

    if (value.isEmpty) {
      return 'Email address cannot be empty';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    if (value.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 128) {
      return 'Password is too long (max 128 characters)';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    value = value.trim();

    if (value.isEmpty) {
      return 'Name cannot be empty';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name is too long (max 50 characters)';
    }

    final nameRegex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and periods';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    value = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (value.isEmpty) {
      return 'Phone number cannot be empty';
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    if (value.length < 10) {
      return 'Phone number is too short';
    }

    if (value.length > 15) {
      return 'Phone number is too long';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }

    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    value = value.trim();

    if (value.isEmpty) {
      return 'URL cannot be empty';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  static String? validateNumeric(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Numeric value is required';
    }

    final numericValue = int.tryParse(value);
    if (numericValue == null) {
      return 'Please enter a valid number';
    }

    if (min != null && numericValue < min) {
      return 'Value must be at least $min';
    }

    if (max != null && numericValue > max) {
      return 'Value must be at most $max';
    }

    return null;
  }

  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }

    if (minLength != null && value.length < minLength) {
      return '${fieldName ?? 'Field'} must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be at most $maxLength characters';
    }

    return null;
  }

  static String? validateAlphanumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    value = value.trim();

    if (value.isEmpty) {
      return '$fieldName cannot be empty';
    }

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return '$fieldName can only contain letters and numbers';
    }

    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  static String? validateIPAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'IP address is required';
    }

    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipRegex.hasMatch(value)) {
      return 'Please enter a valid IP address';
    }

    return null;
  }

  static String? validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Port number is required';
    }

    final port = int.tryParse(value);
    if (port == null) {
      return 'Port must be a number';
    }

    if (port < 1 || port > 65535) {
      return 'Port must be between 1 and 65535';
    }

    return null;
  }

  static String? validateDeviceId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device ID is required';
    }

    value = value.trim();

    if (value.isEmpty) {
      return 'Device ID cannot be empty';
    }

    if (value.length < 8) {
      return 'Device ID is too short';
    }

    if (value.length > 64) {
      return 'Device ID is too long';
    }

    final deviceIdRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
    if (!deviceIdRegex.hasMatch(value)) {
      return 'Device ID can only contain letters, numbers, hyphens, and underscores';
    }

    return null;
  }
}
