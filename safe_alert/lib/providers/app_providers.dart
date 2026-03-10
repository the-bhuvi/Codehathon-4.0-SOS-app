import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_alert/models/incident.dart';
import 'package:safe_alert/models/sos_models.dart';
import 'package:safe_alert/models/user_profile.dart';
import 'package:safe_alert/services/api_service.dart';
import 'package:safe_alert/services/location_service.dart';
import 'package:safe_alert/services/supabase_service.dart';
import 'package:safe_alert/services/storage_service.dart';
import 'package:safe_alert/services/offline_queue_service.dart';
import 'package:safe_alert/services/sms_service.dart';

// Service providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService());
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  final service = OfflineQueueService(
    apiService: ref.read(apiServiceProvider),
    storageService: ref.read(storageServiceProvider),
  );
  service.startListening();
  ref.onDispose(() => service.stopListening());
  return service;
});

// Location provider
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentPosition();
});

// User profile provider
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final storage = ref.read(storageServiceProvider);
  return await storage.getUserProfile();
});

// SOS State
enum SOSStatus { idle, sending, sent, failed, cancelled }

class SOSState {
  final SOSStatus status;
  final SOSResponse? response;
  final Incident? activeIncident;
  final String? errorMessage;
  final DateTime? sentAt;

  const SOSState({
    this.status = SOSStatus.idle,
    this.response,
    this.activeIncident,
    this.errorMessage,
    this.sentAt,
  });

