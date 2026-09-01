/// Mirrors backend_python/disease_info.py so the app can show treatment
/// steps and answer the AI Treatment Assistant's suggested questions
/// without a network round trip (report Section 4.2.3 describes the
/// assistant as greeting the farmer with the diagnosis already in context —
/// there is no dedicated chat endpoint in Table 4.2, so this runs locally).
class TreatmentStep {
  final int step;
  final String title;
  final String urgency;
  final String description;
  const TreatmentStep({
    required this.step,
    required this.title,
    required this.urgency,
    required this.description,
  });
}

class DiseaseInfo {
  final String label;
  final String? causalAgent;
  final bool curable;
  final String? warning;
  final List<TreatmentStep> treatmentSteps;
  const DiseaseInfo({
    required this.label,
    this.causalAgent,
    required this.curable,
    this.warning,
    required this.treatmentSteps,
  });
}

const Map<String, DiseaseInfo> diseaseInfoByKey = {
  'Bud_Root_Dropping': DiseaseInfo(
    label: 'Bud Root Dropping',
    causalAgent: 'Bud Root Dropping',
    curable: true,
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'Remove dropped/rotting buds', urgency: 'Immediate',
          description: 'Clear fallen buds and roots from the base of the tree to stop the spread of secondary infection.'),
      TreatmentStep(step: 2, title: 'Apply systemic fungicide', urgency: 'Within 48 hrs',
          description: 'Drench the crown with a systemic fungicide such as Hexaconazole as per label dosage.'),
      TreatmentStep(step: 3, title: 'Improve drainage', urgency: 'This week',
          description: 'Waterlogging around the base is a common trigger — improve soil drainage around affected trees.'),
    ],
  ),
  'Bud_Rot': DiseaseInfo(
    label: 'Bud Rot',
    causalAgent: 'Phytophthora palmivora',
    curable: true,
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'Remove rotting bud tissue', urgency: 'Immediate',
          description: 'Cut away and destroy all visibly rotten spear leaf and bud tissue.'),
      TreatmentStep(step: 2, title: 'Apply Bordeaux mixture', urgency: 'Within 48 hrs',
          description: 'Apply 1% Bordeaux mixture to the crown region to arrest fungal spread.'),
      TreatmentStep(step: 3, title: 'Follow-up inspection', urgency: '2 weeks',
          description: 'Re-inspect the crown; severely affected palms with a collapsed spear may need to be removed.'),
    ],
  ),
  'Gray_Leaf_Spot': DiseaseInfo(
    label: 'Gray Leaf Spot',
    causalAgent: 'Pestalotiopsis palmarum',
    curable: true,
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'Remove heavily spotted leaves', urgency: 'Within 24 hrs',
          description: 'Prune and destroy the most heavily infected leaflets to reduce spore load.'),
      TreatmentStep(step: 2, title: 'Apply copper fungicide', urgency: 'Within 48 hrs',
          description: 'Spray copper oxychloride (3g/litre) focusing on leaf undersides.'),
      TreatmentStep(step: 3, title: 'Improve air circulation', urgency: 'This week',
          description: 'Thin nearby vegetation — high humidity favours this fungus.'),
    ],
  ),
  'Healthy_Leaves': DiseaseInfo(
    label: 'Healthy',
    curable: true,
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'No treatment required', urgency: 'N/A',
          description: 'This tree shows no visible signs of disease. Continue routine monitoring.'),
    ],
  ),
  'Leaf_Rot': DiseaseInfo(
    label: 'Leaf Rot',
    causalAgent: 'Colletotrichum gloeosporioides',
    curable: true,
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'Remove infected leaflets', urgency: 'Within 24 hrs',
          description: 'Cut and destroy rotting leaf tissue before spores mature.'),
      TreatmentStep(step: 2, title: 'Apply Mancozeb', urgency: 'Within 48 hrs',
          description: 'Spray Mancozeb 75% WP (2.5g/litre) as an alternative to copper-based fungicide.'),
      TreatmentStep(step: 3, title: 'Follow-up inspection', urgency: '2 weeks',
          description: 'Re-scan the tree; escalate to an agricultural officer if the rot continues to spread.'),
    ],
  ),
  'Leaf_Yellowing': DiseaseInfo(
    label: 'Leaf Yellowing',
    causalAgent: 'Nutrient deficiency / Weligama Coconut Leaf Wilt (WCLWD)',
    curable: false,
    warning: 'Leaf Yellowing may indicate WCLWD phytoplasma, which is incurable. '
        'If suspected, remove the infected tree immediately and contact your agricultural officer.',
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'Conduct Soil & Leaf Nutrient Test', urgency: 'Immediate',
          description: 'Yellowing can be caused by potassium, magnesium, or boron deficiency. '
              'Collect soil and leaf samples and send to your nearest agricultural lab before applying any treatment.'),
      TreatmentStep(step: 2, title: 'Apply Deficient Nutrients', urgency: 'After lab results',
          description: 'Based on test results, apply the deficient element: potassium sulphate (500 g/tree), '
              'magnesium sulphate (Epsom salt, 200 g/tree), or borax (30 g/tree). Do not apply all at once without lab guidance.'),
      TreatmentStep(step: 3, title: 'Check for WCLWD Phytoplasma', urgency: 'Within 48 hrs',
          description: 'If yellowing progresses from lower to upper fronds, nuts fall prematurely, or the spear leaf wilts '
              '— suspect Weligama Coconut Leaf Wilt Disease. There is NO chemical cure.'),
    ],
  ),
  'Stem_Bleeding': DiseaseInfo(
    label: 'Stem Bleeding',
    causalAgent: 'Thielaviopsis paradoxa',
    curable: true,
    treatmentSteps: [
      TreatmentStep(step: 1, title: 'Scrape the bleeding patch', urgency: 'Immediate',
          description: 'Remove the affected bark and scrape away discoloured tissue until healthy wood is exposed.'),
      TreatmentStep(step: 2, title: 'Apply fungicidal paste', urgency: 'Within 48 hrs',
          description: 'Apply Bordeaux paste or Tridemorph paste over the scraped wound.'),
      TreatmentStep(step: 3, title: 'Re-inspect the trunk', urgency: '2 weeks',
          description: 'Check that the bleeding has stopped and the wound is drying out cleanly.'),
    ],
  ),
};

