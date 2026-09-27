import 'dart:collection';

/// Clinical severity of a drug-food or drug-nutrient interaction.
enum InteractionSeverity {
  /// Absolutely contraindicated: severe toxicity or mortality risk.
  contraindicated,

  /// High clinical risk: significant alterations in bioavailability or clearance.
  major,

  /// Moderate clinical risk: requires temporal spacing or dose adjustment.
  moderate,

  /// Minor or informational: slight absorption delays or mild synergy.
  minor,
}

/// Pharmacological mechanism underpinning the food-drug interaction.
enum InteractionMechanism {
  /// Cytochrome P450 3A4 enzyme inhibition (e.g. Grapefruit furanocoumarins).
  cyp3a4Inhibition,

  /// Cytochrome P450 enzyme induction (e.g. St. John's Wort).
  cypInduction,

  /// Insoluble chelation complex with multivalent cations (Ca2+, Mg2+, Fe2+, Al3+).
  chelation,

  /// Pharmacodynamic antagonism (e.g. Vitamin K counteracting Warfarin).
  pharmacodynamicAntagonism,

  /// Synergistic CNS or respiratory depression.
  cnsDepressionSynergy,

  /// Potassium retention synergism resulting in severe hyperkalemia.
  hyperkalemiaSynergy,

  /// Competitive transport across blood-brain barrier (e.g. Large Neutral Amino Acids).
  competitiveTransportInhibition,

  /// Gastric mucosal irritation or bleeding risk synergy.
  gastrointestinalIrritation,

  /// Vasopressor amine accumulation (e.g. Tyramine hypertensive crisis).
  tyraminePressorCrisis,

  /// Aldehyde dehydrogenase inhibition causing disulfiram-like reaction.
  disulfiramReaction,
}

/// Structured drug-food interaction rule.
class DrugFoodRule {
  final String id;
  final List<String> drugKeywords;
  final List<String> foodKeywords;
  final String foodCategory;
  final InteractionSeverity severity;
  final InteractionMechanism mechanism;
  final String clinicalEffect;
  final String patientInstruction;
  final int requiredSpacingHours; // 0 if absolute avoidance
  final String scientificRationale;

  const DrugFoodRule({
    required this.id,
    required this.drugKeywords,
    required this.foodKeywords,
    required this.foodCategory,
    required this.severity,
    required this.mechanism,
    required this.clinicalEffect,
    required this.patientInstruction,
    this.requiredSpacingHours = 0,
    required this.scientificRationale,
  });
}

/// Detection result returned when checking a patient's regimen.
class FoodInteractionAlert {
  final String medicationName;
  final String foodItem;
  final DrugFoodRule rule;
  final DateTime detectedAt;

  const FoodInteractionAlert({
    required this.medicationName,
    required this.foodItem,
    required this.rule,
    required this.detectedAt,
  });

  InteractionSeverity get severity => rule.severity;
  String get title => '${rule.foodCategory} + $medicationName';
  String get instructions => rule.patientInstruction;
  String get mechanismText => rule.clinicalEffect;
}

