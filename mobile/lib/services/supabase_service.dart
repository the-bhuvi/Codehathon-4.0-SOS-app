import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safe_alert/models/incident.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Incident>> getIncidents({String? deviceId}) async {
    var query = _client
        .from('incidents')
        .select()
        .order('created_at', ascending: false);

    final response = await query;
    return (response as List)
        .map((json) => Incident.fromJson(json))
        .toList();
  }

  Future<Incident?> getIncident(String id) async {
    final response =
        await _client.from('incidents').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Incident.fromJson(response);
  }

  Future<void> updateIncidentStatus(String id, String status) async {
    await _client.from('incidents').update({'status': status}).eq('id', id);
  }

  Future<void> cancelIncident(String id) async {
    await updateIncidentStatus(id, 'resolved');
  }

  /// Insert an SOS incident directly into Supabase (fallback when AI backend is unreachable).
  /// Note: created_at is NOT sent - database will use its default (server time)
  Future<Incident> insertIncident({
    required double lat,
    required double lng,
    required String message,
    required String severity,
    String? emergencyType,
    String? agency,
    String? userName,
    String? userPhone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? medicalConditions,
  }) async {
    // Don't send created_at - let database use server timestamp
    final data = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'message': message,
      'severity': severity,
      'status': 'active',
    };
    // Add optional fields (new columns) - will be ignored if DB hasn't been migrated yet
    if (emergencyType != null) data['emergency_type'] = emergencyType;
    if (agency != null) data['agency'] = agency;
    if (userName != null && userName.isNotEmpty) data['user_name'] = userName;
    if (userPhone != null && userPhone.isNotEmpty) data['user_phone'] = userPhone;
    if (emergencyContactName != null && emergencyContactName.isNotEmpty) {
      data['emergency_contact_name'] = emergencyContactName;
    }
    if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty) {
      data['emergency_contact_phone'] = emergencyContactPhone;
    }
    if (bloodGroup != null && bloodGroup.isNotEmpty) data['blood_group'] = bloodGroup;
    if (medicalConditions != null && medicalConditions.isNotEmpty) {
      data['medical_conditions'] = medicalConditions;
    }

    try {
      final response =
          await _client.from('incidents').insert(data).select().single();
      return Incident.fromJson(response);
    } catch (e) {
      // If new columns don't exist yet, retry with minimal data
      // Don't send created_at - let database use server timestamp
      final minData = {
        'lat': lat,
        'lng': lng,
        'message': message,
        'severity': severity,
        'status': 'active',
      };
      final response =
          await _client.from('incidents').insert(minData).select().single();
      return Incident.fromJson(response);
    }
  }

  /// Route emergency type to agency
  static String routeToAgency(String emergencyType) {
    switch (emergencyType.toLowerCase()) {
      case 'fire':
        return 'Fire Department';
      case 'medical':
      case 'medical emergency':
        return 'Ambulance';
      case 'robbery':
      case 'someone following me':
      case 'feeling unsafe':
        return 'Police';
      case 'accident':
        return 'Police';
      default:
        return 'Police';
    }
  }

  /// Simple rule-based severity classification
  static String classifySeverity(String message) {
    final lower = message.toLowerCase();
    const highKeywords = [
      'violence', 'attack', 'kidnap', 'gun', 'kill', 'murder',
      'fire', 'danger', 'weapon', 'stab', 'shoot', 'bomb', 'threat',
    ];
    const mediumKeywords = [
      'accident', 'injury', 'crash', 'bleeding', 'medical', 'hurt',
      'ambulance', 'fracture', 'unconscious', 'pain',
    ];
    if (highKeywords.any((w) => lower.contains(w))) return 'HIGH';
    if (mediumKeywords.any((w) => lower.contains(w))) return 'MEDIUM';
    return 'LOW';
  }

  Stream<List<Incident>> watchIncidents() {
    return _client
        .from('incidents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Incident.fromJson(json)).toList());
  }
}
