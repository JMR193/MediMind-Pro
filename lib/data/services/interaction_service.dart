import '../../domain/models/medication.dart';
import 'prescription_parser_service.dart';

enum InteractionSeverity {
  critical, // Contraindicated / severe risk
  moderate, // Precaution / monitoring required
  advisory, // Timing / spacing advisory (e.g. eye drop wash-out)
}

class DrugInteractionWarning {
  final String drugA;
  final String drugB;
  final InteractionSeverity severity;
  final String title;
  final String description;
  final String clinicalRecommendation;

  const DrugInteractionWarning({
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.title,
    required this.description,
    required this.clinicalRecommendation,
  });
}

class FoodInteractionWarning {
  final String foodItem;
  final String medicationName;
  final InteractionSeverity severity;
  final String title;
  final String description;
  final String clinicalRecommendation;

  const FoodInteractionWarning({
    required this.foodItem,
    required this.medicationName,
    required this.severity,
    required this.title,
    required this.description,
    required this.clinicalRecommendation,
  });
}

class ConditionContraindicationWarning {
  final String condition;
  final String medicationName;
  final InteractionSeverity severity;
  final String title;
  final String description;
  final String clinicalRecommendation;

  const ConditionContraindicationWarning({
    required this.condition,
    required this.medicationName,
    required this.severity,
    required this.title,
    required this.description,
    required this.clinicalRecommendation,
  });
}

/// Clinical Drug-Drug Interaction (DDI) & Food Safety Service
/// 100% On-Device pharmacology safety engine.
class InteractionService {
  static final InteractionService _instance = InteractionService._internal();
  factory InteractionService() => _instance;
  InteractionService._internal();