/// Comprehensive On-Device Drug-Food-Nutrient Interaction AI Engine.
///
/// Grounded in FDA Biopharmaceutics guidelines, Cytochrome P450 tables,
/// and clinical pharmacokinetics (zero cloud telemetry required).
class DrugFoodInteractionAiService {
  static final List<DrugFoodRule> _knowledgeBase = [
    // 1. Grapefruit (Furanocoumarins) & CYP3A4 Substrates
    const DrugFoodRule(
      id: 'food_grapefruit_statins',
      drugKeywords: [
        'atorvastatin',
        'simvastatin',
        'lovastatin',
        'lipitor',
        'zocor'
      ],
      foodKeywords: ['grapefruit', 'pomelo', 'seville orange', 'tangelo'],
      foodCategory: 'Grapefruit & Citrus Furanocoumarins',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.cyp3a4Inhibition,
      clinicalEffect:
          'Furanocoumarins irreversibly inhibit intestinal CYP3A4, causing up to a 12-fold increase in statin plasma levels, dramatically raising rhabdomyolysis and acute kidney injury risk.',
      patientInstruction:
          'Completely avoid grapefruit juice and fresh grapefruit while on this statin. Consider asking your doctor about Rosuvastatin or Pravastatin which do not rely on CYP3A4.',
      requiredSpacingHours: 0, // Cannot be solved by spacing due to irreversible enzyme inhibition lasting >48h
      scientificRationale:
          'Intestinal CYP3A4 enterocyte degradation requires 48-72 hours for de novo protein synthesis. Temporal spacing within the day is ineffective.',
    ),

    const DrugFoodRule(
      id: 'food_grapefruit_ccb',
      drugKeywords: [
        'amlodipine',
        'nifedipine',
        'felodipine',
        'verapamil',
        'diltiazem',
        'norvasc',
        'procardia'
      ],
      foodKeywords: ['grapefruit', 'pomelo'],
      foodCategory: 'Grapefruit & Citrus Furanocoumarins',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.cyp3a4Inhibition,
      clinicalEffect:
          'Elevated calcium channel blocker concentrations leading to profound hypotension, orthostatic syncope, bradycardia, and peripheral edema.',
      patientInstruction:
          'Avoid grapefruit and grapefruit juice. If consumed, monitor blood pressure closely for severe drops and dizziness.',
      requiredSpacingHours: 0,
      scientificRationale:
          'Extensive first-pass intestinal metabolism is blunted by furanocoumarins (bergamottin and 6\',7\'-dihydroxybergamottin).',
    ),

    // 2. Vitamin K Rich Foods & Warfarin
    const DrugFoodRule(
      id: 'food_vitamink_warfarin',
      drugKeywords: ['warfarin', 'coumadin', 'jantoven'],
      foodKeywords: [
        'spinach',
        'kale',
        'broccoli',
        'brussels sprouts',
        'collard greens',
        'cabbage',
        'green tea',
        'seaweed',
        'natto'
      ],
      foodCategory: 'Vitamin K Rich Foods',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.pharmacodynamicAntagonism,
      clinicalEffect:
          'Vitamin K competitively overcomes Warfarin\'s inhibition of VKORC1 (Vitamin K epoxide reductase), decreasing INR and promoting thrombosis/stroke risk.',
      patientInstruction:
          'Do NOT eliminate greens entirely, but maintain a STRICTLY CONSISTENT daily intake. Sudden increases or decreases in green leafy vegetables will destabilize your INR.',
      requiredSpacingHours: 0,
      scientificRationale:
          'Warfarin acts by inhibiting vitamin K recycling. Acute fluctuations in dietary phylloquinone directly counteract therapeutic anticoagulation.',
    ),

    // 3. Calcium, Dairy & Polyvalent Cation Chelation
    const DrugFoodRule(
      id: 'food_dairy_tetracyclines',
      drugKeywords: [
        'doxycycline',
        'tetracycline',
        'minocycline',
        'vibramycin'
      ],
      foodKeywords: [
        'milk',
        'cheese',
        'yogurt',
        'calcium',
        'antacid',
        'ice cream',
        'tofu with calcium'
      ],
      foodCategory: 'Dairy & Multivalent Cations (Ca2+, Mg2+, Fe2+)',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.chelation,
      clinicalEffect:
          'Calcium ions bind directly to the tetracycline molecule in the gastrointestinal tract, forming an insoluble, unabsorbable chelate complex (bioavailability plummets by 50-80%).',
      patientInstruction:
          'Take this antibiotic on an empty stomach with a full glass of water. Wait at least 2 HOURS before or 4 HOURS after consuming milk, yogurt, cheese, or antacids.',
      requiredSpacingHours: 2,
      scientificRationale:
          'Polyvalent metal ions (Ca2+, Mg2+, Al3+, Fe2+) coordinate with 1,3-diketone and phenolic groups on tetracyclines, forming neutral insoluble precipitates.',
    ),

    const DrugFoodRule(
      id: 'food_dairy_fluoroquinolones',
      drugKeywords: [
        'ciprofloxacin',
        'levofloxacin',
        'moxifloxacin',
        'cipro',
        'levaquin'
      ],
      foodKeywords: [
        'milk',
        'dairy',
        'calcium fortified juice',
        'magnesium antacid',
        'iron supplement'
      ],
      foodCategory: 'Dairy & Polyvalent Cations',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.chelation,
      clinicalEffect:
          'Ciprofloxacin binds strongly to divalent/trivalent cations, resulting in therapeutic failure of antibiotic coverage and potential development of resistant bacteria.',
      patientInstruction:
          'Take at least 2 hours before or 4-6 hours after milk, yogurt, calcium-fortified orange juice, or iron/magnesium vitamins.',
      requiredSpacingHours: 2,
      scientificRationale:
          'The 4-keto and 3-carboxyl groups of fluoroquinolones form insoluble bidentate chelates with Ca2+ and Mg2+.',
    ),

    const DrugFoodRule(
      id: 'food_dairy_levothyroxine',
      drugKeywords: ['levothyroxine', 'synthroid', 'euthyrox', 'levoxyl'],
      foodKeywords: [
        'milk',
        'calcium',
        'soy',
        'coffee',
        'espresso',
        'iron',
        'papaya'
      ],
      foodCategory: 'Dairy, Coffee & Soy Protein',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.chelation,
      clinicalEffect:
          'Calcium, dietary fiber, espresso, and soy protein physically bind thyroxine (T4) in the stomach, reducing bioavailability and causing uncontrolled hypothyroidism (TSH elevation).',
      patientInstruction:
          'Take Levothyroxine immediately upon waking with a full glass of plain water. Wait a minimum of 30-60 MINUTES before breakfast or coffee, and 4 HOURS before calcium/iron supplements.',
      requiredSpacingHours: 4,
      scientificRationale:
          'Levothyroxine absorption occurs primarily in the jejunum/ileum and requires an acidic gastric environment. Food and coffee raise pH and adsorb T4.',
    ),

    // 4. Potassium-Rich Foods & ACE Inhibitors / ARBs / Spironolactone
    const DrugFoodRule(
      id: 'food_potassium_raas',
      drugKeywords: [
        'lisinopril',
        'losartan',
        'spironolactone',
        'enalapril',
        'ramipril',
        'valsartan',
        'aldactone'
      ],
      foodKeywords: [
        'banana',
        'salt substitute',
        'potassium chloride',
        'avocado',
        'coconut water',
        'dried apricots',
        'blackstrap molasses'
      ],
      foodCategory: 'High-Potassium Foods & Salt Substitutes',
      severity: InteractionSeverity.major,
      mechanism: InteractionMechanism.hyperkalemiaSynergy,
      clinicalEffect:
          'Inhibition of aldosterone by ACEi/ARBs/spironolactone impairs renal potassium excretion. Excessive dietary potassium can trigger life-threatening hyperkalemia and cardiac arrhythmias.',
      patientInstruction:
          'Avoid salt substitutes containing Potassium Chloride (KCl) and limit massive daily intake of bananas and coconut water. Report any sudden muscle weakness, tingling, or palpitations immediately.',
      requiredSpacingHours: 0,
      scientificRationale:
          'Aldosterone mediates renal cortical collecting duct Na+/K+ ATPase exchange. Blunting aldosterone while supplementing potassium creates potassium retention.',
    ),

    // 5. Alcohol & CNS Depressants / Sedatives / Metronidazole
    const DrugFoodRule(
      id: 'food_alcohol_cns',
      drugKeywords: [
        'alprazolam',
        'lorazepam',
        'clonazepam',
        'diazepam',
        'zolpidem',
        'ambien',
        'xanax',
        'ativan',
        'gabapentin',
        'pregabalin',
        'tramadol',
        'oxycodone'
      ],
      foodKeywords: ['alcohol', 'wine', 'beer', 'whiskey', 'vodka', 'liquor'],
      foodCategory: 'Alcoholic Beverages',
      severity: InteractionSeverity.contraindicated,
      mechanism: InteractionMechanism.cnsDepressionSynergy,
      clinicalEffect:
          'Dangerous synergistic potentiation of central nervous system and respiratory depression. Can lead to profound sedation, coma, respiratory arrest, and death.',
      patientInstruction:
          'STRICTLY AVOID ALL ALCOHOL. Combining alcohol with sedatives or pain medications is potentially fatal.',
      requiredSpacingHours: 0,
      scientificRationale:
          'GABA-A receptor allosteric potentiation by ethanol and benzodiazepines synergistically hyperpolarizes neuronal membranes, blunting medullary respiratory drive.',
    ),

    const DrugFoodRule(
      id: 'food_alcohol_metronidazole',
      drugKeywords: ['metronidazole', 'flagyl', 'tinidazole'],
      foodKeywords: [
        'alcohol',
        'wine',
        'beer',
        'cocktails',
        'cough syrup with alcohol'
      ],
      foodCategory: 'Alcoholic Beverages & Tonics',
      severity: InteractionSeverity.contraindicated,
      mechanism: InteractionMechanism.disulfiramReaction,
      clinicalEffect:
          'Severe disulfiram-like acetaldehyde toxicity: throbbing headache, violent vomiting, facial flushing, tachycardia, hypotension, and chest tightness.',
      patientInstruction:
          'Do NOT drink any alcohol during treatment and for at least 72 HOURS after your last dose of metronidazole. Check cough syrups and mouthwashes for hidden alcohol.',
      requiredSpacingHours: 72,
      scientificRationale:
          'Inhibition of hepatic aldehyde dehydrogenase (ALDH) causes toxic accumulation of acetaldehyde following ethanol ingestion.',
    ),

    // 6. Tyramine-Rich Foods & MAO Inhibitors
    const DrugFoodRule(
      id: 'food_tyramine_maoi',
      drugKeywords: [
        'selegiline',
        'rasagiline',
        'phenelzine',
        'tranylcypromine',
        'linezolid',
        'zyvox'
      ],
      foodKeywords: [
        'aged cheese',
        'parmesan',
        'cheddar',
        'cured meat',
        'salami',
        'soy sauce',
        'miso',
        'draft beer',
        'red wine',
        'sauerkraut'
      ],
      foodCategory: 'Tyramine-Rich Aged & Fermented Foods',
      severity: InteractionSeverity.contraindicated,
      mechanism: InteractionMechanism.tyraminePressorCrisis,
      clinicalEffect:
          'Dietary tyramine cannot be degraded in the gut/liver due to MAO inhibition. Tyramine enters systemic circulation, releasing massive norepinephrine and causing malignant hypertensive crisis and intracranial hemorrhage.',
      patientInstruction:
          'Follow a strict low-tyramine diet. Avoid aged cheeses, cured meats, fermented soybeans, and tap beers. Seek immediate emergency care for severe sudden occipital headache.',
      requiredSpacingHours: 0,
      scientificRationale:
          'Monoamine oxidase-A in intestinal mucosa normally metabolizes ingested tyramine. MAO inhibition allows tyramine to act as a false neurotransmitter displacing vesicular norepinephrine.',
    ),

    // 7. High-Protein Meals & Levodopa (Parkinson\'s Disease)
    const DrugFoodRule(
      id: 'food_protein_levodopa',
      drugKeywords: ['levodopa', 'carbidopa', 'sinemet', 'rytary', 'stalevo'],
      foodKeywords: [
        'steak',
        'chicken',
        'protein shake',
        'eggs',
        'whey protein',
        'fish',
        'beef'
      ],
      foodCategory: 'High-Protein Meals',
      severity: InteractionSeverity.moderate,
      mechanism: InteractionMechanism.competitiveTransportInhibition,
      clinicalEffect:
          'Large Neutral Amino Acids (LNAAs) from dietary protein compete directly with Levodopa for intestinal absorption and blood-brain barrier transport, triggering acute "off" episodes and motor freezes.',
      patientInstruction:
          'Take Levodopa 30-45 minutes before meals or 1-2 hours after meals. If experiencing nausea, consume with a small carbohydrate snack (e.g. crackers), not high-protein foods.',
      requiredSpacingHours: 1,
      scientificRationale:
          'Both Levodopa and amino acids (leucine, isoleucine, valine, phenylalanine) depend on the LAT1 (L-type amino acid transporter 1) to cross the blood-brain barrier.',
    ),

    // 8. St. John's Wort & CYP3A4 / P-gp Substrates
    const DrugFoodRule(
      id: 'food_stjohnswort_cypsubstrates',
      drugKeywords: [
        'cyclosporine',
        'tacrolimus',
        'apixaban',
        'rivaroxaban',
        'eliquis',
        'xarelto',
        'oral contraceptive',
        'birth control',
        'estrogen',
        'sertraline',
        'fluoxetine',
        'escitalopram'
      ],
      foodKeywords: [
        'st. john\'s wort',
        'hypericum',
        'herbal depression supplement'
      ],
      foodCategory: 'St. John\'s Wort (Herbal)',
      severity: InteractionSeverity.contraindicated,
      mechanism: InteractionMechanism.cypInduction,
      clinicalEffect:
          'Potent P-glycoprotein and CYP3A4 induction decreases medication blood levels leading to organ transplant rejection, stroke from anticoagulant failure, or unintended pregnancy. Combined with SSRIs, causes Serotonin Syndrome.',
      patientInstruction:
          'Do NOT take St. John\'s Wort with any prescribed medications without explicit physician approval.',
      requiredSpacingHours: 0,
      scientificRationale:
          'Hyperforin activates the Pregnane X Receptor (PXR), profoundly up-regulating CYP3A4 and ABCB1 (MDR1) transporter expression throughout the body.',
    ),

    // 9. NSAIDs & Food (Gastric Protection)
    const DrugFoodRule(
      id: 'food_nsaid_stomach',
      drugKeywords: [
        'ibuprofen',
        'naproxen',
        'aspirin',
        'diclofenac',
        'meloxicam',
        'advil',
        'aleve'
      ],
      foodKeywords: ['empty stomach', 'fasting'],
      foodCategory: 'Empty Stomach Fasting',
      severity: InteractionSeverity.moderate,
      mechanism: InteractionMechanism.gastrointestinalIrritation,
      clinicalEffect:
          'Inhibition of gastric protective prostaglandins (PGE2) combined with direct topical acid irritation risks peptic ulceration, gastritis, and gastrointestinal bleeding.',
      patientInstruction:
          'Always take NSAIDs with a meal, snack, or glass of milk to protect your stomach lining. Never take on an empty stomach if you have a history of ulcers.',
      requiredSpacingHours: 0,
      scientificRationale:
          'Systemic COX-1 inhibition reduces mucosal blood flow and bicarbonate secretion; food buffers local direct irritation.',
    ),
  ];

