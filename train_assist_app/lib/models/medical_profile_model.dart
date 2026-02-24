class MedicalProfile {
  final String bloodGroup;
  final String allergies;
  final String conditions;
  final String emergencyContact1Name;
  final String emergencyContact1Phone;
  final String emergencyContact2Name;
  final String emergencyContact2Phone;
  final String doctorName;
  final String doctorPhone;

  MedicalProfile({
    this.bloodGroup = '',
    this.allergies = '',
    this.conditions = '',
    this.emergencyContact1Name = '',
    this.emergencyContact1Phone = '',
    this.emergencyContact2Name = '',
    this.emergencyContact2Phone = '',
    this.doctorName = '',
    this.doctorPhone = '',
  });

  bool get isEmpty =>
      bloodGroup.isEmpty &&
      allergies.isEmpty &&
      conditions.isEmpty &&
      emergencyContact1Phone.isEmpty;

  Map<String, dynamic> toJson() => {
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'conditions': conditions,
        'emergencyContact1Name': emergencyContact1Name,
        'emergencyContact1Phone': emergencyContact1Phone,
        'emergencyContact2Name': emergencyContact2Name,
        'emergencyContact2Phone': emergencyContact2Phone,
        'doctorName': doctorName,
        'doctorPhone': doctorPhone,
      };

  factory MedicalProfile.fromJson(Map<String, dynamic> j) => MedicalProfile(
        bloodGroup: j['bloodGroup'] as String? ?? '',
        allergies: j['allergies'] as String? ?? '',
        conditions: j['conditions'] as String? ?? '',
        emergencyContact1Name: j['emergencyContact1Name'] as String? ?? '',
        emergencyContact1Phone: j['emergencyContact1Phone'] as String? ?? '',
        emergencyContact2Name: j['emergencyContact2Name'] as String? ?? '',
        emergencyContact2Phone: j['emergencyContact2Phone'] as String? ?? '',
        doctorName: j['doctorName'] as String? ?? '',
        doctorPhone: j['doctorPhone'] as String? ?? '',
      );

  MedicalProfile copyWith({
    String? bloodGroup,
    String? allergies,
    String? conditions,
    String? emergencyContact1Name,
    String? emergencyContact1Phone,
    String? emergencyContact2Name,
    String? emergencyContact2Phone,
    String? doctorName,
    String? doctorPhone,
  }) =>
      MedicalProfile(
        bloodGroup: bloodGroup ?? this.bloodGroup,
        allergies: allergies ?? this.allergies,
        conditions: conditions ?? this.conditions,
        emergencyContact1Name:
            emergencyContact1Name ?? this.emergencyContact1Name,
        emergencyContact1Phone:
            emergencyContact1Phone ?? this.emergencyContact1Phone,
        emergencyContact2Name:
            emergencyContact2Name ?? this.emergencyContact2Name,
        emergencyContact2Phone:
            emergencyContact2Phone ?? this.emergencyContact2Phone,
        doctorName: doctorName ?? this.doctorName,
        doctorPhone: doctorPhone ?? this.doctorPhone,
      );
}
