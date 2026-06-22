import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.black,
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1. Acceptance of Terms'),
            _sectionBody(
              'By creating an account and using Luvco, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our service.',
            ),
            _sectionTitle('2. Use of the Service'),
            _sectionBody(
              'Luvco is designed to help you make healthier, more sustainable food choices. You agree to use the app only for lawful purposes and in a way that does not infringe the rights of others.',
            ),
            _sectionTitle('3. Account Responsibility'),
            _sectionBody(
              'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.',
            ),
            _sectionTitle('4. Product & Nutrition Information'),
            _sectionBody(
              'The nutritional and sustainability data provided in Luvco is sourced from third-party databases and is for informational purposes only. Always consult a qualified health professional before making dietary changes.',
            ),
            _sectionTitle('5. Intellectual Property'),
            _sectionBody(
              'All content, trademarks, and data within the Luvco app are the property of Luvco and may not be reproduced or used without prior written permission.',
            ),
            _sectionTitle('6. Limitation of Liability'),
            _sectionBody(
              'Luvco shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the app or inability to access it.',
            ),
            _sectionTitle('7. Changes to Terms'),
            _sectionBody(
              'We may update these Terms from time to time. Continued use of Luvco after changes constitutes your acceptance of the new Terms.',
            ),
            _sectionTitle('8. Contact Us'),
            _sectionBody(
              'If you have any questions about these Terms, please contact us at support@luvco.app.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      );

  Widget _sectionBody(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.darkGrey,
          height: 1.6,
        ),
      );
}
