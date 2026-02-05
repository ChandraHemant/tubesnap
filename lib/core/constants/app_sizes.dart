import 'package:flutter/material.dart';

class AppSizes {
  // Padding & Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;
  static const double padding3XL = 32.0;
  static const double padding4XL = 40.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radius3XL = 32.0;
  static const double radiusFull = 999.0;

  // Icon Sizes
  static const double iconXS = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 40.0;
  static const double icon3XL = 48.0;
  static const double icon4XL = 64.0;

  // Font Sizes
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 18.0;
  static const double fontXXL = 20.0;
  static const double font3XL = 24.0;
  static const double font4XL = 28.0;
  static const double font5XL = 32.0;
  static const double font6XL = 36.0;

  // Button Heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;
  static const double buttonHeightXL = 60.0;

  // Input Heights
  static const double inputHeightS = 40.0;
  static const double inputHeightM = 48.0;
  static const double inputHeightL = 56.0;

  // Card Sizes
  static const double cardElevation = 0.0;
  static const double cardBorderWidth = 1.0;

  // Thumbnail Sizes
  static const double thumbnailS = 60.0;
  static const double thumbnailM = 80.0;
  static const double thumbnailL = 120.0;
  static const double thumbnailXL = 160.0;

  // Bottom Navigation
  static const double bottomNavHeight = 70.0;

  // App Bar
  static const double appBarHeight = 56.0;

  // Divider
  static const double dividerThickness = 1.0;

  // Progress Indicator
  static const double progressHeight = 4.0;
  static const double progressHeightL = 8.0;

  // Border Radius Presets
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusXXL => BorderRadius.circular(radiusXXL);

  // Padding Presets
  static EdgeInsets get paddingAllS => const EdgeInsets.all(paddingS);
  static EdgeInsets get paddingAllM => const EdgeInsets.all(paddingM);
  static EdgeInsets get paddingAllL => const EdgeInsets.all(paddingL);
  static EdgeInsets get paddingAllXL => const EdgeInsets.all(paddingXL);

  static EdgeInsets get paddingHorizontalL => const EdgeInsets.symmetric(horizontal: paddingL);
  static EdgeInsets get paddingVerticalL => const EdgeInsets.symmetric(vertical: paddingL);

  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(
    horizontal: paddingL,
    vertical: paddingL,
  );
}