  /// Get total registered clinical rules.
  static int get ruleCount => _knowledgeBase.length;

  /// Analyze a list of prescribed medications against all known food, drink, and supplement interactions.
  static List<FoodInteractionAlert> scanCabinetForFoodInteractions(
      List<String> medicationNames) {
    final alerts = <FoodInteractionAlert>[];
    final seen = <String>{};

    for (final med in medicationNames) {
      final cleanMed = med.toLowerCase().trim();

      for (final rule in _knowledgeBase) {
        final matchesMed = rule.drugKeywords.any((kw) =>
            cleanMed.contains(kw.toLowerCase()) ||
            kw.toLowerCase().contains(cleanMed));

        if (matchesMed) {
          final alertKey = '${rule.id}_$cleanMed';
          if (!seen.contains(alertKey)) {
            seen.add(alertKey);
            alerts.add(FoodInteractionAlert(
              medicationName: med,
              foodItem: rule.foodKeywords.first,
              rule: rule,
              detectedAt: DateTime.now(),
            ));
          }
        }
      }
    }

    // Sort by severity (contraindicated first, then major, then moderate)
    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return UnmodifiableListView(alerts);
  }

  /// Instant query: Patient enters a food, drink, or supplement name (e.g. "grapefruit juice", "milk", "kale")
  /// and checks if it conflicts with their active cabinet.
  static List<FoodInteractionAlert> checkFoodItemAgainstCabinet({
    required String queryFood,
    required List<String> activeMedications,
  }) {
    final cleanFood = queryFood.toLowerCase().trim();
    final alerts = <FoodInteractionAlert>[];

    for (final med in activeMedications) {
      final cleanMed = med.toLowerCase().trim();

      for (final rule in _knowledgeBase) {
        final matchesMed = rule.drugKeywords.any((kw) =>
            cleanMed.contains(kw.toLowerCase()) ||
            kw.toLowerCase().contains(cleanMed));

        final matchesFood = rule.foodKeywords.any((fk) =>
            cleanFood.contains(fk.toLowerCase()) ||
            fk.toLowerCase().contains(cleanFood));

        if (matchesMed && matchesFood) {
          alerts.add(FoodInteractionAlert(
            medicationName: med,
            foodItem: queryFood,
            rule: rule,
            detectedAt: DateTime.now(),
          ));
        }
      }
    }

    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return alerts;
  }

  /// Returns common food interaction items for quick chips in UI.
  static const List<String> commonFoodQueryChips = [
    '🍊 Grapefruit Juice',
    '🥛 Milk & Dairy',
    '🥬 Spinach & Kale (Vitamin K)',
    '🍌 Bananas (Potassium)',
    '☕ Coffee & Espresso',
    '🍷 Wine & Beer (Alcohol)',
    '🥩 High-Protein Steak',
    '🧀 Aged Cheeses (Tyramine)',
    '🌿 St. John\'s Wort',
    '💊 Calcium / Iron Pills',
  ];
}
