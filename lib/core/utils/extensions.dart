import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Extensions for the String type
extension StringExtensions on String {
  /// Capitalizes the first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Checks if the string is a valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    ).hasMatch(this);
  }

  /// Checks if the string is a valid phone number
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-\.]'), '');
    return RegExp(r'^(?:(?:\+|00)33|0)[1-9](?:[0-9]{8})$').hasMatch(cleaned);
  }

  /// Masks part of the string (for email, phone, etc.)
  String mask(
      {int visibleStart = 3, int visibleEnd = 3, String maskChar = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;

    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final masked = maskChar * (length - visibleStart - visibleEnd);

    return '$start$masked$end';
  }

  /// Truncates the string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Removes multiple spaces and trims
  String get cleanSpaces {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Converts to slug (URL-friendly)
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[òóôõö]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll(RegExp('[ýÿ]'), 'y')
        .replaceAll(RegExp('[ñ]'), 'n')
        .replaceAll(RegExp('[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp('-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Safely parses to int
  int? toIntOrNull() => int.tryParse(this);

  /// Safely parses to double
  double? toDoubleOrNull() => double.tryParse(this);
}

/// Extensions for nullable String type
extension NullableStringExtensions on String? {
  /// Returns true if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Returns the value or a default string
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}

/// Extensions for DateTime
extension DateTimeExtensions on DateTime {
  /// Formats as French date (dd/MM/yyyy)
  String get toFrenchDate {
    return DateFormat(AppConstants.dateFormat, 'fr_FR').format(this);
  }

  /// Formats as time (HH:mm)
  String get toTime {
    return DateFormat(AppConstants.timeFormat).format(this);
  }

  /// Formats as date and time
  String get toDateTime {
    return DateFormat(AppConstants.dateTimeFormat, 'fr_FR').format(this);
  }

  /// Formats for the API
  String get toApiFormat {
    return DateFormat(AppConstants.apiDateTimeFormat).format(toUtc());
  }

  /// Formats as relative time (X minutes ago, etc.)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Il y a $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Il y a $hours heure${hours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Il y a $days jour${days > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Checks if it's today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if it's yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Checks if it's this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Start of the day
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of the day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Start of the month
  DateTime get startOfMonth => DateTime(year, month);

  /// End of the month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
}

/// Extensions for numbers
extension NumExtensions on num {
  /// Formats as currency (EUR)
  String get toCurrency {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(this);
  }

  /// Formats with thousands separators
  String get toFormatted {
    return NumberFormat('#,###', 'fr_FR').format(this);
  }

  /// Formats as percentage
  String get toPercent {
    return '${toStringAsFixed(1)}%';
  }

  /// Formats as kilometers
  String get toKilometers {
    return '$toFormatted km';
  }

  /// Formats as liters
  String get toLiters {
    return '${toStringAsFixed(1)} L';
  }

  /// Converts to Duration
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
  Duration get hours => Duration(hours: toInt());
  Duration get days => Duration(days: toInt());
}

/// Extensions for lists
extension ListExtensions<T> on List<T> {
  /// Returns the first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Returns the last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Splits the list into chunks
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// Removes duplicates while preserving order
  List<T> distinct() {
    return toSet().toList();
  }
}

/// Extensions for BuildContext
extension ContextExtensions on BuildContext {
  /// Shortcuts for MediaQuery
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Checks the screen type
  bool get isMobile => screenWidth < AppConstants.mobileBreakpoint;
  bool get isTablet =>
      screenWidth >= AppConstants.mobileBreakpoint &&
      screenWidth < AppConstants.desktopBreakpoint;
  bool get isDesktop => screenWidth >= AppConstants.desktopBreakpoint;

  /// Shortcuts for the theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  /// Displays a SnackBar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Displays an error SnackBar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.error,
    );
  }

  /// Displays a success SnackBar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
    );
  }

  // ─── Helpers responsive ────────────────────────────────────────────────────

  /// Padding horizontal adaptatif : 16 (mobile) → 24 (tablet) → 32 (desktop)
  double get responsiveHorizontalPadding {
    if (isDesktop) return AppSpacing.xl;
    if (isTablet) return AppSpacing.lg;
    return AppSpacing.md;
  }

  /// Padding standard adaptatif : 12 (mobile) → 16 (tablet) → 24 (desktop)
  double get responsivePadding {
    if (isDesktop) return AppSpacing.lg;
    if (isTablet) return AppSpacing.md;
    return AppSpacing.sm + AppSpacing.xs; // 12
  }

  /// Facteur de scale typographique : 1.0 (mobile) → 1.05 (tablet) → 1.1 (desktop)
  double get responsiveFontScale {
    if (isDesktop) return 1.1;
    if (isTablet) return 1.05;
    return 1.0;
  }

  /// Taille d'icône adaptée au breakpoint à partir d'une taille de base.
  ///
  /// Exemple : `context.responsiveIconSize(24)` → 24 / 26 / 28
  double responsiveIconSize(double baseSize) {
    if (isDesktop) return baseSize * 1.15;
    if (isTablet) return baseSize * 1.08;
    return baseSize;
  }

  /// Nombre de colonnes adapté au breakpoint.
  ///
  /// Exemple : `context.responsiveColumns()` → 1 / 2 / 3
  int responsiveColumns({int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  /// Retourne une valeur typée selon le breakpoint.
  ///
  /// Exemple : `context.rv<double>(mobile: 16, tablet: 24, desktop: 32)`
  T rv<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Retourne un TextStyle avec la fontSize scalée selon le breakpoint.
  TextStyle scaledTextStyle(TextStyle base) {
    final scaled = (base.fontSize ?? 14) * responsiveFontScale;
    return base.copyWith(fontSize: scaled);
  }
}

/// Extensions for Duration
extension DurationExtensions on Duration {
  /// Formats as hours and minutes
  String get toHoursMinutes {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    }
    return '${minutes}min';
  }

  /// Formats in a compact manner
  String get compact {
    if (inDays > 0) return '${inDays}j';
    if (inHours > 0) return '${inHours}h';
    if (inMinutes > 0) return '${inMinutes}m';
    return '${inSeconds}s';
  }
}
