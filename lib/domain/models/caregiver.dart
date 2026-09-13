class Caregiver {
  final String id;
  final String name;
  final String relationship; // e.g. 'Spouse', 'Child', 'Nurse'
  final String? phone;
  final String? email;
  final int missedDosesBeforeAlert; // alert after N consecutive misses
  final bool isActive;
  final DateTime addedAt;

  const Caregiver({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.email,
    this.missedDosesBeforeAlert = 2,
    this.isActive = true,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'missedDosesBeforeAlert': missedDosesBeforeAlert,
        'isActive': isActive,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Caregiver.fromJson(Map<String, dynamic> json) => Caregiver(
        id: json['id'] as String,
        name: json['name'] as String,
        relationship: json['relationship'] as String? ?? 'Caregiver',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        missedDosesBeforeAlert: json['missedDosesBeforeAlert'] as int? ?? 2,
        isActive: json['isActive'] as bool? ?? true,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