  SOSState copyWith({
    SOSStatus? status,
    SOSResponse? response,
    Incident? activeIncident,
    String? errorMessage,
    DateTime? sentAt,
  }) {
    return SOSState(
      status: status ?? this.status,
      response: response ?? this.response,
      activeIncident: activeIncident ?? this.activeIncident,
      errorMessage: errorMessage ?? this.errorMessage,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  final ApiService _apiService;
  final LocationService _locationService;
  final SupabaseService _supabaseService;
  final OfflineQueueService _offlineQueueService;
  final StorageService _storageService;
  Timer? _autoSendTimer;

  SOSNotifier({
    required ApiService apiService,
    required LocationService locationService,
    required SupabaseService supabaseService,
    required OfflineQueueService offlineQueueService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _locationService = locationService,
        _supabaseService = supabaseService,
        _offlineQueueService = offlineQueueService,
        _storageService = storageService,
        super(const SOSState());

  void startAutoSendCountdown(String message) {
    _autoSendTimer?.cancel();
    _autoSendTimer = Timer(const Duration(seconds: 30), () {
      sendSOS(message);
    });
  }

  void cancelAutoSend() {
    _autoSendTimer?.cancel();
    _autoSendTimer = null;
  }

  Future<void> sendSOS(String message, {String emergencyType = 'general'}) async {
    _autoSendTimer?.cancel();
    state = state.copyWith(status: SOSStatus.sending);

    try {
      Position? position = await _locationService.getCurrentPosition();
      position ??= await _locationService.getLastKnownPosition();

      final effectiveMessage =
          message.isEmpty ? 'Emergency! Need help!' : message;
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // Load user profile
      final profile = await _storageService.getUserProfile();
      final agency = SupabaseService.routeToAgency(emergencyType);

      final request = SOSRequest(
        message: effectiveMessage,
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
        emergencyType: emergencyType,
        userName: profile.fullName,
        userPhone: profile.phone,
        emergencyContactName: profile.emergencyContactName,
        emergencyContactPhone: profile.emergencyContactPhone,
        bloodGroup: profile.bloodGroup,
        medicalConditions: profile.medicalConditions,
      );

      try {
        final response = await _apiService.sendSOS(request);
        Incident? incident;
        if (response.storedIncident != null) {
          incident = Incident.fromJson(response.storedIncident!);
        }

        state = SOSState(
          status: SOSStatus.sent,
          response: response,
          activeIncident: incident,
          sentAt: DateTime.now(),
        );
      } on SOSOfflineException {
        // Fallback: insert directly into Supabase with rule-based severity
        try {
          final severity = SupabaseService.classifySeverity(effectiveMessage);
          final incident = await _supabaseService.insertIncident(
            lat: lat,
            lng: lng,
            message: effectiveMessage,
            severity: severity,
            timestamp: timestamp,
            emergencyType: emergencyType,
            agency: agency,
            userName: profile.fullName,
            userPhone: profile.phone,
            emergencyContactName: profile.emergencyContactName,
            emergencyContactPhone: profile.emergencyContactPhone,
            bloodGroup: profile.bloodGroup,
            medicalConditions: profile.medicalConditions,
          );

          state = SOSState(
            status: SOSStatus.sent,
            response: SOSResponse(success: true, aiSeverity: severity, agency: agency),
            activeIncident: incident,
            sentAt: DateTime.now(),
          );
        } catch (supabaseError) {
          await _offlineQueueService.enqueue(request);
          state = SOSState(
            status: SOSStatus.sent,
            response: SOSResponse(success: true, aiSeverity: 'PENDING'),
            sentAt: DateTime.now(),
          );
        }
      } on SOSApiException {
        try {
          final severity = SupabaseService.classifySeverity(effectiveMessage);
          final incident = await _supabaseService.insertIncident(
            lat: lat,
            lng: lng,
            message: effectiveMessage,
            severity: severity,
            timestamp: timestamp,
            emergencyType: emergencyType,
            agency: agency,
            userName: profile.fullName,
            userPhone: profile.phone,
            emergencyContactName: profile.emergencyContactName,
            emergencyContactPhone: profile.emergencyContactPhone,
            bloodGroup: profile.bloodGroup,
            medicalConditions: profile.medicalConditions,
          );

          state = SOSState(
            status: SOSStatus.sent,
            response: SOSResponse(success: true, aiSeverity: severity, agency: agency),
            activeIncident: incident,
            sentAt: DateTime.now(),
          );
        } catch (supabaseError) {
          await _offlineQueueService.enqueue(request);
          state = SOSState(
            status: SOSStatus.sent,
            response: SOSResponse(success: true, aiSeverity: 'PENDING'),
            sentAt: DateTime.now(),
          );
        }
      }

      // Send SMS to emergency contacts
      _sendEmergencySMS(profile, effectiveMessage, lat, lng);

    } catch (e) {
      state = state.copyWith(
        status: SOSStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Send SMS directly to emergency contacts using Android SmsManager.
  /// No user interaction needed — SMS is sent automatically in the background.
  Future<void> _sendEmergencySMS(UserProfile profile, String message, double lat, double lng) async {
    try {
      final contacts = await _storageService.getContacts();
      if (contacts.isEmpty && profile.emergencyContactPhone.isEmpty) return;

      final timestamp = DateTime.now().toString().substring(0, 19);
      final smsBody = SmsService.buildSOSMessage(
        userName: profile.fullName,
        distressMessage: message,
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
      );

      // Collect all phone numbers
      final phones = <String>{};
      if (profile.emergencyContactPhone.isNotEmpty) {
        phones.add(profile.emergencyContactPhone);
      }
      for (final contact in contacts) {
        if (contact.phone.isNotEmpty) phones.add(contact.phone);
      }

      // Send SMS directly to each contact
      final failures = <String>[];
      for (final phone in phones) {
        final success = await SmsService.sendSMS(phone: phone, message: smsBody);
        if (!success) failures.add(phone);
      }

      // Show notification if any SMS failed
      if (failures.isNotEmpty) {
        debugPrint('SMS failed for: ${failures.join(", ")}');
      }
    } catch (e) {
      debugPrint('SMS sending error: $e');
      // SMS is best-effort, don't fail the SOS
    }
  }

  Future<void> cancelSOS() async {
    if (state.activeIncident != null) {
      try {
        await _supabaseService.cancelIncident(state.activeIncident!.id);
      } catch (_) {}
    }
    state = const SOSState(status: SOSStatus.cancelled);
    await Future.delayed(const Duration(seconds: 2));
    state = const SOSState();
  }

  void reset() {
    _autoSendTimer?.cancel();
    state = const SOSState();
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    super.dispose();
  }
}

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  return SOSNotifier(
    apiService: ref.read(apiServiceProvider),
    locationService: ref.read(locationServiceProvider),
    supabaseService: ref.read(supabaseServiceProvider),
    offlineQueueService: ref.read(offlineQueueServiceProvider),
    storageService: ref.read(storageServiceProvider),
  );
});

// Incidents provider
final incidentsProvider = StreamProvider<List<Incident>>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return supabaseService.watchIncidents();
});

// Settings providers
final userNameProvider = FutureProvider<String>((ref) async {
  final storage = ref.read(storageServiceProvider);
  return await storage.getUserName();
});

final shareLocationProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(storageServiceProvider);
  return await storage.getShareLocation();
});

final languageProvider = FutureProvider<String>((ref) async {
  final storage = ref.read(storageServiceProvider);
  return await storage.getLanguage();
});
