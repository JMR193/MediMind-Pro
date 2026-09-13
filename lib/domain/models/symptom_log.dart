/// Symptom severity scale 1-10
enum SymptomType {
  redness,
  pain,
  blurredVision,
  discharge,
  irritation,
  headache,
  dryness,
  lightSensitivity,
  floaters,
  swelling,
  other,
}

class SymptomLog {
  final String id;
  final DateTime timestamp;
  final SymptomType symptomType;
  final String? customSymptom; // if type == other
  final int severity; // 1-10
  final String? notes;
  final String? affectedEye; // 'Left', 'Right', 'Both', 'None'
  final bool escalationTriggered;

  const SymptomLog({
    required this.id,
    required this.timestamp,
    required this.symptomType,
    this.customSymptom,
    required this.severity,
    this.notes,
    this.affectedEye,
    this.escalationTriggered = false,
  });

  /// Returns true if severity warrants urgent care referral
  bool get requiresUrgentEscalation =>
      severity >= 8 ||
      symptomType == SymptomType.floaters ||
      symptomType == SymptomType.blurredVision && severity >= 6;

  String get symptomLabel {
    switch (symptomType) {
      case SymptomType.redness:
        return 'Redness';
      case SymptomType.pain:
        return 'Eye Pain';
      case SymptomType.blurredVision:
        return 'Blurred Vision';
      case SymptomType.discharge:
        return 'Discharge';
      case SymptomType.irritation:
        return 'Irritation / Itching';
      case SymptomType.headache:
        return 'Headache';
      case SymptomType.dryness:
        return 'Dryness';
      case SymptomType.lightSensitivity:
        return 'Light Sensitivity';
      case SymptomType.floaters:
        return 'Floaters / Flashes';
      case SymptomType.swelling:
        return 'Swelling';
      case SymptomType.other:
        return customSymptom ?? 'Other';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'symptomType': symptomType.index,
        'customSymptom': customSymptom,
        'severity': severity,
        'notes': notes,
        'affectedEye': affectedEye,
        'escalationTriggered': escalationTriggered,
      };

  factory SymptomLog.fromJson(Map<String, dynamic> json) => SymptomLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        symptomType: SymptomType.values[json['symptomType'] as int? ?? 0],
        customSymptom: json['customSymptom'] as String?,
        severity: json['severity'] as int? ?? 1,
        notes: json['notes'] as String?,
        affectedEye: json['affectedEye'] as String?,
        escalationTriggered: json['escalationTriggered'] as bool? ?? false,
      );
}
