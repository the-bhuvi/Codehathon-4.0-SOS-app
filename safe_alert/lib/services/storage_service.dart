import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe_alert/models/emergency_contact.dart';
import 'package:safe_alert/models/user_profile.dart';

class StorageService {
  static const String _contactsKey = 'emergency_contacts';
  static const String _userNameKey = 'user_name';
  static const String _serverUrlKey = 'server_url';
  static const String _shareLocationKey = 'share_live_location';
  static const String _languageKey = 'preferred_language';
  static const String _deviceIdKey = 'device_id';
  static const String _offlineQueueKey = 'offline_sos_queue';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // User Profile (Feature 4)
  Future<UserProfile> getUserProfile() async {
    final prefs = await _prefs;
    return UserProfile(
      fullName: prefs.getString('user_full_name') ?? prefs.getString(_userNameKey) ?? '',
      phone: prefs.getString('user_phone') ?? '',
      emergencyContactName: prefs.getString('emergency_contact_name') ?? '',
      emergencyContactPhone: prefs.getString('emergency_contact_phone') ?? '',
      bloodGroup: prefs.getString('blood_group') ?? '',
      medicalConditions: prefs.getString('medical_conditions') ?? '',
    );
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await _prefs;
    await prefs.setString('user_full_name', profile.fullName);
    await prefs.setString('user_phone', profile.phone);
    await prefs.setString('emergency_contact_name', profile.emergencyContactName);
    await prefs.setString('emergency_contact_phone', profile.emergencyContactPhone);
    await prefs.setString('blood_group', profile.bloodGroup);
    await prefs.setString('medical_conditions', profile.medicalConditions);
    await prefs.setString(_userNameKey, profile.fullName);
  }

  // Emergency Contacts
  Future<List<EmergencyContact>> getContacts() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_contactsKey);
    if (jsonStr == null) return [];
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => EmergencyContact.fromJson(e)).toList();
  }

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await _prefs;
    final jsonStr = jsonEncode(contacts.map((e) => e.toJson()).toList());
    await prefs.setString(_contactsKey, jsonStr);
  }

  Future<void> addContact(EmergencyContact contact) async {
    final contacts = await getContacts();
    contacts.add(contact);
    await saveContacts(contacts);
  }

  Future<void> removeContact(String id) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveContacts(contacts);
  }

  // User Settings
  Future<String> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString('user_full_name') ?? prefs.getString(_userNameKey) ?? 'User';
  }

  Future<void> setUserName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_userNameKey, name);
    await prefs.setString('user_full_name', name);
  }

  Future<String> getServerUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_serverUrlKey) ?? 'http://10.0.2.2:8000';
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_serverUrlKey, url);
  }

  Future<bool> getShareLocation() async {
    final prefs = await _prefs;
    return prefs.getBool(_shareLocationKey) ?? true;
  }

  Future<void> setShareLocation(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_shareLocationKey, value);
  }

  Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey) ?? 'English';
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, lang);
  }

  Future<String> getDeviceId() async {
    final prefs = await _prefs;
    return prefs.getString(_deviceIdKey) ?? '';
  }

  Future<void> setDeviceId(String id) async {
    final prefs = await _prefs;
    await prefs.setString(_deviceIdKey, id);
  }

  // Panic mode settings (Feature 5 & 6)
  Future<bool> getShakePanicEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('shake_panic_enabled') ?? true;
  }

  Future<void> setShakePanicEnabled(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool('shake_panic_enabled', val);
  }

  Future<String> getShakeSensitivity() async {
    final prefs = await _prefs;
    return prefs.getString('shake_sensitivity') ?? 'medium';
  }

  Future<void> setShakeSensitivity(String val) async {
    final prefs = await _prefs;
    await prefs.setString('shake_sensitivity', val);
  }

  Future<double> getShakeThreshold() async {
    final prefs = await _prefs;
    return prefs.getDouble('shake_threshold') ?? 12.0;
  }

  Future<void> setShakeThreshold(double val) async {
    final prefs = await _prefs;
    await prefs.setDouble('shake_threshold', val);
  }

  Future<int> getShakeCount() async {
    final prefs = await _prefs;
    return prefs.getInt('shake_count') ?? 3;
  }

  Future<void> setShakeCount(int val) async {
    final prefs = await _prefs;
    await prefs.setInt('shake_count', val);
  }

  Future<bool> getAutoRecordEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('auto_record_enabled') ?? false;
  }

  Future<void> setAutoRecordEnabled(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool('auto_record_enabled', val);
  }

  // Offline Queue
  Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_offlineQueueKey);
    if (jsonStr == null) return [];
    return (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  }

  Future<void> addToOfflineQueue(Map<String, dynamic> sosData) async {
    final queue = await getOfflineQueue();
    queue.add(sosData);
    final prefs = await _prefs;
    await prefs.setString(_offlineQueueKey, jsonEncode(queue));
  }

  Future<void> clearOfflineQueue() async {
    final prefs = await _prefs;
    await prefs.remove(_offlineQueueKey);
  }

  Future<void> removeFromOfflineQueue(int index) async {
    final queue = await getOfflineQueue();
    if (index < queue.length) {
      queue.removeAt(index);
      final prefs = await _prefs;
      await prefs.setString(_offlineQueueKey, jsonEncode(queue));
    }
  }
}