  static const List<({
    List<String> groupA,
    List<String> groupB,
    InteractionSeverity severity,
    String title,
    String description,
    String recommendation,
  })> _interactionRules = [
    // 1. Dual Beta-Blockers (Systemic + Ophthalmic)
    (
      groupA: ['timolol', 'betaxolol', 'carteolol', 'levobunolol'],
      groupB: ['metoprolol', 'atenolol', 'bisoprolol', 'carvedilol', 'propranolol', 'labetalol', 'nebivolol'],
      severity: InteractionSeverity.critical,
      title: 'Dual Beta-Blocker Heart Rate Warning',
      description: 'Combining ophthalmic beta-blocker eye drops with oral beta-blocker tablets can cause severe additive bradycardia (dangerously slow heart rate) and hypotension.',
      recommendation: 'Perform punctal occlusion (pinch tear duct for 60s) to limit systemic absorption, and inform your cardiologist and ophthalmologist.',
    ),

    // 2. Anticoagulants / Antiplatelets + NSAIDs (Severe Bleeding Risk)
    (
      groupA: ['aspirin', 'ecosprin', 'warfarin', 'coumadin', 'clopidogrel', 'plavix', 'apixaban', 'eliquis', 'rivaroxaban', 'xarelto', 'dabigatran'],
      groupB: ['ibuprofen', 'combiflam', 'diclofenac', 'voveran', 'aceclofenac', 'zerodol', 'naproxen', 'piroxicam', 'ketorolac', 'indomethacin'],
      severity: InteractionSeverity.critical,
      title: 'Severe Gastrointestinal Bleeding Risk',
      description: 'Combining blood thinners with NSAID painkillers significantly elevates the risk of stomach ulcers, internal hemorrhage, and major bleeding.',
      recommendation: 'Use Paracetamol / Acetaminophen for pain relief instead of NSAIDs unless specifically co-prescribed with a gastro-protective agent (e.g. Pantoprazole).',
    ),

    // 3. Statins + Macrolides / Grapefruit (Rhabdomyolysis Risk)
    (
      groupA: ['atorvastatin', 'atorva', 'simvastatin', 'zocor', 'lovastatin'],
      groupB: ['clarithromycin', 'erythromycin', 'ketoconazole', 'itraconazole', 'grapefruit'],
      severity: InteractionSeverity.critical,
      title: 'Severe Muscle Toxicity (Rhabdomyolysis) Risk',
      description: 'CYP3A4 enzyme inhibition causes high serum statin levels, multiplying the risk of acute kidney failure and skeletal muscle breakdown (rhabdomyolysis).',
      recommendation: 'Avoid grapefruit completely. If taking macrolide antibiotics, your doctor may pause statin therapy temporarily.',
    ),

    // 4. ACE Inhibitors / ARBs + Potassium-Sparing Diuretics (Hyperkalemia)
    (
      groupA: ['ramipril', 'lisinopril', 'enalapril', 'telmisartan', 'telma', 'losartan', 'valsartan', 'olmesartan'],
      groupB: ['spironolactone', 'aldactone', 'eplerenone', 'potassium'],
      severity: InteractionSeverity.moderate,
      title: 'Elevated Potassium (Hyperkalemia) Precaution',
      description: 'Both medications retain potassium in the body. Concomitant use can lead to dangerously elevated blood potassium levels resulting in cardiac arrhythmias.',
      recommendation: 'Ensure periodic blood electrolyte (serum potassium) monitoring by your primary care physician.',
    ),

    // 5. PDE5 Inhibitors + Nitrates (Fatal Hypotension)
    (
      groupA: ['sildenafil', 'viagra', 'tadalafil', 'cialis', 'vardenafil'],
      groupB: ['nitroglycerin', 'sorbitrate', 'isosorbide mononitrate', 'monotrate', 'nitrolingual'],
      severity: InteractionSeverity.critical,
      title: 'Life-Threatening Hypotension Contraindication',
      description: 'Nitrates combined with PDE5 inhibitors cause severe, irreversible systemic vasodilation resulting in profound cardiovascular collapse and shock.',
      recommendation: 'Absolute contraindication. Never take these medications concurrently.',
    ),

    // 6. Fluoroquinolones + Polyvalent Cations (Chelation Absorption Failure)
    (
      groupA: ['ciprofloxacin', 'ciplox', 'levofloxacin', 'moxifloxacin', 'norfloxacin', 'ofloxacin'],
      groupB: ['calcium', 'shelcal', 'iron', 'ferrous', 'antacid', 'gelusil', 'digene', 'sucralfate'],
      severity: InteractionSeverity.moderate,
      title: 'Antibiotic Chelation & Reduced Absorption',
      description: 'Calcium, iron, or antacids bind to fluoroquinolones in the gut, forming insoluble chelates that reduce antibiotic absorption by up to 80%.',
      recommendation: 'Take fluoroquinolone antibiotics at least 2 hours before or 4 hours after calcium, iron, or antacids.',
    ),

    // 7. Multiple Eye Drops Timing Spacing
    (
      groupA: ['latanoprost', 'timolol', 'bimatoprost', 'travoprost', 'brimonidine', 'dorzolamide', 'brinzolamide', 'moxifloxacin', 'ciplox', 'prednisolone', 'pred forte', 'dexamethasone', 'tobrex'],
      groupB: ['latanoprost', 'timolol', 'bimatoprost', 'travoprost', 'brimonidine', 'dorzolamide', 'brinzolamide', 'moxifloxacin', 'ciplox', 'prednisolone', 'pred forte', 'dexamethasone', 'tobrex'],
      severity: InteractionSeverity.advisory,
      title: 'Ophthalmic Wash-Out Spacing Protocol',
      description: 'Your eye reservoir holds only 1 drop. Instilling a second eye drop within 5 minutes flushes the first medication down the tear duct before it can absorb.',
      recommendation: 'Wait at least 5 to 10 minutes between consecutive eye drops. MediMind has activated automated spacing timers.',
    ),
  ];

