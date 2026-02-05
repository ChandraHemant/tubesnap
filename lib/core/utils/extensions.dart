import 'package:flutter/material.dart';

/// String Extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Capitalize each word
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');

  /// Check if string is a valid email
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Check if string is a valid URL
  bool get isValidUrl => Uri.tryParse(this)?.hasAbsolutePath ?? false;

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Convert to slug format
  String get toSlug => toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

/// Number Extensions
extension NumberExtensions on num {
  /// Format as currency (INR)
  String get toINR => '₹${toStringAsFixed(2).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
  )}';

  /// Format as percentage
  String get toPercent => '${(this * 100).toStringAsFixed(1)}%';

  /// Convert bytes to readable size
  String get toFileSize {
    if (this < 1024) return '${toInt()} B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// DateTime Extensions
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Format as readable date
  String get toReadableDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return '$day/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Format as readable time
  String get toReadableTime {
    final hour = this.hour > 12 ? this.hour - 12 : this.hour;
    final period = this.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Format as full readable datetime
  String get toFullReadable => '$toReadableDate at $toReadableTime';
}

/// Duration Extensions
extension DurationExtensions on Duration {
  /// Format duration to MM:SS or HH:MM:SS
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Context Extensions
extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Pop navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);

  /// Push replacement
  Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushReplacementNamed<T, TO>(routeName, arguments: arguments);

  /// Hide keyboard
  void hideKeyboard() => FocusScope.of(this).unfocus();
}

/// List Extensions
extension ListExtensions<T> on List<T> {
  /// Get element at index or null
  T? getOrNull(int index) => index >= 0 && index < length ? this[index] : null;

  /// Separate list into chunks
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

/// Widget Extensions
extension WidgetExtensions on Widget {
  /// Add padding
  Widget withPadding(EdgeInsetsGeometry padding) => Padding(padding: padding, child: this);

  /// Add margin
  Widget withMargin(EdgeInsetsGeometry margin) => Container(margin: margin, child: this);

  /// Make widget expanded
  Widget get expanded => Expanded(child: this);

  /// Make widget flexible
  Widget get flexible => Flexible(child: this);

  /// Center widget
  Widget get centered => Center(child: this);

  /// Add tap gesture
  Widget onTap(VoidCallback onTap) => GestureDetector(onTap: onTap, child: this);

  /// Add opacity
  Widget withOpacity(double opacity) => Opacity(opacity: opacity, child: this);

  /// Add visibility
  Widget visible(bool isVisible) => Visibility(visible: isVisible, child: this);
}