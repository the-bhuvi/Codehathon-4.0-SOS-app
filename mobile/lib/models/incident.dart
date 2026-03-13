class Incident {
  final String id;
  final double lat;
  final double lng;
  final String? severity;
  final double? severityScore;
  final String? message;
  final String? originalMessage;
  final String? translatedMessage;
  final String? detectedLanguage;
  final String? emergencyType;
  final String? agency;
  final String? audioUrl;
  final String? videoUrl;
  final String? voiceTranscript;
  final String? userName;
  final String? userPhone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodGroup;
  final String? medicalConditions;
  final String status;
  final DateTime createdAt;

  Incident({
    required this.id,
    required this.lat,
    required this.lng,
    this.severity,
    this.severityScore,
    this.message,
    this.originalMessage,
    this.translatedMessage,
    this.detectedLanguage,
    this.emergencyType,
    this.agency,
    this.audioUrl,
    this.videoUrl,
    this.voiceTranscript,
    this.userName,
    this.userPhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodGroup,
    this.medicalConditions,
    required this.status,
    required this.createdAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      severity: json['severity'] as String?,
      severityScore: (json['severity_score'] as num?)?.toDouble(),
      message: json['message'] as String?,
      originalMessage: json['original_message'] as String?,
      translatedMessage: json['translated_message'] as String?,
      detectedLanguage: json['detected_language'] as String?,
      emergencyType: json['emergency_type'] as String?,
      agency: json['agency'] as String?,
      audioUrl: json['audio_url'] as String?,
      videoUrl: json['video_url'] as String?,
      voiceTranscript: json['voice_transcript'] as String?,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      bloodGroup: json['blood_group'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'severity': severity,
        'severity_score': severityScore,
        'message': message,
        'original_message': originalMessage,
        'translated_message': translatedMessage,
        'detected_language': detectedLanguage,
        'emergency_type': emergencyType,
        'agency': agency,
        'audio_url': audioUrl,
        'video_url': videoUrl,
        'voice_transcript': voiceTranscript,
        'user_name': userName,
        'user_phone': userPhone,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'blood_group': bloodGroup,
        'medical_conditions': medicalConditions,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  Incident copyWith({String? status, String? severity}) {
    return Incident(
      id: id, lat: lat, lng: lng,
      severity: severity ?? this.severity,
      severityScore: severityScore,
      message: message,
      originalMessage: originalMessage,
      translatedMessage: translatedMessage,
      detectedLanguage: detectedLanguage,
      emergencyType: emergencyType,
      agency: agency,
      audioUrl: audioUrl,
      videoUrl: videoUrl,
      voiceTranscript: voiceTranscript,
      userName: userName,
      userPhone: userPhone,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      bloodGroup: bloodGroup,
      medicalConditions: medicalConditions,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
