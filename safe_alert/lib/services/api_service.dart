import 'package:dio/dio.dart';
import 'package:safe_alert/models/sos_models.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';

  late final Dio _dio;
  String _baseUrl;

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  Future<SOSResponse> sendSOS(SOSRequest request) async {
    try {
      final response = await _dio.post('/sos', data: request.toJson());
      return SOSResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw SOSOfflineException('No internet connection');
      }
      throw SOSApiException(
        e.response?.data?['detail'] ?? 'Failed to send SOS',
      );
    }
  }
}

class SOSApiException implements Exception {
  final String message;
  SOSApiException(this.message);

  @override
  String toString() => message;
}

class SOSOfflineException implements Exception {
  final String message;
  SOSOfflineException(this.message);

  @override
  String toString() => message;
}
