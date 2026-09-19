import 'education_models.dart';

/// Clinical education catalogue implementing all content required by
/// Section 2 of the specification ("Oral-cancer education Module").
/// Supports English, Hindi, and Kannada.
class EducationCatalog {
  const EducationCatalog._();

  static const List<EducationTopic> topics = [
    // 1. What is Oral Cancer?
    EducationTopic(
      id: 'what_is_oral_cancer',
      category: TopicCategory.basics,
      iconName: 'info_outline',
      titles: {
        EducationLanguage.english: 'What is Oral Cancer?',
        EducationLanguage.hindi: 'मुंह का कैंसर क्या है?',
        EducationLanguage.kannada: 'ಬಾಯಿ ಕ್ಯಾನ್ಸರ್ ಎಂದರೇನು?',
      },
      summaries: {
        EducationLanguage.english:
            'Understand oral cavity malignancies, where they develop, and how cells change.',
        EducationLanguage.hindi:
            'मुंह की गुहा में होने वाले कैंसर, इसके स्थान और कोशिकाओं के बदलाव को समझें।',
        EducationLanguage.kannada:
            'ಬಾಯಿಯ ಕುಹರದಲ್ಲಿ ಉಂಟಾಗುವ ಕ್ಯಾನ್ಸರ್ ಮತ್ತು ಅದರ ಹಂತಗಳನ್ನು ಅರ್ಥಮಾಡಿಕೊಳ್ಳಿ.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'Understanding the Disease',
            body:
                'Oral cancer (most commonly Oral Squamous Cell Carcinoma - OSCC) '
                'develops in the squamous cells that line the surfaces of the mouth, '
                'tongue, and lips. It often begins as a pre-cancerous lesion or patch '
                'that gradually undergoes malignant change.',
            bulletPoints: [
              'Most frequent sites: lateral border of the tongue, floor of the mouth, inner cheeks (buccal mucosa), and lower lip.',
              'Over 90% of oral cancers are squamous cell carcinomas.',
              'Early recognition allows minimally invasive cure with high survival rates.',
            ],
          ),
          ContentSection(
            heading: 'Importance of Early Detection',
            body:
                'When diagnosed at Stage I or II, oral cancer has an 80–90% five-year '
                'survival rate with preserved speech and facial aesthetics. When diagnosed '
                'late (Stage III or IV), treatment is complex and five-year survival drops below 40%.',
            caution:
                'Early oral cancer is frequently completely painless. Do not wait for pain before getting examined.',
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: 'बीमारी को समझना',
            body:
                'मुंह का कैंसर (ओरल स्क्वैमस सेल कार्सिनोमा) मुंह, जीभ और होठों की परत वाली कोशिकाओं में शुरू होता है। '
                'यह अक्सर लाल या सफेद धब्बों के रूप में शुरू होता है।',
            bulletPoints: [
              'सबसे आम स्थान: जीभ के किनारे, मुंह का निचला हिस्सा, गाल का अंदरूनी भाग और होंठ।',
              'शुरुआती जांच से 80-90% मामलों में पूरी तरह ठीक होना संभव है।',
            ],
            caution:
                'शुरुआती कैंसर में अक्सर दर्द नहीं होता। दर्द का इंतज़ार न करें।',
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: 'ರೋಗದ ಬಗ್ಗೆ ಮಾಹಿತಿ',
            body:
                'ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ಸಾಮಾನ್ಯವಾಗಿ ನಾಲಿಗೆ, ತುಟಿಗಳು ಅಥವಾ ಕೆನ್ನೆಯ ಒಳಭಾಗದ ಜೀವಕೋಶಗಳಲ್ಲಿ ಪ್ರಾರಂಭವಾಗುತ್ತದೆ.',
            bulletPoints: [
              'ಸಾಮಾನ್ಯ ಸ್ಥಳಗಳು: ನಾಲಿಗೆಯ ಬದಿಗಳು, ಬಾಯಿಯ ತಳಭಾಗ ಮತ್ತು ಒಸಡುಗಳು.',
              'ಆರಂಭಿಕ ಹಂತದಲ್ಲೇ ಪತ್ತೆಹಚ್ಚಿದರೆ ಶೇಕಡಾ 80-90 ರಷ್ಟು ಗುಣಮುಖರಾಗಬಹುದು.',
            ],
            caution:
                'ಆರಂಭಿಕ ಹಂತದಲ್ಲಿ ನೋವು ಇರುವುದಿಲ್ಲ. ತಕ್ಷಣ ವೈದ್ಯರನ್ನು ಸಂಪರ್ಕಿಸಿ.',
          ),
        ],
      },
    ),

    // 2. Risk Factors
    EducationTopic(
      id: 'risk_factors',
      category: TopicCategory.riskFactors,
      iconName: 'warning_amber_outlined',
      titles: {
        EducationLanguage.english: 'Major Risk Factors',
        EducationLanguage.hindi: 'प्रमुख जोखिम कारक',
        EducationLanguage.kannada: 'ಪ್ರಮುಖ ಅಪಾಯಕಾರಿ ಅಂಶಗಳು',
      },
      summaries: {
        EducationLanguage.english:
            'Tobacco, areca nut, alcohol, HPV, and chronic mucosal irritation.',
        EducationLanguage.hindi:
            'तंबाकू, सुपारी, गुटखा, शराब और पुराना संक्रमण।',
        EducationLanguage.kannada:
            'ತಂಬಾಕು, ಅಡಿಕೆ, ಗುಟ್ಕಾ ಮತ್ತು ಮದ್ಯಪಾನದ ಅಪಾಯಗಳು.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'The Deadly Synergy',
            body:
                'Tobacco in any form and areca nut (betel nut) are the leading causes '
                'of oral cancer in South Asia. When combined with regular alcohol consumption, '
                'the risk multiplies exponentially because alcohol dehydrates the mucosa and makes '
                'carcinogens penetrate tissue faster.',
            bulletPoints: [
              'Smokeless tobacco (Gutkha, Khaini, Zarda): Placed directly against mucosal tissues, releasing nitrosamines.',
              'Areca nut / Betel nut: Causes oral submucous fibrosis (OSMF) which severely restricts mouth opening and has high malignant transformation.',
              'Bidi and cigarette smoking: Heat and carcinogenic combustion chemicals damage the oral lining.',
              'Alcohol: Works synergistically with tobacco, multiplying risk up to 15 times.',
              'Human Papillomavirus (HPV-16): Increasingly associated with tonsillar and base-of-tongue cancers.',
              'Sharp broken teeth or ill-fitting dentures: Chronic physical mechanical trauma.',
            ],
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: 'तंबाकू और सुपारी का खतरा',
            body:
                'गुटखा, खैनी, जर्दा और पान मसाला मुंह के ऊतकों को गंभीर नुकसान पहुंचाते हैं। शराब के साथ इनका सेवन करने से खतरा कई गुना बढ़ जाता है।',
            bulletPoints: [
              'धुआं रहित तंबाकू सीधे गाल के अंदर रखकर चबाने से कैंसरकारी तत्व अवशोषित होते हैं।',
              'सुपारी से मुंह का खुलना कम हो जाता है (ओरल सबम्यूकस फाइब्रोसिस)।',
            ],
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: 'ಅಪಾಯಕಾರಿ ಅಭ್ಯಾಸಗಳು',
            body:
                'ತಂಬಾಕು, ಗುಟ್ಕಾ, ಅಡಿಕೆ ಮತ್ತು ಮದ್ಯಪಾನ ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್‌ಗೆ ಮುಖ್ಯ ಕಾರಣಗಳಾಗಿವೆ.',
            bulletPoints: [
              'ಗುಟ್ಕಾ ಮತ್ತು ಜರ್ದಾ ಬಾಯಿಯ ಒಳಪದರವನ್ನು ಹಾಳುಮಾಡುತ್ತವೆ.',
              'ಅಡಿಕೆ ಸೇವನೆಯಿಂದ ಬಾಯಿ ತೆರೆಯುವುದು ಕಷ್ಟವಾಗುತ್ತದೆ.',
            ],
          ),
        ],
      },
    ),

    // 3. Early Signs & Symptoms
    EducationTopic(
      id: 'early_signs_symptoms',
      category: TopicCategory.earlySigns,
      iconName: 'visibility_outlined',
      titles: {
        EducationLanguage.english: 'Early Signs & Symptoms',
        EducationLanguage.hindi: 'शुरुआती लक्षण और संकेत',
        EducationLanguage.kannada: 'ಆರಂಭಿಕ ಲಕ್ಷಣಗಳು ಮತ್ತು ಎಚ್ಚರಿಕೆಗಳು',
      },
      summaries: {
        EducationLanguage.english:
            'Non-healing ulcers, red/white patches, lumps, and the 2-week rule.',
        EducationLanguage.hindi:
            'न भरने वाले छाले, लाल या सफेद धब्बे, और गांठें।',
        EducationLanguage.kannada:
            'ವಾಸಿಯಾಗದ ಹುಣ್ಣುಗಳು, ಕೆಂಪು ಅಥವಾ ಬಿಳಿ ಕಲೆಗಳು.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'The 14-Day (2-Week) Rule',
            body:
                'Common aphthous ulcers (canker sores) heal naturally within 7 to 10 days. '
                'ANY ulcer, sore, or red/white patch in the mouth that persists for more than 14 days '
                'is considered a clinical red flag until evaluated by a qualified specialist.',
            bulletPoints: [
              'A sore or ulcer that does not heal within 2 weeks.',
              'Velvety red patches (Erythroplakia) or thick white patches (Leukoplakia).',
              'Lump, thickening, or rough spot on the cheek, gums, or tongue.',
              'Unexplained bleeding or numbness in the mouth or lower lip.',
              'Difficulty or pain when chewing, swallowing, or speaking.',
              'Restricted tongue movement or reduced mouth opening.',
              'A persistent painless lump in the neck.',
            ],
            caution:
                'Do not apply over-the-counter pain gels or steroid ointments to an unexplained persistent ulcer without a doctor’s examination.',
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: '14 दिनों का महत्वपूर्ण नियम',
            body:
                'यदि मुंह का कोई छाला या घाव 2 सप्ताह (14 दिन) में ठीक नहीं होता है, तो तुरंत डॉक्टर को दिखाएं।',
            bulletPoints: [
              'मुंह में सफेद या लाल रंग का धब्बा।',
              'गाल या जीभ पर कोई सख्त गांठ।',
              'निगलने या बोलने में परेशानी होना।',
              'गर्दन में कोई गांठ।',
            ],
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: '14 ದಿನಗಳ ನಿಯಮ',
            body:
                'ಯಾವುದೇ ಬಾಯಿಯ ಹುಣ್ಣು 2 ವಾರಗಳಿಗಿಂತ ಹೆಚ್ಚು ಕಾಲ ಉಳಿದಿದ್ದರೆ, ತಕ್ಷಣ ವೈದ್ಯರನ್ನು ಭೇಟಿ ಮಾಡಿ.',
            bulletPoints: [
              'ವಾಸಿಯಾಗದ ಹುಣ್ಣುಗಳು.',
              'ಬಾಯಿಯಲ್ಲಿ ಬಿಳಿ ಅಥವಾ ಕೆಂಪು ಕಲೆಗಳು.',
              'ಆಹಾರ ನುಂಗಲು ಕಷ್ಟವಾಗುವುದು.',
            ],
          ),
        ],
      },
    ),

    // 4. Prevention & Habit Cessation
    EducationTopic(
      id: 'prevention_cessation',
      category: TopicCategory.prevention,
      iconName: 'smoke_free_outlined',
      titles: {
        EducationLanguage.english: 'Cessation & Habit Change',
        EducationLanguage.hindi: 'तंबाकू और सुपारी छोड़ना',
        EducationLanguage.kannada: 'ತಂಬಾಕು ತ್ಯಜಿಸುವ ಮಾರ್ಗದರ್ಶಿ',
      },
      summaries: {
        EducationLanguage.english:
            'How quitting restores oral health, managing triggers, and free quitlines.',
        EducationLanguage.hindi:
            'लत छोड़ने के तरीके, राष्ट्रीय हेल्पलाइन और स्वास्थ्य लाभ।',
        EducationLanguage.kannada:
            'ವ್ಯಸನದಿಂದ ಮುಕ್ತಿ ಪಡೆಯುವ ಕ್ರಮಗಳು ಮತ್ತು ಉಚಿತ ಸಹಾಯವಾಣಿ.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'The Oral Recovery Timeline',
            body:
                'Stopping tobacco and areca nut immediately halts ongoing mutagenic damage. '
                'Within weeks, oral mucosal inflammation subsides, and within 12 months, '
                'the risk of oral malignancy drops dramatically.',
            bulletPoints: [
              'Set a clear Quit Date and inform family and colleagues for accountability.',
              'Identify craving triggers: tea breaks, social gatherings, stress, after meals.',
              'The 4-D Strategy during intense cravings: Delay (wait 5 mins), Deep breath, Drink water, Distract yourself.',
              'Use healthy substitutes: cardamom, cloves, roasted fennel seeds (saunf), or sugar-free gum.',
              'National Tobacco Quitline (Toll-Free India): 1800-11-2356.',
              'mCessation Support: Give a missed call to 011-22901701 for free SMS counseling.',
            ],
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: 'छोड़ने की आसान रणनीतियाँ',
            body:
                'तंबाकू और गुटखा छोड़ते ही मुंह के ऊतकों में सुधार शुरू हो जाता है।',
            bulletPoints: [
              'एक पक्की तारीख तय करें।',
              'क्रेविंग आने पर पानी पिएं या सौंफ/लौंग चबाएं।',
              'राष्ट्रीय तंबाकू क्विटलाइन: 1800-11-2356 (टोल-फ्री)।',
            ],
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: 'ಉತ್ತಮ ಆರೋಗ್ಯಕ್ಕಾಗಿ ತ್ಯಜಿಸಿ',
            body: 'ತಂಬಾಕು ಬಿಟ್ಟ ತಕ್ಷಣ ಬಾಯಿಯ ಒಳಪದರದ ಚೇತರಿಕೆ ಪ್ರಾರಂಭವಾಗುತ್ತದೆ.',
            bulletPoints: [
              'ಒಂದು ದಿನಾಂಕವನ್ನು ನಿಗದಿಪಡಿಸಿ.',
              'ಅಗತ್ಯವಿದ್ದಾಗ ನೀರು ಕುಡಿಯಿರಿ ಅಥವಾ ಸೋಂಪು ಬಳಸಿ.',
              'ರಾಷ್ಟ್ರೀಯ ಸಹಾಯವಾಣಿ: 1800-11-2356.',
            ],
          ),
        ],
      },
    ),

    // 5. Oral Hygiene & Nutrition
    EducationTopic(
      id: 'hygiene_nutrition',
      category: TopicCategory.prevention,
      iconName: 'restaurant_outlined',
      titles: {
        EducationLanguage.english: 'Oral Hygiene & Nutrition',
        EducationLanguage.hindi: 'मौखिक स्वच्छता और पोषण',
        EducationLanguage.kannada: 'ಬಾಯಿಯ ನೈರ್ಮಲ್ಯ ಮತ್ತು ಪೌಷ್ಟಿಕಾಂಶ',
      },
      summaries: {
        EducationLanguage.english:
            'Protective foods, antioxidants, proper brushing, and avoiding sharp dental edges.',
        EducationLanguage.hindi:
            'पौष्टिक आहार, एंटीऑक्सीडेंट और दांतों की देखभाल।',
        EducationLanguage.kannada: 'ಪೌಷ್ಟಿಕ ಆಹಾರ ಮತ್ತು ಬಾಯಿಯ ಶುಚಿತ್ವ.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'Protective Dietary Factors',
            body:
                'Diets rich in fresh vegetables, citrus fruits, and dietary antioxidants '
                '(vitamins A, C, E, lycopene, and beta-carotene) help repair cellular '
                'DNA damage and reduce the risk of oral potentially malignant disorders.',
            bulletPoints: [
              'Eat brightly colored vegetables: carrots, tomatoes, spinach, bell peppers.',
              'Stay well-hydrated to maintain a healthy salivary protective barrier.',
              'Brush twice daily with a soft-bristled toothbrush and clean the tongue gently.',
              'Never ignore a sharp tooth cusp or rough filling that constantly cuts your cheek.',
            ],
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: 'स्वस्थ आहार और स्वच्छता',
            body:
                'हरी पत्तेदार सब्जियां, गाजर, टमाटर और ताजे फल मुंह के कैंसर के खतरे को कम करते हैं।',
            bulletPoints: [
              'नरम ब्रश का प्रयोग करें और दिन में दो बार ब्रश करें।',
              'नुकीले दांत का इलाज तुरंत करवाएं।',
            ],
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: 'ಆರೋಗ್ಯಕರ ಆಹಾರ ಪದ್ಧತಿ',
            body:
                'ಹಸಿರು ತರಕಾರಿಗಳು ಮತ್ತು ಹಣ್ಣುಗಳು ಬಾಯಿಯ ಆರೋಗ್ಯವನ್ನು ಕಾಪಾಡುತ್ತವೆ.',
            bulletPoints: [
              'ದಿನಕ್ಕೆ ಎರಡು ಬಾರಿ ಹಲ್ಲುಜ್ಜಿಕೊಳ್ಳಿ.',
              'ಚೂಪಾದ ಹಲ್ಲಿನ ಸಮಸ್ಯೆಗೆ ಚಿಕಿತ್ಸೆ ಪಡೆಯಿರಿ.',
            ],
          ),
        ],
      },
    ),

    // 6. Biopsy, Referral & Treatment
    EducationTopic(
      id: 'biopsy_and_treatment',
      category: TopicCategory.biopsyTreatment,
      iconName: 'healing_outlined',
      titles: {
        EducationLanguage.english: 'Biopsy, Staging & Treatment',
        EducationLanguage.hindi: 'बायोप्सी और उपचार प्रक्रिया',
        EducationLanguage.kannada: 'ಬಯಾಪ್ಸಿ ಮತ್ತು ಚಿಕಿತ್ಸಾ ಮಾಹಿತಿ',
      },
      summaries: {
        EducationLanguage.english:
            'What happens during a biopsy, why it does not spread cancer, and modern therapies.',
        EducationLanguage.hindi:
            'बायोप्सी से डरने की जरूरत क्यों नहीं है और इलाज के विकल्प।',
        EducationLanguage.kannada: 'ಬಯಾಪ್ಸಿ ವಿಧಾನ ಮತ್ತು ಆಧುನಿಕ ಚಿಕಿತ್ಸೆಗಳು.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'What is an Oral Biopsy?',
            body:
                'A biopsy is a minor, painless 5-minute procedure performed under local anesthesia. '
                'A tiny sample (2–3 mm) of tissue is taken from the edge of the lesion and sent to an '
                'oral pathologist to examine cell architecture under a microscope.',
            bulletPoints: [
              'A biopsy is the ONLY definitive way to diagnose or rule out cancer.',
              'Biopsies DO NOT cause cancer to spread; this is a dangerous myth.',
              'Modern treatment modalities include surgery, radiation therapy, chemotherapy, and immunotherapy tailored by a multidisciplinary oncology board.',
            ],
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: 'बायोप्सी क्या होती है?',
            body:
                'बायोप्सी एक छोटी सी जांच है जिसमें सुन्न करने का इंजेक्शन देकर थोड़ा सा टुकड़ा जांच के लिए लिया जाता है। '
                'इससे कैंसर नहीं फैलता, बल्कि सही इलाज संभव होता है।',
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: 'ಬಯಾಪ್ಸಿ ಎಂದರೇನು?',
            body:
                'ಬಯಾಪ್ಸಿ ಎಂಬುದು ಒಂದು ಸಣ್ಣ ಪರೀಕ್ಷೆಯಾಗಿದ್ದು, ಇದು ಕ್ಯಾನ್ಸರ್ ಇದೆಯೆ ಅಥವಾ ಇಲ್ಲವೆ ಎಂದು ನಿಖರವಾಗಿ ತಿಳಿಸುತ್ತದೆ. ಬಯಾಪ್ಸಿಯಿಂದ ಕ್ಯಾನ್ಸರ್ ಹರಡುವುದಿಲ್ಲ.',
          ),
        ],
      },
    ),

    // 7. Caregiver Guidance
    EducationTopic(
      id: 'caregiver_guidance',
      category: TopicCategory.caregiver,
      iconName: 'diversity_1_outlined',
      titles: {
        EducationLanguage.english: 'Caregiver & Family Guidance',
        EducationLanguage.hindi: 'परिवार और देखभाल करने वालों के लिए',
        EducationLanguage.kannada: 'ಕುಟುಂಬದವರಿಗೆ ಮತ್ತು ಆರೈಕೆದಾರರಿಗೆ',
      },
      summaries: {
        EducationLanguage.english:
            'Supporting a loved one through screening, diagnosis, and emotional recovery.',
        EducationLanguage.hindi: 'मरीज का मानसिक और शारीरिक सहयोग कैसे करें।',
        EducationLanguage.kannada:
            'ರೋಗಿಯ ಆರೈಕೆ ಮತ್ತು ಮಾನಸಿಕ ಧೈರ್ಯ ತುಂಬುವ ವಿಧಾನ.',
      },
      contentSections: {
        EducationLanguage.english: [
          ContentSection(
            heading: 'Supporting Without Blaming',
            body:
                'Facing a suspicious lesion or cancer diagnosis triggers intense anxiety, fear, '
                'and guilt. Family support is critical for treatment compliance.',
            bulletPoints: [
              'Avoid lecturing or blaming the patient for past tobacco or alcohol habits.',
              'Accompany the patient to specialist consultations and help take notes.',
              'Assist with soft, nutrient-rich meal preparation if swallowing is uncomfortable.',
              'Encourage regular hydration and help manage medication/checkup schedules.',
            ],
          ),
        ],
        EducationLanguage.hindi: [
          ContentSection(
            heading: 'सहानुभूतिपूर्ण देखभाल',
            body:
                'मरीज पर दोषारोपण न करें। उनके साथ डॉक्टर के पास जाएं और दवाइयों व खानपान का ध्यान रखें।',
          ),
        ],
        EducationLanguage.kannada: [
          ContentSection(
            heading: 'ಪ್ರೀತಿ ಮತ್ತು ಕಾಳಜಿ',
            body: 'ರೋಗಿಗೆ ಧೈರ್ಯ ತುಂಬಿ. ವೈದ್ಯರ ಭೇಟಿಯ ಸಮಯದಲ್ಲಿ ಅವರೊಂದಿಗೆ ಇರಿ.',
          ),
        ],
      },
    ),
  ];

  static const List<MythFactItem> mythsAndFacts = [
    MythFactItem(
      myth: 'Only elderly people and heavy cigarette smokers get oral cancer.',
      fact:
          'FACT: Anyone with tobacco or areca nut use can develop oral cancer, even in their 20s and 30s.',
      explanation:
          'In South Asia, gutkha, paan masala, and areca nut chewing cause aggressive oral lesions in teenagers and young adults.',
    ),
    MythFactItem(
      myth: 'A biopsy will cause the cancer to spread or grow faster.',
      fact:
          'FACT: A biopsy is completely safe and is the ONLY way to confirm a diagnosis.',
      explanation:
          'Tissue sampling is microscopic and does not metastasize cancer. Delaying a biopsy allows an undiagnosed lesion to advance.',
    ),
    MythFactItem(
      myth: 'If a mouth sore does not hurt, it cannot be cancer.',
      fact:
          'FACT: Early oral cancers and precancers are almost always completely painless.',
      explanation:
          'Pain usually appears only in advanced stages when deep nerves are invaded. A painless ulcer lasting >2 weeks is a red flag.',
    ),
    MythFactItem(
      myth: 'Areca nut without tobacco (plain supari) is safe and natural.',
      fact:
          'FACT: Areca nut is a Group 1 human carcinogen on its own, even without tobacco.',
      explanation:
          'Areca nut contains arecoline, which damages oral fibroblasts, causes irreversible submucous fibrosis, and directly causes cancer.',
    ),
    MythFactItem(
      myth:
          'Oral cancer is contagious and can spread through saliva or sharing utensils.',
      fact: 'FACT: Oral cancer cannot be transmitted from person to person.',
      explanation:
          'Cancer is a disorder of cell DNA and mucosal genetics, not an infectious disease. You cannot catch oral cancer.',
    ),
  ];

  static const List<FaqItem> faqs = [
    FaqItem(
      question: 'How often should I perform an oral self-examination?',
      answer:
          'Every adult—especially those with a history of tobacco, areca nut, or alcohol use—should inspect their mouth once every month using a mirror and good lighting.',
    ),
    FaqItem(
      question:
          'What is the difference between a normal mouth ulcer and a cancerous ulcer?',
      answer:
          'Normal canker sores are small, painful, and heal completely within 7 to 10 days. A potentially malignant ulcer persists beyond 14 days, often has hard raised edges, central sloughing, and may not hurt initially.',
    ),
    FaqItem(
      question: 'Can a white patch (leukoplakia) disappear on its own?',
      answer:
          'If caused purely by tobacco or chronic friction, some early lesions may regress after complete cessation of the habit. However, every white patch must be clinically evaluated and monitored for dysplastic change.',
    ),
    FaqItem(
      question:
          'What should I do if the app shows "Professional Check Required"?',
      answer:
          'Do not panic. It means you reported a finding that fits clinical red-flag criteria (such as a lesion persisting >2 weeks). Visit an Oral Medicine specialist, Maxillofacial Surgeon, or ENT doctor for a direct clinical examination.',
    ),
    FaqItem(
      question: 'Does the mobile app diagnose oral cancer?',
      answer:
          'No. The app strictly supports awareness, self-examination, and structured referral. Only a certified clinician performing a physical examination and tissue biopsy can diagnose oral cancer.',
    ),
  ];
}