  static const List<({
    List<String> keywords,
    String foodItem,
    InteractionSeverity severity,
    String title,
    String description,
    String recommendation,
  })> _foodInteractionRules = [
    (
      keywords: ['atorvastatin', 'atorva', 'simvastatin', 'zocor', 'lovastatin', 'amlodipine', 'nifedipine', 'felodipine'],
      foodItem: 'Grapefruit & Grapefruit Juice',
      severity: InteractionSeverity.critical,
      title: 'Grapefruit CYP3A4 Toxicity Warning',
      description: 'Grapefruit compounds inhibit intestinal CYP3A4 enzymes, preventing drug clearance and causing up to 300% higher drug concentrations in your bloodstream, elevating risk of muscle breakdown or severe hypotension.',
      recommendation: 'Avoid grapefruit, pomelos, and Seville oranges while on this medication.',
    ),
    (
      keywords: ['ciprofloxacin', 'ciplox', 'levofloxacin', 'moxifloxacin', 'doxycycline', 'dox', 'tetracycline'],
      foodItem: 'Milk, Yogurt & Dairy Products',
      severity: InteractionSeverity.moderate,
      title: 'Calcium Chelation Blocks Absorption',
      description: 'Calcium in dairy binds to antibiotics in the stomach, forming insoluble chelates that pass unabsorbed, causing antibiotic treatment failure.',
      recommendation: 'Consume dairy at least 2 hours before or 4 hours after taking this antibiotic.',
    ),
    (
      keywords: ['metronidazole', 'flagyl', 'tinidazole', 'lorazepam', 'alprazolam', 'diazepam', 'paracetamol', 'acetaminophen'],
      foodItem: 'Alcoholic Beverages',
      severity: InteractionSeverity.critical,
      title: 'Severe Alcohol Interaction & Toxicity',
      description: 'Alcohol causes severe disulfiram-like reactions (vomiting, flushing, tachycardia) with Metronidazole, or dangerous CNS respiratory depression with sedatives, or hepatic injury with Paracetamol.',
      recommendation: 'Completely abstain from all alcoholic beverages during treatment.',
    ),
    (
      keywords: ['ramipril', 'lisinopril', 'enalapril', 'telmisartan', 'telma', 'losartan', 'spironolactone', 'aldactone'],
      foodItem: 'High-Potassium Foods & Salt Substitutes',
      severity: InteractionSeverity.moderate,
      title: 'Elevated Serum Potassium (Hyperkalemia)',
      description: 'These blood pressure medications reduce potassium excretion. Excessive intake of bananas, avocados, or potassium-chloride salt substitutes can trigger dangerous arrhythmias.',
      recommendation: 'Avoid potassium salt substitutes and maintain moderate dietary potassium intake.',
    ),
    (
      keywords: ['warfarin', 'coumadin'],
      foodItem: 'Dark Leafy Greens (Vitamin K Rich)',
      severity: InteractionSeverity.critical,
      title: 'Vitamin K Warfarin Antagonism',
      description: 'High intake of spinach, kale, or broccoli provides excess Vitamin K, directly neutralizing Warfarin and increasing stroke/clot risk.',
      recommendation: 'Maintain a consistent daily Vitamin K intake. Do not make drastic sudden dietary changes.',
    ),
    (
      keywords: ['theophylline', 'pseudoephedrine', 'ciprofloxacin'],
      foodItem: 'Caffeine (Coffee, Energy Drinks)',
      severity: InteractionSeverity.moderate,
      title: 'Additive CNS & Cardiac Stimulation',
      description: 'Decreased caffeine metabolism leads to tremors, palpitations, anxiety, and insomnia.',
      recommendation: 'Limit coffee, black tea, and energy drink consumption.',
    ),
  ];

