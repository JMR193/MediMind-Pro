enum SeverityLevel {
  low,
  moderate,
  high,
  critical,
}

class DrugInteractionWarning {
  final String substance1;
  final String substance2;
  final SeverityLevel severity;
  final String clinicalImpact;
  final String recommendation;

  DrugInteractionWarning({
    required this.substance1,
    required this.substance2,
    required this.severity,
    required this.clinicalImpact,
    required this.recommendation,
  });

  static List<DrugInteractionWarning> getKnownInteractions() {
    return [
      DrugInteractionWarning(
        substance1: "Atorvastatin / Simvastatin",
        substance2: "Grapefruit Juice",
        severity: SeverityLevel.high,
        clinicalImpact: "Grapefruit inhibits CYP3A4, dramatically increasing statin levels in blood and risking rhabdomyolysis.",
        recommendation: "Avoid consuming grapefruit or grapefruit juice while taking statin medications.",
      ),
      DrugInteractionWarning(
        substance1: "Ciprofloxacin / Levofloxacin",
        substance2: "Calcium / Milk / Antacids",
        severity: SeverityLevel.high,
        clinicalImpact: "Multivalent cations chelate quinolone antibiotics, reducing absorption by up to 90%.",
        recommendation: "Take antibiotic 2 hours before or 6 hours after dairy or calcium supplements.",
      ),
      DrugInteractionWarning(
        substance1: "Latanoprost",
        substance2: "Timolol Drops",
        severity: SeverityLevel.moderate,
        clinicalImpact: "Multiple eye drop formulations applied concurrently wash each other out before ocular surface absorption.",
        recommendation: "Maintain a strict 5 to 10 minute interval between administering different eye drop medications.",
      ),
      DrugInteractionWarning(
        substance1: "Warfarin",
        substance2: "Ibuprofen / Aspirin / NSAIDs",
        severity: SeverityLevel.critical,
        clinicalImpact: "NSAIDs inhibit platelet function and irritate gastric mucosa, multiplying gastrointestinal hemorrhage risk.",
        recommendation: "Consult your prescribing doctor before taking any OTC pain relievers with Warfarin.",
      ),
      DrugInteractionWarning(
        substance1: "Levothyroxine",
        substance2: "Coffee / Food",
        severity: SeverityLevel.moderate,
        clinicalImpact: "Dietary fiber and espresso reduce thyroid hormone absorption.",
        recommendation: "Take on an empty stomach with a full glass of plain water 30–60 minutes before breakfast.",
      ),
    ];
  }
}
