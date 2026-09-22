import '../../core/app_images.dart';
enum TreatmentModality {
  surgeryOnly,
  surgeryRadiotherapy,
  surgeryChemoRadiotherapy,
}

extension TreatmentModalityX on TreatmentModality {
  String get label => switch (this) {
    TreatmentModality.surgeryOnly => 'Surgery Only',
    TreatmentModality.surgeryRadiotherapy => 'Surgery + Radiotherapy',
    TreatmentModality.surgeryChemoRadiotherapy =>
      'Surgery + Chemo + Radiotherapy',
  };

  String get shortDescription => switch (this) {
    TreatmentModality.surgeryOnly =>
      'Focus on jaw opening physiotherapy, tongue speech drills, and scar mobility.',
    TreatmentModality.surgeryRadiotherapy =>
      'Focus on dry mouth (xerostomia) hydration, saliva substitutes, and radiation caries prevention.',
    TreatmentModality.surgeryChemoRadiotherapy =>
      'Focus on infection barrier precautions, oral mucositis, nutrition, and psychological well-being.',
  };
}

class RehabExercise {
  const RehabExercise({
    required this.title,
    required this.targetArea,
    required this.instruction,
    required this.frequency,
    required this.clinicalBenefit,
    this.imageAsset,
  });

  final String title;
  final String targetArea;
  final String instruction;
  final String frequency;
  final String clinicalBenefit;

  /// Demonstration photograph. A written instruction alone is hard to follow for
  /// a physical manoeuvre, especially for someone recovering from surgery.
  ///
  /// Null renders no image rather than a broken frame, so an exercise stays
  /// usable before its photograph exists.
  final String? imageAsset;
}

class RehabProtocol {
  const RehabProtocol({
    required this.modality,
    required this.keyPriorities,
    required this.exercises,
    required this.specialInstructions,
    required this.hydrationReminderHours,
  });

  final TreatmentModality modality;
  final List<String> keyPriorities;
  final List<RehabExercise> exercises;
  final List<String> specialInstructions;
  final int hydrationReminderHours;
}

class RehabilitationCatalog {
  const RehabilitationCatalog._();

