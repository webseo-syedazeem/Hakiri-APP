class ActivityModel {
  final String slug;
  final String name;
  final bool isMvp;
  final String tagline;
  final String description;
  final String cognitiveMechanism;
  final int prepDurationSeconds;
  final int defaultDurationSeconds;
  final List<String> benefits;
  final List<String> successMeasures;

  const ActivityModel({
    required this.slug,
    required this.name,
    required this.isMvp,
    required this.tagline,
    required this.description,
    required this.cognitiveMechanism,
    required this.prepDurationSeconds,
    required this.defaultDurationSeconds,
    required this.benefits,
    required this.successMeasures,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        slug: json['slug'] ?? '',
        name: json['name'] ?? '',
        isMvp: json['is_mvp'] ?? false,
        tagline: json['tagline'] ?? '',
        description: json['description'] ?? '',
        cognitiveMechanism: json['cognitive_mechanism'] ?? '',
        prepDurationSeconds: json['prep_duration_seconds'] ?? 5,
        defaultDurationSeconds: json['default_duration_seconds'] ?? 60,
        benefits: List<String>.from(json['benefits'] ?? []),
        successMeasures: List<String>.from(json['success_measures'] ?? []),
      );
}

class PromptModel {
  final String id;
  final String activitySlug;
  final String difficulty;
  final String? title;
  final String promptText;
  final String? secondaryText;
  final String objective;
  final String exemplarResponse;
  final List<String> tags;
  final List<String> industries;
  final int durationSeconds;
  final int prepSeconds;

  const PromptModel({
    required this.id,
    required this.activitySlug,
    required this.difficulty,
    this.title,
    required this.promptText,
    this.secondaryText,
    required this.objective,
    required this.exemplarResponse,
    required this.tags,
    this.industries = const ['general'],
    required this.durationSeconds,
    required this.prepSeconds,
  });

  /// Pure general / untagged only. A sales+general tag is NOT general —
  /// otherwise healthcare users get brand/logo prompts.
  bool get isGeneralIndustry {
    if (industries.isEmpty) return true;
    final careers =
        industries.where((i) => i != 'general' && i.trim().isNotEmpty);
    return careers.isEmpty;
  }

  bool matchesCareer(String? career) {
    if (career == null ||
        career.isEmpty ||
        career == 'general' ||
        career == 'other') {
      return isGeneralIndustry;
    }
    return industries.contains(career) || tags.contains(career);
  }

  factory PromptModel.fromJson(Map<String, dynamic> json) => PromptModel(
        id: json['id'] ?? '',
        activitySlug: json['activity_slug'] ?? '',
        difficulty: json['difficulty'] ?? 'beginner',
        title: json['title'],
        promptText: json['prompt_text'] ?? '',
        secondaryText: json['secondary_text'],
        objective: json['objective'] ?? '',
        exemplarResponse: json['exemplar_response'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        industries: List<String>.from(
          json['industries'] ?? const ['general'],
        ),
        durationSeconds: json['duration_seconds'] ?? 60,
        prepSeconds: json['prep_seconds'] ?? 5,
      );
}
