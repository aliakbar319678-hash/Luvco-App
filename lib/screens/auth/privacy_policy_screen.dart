import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.black,
        title: Text(
          'Privacy Policy',
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
            _sectionTitle('1. Information We Collect'),
            _sectionBody(
              'We collect information you provide when creating an account, such as your name, email address, and dietary preferences. We may also collect usage data to improve the app experience.',
            ),
            _sectionTitle('2. How We Use Your Information'),
            _sectionBody(
              'Your information is used to personalize your experience, provide product recommendations, and improve our services. We do not sell your personal data to third parties.',
            ),
            _sectionTitle('3. Data Storage & Security'),
            _sectionBody(
              'Your data is stored securely using industry-standard encryption. We take reasonable measures to protect your information from unauthorized access, disclosure, or loss.',
            ),
            _sectionTitle('4. Sharing of Information'),
            _sectionBody(
              'We may share anonymized, aggregated data with partners for research or analytics purposes. We will never share your personally identifiable information without your consent, except as required by law.',
            ),
            _sectionTitle('5. Cookies & Tracking'),
            _sectionBody(
              'Luvco may use cookies and similar technologies to enhance your experience and analyze usage patterns. You can control cookie settings through your device preferences.',
            ),
            _sectionTitle('6. Your Rights'),
            _sectionBody(
              'You have the right to access, correct, or delete your personal data at any time. To make such a request, contact us at privacy@luvco.app.',
            ),
            _sectionTitle('7. Children\'s Privacy'),
            _sectionBody(
              'Luvco is not intended for users under the age of 13. We do not knowingly collect personal information from children.',
            ),
            _sectionTitle('8. Changes to This Policy'),
            _sectionBody(
              'We may update this Privacy Policy periodically. We will notify you of significant changes through the app or by email.',
            ),
            _sectionTitle('9. Contact Us'),
            _sectionBody(
              'If you have any questions about this Privacy Policy, please contact us at privacy@luvco.app.',
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
