import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Widget affichant un layout différent selon le breakpoint.
///
/// Utilisation :
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),    // optionnel, fallback sur mobile
///   desktop: DesktopView(),  // optionnel, fallback sur tablet puis mobile
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= AppConstants.desktopBreakpoint && desktop != null) {
          return desktop!;
        }
        if (width >= AppConstants.mobileBreakpoint && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Retourne une valeur typée selon le breakpoint actuel.
///
/// Utilisation :
/// ```dart
/// final columns = responsiveValue<int>(context, mobile: 1, tablet: 2, desktop: 3);
/// final padding = responsiveValue<double>(context, mobile: 16, tablet: 24, desktop: 32);
/// ```
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= AppConstants.desktopBreakpoint && desktop != null) return desktop as T;
  if (width >= AppConstants.mobileBreakpoint && tablet != null) return tablet as T;
  return mobile;
}

/// Grid responsive : retourne le nombre de colonnes adapté à l'écran.
///
/// Utilisation :
/// ```dart
/// GridView.count(crossAxisCount: responsiveColumns(context))
/// ```
int responsiveColumns(
  BuildContext context, {
  int mobile = 1,
  int tablet = 2,
  int desktop = 3,
}) {
  return responsiveValue<int>(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}

/// Builder responsive avec accès aux contraintes et au breakpoint courant.
///
/// Utilisation :
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, sizingInfo) {
///     if (sizingInfo.isDesktop) return DesktopLayout();
///     return MobileLayout();
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, SizingInformation sizingInfo) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizingInfo = SizingInformation(
          screenSize: MediaQuery.of(context).size,
          localWidgetSize: Size(constraints.maxWidth, constraints.maxHeight),
        );
        return builder(context, sizingInfo);
      },
    );
  }
}

/// Informations de taille passées au ResponsiveBuilder.
class SizingInformation {
  const SizingInformation({
    required this.screenSize,
    required this.localWidgetSize,
  });

  final Size screenSize;
  final Size localWidgetSize;

  double get screenWidth => screenSize.width;
  double get localWidth => localWidgetSize.width;

  bool get isMobile => screenWidth < AppConstants.mobileBreakpoint;
  bool get isTablet =>
      screenWidth >= AppConstants.mobileBreakpoint &&
      screenWidth < AppConstants.desktopBreakpoint;
  bool get isDesktop => screenWidth >= AppConstants.desktopBreakpoint;
}
