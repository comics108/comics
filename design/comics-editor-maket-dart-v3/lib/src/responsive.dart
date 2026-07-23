import 'package:flutter/widgets.dart';

/// Adaptive breakpoints — matches the design-system layer:
/// ≤600 phone · 601–1024 tablet (iPad / Android tablet) · ≥1025 desktop/web.
enum FormFactor { phone, tablet, desktop }

FormFactor formFactorOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w <= 600) return FormFactor.phone;
  if (w <= 1024) return FormFactor.tablet;
  return FormFactor.desktop;
}

extension FormFactorX on FormFactor {
  bool get isPhone => this == FormFactor.phone;
  bool get isTablet => this == FormFactor.tablet;
  bool get isDesktop => this == FormFactor.desktop;
  bool get isTouch => this != FormFactor.desktop;

  /// 44–50px touch targets on touch devices, denser on desktop.
  double get controlH => this == FormFactor.desktop ? 38 : 44;
  double get iconBtn => this == FormFactor.desktop ? 32 : 44;
}
