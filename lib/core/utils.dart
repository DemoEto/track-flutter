// Utility functions

import 'package:intl/intl.dart';

class DateTimeUtils {
  // Format date for display
  static String formatDisplayDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date and time for display
  static String formatDisplayDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Format time for display
  static String formatDisplayTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Check if a date is today
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.day == today.day && date.month == today.month && date.year == today.year;
  }

  // Check if a date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Check if a date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }
}

class ValidationUtils {
  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, with at least one letter and one number
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // Validate phone number format
  static bool isValidPhone(String phone) {
    // Basic phone validation (adjust as needed)
    final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{0,15}$');
    return phoneRegex.hasMatch(phone);
  }
}

class StringUtils {
  // Capitalize first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Convert a string to title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
