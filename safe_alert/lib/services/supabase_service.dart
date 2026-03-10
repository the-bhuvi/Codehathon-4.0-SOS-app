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

  Stream<List<Incident>> watchIncidents() {
    return _client
        .from('incidents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Incident.fromJson(json)).toList());
  }
}
