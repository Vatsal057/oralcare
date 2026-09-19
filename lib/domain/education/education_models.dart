enum EducationLanguage { english, hindi, kannada }

extension EducationLanguageX on EducationLanguage {
  String get label => switch (this) {
    EducationLanguage.english => 'English',
    EducationLanguage.hindi => 'हिंदी (Hindi)',
    EducationLanguage.kannada => 'ಕನ್ನಡ (Kannada)',
  };

  String get code => switch (this) {
    EducationLanguage.english => 'en',
    EducationLanguage.hindi => 'hi',
    EducationLanguage.kannada => 'kn',
  };
}

enum TopicCategory {
  basics,
  riskFactors,
  earlySigns,
  prevention,
  biopsyTreatment,
  caregiver,
  mythsFacts,
  faqs,
}

extension TopicCategoryX on TopicCategory {
  String get label => switch (this) {
    TopicCategory.basics => 'Overview',
    TopicCategory.riskFactors => 'Risk Factors',
    TopicCategory.earlySigns => 'Early Signs',
    TopicCategory.prevention => 'Prevention',
    TopicCategory.biopsyTreatment => 'Biopsy & Care',
    TopicCategory.caregiver => 'Caregivers',
    TopicCategory.mythsFacts => 'Myths vs Facts',
    TopicCategory.faqs => 'FAQs',
  };
}

class EducationTopic {
  const EducationTopic({
    required this.id,
    required this.category,
    required this.iconName,
    required this.titles,
    required this.summaries,
    required this.contentSections,
  });

  final String id;
  final TopicCategory category;
  final String iconName;
  final Map<EducationLanguage, String> titles;
  final Map<EducationLanguage, String> summaries;
  final Map<EducationLanguage, List<ContentSection>> contentSections;

  String title(EducationLanguage lang) =>
      titles[lang] ?? titles[EducationLanguage.english]!;
  String summary(EducationLanguage lang) =>
      summaries[lang] ?? summaries[EducationLanguage.english]!;
  List<ContentSection> sections(EducationLanguage lang) =>
      contentSections[lang] ?? contentSections[EducationLanguage.english]!;
}

class ContentSection {
  const ContentSection({
    required this.heading,
    required this.body,
    this.bulletPoints = const [],
    this.caution,
  });

  final String heading;
  final String body;
  final List<String> bulletPoints;
  final String? caution;
}

class MythFactItem {
  const MythFactItem({
    required this.myth,
    required this.fact,
    required this.explanation,
  });

  final String myth;
  final String fact;
  final String explanation;
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
