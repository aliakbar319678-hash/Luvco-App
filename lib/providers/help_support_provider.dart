import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────
// Which top-level section is expanded: null = all collapsed
// ─────────────────────────────────────────────────────────────────
enum HelpSection { privacyPolicy, termsAndConditions, faqs }

class HelpSupportState {
  final HelpSection? expandedSection; // null = all collapsed
  final int? expandedFaqIndex; // which FAQ item is open

  const HelpSupportState({this.expandedSection, this.expandedFaqIndex});

  HelpSupportState copyWith({
    HelpSection? expandedSection,
    bool clearSection = false,
    int? expandedFaqIndex,
    bool clearFaq = false,
  }) => HelpSupportState(
    expandedSection: clearSection
        ? null
        : (expandedSection ?? this.expandedSection),
    expandedFaqIndex: clearFaq
        ? null
        : (expandedFaqIndex ?? this.expandedFaqIndex),
  );
}

class HelpSupportNotifier extends StateNotifier<HelpSupportState> {
  HelpSupportNotifier() : super(const HelpSupportState());

  // Tap a top-level section — toggle open/closed
  void toggleSection(HelpSection section) {
    if (state.expandedSection == section) {
      // Already open — close it
      state = const HelpSupportState();
    } else {
      // Open new section, reset FAQ index
      state = HelpSupportState(
        expandedSection: section,
        expandedFaqIndex: null,
      );
    }
  }

  // Tap a FAQ item — toggle its answer
  void toggleFaq(int index) {
    if (state.expandedFaqIndex == index) {
      state = state.copyWith(clearFaq: true);
    } else {
      state = state.copyWith(expandedFaqIndex: index);
    }
  }
}

final helpSupportProvider =
    StateNotifierProvider.autoDispose<HelpSupportNotifier, HelpSupportState>(
      (_) => HelpSupportNotifier(),
    );
