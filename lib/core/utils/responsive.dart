
import 'package:flutter/material.dart';

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// Screen breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
}

/// Responsive utility class for handling different screen sizes
class Responsive {
  final BuildContext context;
  late final Size _screenSize;
  late final double _width;
  late final double _height;
  late final DeviceType _deviceType;
  late final Orientation _orientation;

  Responsive(this.context) {
    _screenSize = MediaQuery.of(context).size;
    _width = _screenSize.width;
    _height = _screenSize.height;
    _orientation = MediaQuery.of(context).orientation;
    _deviceType = _getDeviceType();
  }

  // Getters
  Size get screenSize => _screenSize;
  double get width => _width;
  double get height => _height;
  DeviceType get deviceType => _deviceType;
  Orientation get orientation => _orientation;
  bool get isPortrait => _orientation == Orientation.portrait;
  bool get isLandscape => _orientation == Orientation.landscape;

  // Device type checks
  bool get isMobile => _deviceType == DeviceType.mobile;
  bool get isTablet => _deviceType == DeviceType.tablet;
  bool get isDesktop => _deviceType == DeviceType.desktop;
  bool get isMobileOrTablet => isMobile || isTablet;

  // Screen size helpers
  double get safeAreaTop => MediaQuery.of(context).padding.top;
  double get safeAreaBottom => MediaQuery.of(context).padding.bottom;
  double get safeAreaHorizontal => MediaQuery.of(context).padding.horizontal;
  double get statusBarHeight => MediaQuery.of(context).padding.top;
  double get bottomNavHeight => kBottomNavigationBarHeight;

  DeviceType _getDeviceType() {
    if (_width < Breakpoints.mobile) return DeviceType.mobile;
    if (_width < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Responsive value based on device type
  T value<T>({required T mobile, T? tablet, T? desktop}) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Width percentage
  double wp(double percentage) => _width * (percentage / 100);

  /// Height percentage
  double hp(double percentage) => _height * (percentage / 100);

  /// Responsive font size
  double sp(double size) {
    final scale = _width / 375; // Base width (iPhone 11)
    final scaledSize = size * scale;
    return scaledSize.clamp(size * 0.8, size * 1.3);
  }

  /// Responsive spacing/sizing
  double rs(double size) {
    return value(
      mobile: size,
      tablet: size * 1.2,
      desktop: size * 1.4,
    );
  }

  /// Responsive icon size
  double iconSize({double mobile = 24, double? tablet, double? desktop}) {
    return value(mobile: mobile, tablet: tablet ?? mobile * 1.2, desktop: desktop ?? mobile * 1.4);
  }

  /// Grid columns based on screen width
  int get gridColumns {
    if (_width < 600) return 2;
    if (_width < 900) return 3;
    if (_width < 1200) return 4;
    return 6;
  }

  /// Content max width for centered layouts
  double get contentMaxWidth {
    if (isMobile) return _width;
    if (isTablet) return 720;
    return 1140;
  }

  /// Horizontal padding based on device
  double get horizontalPadding {
    return value(mobile: 16.0, tablet: 24.0, desktop: 32.0);
  }

  /// Vertical padding based on device
  double get verticalPadding {
    return value(mobile: 16.0, tablet: 20.0, desktop: 24.0);
  }

  /// Card padding
  EdgeInsets get cardPadding {
    return EdgeInsets.all(value(mobile: 16.0, tablet: 20.0, desktop: 24.0));
  }

  /// Screen padding
  EdgeInsets get screenPadding {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  /// Border radius based on device
  double get borderRadius {
    return value(mobile: 16.0, tablet: 20.0, desktop: 24.0);
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Responsive layout widget with sidebar support
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget? desktopBody;
  final Widget? sidebar;
  final bool showSidebarOnTablet;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    this.desktopBody,
    this.sidebar,
    this.showSidebarOnTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (responsive.isDesktop && sidebar != null) {
      return Row(
        children: [
          SizedBox(width: 280, child: sidebar),
          Expanded(child: desktopBody ?? tabletBody ?? mobileBody),
        ],
      );
    }

    if (responsive.isTablet && showSidebarOnTablet && sidebar != null) {
      return Row(
        children: [
          SizedBox(width: 240, child: sidebar),
          Expanded(child: tabletBody ?? mobileBody),
        ],
      );
    }

    if (responsive.isTablet) {
      return tabletBody ?? mobileBody;
    }

    return mobileBody;
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double childAspectRatio;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final columns = responsive.value(
      mobile: mobileColumns ?? 2,
      tablet: tabletColumns ?? 3,
      desktop: desktopColumns ?? 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
      this.text, {
        super.key,
        required this.fontSize,
        this.fontWeight,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: responsive.sp(fontSize),
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

/// Responsive sized box
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;

  const ResponsiveSizedBox({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return SizedBox(
      width: width != null ? responsive.rs(width!) : null,
      height: height != null ? responsive.rs(height!) : null,
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? all;
  final double? horizontal;
  final double? vertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
    this.all,
    this.horizontal,
    this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    EdgeInsets effectivePadding;
    if (padding != null) {
      effectivePadding = EdgeInsets.only(
        left: responsive.rs(padding!.left),
        right: responsive.rs(padding!.right),
        top: responsive.rs(padding!.top),
        bottom: responsive.rs(padding!.bottom),
      );
    } else if (all != null) {
      effectivePadding = EdgeInsets.all(responsive.rs(all!));
    } else {
      effectivePadding = EdgeInsets.symmetric(
        horizontal: responsive.rs(horizontal ?? 0),
        vertical: responsive.rs(vertical ?? 0),
      );
    }

    return Padding(padding: effectivePadding, child: child);
  }
}

/// Extension for easy access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
}