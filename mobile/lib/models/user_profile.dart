class UserProfile {
  final String fullName;
  final String phone;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final String medicalConditions;

  const UserProfile({
    this.fullName = '',
    this.phone = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bloodGroup = '',
    this.medicalConditions = '',
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'blood_group': bloodGroup,
        'medical_conditions': medicalConditions,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      emergencyContactName: json['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? '',
      medicalConditions: json['medical_conditions'] as String? ?? '',
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? medicalConditions,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalConditions: medicalConditions ?? this.medicalConditions,
    );
  }

  bool get isComplete => fullName.isNotEmpty && phone.isNotEmpty;
}
