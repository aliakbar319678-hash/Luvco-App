import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum LuvcoLogoColor { white, pink }

class LuvcoLogo extends StatelessWidget {
  final double width;
  final LuvcoLogoColor color;

  const LuvcoLogo({
    super.key,
    required this.width,
    this.color = LuvcoLogoColor.white,
  });

  String get _assetPath {
    switch (color) {
      case LuvcoLogoColor.white:
        return 'assets/images/luvco_logo_white.svg';
      case LuvcoLogoColor.pink:
        return 'assets/images/luvco_logo_pink.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(_assetPath, width: width, fit: BoxFit.contain);
  }
}
