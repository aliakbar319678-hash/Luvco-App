import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/content_api_service.dart';
import '../models/content_model.dart';

// ─────────────────────────────────────────────────────────────────
// Which top-level section is expanded: null = all collapsed
// ─────────────────────────────────────────────────────────────────
enum HelpSection { privacyPolicy, termsAndConditions, faqs }

class HelpSupportState {
  final HelpSection? expandedSection; // null = all collapsed
  final int? expandedFaqIndex; // which FAQ item is open
  final List<FaqItem> faqs;
  final ContentDoc? privacyDoc;
  final ContentDoc? termsDoc;
  final bool isLoading;
  final String? errorMessage;

  const HelpSupportState({
    this.expandedSection,
    this.expandedFaqIndex,
    this.faqs = const [],
    this.privacyDoc,
    this.termsDoc,
    this.isLoading = false,
    this.errorMessage,
  });

  HelpSupportState copyWith({
    HelpSection? expandedSection,
    bool clearSection = false,
    int? expandedFaqIndex,
    bool clearFaq = false,
    List<FaqItem>? faqs,
    ContentDoc? privacyDoc,
    ContentDoc? termsDoc,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => HelpSupportState(
    expandedSection: clearSection
        ? null
        : (expandedSection ?? this.expandedSection),
    expandedFaqIndex: clearFaq
        ? null 
        : (expandedFaqIndex ?? this.expandedFaqIndex),
    faqs: faqs ?? this.faqs,
    privacyDoc: privacyDoc ?? this.privacyDoc,
    termsDoc: termsDoc ?? this.termsDoc,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class HelpSupportNotifier extends StateNotifier<HelpSupportState> {
  HelpSupportNotifier() : super(const HelpSupportState()) {
    loadContent();
  }

  /// Fetches FAQs, Privacy Policy, and Terms of Service from backend content API.
  Future<void> loadContent() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final faqs = await ContentApiService.instance.getFAQs();
      final privacyDoc = await ContentApiService.instance.getPrivacyPolicy();
      final termsDoc = await ContentApiService.instance.getTermsOfService();

      state = state.copyWith(
        faqs: faqs,
        privacyDoc: privacyDoc,
        termsDoc: termsDoc,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Tap a top-level section — toggle open/closed
  void toggleSection(HelpSection section) {
    if (state.expandedSection == section) {
      // Already open — close it
      state = state.copyWith(clearSection: true);
    } else {
      // Open new section, reset FAQ index
      state = state.copyWith(
        expandedSection: section,
        clearFaq: true,
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

