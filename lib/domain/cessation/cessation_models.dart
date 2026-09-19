import 'dart:convert';

enum CravingTrigger {
  stress,
  social,
  afterMeal,
  boredom,
  teaCoffee,
  anxiety,
  other,
}

extension CravingTriggerX on CravingTrigger {
  String get label => switch (this) {
    CravingTrigger.stress => 'Work / Stress',
    CravingTrigger.social => 'Social gathering / Friends',
    CravingTrigger.afterMeal => 'After eating a meal',
    CravingTrigger.boredom => 'Boredom / Free time',
    CravingTrigger.teaCoffee => 'With Chai / Coffee',
    CravingTrigger.anxiety => 'Anxiety / Restlessness',
    CravingTrigger.other => 'Other trigger',
  };
}

class CravingEntry {
  const CravingEntry({
    required this.id,
    required this.timestamp,
    required this.trigger,
    required this.intensity, // 1 to 5
    required this.resisted,
  });

  final String id;
  final DateTime timestamp;
  final CravingTrigger trigger;
  final int intensity;
  final bool resisted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'trigger': trigger.name,
    'intensity': intensity,
    'resisted': resisted ? 1 : 0,
  };

  factory CravingEntry.fromJson(Map<String, dynamic> json) => CravingEntry(
    id: json['id'] as String,
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    trigger: CravingTrigger.values.firstWhere(
      (t) => t.name == json['trigger'],
      orElse: () => CravingTrigger.other,
    ),
    intensity: (json['intensity'] as num?)?.toInt() ?? 3,
    resisted: (json['resisted'] as int? ?? 1) == 1,
  );
}

class QuitPlan {
  const QuitPlan({
    required this.quitDate,
    required this.habitTypes, // e.g. ['Smoking', 'Gutkha', 'Areca nut']
    required this.dailyUnits,
    required this.costPerUnit,
    this.cravingLogs = const [],
  });

  final DateTime quitDate;
  final List<String> habitTypes;
  final int dailyUnits;
  final double costPerUnit;
  final List<CravingEntry> cravingLogs;

  Duration get timeSinceQuit {
    final diff = DateTime.now().difference(quitDate);
    return diff.isNegative ? Duration.zero : diff;
  }

  int get daysQuit => timeSinceQuit.inDays;
  int get hoursQuit => timeSinceQuit.inHours % 24;

  int get unitsAvoided {
    final days = timeSinceQuit.inMinutes / (24 * 60);
    return (days * dailyUnits).round();
  }

  double get moneySaved {
    return unitsAvoided * costPerUnit;
  }

  QuitPlan copyWith({
    DateTime? quitDate,
    List<String>? habitTypes,
    int? dailyUnits,
    double? costPerUnit,
    List<CravingEntry>? cravingLogs,
  }) => QuitPlan(
    quitDate: quitDate ?? this.quitDate,
    habitTypes: habitTypes ?? this.habitTypes,
    dailyUnits: dailyUnits ?? this.dailyUnits,
    costPerUnit: costPerUnit ?? this.costPerUnit,
    cravingLogs: cravingLogs ?? this.cravingLogs,
  );

  Map<String, dynamic> toJson() => {
    'quit_date': quitDate.toIso8601String(),
    'habit_types': habitTypes,
    'daily_units': dailyUnits,
    'cost_per_unit': costPerUnit,
    'cravings': cravingLogs.map((c) => c.toJson()).toList(),
  };

  factory QuitPlan.fromJson(Map<String, dynamic> json) => QuitPlan(
    quitDate:
        DateTime.tryParse(json['quit_date'] as String? ?? '') ?? DateTime.now(),
    habitTypes: (json['habit_types'] as List?)?.cast<String>() ?? ['Tobacco'],
    dailyUnits: (json['daily_units'] as num?)?.toInt() ?? 5,
    costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? 10.0,
    cravingLogs:
        (json['cravings'] as List?)
            ?.map(
              (e) => CravingEntry.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        [],
  );

  String serialize() => jsonEncode(toJson());
}

class HealthMilestone {
  const HealthMilestone({
    required this.durationRequired,
    required this.title,
    required this.description,
    required this.benefitDetail,
  });

  final Duration durationRequired;
  final String title;
  final String description;
  final String benefitDetail;

  bool isAchieved(Duration timeSinceQuit) => timeSinceQuit >= durationRequired;
}

class CessationCatalog {
  const CessationCatalog._();

  static final List<HealthMilestone> milestones = [
    const HealthMilestone(
      durationRequired: Duration(minutes: 20),
      title: '20 Minutes: Heart Rate Normalizes',
      description:
          'Blood pressure and pulse rate begin dropping to normal levels.',
      benefitDetail:
          'Cardiovascular stress eases immediately after stopping nicotine.',
    ),
    const HealthMilestone(
      durationRequired: Duration(hours: 24),
      title: '24 Hours: Carbon Monoxide Drops',
      description:
          'Carbon monoxide in your bloodstream drops to normal levels.',
      benefitDetail:
          'Oxygen levels in mucosal cells and tissues increase significantly.',
    ),
    const HealthMilestone(
      durationRequired: Duration(days: 2),
      title: '48 Hours: Taste & Smell Reawaken',
      description:
          'Nerve endings damaged by tobacco and areca begin regenerating.',
      benefitDetail:
          'Taste buds in the oral cavity start recovering their sensory acuity.',
    ),
    const HealthMilestone(
      durationRequired: Duration(days: 14),
      title: '2 Weeks: Oral Mucosa Regeneration',
      description:
          'Superficial mucosal inflammation and erythroplakia risk begin receding.',
      benefitDetail:
          'Tissue irritation and chronic dryness subside; cellular healing accelerates.',
    ),
    const HealthMilestone(
      durationRequired: Duration(days: 30),
      title: '1 Month: Gums and Teeth Healthier',
      description:
          'Gingival blood supply improves, reducing periodontal bone loss.',
      benefitDetail:
          'Significant reduction in oral lesions and reduced mouth stiffness.',
    ),
    const HealthMilestone(
      durationRequired: Duration(days: 365),
      title: '1 Year: Oral Cancer Risk Drops by 50%',
      description:
          'Your risk of oral cancer drops by half compared to continuing users.',
      benefitDetail:
          'Long-term genetic stability and major reduction in head & neck cancer risk.',
    ),
  ];
}
