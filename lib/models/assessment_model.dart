class AssessmentOption {
  final String id;
  final String label;
  final String description;

  const AssessmentOption({
    required this.id,
    required this.label,
    required this.description,
  });
}

class AssessmentQuestion {
  final String id;
  final String title;
  final String subtitle;
  final List<AssessmentOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.options,
  });
}

class AssessmentAnswers {
  String? voiceProfile;
  String? careerStage;
  String? careerType;
  String? confidence;
  String? roadblock;
  String? primaryGoal;

  AssessmentAnswers({
    this.voiceProfile,
    this.careerStage,
    this.careerType,
    this.confidence,
    this.roadblock,
    this.primaryGoal,
  });

  Map<String, dynamic> toJson() => {
        'voice_profile': voiceProfile,
        'career_stage': careerStage,
        'career_type': careerType,
        'speaking_confidence': confidence,
        'primary_roadblock': roadblock,
        'primary_goal': primaryGoal,
      };

  factory AssessmentAnswers.fromJson(Map<String, dynamic> json) => AssessmentAnswers(
        voiceProfile: json['voice_profile'],
        careerStage: json['career_stage'],
        careerType: json['career_type'],
        confidence: json['speaking_confidence'],
        roadblock: json['primary_roadblock'],
        primaryGoal: json['primary_goal'],
      );
}

class MilestoneItem {
  final int week;
  final String title;
  final String focus;

  const MilestoneItem({
    required this.week,
    required this.title,
    required this.focus,
  });

  Map<String, dynamic> toJson() => {'week': week, 'title': title, 'focus': focus};
  factory MilestoneItem.fromJson(Map<String, dynamic> json) => MilestoneItem(
        week: json['week'] ?? 1,
        title: json['title'] ?? '',
        focus: json['focus'] ?? '',
      );
}

class PersonalizedPlanModel {
  final String headline;
  final String summary;
  final String recommendedTrack;
  final String primaryRoadblock;
  final List<String> initialDrills;
  final List<MilestoneItem> milestones;

  const PersonalizedPlanModel({
    required this.headline,
    required this.summary,
    required this.recommendedTrack,
    required this.primaryRoadblock,
    required this.initialDrills,
    required this.milestones,
  });

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'summary': summary,
        'recommended_track': recommendedTrack,
        'primary_roadblock': primaryRoadblock,
        'initial_drills': initialDrills,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory PersonalizedPlanModel.fromJson(Map<String, dynamic> json) => PersonalizedPlanModel(
        headline: json['headline'] ?? '',
        summary: json['summary'] ?? '',
        recommendedTrack: json['recommended_track'] ?? '',
        primaryRoadblock: json['primary_roadblock'] ?? '',
        initialDrills: List<String>.from(json['initial_drills'] ?? []),
        milestones: (json['milestones'] as List<dynamic>? ?? [])
            .map((e) => MilestoneItem.fromJson(e))
            .toList(),
      );
}