const List<String> suggestedTreatmentQuestions = [
  'What causes this disease?',
  'How to prevent spreading?',
  'Is the treatment safe for workers?',
  'How often should I apply treatment?',
];

/// Simple rule-based responder standing in for the assistant — matches each
/// suggested question and falls back to a generic answer built from the
/// disease's treatment steps for anything else typed in free text.
String answerTreatmentQuestion(DiseaseInfo info, String question) {
  final q = question.toLowerCase();
  if (q.contains('cause')) {
    return info.causalAgent != null
        ? '${info.label} is caused by ${info.causalAgent}.'
        : '${info.label} does not have a specific pathogen on record — it reflects a healthy tree.';
  }
  if (q.contains('prevent') || q.contains('spread')) {
    return 'Isolate tools used on this tree, remove and destroy infected tissue rather than composting it, '
        'and avoid moving infected material between plantation sections.';
  }
  if (q.contains('safe') || q.contains('worker')) {
    return 'Wear gloves and a mask when handling fungicide sprays, and keep workers away from the treated '
        'area for at least a few hours after application.';
  }
  if (q.contains('often') || q.contains('frequency') || q.contains('apply')) {
    return 'Follow the urgency tags on each treatment step — most sprays are applied once, then re-checked '
        'after the follow-up inspection window (typically 2 weeks).';
  }
  if (info.warning != null && (q.contains('cure') || q.contains('wclwd') || q.contains('incurable'))) {
    return info.warning!;
  }
  final firstStep = info.treatmentSteps.first;
  return 'For ${info.label}, the first step is "${firstStep.title}" (${firstStep.urgency}): ${firstStep.description}';
}