  static const List<({
    List<String> conditionKeywords,
    List<String> medKeywords,
    InteractionSeverity severity,
    String title,
    String description,
    String recommendation,
  })> _conditionContraindicationRules = [
    (
      conditionKeywords: ['asthma', 'copd', 'bronchospasm', 'wheezing', 'respiratory'],
      medKeywords: ['timolol', 'betaxolol', 'propranolol', 'atenolol', 'metoprolol', 'carvedilol', 'labetalol'],
      severity: InteractionSeverity.critical,
      title: 'Asthma / COPD Bronchospasm Contraindication',
      description: 'Beta-blockers (even ophthalmic eye drops like Timolol) can trigger severe, life-threatening bronchoconstriction in patients with asthma or reactive airway disease.',
      recommendation: 'Inform your ophthalmologist immediately. Selective alpha-agonists (e.g. Brimonidine) or prostaglandin analogs (e.g. Latanoprost) are safer glaucoma alternatives.',
    ),
    (
      conditionKeywords: ['ulcer', 'peptic', 'gastritis', 'gerd', 'gastrointestinal bleed', 'stomach bleed'],
      medKeywords: ['ibuprofen', 'diclofenac', 'voveran', 'aceclofenac', 'zerodol', 'naproxen', 'aspirin', 'ecosprin', 'ketorolac'],
      severity: InteractionSeverity.critical,
      title: 'Peptic Ulcer / Gastrointestinal Bleeding Risk',
      description: 'NSAIDs inhibit gastric protective prostaglandins, causing severe ulceration, perforation, or acute gastrointestinal hemorrhage.',
      recommendation: 'Avoid oral NSAIDs. If analgesia is required, use Paracetamol or consult your physician for a selective COX-2 inhibitor with a proton pump inhibitor.',
    ),
    (
      conditionKeywords: ['hypertension', 'high blood pressure', 'bp'],
      medKeywords: ['pseudoephedrine', 'phenylephrine', 'sudafed', 'sinarest', 'nasivion', 'oxymetazoline'],
      severity: InteractionSeverity.moderate,
      title: 'Decongestant Blood Pressure Elevation',
      description: 'Sympathomimetic decongestants cause systemic vasoconstriction, causing sharp, dangerous blood pressure spikes in hypertensive patients.',
      recommendation: 'Use saline nasal sprays or steam inhalation instead of oral decongestants.',
    ),
    (
      conditionKeywords: ['bradycardia', 'heart block', 'slow pulse', 'arrhythmia'],
      medKeywords: ['timolol', 'metoprolol', 'atenolol', 'verapamil', 'diltiazem', 'digoxin'],
      severity: InteractionSeverity.critical,
      title: 'Severe Bradycardia / Heart Block Warning',
      description: 'These medications slow cardiac electrical conduction. In patients with baseline bradycardia, they can cause syncope, severe heart block, or cardiac arrest.',
      recommendation: 'Monitor resting pulse regularly. If pulse drops below 50 bpm, contact your cardiologist immediately.',
    ),
    (
      conditionKeywords: ['kidney', 'renal', 'ckd', 'nephropathy'],
      medKeywords: ['ibuprofen', 'diclofenac', 'aceclofenac', 'gentamicin', 'amikacin', 'methotrexate'],
      severity: InteractionSeverity.critical,
      title: 'Renal Function Deterioration (Nephrotoxicity)',
      description: 'NSAIDs reduce renal blood flow via afferent arteriolar constriction, accelerating acute kidney injury in patients with compromised kidney function.',
      recommendation: 'Never self-medicate with NSAID painkillers. Consult your nephrologist.',
    ),
    (
      conditionKeywords: ['glaucoma', 'closed-angle', 'intraocular pressure'],
      medKeywords: ['chlorpheniramine', 'diphenhydramine', 'amitriptyline', 'scopolamine', 'atropine'],
      severity: InteractionSeverity.critical,
      title: 'Angle-Closure Glaucoma Crisis Precaution',
      description: 'Anticholinergic drugs dilate the pupil and crowd the anterior chamber angle, triggering acute angle-closure glaucoma crises with rapid irreversible vision loss.',
      recommendation: 'Avoid over-the-counter anticholinergic antihistamines or sleeping aids without ophthalmologist clearance.',
    ),
  ];

