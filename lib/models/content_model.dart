/// Model representing a single FAQ item.
class FaqItem {
  final String question;
  final String answer;

  const FaqItem({
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

/// Model representing a heading/content section in static document policies.
class ContentSection {
  final String heading;
  final String content;

  const ContentSection({
    required this.heading,
    required this.content,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      heading: json['heading'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

/// Model representing a full content document (e.g. Privacy Policy or Terms).
class ContentDoc {
  final String title;
  final String effectiveDate;
  final List<ContentSection> sections;

  const ContentDoc({
    required this.title,
    required this.effectiveDate,
    required this.sections,
  });

  factory ContentDoc.fromJson(Map<String, dynamic> json) {
    final list = json['sections'] as List? ?? [];
    return ContentDoc(
      title: json['title'] as String? ?? '',
      effectiveDate: json['effectiveDate'] as String? ?? '',
      sections: list
          .map((item) => ContentSection.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
