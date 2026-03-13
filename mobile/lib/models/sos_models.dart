class SOSRequest {
  final String message;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String emergencyType;
  final String userName;
  final String userPhone;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final String medicalConditions;

  SOSRequest({
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.emergencyType = 'general',
    this.userName = '',
    this.userPhone = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bloodGroup = '',
    this.medicalConditions = '',
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'emergency_type': emergencyType,
        'user_name': userName,
        'user_phone': userPhone,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'blood_group': bloodGroup,
        'medical_conditions': medicalConditions,
      };
}

class SOSResponse {
  final bool success;
  final String aiSeverity;
  final double? severityScore;
  final String? detectedLanguage;
  final String? translatedMessage;
  final String? agency;
  final Map<String, dynamic>? storedIncident;

  SOSResponse({
    required this.success,
    required this.aiSeverity,
    this.severityScore,
    this.detectedLanguage,
    this.translatedMessage,
    this.agency,
    this.storedIncident,
  });

  factory SOSResponse.fromJson(Map<String, dynamic> json) {
    return SOSResponse(
      success: json['success'] as bool? ?? false,
      aiSeverity: json['ai_severity'] as String? ?? 'MEDIUM',
      severityScore: (json['severity_score'] as num?)?.toDouble(),
      detectedLanguage: json['detected_language'] as String?,
      translatedMessage: json['translated_message'] as String?,
      agency: json['agency'] as String?,
      storedIncident: json['stored_incident'] as Map<String, dynamic>?,
    );
  }
}
