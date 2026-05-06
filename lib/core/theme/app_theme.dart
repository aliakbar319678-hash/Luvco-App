// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'app_colors.dart';

// class AppTheme {
//   AppTheme._();

//   static ThemeData get lightTheme {
//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: const ColorScheme.light(
//         primary: AppColors.royalPurple,
//         secondary: AppColors.vibrantPink,
//         surface: AppColors.pureWhite,
//       ),
//       scaffoldBackgroundColor: AppColors.pureWhite,
//       textTheme: GoogleFonts.poppinsTextTheme(),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: AppColors.inputFill,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 14,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: AppColors.inputBorder),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: AppColors.inputBorder),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(
//             color: AppColors.royalPurple,
//             width: 1.5,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.royalPurple,
        secondary: AppColors.vibrantPink,
        surface: AppColors.pureWhite,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: AppColors.pureWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }
}
