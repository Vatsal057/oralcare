/// Canonical asset paths for every illustration the app expects.
///
/// Deliberately free of any Flutter import: the risk, education and
/// rehabilitation catalogues in `domain/` reference these constants, and that
/// layer is kept free of UI dependencies so it stays testable on its own.
///
/// Referencing an image by name rather than by raw string makes a typo a compile
/// error and keeps the full inventory of expected artwork visible in one place.
class AppImages {
  const AppImages._();

  static const String _dir = 'assets/images';

  // --- Guided self-examination sites (spec Table 5) ---
  static const String siteLips = '$_dir/1.jpg';
  static const String siteInnerCheeks = '$_dir/2.jpg';
  static const String siteGums = '$_dir/3.jpg';
  static const String siteTongue = '$_dir/4.jpg';
  static const String siteFloorOfMouth = '$_dir/5.jpg';
  static const String sitePalate = '$_dir/6.jpg';
  static const String siteNeck = '$_dir/7.jpg';
  static const String siteThroat = '$_dir/8.jpg';

  // --- Lesion reference gallery: appearances ---
  static const String signLeukoplakia = '$_dir/A.jpg';
  static const String signErythroleukoplakia = '$_dir/B.jpg';
  static const String signVerrucous = '$_dir/C.jpg';
  static const String signUlcer = '$_dir/D.jpg';
  static const String signExophytic = '$_dir/E.jpg';
  static const String signOsmf = '$_dir/F.jpg';

  // --- Lesion reference gallery: signs added after clinical review ---
  static const String signNormalMouth = '$_dir/sign_normal_mouth.jpg';
  static const String signRedPatch = '$_dir/sign_red_patch.jpg';
  static const String signBleedingGums = '$_dir/sign_bleeding_gums.jpg';
  static const String signNeckLump = '$_dir/sign_neck_lump.jpg';
  static const String signLooseTeeth = '$_dir/sign_loose_teeth.jpg';
  static const String signJawSwelling = '$_dir/sign_jaw_swelling.jpg';
  static const String signPusBoil = '$_dir/sign_pus_boil.jpg';

  // --- Rehabilitation exercises ---
  static const String rehabJawOpening = '$_dir/rehab_jaw_opening.jpg';
  static const String rehabTongueMovement = '$_dir/rehab_tongue_movement.jpg';
  static const String rehabNeckShoulder = '$_dir/rehab_neck_shoulder.jpg';
  static const String rehabMendelsohn = '$_dir/rehab_mendelsohn.jpg';
  static const String rehabSpatulaStretch = '$_dir/rehab_spatula_stretch.jpg';
  static const String rehabEffortfulSwallow =
      '$_dir/rehab_effortful_swallow.jpg';
  static const String rehabBreathing = '$_dir/rehab_breathing.jpg';

  // --- Education topics ---
  static const String eduWhatIsOralCancer =
      '$_dir/edu_what_is_oral_cancer.jpg';
  static const String eduRiskFactors = '$_dir/edu_risk_factors.jpg';
  static const String eduEarlySigns = '$_dir/edu_early_signs.jpg';
  static const String eduCessation = '$_dir/edu_cessation.jpg';
  static const String eduHygieneNutrition =
      '$_dir/edu_hygiene_nutrition.jpg';
  static const String eduBiopsyTreatment = '$_dir/edu_biopsy_treatment.jpg';
  static const String eduCaregiver = '$_dir/edu_caregiver.jpg';

  // --- Risk-factor questions ---
  static const String riskSmoking = '$_dir/risk_smoking.jpg';
  static const String riskSmokelessTobacco =
      '$_dir/risk_smokeless_tobacco.jpg';
  static const String riskArecaBetel = '$_dir/risk_areca_betel.jpg';
  static const String riskGutkha = '$_dir/risk_gutkha.jpg';
  static const String riskAlcohol = '$_dir/risk_alcohol.jpg';

  // --- Diagrams ---
  static const String mouthMap = '$_dir/mouth_map.jpg';

  /// Every asset the app expects, for the coverage test.
  static const List<String> all = [
    siteLips, siteInnerCheeks, siteGums, siteTongue,
    siteFloorOfMouth, sitePalate, siteNeck, siteThroat,
    signLeukoplakia, signErythroleukoplakia, signVerrucous,
    signUlcer, signExophytic, signOsmf,
    signNormalMouth, signRedPatch, signBleedingGums, signNeckLump,
    signLooseTeeth, signJawSwelling, signPusBoil,
    rehabJawOpening, rehabTongueMovement, rehabNeckShoulder, rehabMendelsohn,
    rehabSpatulaStretch, rehabEffortfulSwallow, rehabBreathing,
    eduWhatIsOralCancer, eduRiskFactors, eduEarlySigns, eduCessation,
    eduHygieneNutrition, eduBiopsyTreatment, eduCaregiver,
    riskSmoking, riskSmokelessTobacco, riskArecaBetel, riskGutkha, riskAlcohol,
    mouthMap,
  ];
}
