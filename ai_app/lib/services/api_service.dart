/// API Service — handles all HTTP communication with the FastAPI backend
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/service_models.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  /// Send a natural language service request to the orchestrator
  Future<ServiceResponse> sendServiceRequest({
    required String message,
    String userId = 'user_001',
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.post(
        '/api/service-request',
        data: {
          'user_id': userId,
          'message': message,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      return ServiceResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Failed to process request: ${e.response?.data ?? e.message}',
      );
    }
  }

  /// Book a specific provider
  Future<Map<String, dynamic>> bookProvider({
    required String userId,
    required Map<String, dynamic> provider,
    required Map<String, dynamic> intent,
  }) async {
    try {
      final response = await _dio.post(
        '/api/book',
        data: {
          'user_id': userId,
          'provider': provider,
          'intent': intent,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to book provider: ${e.response?.data ?? e.message}');
    }
  }

  /// Get all bookings for a user
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final response = await _dio.get('/api/bookings/$userId');
      final bookings = response.data['bookings'] as List? ?? [];
      return bookings.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception('Failed to get bookings: ${e.message}');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _dio.post('/api/booking/$bookingId/cancel');
    } on DioException catch (e) {
      throw Exception('Failed to cancel booking: ${e.message}');
    }
  }

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