  /// Checks interactions between currently active medications and newly scanned/added medications
  List<DrugInteractionWarning> checkInteractions({
    required List<Medication> existingMedications,
    required List<ParsedMedicationDraft> newDrafts,
  }) {
    final List<String> allDrugNames = [
      ...existingMedications.map((m) => m.name.toLowerCase()),
      ...newDrafts.map((d) => d.name.toLowerCase()),
    ];

    final List<DrugInteractionWarning> warnings = [];
    final Set<String> pairedKeys = {};

    for (int i = 0; i < allDrugNames.length; i++) {
      for (int j = i + 1; j < allDrugNames.length; j++) {
        final drug1 = allDrugNames[i];
        final drug2 = allDrugNames[j];

        // Check against rules
        for (final rule in _interactionRules) {
          final matchesA1 = rule.groupA.any((k) => drug1.contains(k));
          final matchesB2 = rule.groupB.any((k) => drug2.contains(k));
          final matchesA2 = rule.groupA.any((k) => drug2.contains(k));
          final matchesB1 = rule.groupB.any((k) => drug1.contains(k));

          // Prevent self-matching for non-eye drops
          if (drug1 == drug2 && rule.severity != InteractionSeverity.advisory) {
            continue;
          }

          if ((matchesA1 && matchesB2) || (matchesA2 && matchesB1)) {
            final pairKey = '${rule.title}_${[drug1, drug2]..sort()}';
            if (!pairedKeys.contains(pairKey)) {
              pairedKeys.add(pairKey);
              warnings.add(DrugInteractionWarning(
                drugA: drug1,
                drugB: drug2,
                severity: rule.severity,
                title: rule.title,
                description: rule.description,
                clinicalRecommendation: rule.recommendation,
              ));
            }
          }
        }
      }
    }

    return warnings;
  }

  /// Evaluates dietary, food and beverage interactions across all active medications
  List<FoodInteractionWarning> checkFoodInteractions(List<Medication> medications) {
    final List<FoodInteractionWarning> warnings = [];
    final Set<String> seen = {};

    for (final med in medications) {
      final nameLower = med.name.toLowerCase();
      for (final rule in _foodInteractionRules) {
        if (rule.keywords.any((k) => nameLower.contains(k))) {
          final key = '${rule.foodItem}_${med.name}';
          if (!seen.contains(key)) {
            seen.add(key);
            warnings.add(FoodInteractionWarning(
              foodItem: rule.foodItem,
              medicationName: med.name,
              severity: rule.severity,
              title: rule.title,
              description: rule.description,
              clinicalRecommendation: rule.recommendation,
            ));
          }
        }
      }
    }

    return warnings;
  }

  /// Evaluates patient medical conditions against active medications for clinical contraindications
  List<ConditionContraindicationWarning> checkConditionContraindications(
    List<Medication> medications,
    String? patientConditions,
  ) {
    if (patientConditions == null || patientConditions.trim().isEmpty) return [];
    final conditionsLower = patientConditions.toLowerCase();
    final List<ConditionContraindicationWarning> warnings = [];
    final Set<String> seen = {};

    for (final med in medications) {
      final nameLower = med.name.toLowerCase();
      for (final rule in _conditionContraindicationRules) {
        final matchesCondition = rule.conditionKeywords.any((c) => conditionsLower.contains(c));
        final matchesMed = rule.medKeywords.any((m) => nameLower.contains(m));

        if (matchesCondition && matchesMed) {
          final key = '${rule.title}_${med.name}';
          if (!seen.contains(key)) {
            seen.add(key);
            warnings.add(ConditionContraindicationWarning(
              condition: rule.conditionKeywords.first,
              medicationName: med.name,
              severity: rule.severity,
              title: rule.title,
              description: rule.description,
              clinicalRecommendation: rule.recommendation,
            ));
          }
        }
      }
    }

    return warnings;
  }
}
