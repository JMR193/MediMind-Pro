/// User Profile Domain Model
class UserProfile {
  final String id;
  final String name;
  final String relationship; // 'Self', 'Mother', 'Father', 'Child', 'Spouse', 'Pet', 'Other'
  final bool isPrimaryUser;
  final String colorHex;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? primaryDoctorName;
  final String? primaryDoctorPhone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? allergies;
  final String? medicalConditions;
  final String? avatarPath;
  final String? notes;

  const UserProfile({
    required this.id,
    required this.name,
    this.relationship = 'Self',
    this.isPrimaryUser = false,
    this.colorHex = '#0284C7',
    this.dateOfBirth,
    this.bloodGroup,
    this.primaryDoctorName,
    this.primaryDoctorPhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.allergies,
    this.medicalConditions,
    this.avatarPath,
    this.notes,
  });

  int? get ageYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'isPrimaryUser': isPrimaryUser,
        'colorHex': colorHex,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'bloodGroup': bloodGroup,
        'primaryDoctorName': primaryDoctorName,
        'primaryDoctorPhone': primaryDoctorPhone,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'allergies': allergies,
        'medicalConditions': medicalConditions,
        'avatarPath': avatarPath,
        'notes': notes,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Patient',
        relationship: json['relationship'] as String? ?? 'Self',
        isPrimaryUser: json['isPrimaryUser'] as bool? ?? false,
        colorHex: json['colorHex'] as String? ?? '#0284C7',
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'] as String)
            : null,
        bloodGroup: json['bloodGroup'] as String?,
        primaryDoctorName: json['primaryDoctorName'] as String?,
        primaryDoctorPhone: json['primaryDoctorPhone'] as String?,
        emergencyContactName: json['emergencyContactName'] as String?,
        emergencyContactPhone: json['emergencyContactPhone'] as String?,
        allergies: json['allergies'] as String?,
        medicalConditions: json['medicalConditions'] as String?,
        avatarPath: json['avatarPath'] as String?,
        notes: json['notes'] as String?,
      );

  UserProfile copyWith({
    String? id,
    String? name,
    String? relationship,
    bool? isPrimaryUser,
    String? colorHex,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? primaryDoctorName,
    String? primaryDoctorPhone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? allergies,
    String? medicalConditions,
    String? avatarPath,
    String? notes,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        isPrimaryUser: isPrimaryUser ?? this.isPrimaryUser,
        colorHex: colorHex ?? this.colorHex,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        primaryDoctorName: primaryDoctorName ?? this.primaryDoctorName,
        primaryDoctorPhone: primaryDoctorPhone ?? this.primaryDoctorPhone,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
        allergies: allergies ?? this.allergies,
        medicalConditions: medicalConditions ?? this.medicalConditions,
        avatarPath: avatarPath ?? this.avatarPath,
        notes: notes ?? this.notes,
      );
}
