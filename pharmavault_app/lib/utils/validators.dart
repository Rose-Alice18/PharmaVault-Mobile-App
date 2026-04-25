import 'package:flutter/services.dart';

/// Centralised input validation and sanitization for PharmaVault.
///
/// Usage:
///   validator: AppValidators.email
///   inputFormatters: AppFormatters.name
class AppValidators {
  AppValidators._();

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required.';
    final s = v.trim();
    if (s.length < 2)  return 'Name must be at least 2 characters.';
    if (s.length > 60) return 'Name must not exceed 60 characters.';
    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(s)) {
      return 'Name can only contain letters, spaces, hyphens or apostrophes.';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required.';
    final s = v.trim();
    if (s.length > 100) return 'Email address is too long.';
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(s)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 8)  return 'Password must be at least 8 characters.';
    if (v.length > 64) return 'Password is too long.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Password must contain at least one letter.';
    if (!RegExp(r'[0-9]').hasMatch(v))    return 'Password must contain at least one number.';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required.';
    final digits = v.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return 'Phone number must contain only digits.';
    if (digits.length < 9)  return 'Phone number is too short.';
    if (digits.length > 15) return 'Phone number is too long.';
    return null;
  }

  static String? city(String? v) {
    if (v == null || v.trim().isEmpty) return 'City is required.';
    final s = v.trim();
    if (s.length < 2)  return 'City name is too short.';
    if (s.length > 50) return 'City name is too long.';
    if (!RegExp(r"^[a-zA-Z\s\-]+$").hasMatch(s)) {
      return 'City can only contain letters and spaces.';
    }
    return null;
  }

  static String? address(String? v) {
    if (v == null || v.trim().isEmpty) return 'Address is required.';
    final s = v.trim();
    if (s.length < 5)   return 'Please enter a complete address.';
    if (s.length > 150) return 'Address is too long (max 150 characters).';
    return null;
  }

  static String? Function(String?) required(String label) =>
      (String? v) => (v == null || v.trim().isEmpty) ? '$label is required.' : null;

  /// Removes characters that could be used for injection attacks.
  static String sanitize(String v) =>
      v.trim().replaceAll(RegExp(r'''[<>"'`;\\]'''), '');

  /// Sanitizes and truncates a search query.
  static String sanitizeSearch(String v) {
    final clean = sanitize(v);
    return clean.length > 100 ? clean.substring(0, 100) : clean;
  }
}

/// Ready-made input formatter lists to pass to TextFormField.inputFormatters.
class AppFormatters {
  AppFormatters._();

  static List<TextInputFormatter> get name => [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-'\.]")),
    LengthLimitingTextInputFormatter(60),
  ];

  static List<TextInputFormatter> get email => [
    FilteringTextInputFormatter.deny(RegExp(r'\s')), // no spaces in email
    LengthLimitingTextInputFormatter(100),
  ];

  static List<TextInputFormatter> get password => [
    LengthLimitingTextInputFormatter(64),
  ];

  static List<TextInputFormatter> get phone => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
    LengthLimitingTextInputFormatter(16),
  ];

  static List<TextInputFormatter> get city => [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
    LengthLimitingTextInputFormatter(50),
  ];

  static List<TextInputFormatter> get address => [
    LengthLimitingTextInputFormatter(150),
  ];

  static List<TextInputFormatter> get search => [
    FilteringTextInputFormatter.deny(RegExp(r'''[<>"'`;\\]''')),
    LengthLimitingTextInputFormatter(100),
  ];

  static List<TextInputFormatter> get positiveInt => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];

  static List<TextInputFormatter> get price => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    LengthLimitingTextInputFormatter(8),
  ];
}
