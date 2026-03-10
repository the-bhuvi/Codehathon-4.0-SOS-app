class Incident {
  final String id;
  final double lat;
  final double lng;
  final String? severity;
  final String? message;
  final String status;
  final DateTime createdAt;

  Incident({
    required this.id,
    required this.lat,
    required this.lng,
    this.severity,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      severity: json['severity'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'severity': severity,
        'message': message,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  Incident copyWith({String? status, String? severity}) {
    return Incident(
      id: id,
      lat: lat,
      lng: lng,
      severity: severity ?? this.severity,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