  static const Map<TreatmentModality, RehabProtocol> protocols = {
    TreatmentModality.surgeryOnly: RehabProtocol(
      modality: TreatmentModality.surgeryOnly,
      keyPriorities: [
        'Prevent jaw joint stiffness (trismus) and contractures.',
        'Restore tongue range of motion for clear speech and safe swallowing.',
        'Gentle neck and shoulder mobilization after lymph node dissection.',
      ],
      exercises: [
        RehabExercise(
          title: 'Gentle Jaw Opening (Active Stretch)',
        imageAsset: AppImages.rehabJawOpening,
          targetArea: 'Temporomandibular Joint & Masseter',
          instruction:
              'Slowly open your mouth as wide as comfortably possible without sharp pain. '
              'Hold open for 5 seconds, then relax. Repeat 5 times.',
          frequency: '3 to 4 times daily',
          clinicalBenefit:
              'Maintains inter-incisal distance and prevents permanent trismus after resection.',
        ),
        RehabExercise(
          title: 'Tongue Protrusion and Lateralization',
        imageAsset: AppImages.rehabTongueMovement,
          targetArea: 'Remaining Tongue Musculature',
          instruction:
              'Stick tongue straight out toward chin. Then move tip to left corner of mouth, '
              'then to right corner. Hold each position for 3 seconds.',
          frequency: '5 repetitions, 3 times daily',
          clinicalBenefit:
              'Retrains speech articulation for lingual sounds (T, D, N, S) and bolus control.',
        ),
        RehabExercise(
          title: 'Gentle Neck Rotation and Shoulder Shrugs',
        imageAsset: AppImages.rehabNeckShoulder,
          targetArea: 'Sternocleidomastoid & Trapezius',
          instruction:
              'Slowly turn head to look over left shoulder, then right shoulder. '
              'Next, shrug shoulders upward toward ears and release smoothly.',
          frequency: '10 repetitions, twice daily',
          clinicalBenefit:
              'Reduces shoulder drop and cervical myofascial pain following selective neck dissection.',
        ),
      ],
      specialInstructions: [
        'Do not force jaw stretch beyond pain threshold.',
        'Maintain strict oral hygiene to keep surgical intraoral suture lines clean.',
        'Continue complete cessation of tobacco and alcohol to prevent flap necrosis.',
      ],
      hydrationReminderHours: 3,
    ),

    TreatmentModality.surgeryRadiotherapy: RehabProtocol(
      modality: TreatmentModality.surgeryRadiotherapy,
      keyPriorities: [
        'Combat radiation-induced dry mouth (xerostomia) and salivary gland fibrosis.',
        'Protect enamel from radiation-related rampant dental decay.',
        'Sustain swallow reflex and maintain jaw opening.',
      ],
      exercises: [
        RehabExercise(
          title: 'Mendelsohn Maneuver (Swallow Protection)',
        imageAsset: AppImages.rehabMendelsohn,
          targetArea: 'Pharyngeal Constrictors & Larynx',
          instruction:
              'Swallow your saliva and feel your Adams apple rise. At the peak of the swallow, '
              'squeeze your throat muscles to hold it up for 2 seconds before finishing the swallow.',
          frequency: '5 swallows, 3 times daily',
          clinicalBenefit:
              'Improves airway closure and pharyngeal clearance to prevent chronic aspiration.',
        ),
        RehabExercise(
          title: 'Passive Jaw Depressor Stretch (Wooden Spatula Stack)',
        imageAsset: AppImages.rehabSpatulaStretch,
          targetArea: 'Fibrosed Masticatory Muscles',
          instruction:
              'Gently insert a stack of wooden tongue depressors between upper and lower molars. '
              'Hold for 60 seconds. Add one blade every few weeks as tolerated.',
          frequency: '3 times daily',
          clinicalBenefit:
              'Counteracts post-radiation progressive muscle fibrosis.',
        ),
      ],
      specialInstructions: [
        'DRY MOUTH (XEROSTOMIA) PROTOCOL: Sip water frequently every 2 to 3 hours.',
        'Use artificial saliva substitutes (carboxymethylcellulose sprays) before meals and bed.',
        'Rinse with warm salt and sodium bicarbonate water (1/2 tsp salt + 1/2 tsp baking soda in 1 cup warm water) to soothe tissues.',
        'Daily 1.1% neutral sodium fluoride gel application to prevent radiation caries.',
        'Avoid commercial mouthwashes containing alcohol (which burns and dries mucosal tissues).',
      ],
      hydrationReminderHours: 2,
    ),

    TreatmentModality.surgeryChemoRadiotherapy: RehabProtocol(
      modality: TreatmentModality.surgeryChemoRadiotherapy,
      keyPriorities: [
        'Strict infection prevention during chemotherapy-induced neutropenia.',
        'Relief from severe oral mucositis and mucosal ulceration.',
        'High-calorie soft nutrition and psychological coping for hair loss and fatigue.',
      ],
      exercises: [
        RehabExercise(
          title: 'Effortful Swallow & Tongue Base Retraction',
        imageAsset: AppImages.rehabEffortfulSwallow,
          targetArea: 'Oropharyngeal Wall & Tongue Base',
          instruction:
              'Swallow as hard as possible, squeezing all your throat muscles tightly together, '
              'as if swallowing a grape whole.',
          frequency: '5 hard swallows, 3 times daily',
          clinicalBenefit:
              'Keeps pharyngeal musculature active even while receiving tube feeding or liquid diets.',
        ),
        RehabExercise(
          title: 'Deep Diaphragmatic Calming Breathing',
        imageAsset: AppImages.rehabBreathing,
          targetArea: 'Autonomic Nervous System & Core',
          instruction:
              'Place one hand on chest and one on stomach. Breathe in slowly through nose for 4 counts '
              'feeling stomach rise. Exhale gently through mouth for 6 counts.',
          frequency: '5 minutes morning and night',
          clinicalBenefit:
              'Reduces cancer treatment-related anxiety, nausea, and emotional distress.',
        ),
      ],
      specialInstructions: [
        'INFECTION ALERT: Check your temperature daily. Any fever above 100.4°F (38°C) is a medical emergency requiring immediate hospital admission.',
        'MUCOSITIS CARE: Eat soft, bland, room-temperature foods (khichdi, curd, blended dal, milkshakes). Avoid spicy, acidic, or hard crunchy foods.',
        'Use an ultra-soft pediatric toothbrush rinsed in warm water. If bleeding occurs, clean teeth with sterile foam swabs.',
        'EMOTIONAL & PSYCHOLOGICAL SUPPORT: Hair loss from chemo, altered speech, and facial changes can be distressing. These effects are manageable and hair regrows after chemotherapy completion.',
        'Connect with cancer support groups or speak with a psycho-oncology counselor for coping strategies.',
      ],
      hydrationReminderHours: 2,
    ),
  };
}
