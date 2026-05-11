import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/help_support_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────
// Help & Support Screen
// Frames: 1.6.19 / 1.6.20 / 1.6.21 / 1.6.22
// ─────────────────────────────────────────────────────────────────
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  // ── Demo content ──────────────────────────────────────────────
  static const _policyTitle = '1. Duis maximus enim ut massa bibendum dignissim.';
  static const _policyBody =
      'In malesuada convallis leo. Maecenas ut malesuada risus, '
      'ut fermentum erat. Ut porta neque in mauris auctor pretium. '
      'Duis lacinia eros non velit blandit, at venenatis quam varius. '
      'Praesent sit amet arcu ac ipsum vestibulum ornare. Proin in '
      'eleifend massa. Duis tempor urna rhoncus orci vestibulum rutrum. '
      'Nullam rhoncus, lectus eu rhoncus auctor, nisi ipsum luctus nisl, '
      'nec mollis libero justo id nibh.\n\n'
      'Aenean non tincidunt ligula. Sed consequat sodales dui, id commodo '
      'lectus. Nam enim ipsum, ultrices vel bibendum vel, pretium in augue. '
      'Fusce imperdiet est rutrum ante consectetur ullamcorper. Fusce '
      'imperdiet aliquet nunc, vel facilisis odio ornare a. Donec est tellus, '
      'bibendum ut mollis a, molestie ut magna.\n\n'
      'Suspendisse at efficitur diam. Vivamus sit amet suscipit lacus, ac '
      'consectetur arcu. In venenatis augue diam, quis convallis lacus iaculis at.';

  static const _termsTitle = '1. Duis maximus enim ut massa bibendum dignissim.';
  static const _termsBody =
      'In malesuada convallis leo. Maecenas ut malesuada risus, '
      'ut fermentum erat. Ut porta neque in mauris auctor pretium. '
      'Duis lacinia eros non velit blandit, at venenatis quam varius. '
      'Praesent sit amet arcu ac ipsum vestibulum ornare. Proin in '
      'eleifend massa. Duis tempor urna rhoncus orci vestibulum rutrum. '
      'Nullam rhoncus, lectus eu rhoncus auctor, nisi ipsum luctus nisl, '
      'nec mollis libero justo id nibh.\n\n'
      'Aenean non tincidunt ligula. Sed consequat sodales dui, id commodo '
      'lectus. Nam enim ipsum, ultrices vel bibendum vel, pretium in augue. '
      'Fusce imperdiet est rutrum ante consectetur ullamcorper.';

  static const _faqItems = [
    _FaqItem(
      question: '1. How do you...?',
      answer:
          'In malesuada convallis leo. Maecenas ut malesuada risus, ut '
          'fermentum erat. Ut porta neque in mauris auctor pretium.',
    ),
    _FaqItem(
      question: '2. How do you...?',
      answer:
          'Praesent sit amet arcu ac ipsum vestibulum ornare. Proin in '
          'eleifend massa. Duis tempor urna rhoncus orci vestibulum rutrum.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(helpSupportProvider);
    final notifier = ref.read(helpSupportProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _HelpHeader(padding: padding, scale: scale, size: size),

            // ── Scrollable body ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.058,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // ── Privacy Policy ──────────────────────────
                    _SectionCard(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      isExpanded:
                          state.expandedSection == HelpSection.privacyPolicy,
                      onToggle: () =>
                          notifier.toggleSection(HelpSection.privacyPolicy),
                      expandedContent: _PolicyContent(
                        title: _policyTitle,
                        body: _policyBody,
                        scale: scale,
                      ),
                      scale: scale,
                    ),

                    const SizedBox(height: 12),

                    // ── Terms & Conditions ──────────────────────
                    _SectionCard(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      isExpanded:
                          state.expandedSection ==
                          HelpSection.termsAndConditions,
                      onToggle: () => notifier.toggleSection(
                        HelpSection.termsAndConditions,
                      ),
                      expandedContent: _PolicyContent(
                        title: _termsTitle,
                        body: _termsBody,
                        scale: scale,
                      ),
                      scale: scale,
                    ),

                    const SizedBox(height: 12),

                    // ── FAQ's ───────────────────────────────────
                    _SectionCard(
                      icon: Icons.chat_outlined,
                      title: "FAQ's",
                      isExpanded: state.expandedSection == HelpSection.faqs,
                      onToggle: () => notifier.toggleSection(HelpSection.faqs),
                      expandedContent: _FaqContent(
                        items: _faqItems,
                        expandedIndex: state.expandedFaqIndex,
                        onToggleFaq: notifier.toggleFaq,
                        scale: scale,
                      ),
                      scale: scale,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + "Help & Support" pink title
// ─────────────────────────────────────────────────────────────────
class _HelpHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _HelpHeader({
    required this.padding,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: padding.top + 12,
        bottom: 16,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Back arrow ──
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20 * scale.clamp(0.85, 1.2),
            ),
          ),
          const SizedBox(width: 8),

          // ── Title ──
          Expanded(
            child: Text(
              'Help & Support',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),

          // ── Balance spacer ──
          SizedBox(width: 28 * scale.clamp(0.85, 1.2)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section accordion card
// Collapsed: icon + title + "+" button
// Expanded: icon + title + "×" button + AnimatedSize content below
// Matches frames 1.6.19–1.6.22 exactly
// ─────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget expandedContent;
  final double scale;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.expandedContent,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // ── Section icon ──
                  Icon(
                    icon,
                    color: AppColors.black,
                    size: 22 * scale.clamp(0.85, 1.2),
                  ),
                  const SizedBox(width: 12),

                  // ── Title ──
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15 * scale.clamp(0.85, 1.2),
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ),

                  // ── Toggle icon: + when collapsed, × when expanded ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isExpanded ? Icons.close : Icons.add,
                      key: ValueKey(isExpanded),
                      color: AppColors.black,
                      size: 22 * scale.clamp(0.85, 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content — AnimatedSize for smooth expand ──
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.clearGrey.withValues(alpha: 0.6),
                      ),
                      expandedContent,
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Policy/Terms expanded content — scrollable text block
// Matches frames 1.6.20 & 1.6.21
// ─────────────────────────────────────────────────────────────────
class _PolicyContent extends StatelessWidget {
  final String title;
  final String body;
  final double scale;

  const _PolicyContent({
    required this.title,
    required this.body,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 13 * scale.clamp(0.85, 1.2),
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: '$title\n\n',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            TextSpan(
              text: body,
              style: const TextStyle(
                color: AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FAQ expanded content — nested accordion rows
// Matches frame 1.6.22 exactly:
// "?" icon + question text + chevron up/down
// Answer visible under expanded item
// ─────────────────────────────────────────────────────────────────
class _FaqContent extends StatelessWidget {
  final List<_FaqItem> items;
  final int? expandedIndex;
  final ValueChanged<int> onToggleFaq;
  final double scale;

  const _FaqContent({
    required this.items,
    required this.expandedIndex,
    required this.onToggleFaq,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isOpen = expandedIndex == index;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              // ── Question row ──
              InkWell(
                onTap: () => onToggleFaq(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // "?" circle icon
                      Container(
                        width: 24 * scale.clamp(0.85, 1.2),
                        height: 24 * scale.clamp(0.85, 1.2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.neutralGrey,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '?',
                            style: GoogleFonts.inter(
                              fontSize: 11 * scale.clamp(0.85, 1.2),
                              fontWeight: FontWeight.w700,
                              color: AppColors.neutralGrey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Question text
                      Expanded(
                        child: Text(
                          item.question,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ),

                      // Chevron up when open, down when closed
                      Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.black,
                        size: 22 * scale.clamp(0.85, 1.2),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Answer — AnimatedSize expand/collapse ──
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(50, 0, 16, 14),
                        child: Text(
                          item.answer,
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            color: AppColors.darkGrey,
                            height: 1.55,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Divider between FAQ items (not after last) ──
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.clearGrey.withValues(alpha: 0.6),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FAQ data model
// ─────────────────────────────────────────────────────────────────
class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
