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
  static const String siteLips = '$_dir/1.png';
  static const String siteInnerCheeks = '$_dir/2.png';
  static const String siteGums = '$_dir/3.png';
  static const String siteTongue = '$_dir/4.png';
  static const String siteFloorOfMouth = '$_dir/5.png';
  static const String sitePalate = '$_dir/6.png';
  static const String siteNeck = '$_dir/7.png';
  static const String siteThroat = '$_dir/8.png';

  // --- Lesion reference gallery: appearances ---
  static const String signLeukoplakia = '$_dir/A.png';
  static const String signErythroleukoplakia = '$_dir/B.png';
  static const String signVerrucous = '$_dir/C.png';
  static const String signUlcer = '$_dir/D.png';
  static const String signExophytic = '$_dir/E.png';
  static const String signOsmf = '$_dir/F.png';

  // --- Lesion reference gallery: signs added after clinical review ---
  static const String signNormalMouth = '$_dir/sign_normal_mouth.png';
  static const String signRedPatch = '$_dir/sign_red_patch.png';
  static const String signBleedingGums = '$_dir/sign_bleeding_gums.png';
  static const String signNeckLump = '$_dir/sign_neck_lump.png';
  static const String signLooseTeeth = '$_dir/sign_loose_teeth.png';
  static const String signJawSwelling = '$_dir/sign_jaw_swelling.png';
  static const String signPusBoil = '$_dir/sign_pus_boil.png';

  // --- Rehabilitation exercises ---
  static const String rehabJawOpening = '$_dir/rehab_jaw_opening.png';
  static const String rehabTongueMovement = '$_dir/rehab_tongue_movement.png';
  static const String rehabNeckShoulder = '$_dir/rehab_neck_shoulder.png';
  static const String rehabMendelsohn = '$_dir/rehab_mendelsohn.png';
  static const String rehabSpatulaStretch = '$_dir/rehab_spatula_stretch.png';
  static const String rehabEffortfulSwallow =
      '$_dir/rehab_effortful_swallow.png';
  static const String rehabBreathing = '$_dir/rehab_breathing.png';

  // --- Education topics ---
  static const String eduWhatIsOralCancer =
      '$_dir/edu_what_is_oral_cancer.png';
  static const String eduRiskFactors = '$_dir/edu_risk_factors.png';
  static const String eduEarlySigns = '$_dir/edu_early_signs.png';
  static const String eduCessation = '$_dir/edu_cessation.png';
  static const String eduHygieneNutrition =
      '$_dir/edu_hygiene_nutrition.png';
  static const String eduBiopsyTreatment = '$_dir/edu_biopsy_treatment.png';
  static const String eduCaregiver = '$_dir/edu_caregiver.png';

  // --- Risk-factor questions ---
  static const String riskSmoking = '$_dir/risk_smoking.png';
  static const String riskSmokelessTobacco =
      '$_dir/risk_smokeless_tobacco.png';
  static const String riskArecaBetel = '$_dir/risk_areca_betel.png';
  static const String riskGutkha = '$_dir/risk_gutkha.png';
  static const String riskAlcohol = '$_dir/risk_alcohol.png';

  // --- Diagrams ---
  static const String mouthMap = '$_dir/mouth_map.png';

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
