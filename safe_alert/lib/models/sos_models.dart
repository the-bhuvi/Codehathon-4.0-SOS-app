class SOSRequest {
  final String message;
  final double latitude;
  final double longitude;
  final String timestamp;

  SOSRequest({
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      };
}

class SOSResponse {
  final bool success;
  final String aiSeverity;
  final Map<String, dynamic>? storedIncident;

  SOSResponse({
    required this.success,
    required this.aiSeverity,
    this.storedIncident,
  });

  factory SOSResponse.fromJson(Map<String, dynamic> json) {
    return SOSResponse(
      success: json['success'] as bool? ?? false,
      aiSeverity: json['ai_severity'] as String? ?? 'MEDIUM',
      storedIncident: json['stored_incident'] as Map<String, dynamic>?,
    );
  }
}
