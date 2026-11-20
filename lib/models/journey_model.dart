class JourneyChapter {
  final String id;
  final int number;
  final String title;
  final String months;
  final String purpose;
  final String status; // current | completed | upcoming
  final List<String> scoringEmphasis;

  const JourneyChapter({
    required this.id,
    required this.number,
    required this.title,
    required this.months,
    required this.purpose,
    required this.status,
    this.scoringEmphasis = const [],
  });

  factory JourneyChapter.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final emphasis = map['scoring_emphasis'];
    return JourneyChapter(
      id: (map['id'] ?? '').toString(),
      number: (map['number'] as num?)?.round() ?? 0,
      title: (map['title'] ?? '').toString(),
      months: (map['months'] ?? '').toString(),
      purpose: (map['purpose'] ?? '').toString(),
      status: (map['status'] ?? 'upcoming').toString(),
      scoringEmphasis: emphasis is List
          ? emphasis.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class JourneyCurrentChapter {
  final String id;
  final int number;
  final String title;
  final String months;
  final String purpose;
  final int weekInChapter;
  final int weeksInChapter;
  final List<String> scoringEmphasis;

  const JourneyCurrentChapter({
    required this.id,
    required this.number,
    required this.title,
    required this.months,
    required this.purpose,
    required this.weekInChapter,
    required this.weeksInChapter,
    this.scoringEmphasis = const [],
  });

  factory JourneyCurrentChapter.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final emphasis = map['scoring_emphasis'];
    return JourneyCurrentChapter(
      id: (map['id'] ?? '').toString(),
      number: (map['number'] as num?)?.round() ?? 1,
      title: (map['title'] ?? 'Build the habit').toString(),
      months: (map['months'] ?? '').toString(),
      purpose: (map['purpose'] ?? '').toString(),
      weekInChapter: (map['week_in_chapter'] as num?)?.round() ?? 1,
      weeksInChapter: (map['weeks_in_chapter'] as num?)?.round() ?? 8,
      scoringEmphasis: emphasis is List
          ? emphasis.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class JourneyWeeklyReview {
  final String focus;
  final int practisedDays;
  final String practisedLabel;
  final String? pillarMovementLabel;
  final String? strongestMeasure;
  final String? keepWorkingOn;
  final String nextWeekFocus;

  const JourneyWeeklyReview({
    required this.focus,
    required this.practisedDays,
    required this.practisedLabel,
    this.pillarMovementLabel,
    this.strongestMeasure,
    this.keepWorkingOn,
    required this.nextWeekFocus,
  });

  factory JourneyWeeklyReview.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final movement = map['pillar_movement'];
    String? movementLabel;
    if (movement is Map) {
      movementLabel = (movement['label'] ?? '').toString();
      if (movementLabel.isEmpty) movementLabel = null;
    }
    return JourneyWeeklyReview(
      focus: (map['focus'] ?? '').toString(),
      practisedDays: (map['practised_days'] as num?)?.round() ?? 0,
      practisedLabel: (map['practised_label'] ?? '').toString(),
      pillarMovementLabel: movementLabel,
      strongestMeasure: map['strongest_measure']?.toString(),
      keepWorkingOn: map['keep_working_on']?.toString(),
      nextWeekFocus: (map['next_week_focus'] ?? '').toString(),
    );
  }
}

class JourneySnapshot {
  final String weeklyFocus;
  final String nextWeekFocus;
  final int absoluteWeek;
  final double yearProgressPct;
  final int practiceDaysThisWeek;
  final JourneyCurrentChapter chapter;
  final List<JourneyChapter> chapters;
  final JourneyWeeklyReview weeklyReview;

  const JourneySnapshot({
    required this.weeklyFocus,
    required this.nextWeekFocus,
    required this.absoluteWeek,
    required this.yearProgressPct,
    required this.practiceDaysThisWeek,
    required this.chapter,
    required this.chapters,
    required this.weeklyReview,
  });

  factory JourneySnapshot.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final chaptersRaw = map['chapters'];
    final chapters = <JourneyChapter>[];
    if (chaptersRaw is List) {
      for (final item in chaptersRaw) {
        if (item is Map) {
          chapters.add(
            JourneyChapter.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return JourneySnapshot(
      weeklyFocus: (map['weekly_focus'] ?? '').toString(),
      nextWeekFocus: (map['next_week_focus'] ?? '').toString(),
      absoluteWeek: (map['absolute_week'] as num?)?.round() ?? 1,
      yearProgressPct: (map['year_progress_pct'] as num?)?.toDouble() ?? 0,
      practiceDaysThisWeek:
          (map['practice_days_this_week'] as num?)?.round() ?? 0,
      chapter: JourneyCurrentChapter.fromJson(
        map['chapter'] as Map<String, dynamic>?,
      ),
      chapters: chapters,
      weeklyReview: JourneyWeeklyReview.fromJson(
        map['weekly_review'] as Map<String, dynamic>?,
      ),
    );
  }
}
