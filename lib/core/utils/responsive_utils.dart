import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  /// Gets the screen scaling factor based on a 390px base width (Figma standard).
  double get scale => (MediaQuery.sizeOf(this).width / 390).clamp(0.85, 1.3);

  /// Scales a numeric value based on the current screen size.
  double s(num value) => value * scale;

  /// Gets the top padding (safe area)
  double get topPadding => MediaQuery.paddingOf(this).top;
  
  /// Gets the bottom padding (safe area)
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
}
