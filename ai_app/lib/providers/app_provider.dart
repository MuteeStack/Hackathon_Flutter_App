/// App Provider — Central state management; saves history to Firestore
import 'package:flutter/material.dart';
import '../models/service_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // --- State ---
  bool _isLoading = false;
  String? _errorMessage;
  ServiceResponse? _currentResponse;
  String? _currentHistoryKey;
  int _currentStep = 0;
  String? _pendingSearchQuery;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ServiceResponse? get currentResponse => _currentResponse;
  String? get currentHistoryKey => _currentHistoryKey;
  int get currentStep => _currentStep;
  String? get pendingSearchQuery => _pendingSearchQuery;

  // --- Setters ---
  void setPendingSearchQuery(String? query) {
    _pendingSearchQuery = query;
    notifyListeners();
  }

  /// Send a service request and save result to Firestore history
  Future<void> sendRequest(String message, {String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentResponse = null;
    _currentStep = 0;
    notifyListeners();

    try {
      final uid = userId ?? 'anonymous';
      final response = await _apiService.sendServiceRequest(
        message: message,
        userId: uid,
      );
      _currentResponse = response;
      _isLoading = false;
      notifyListeners();

      // Save to Firestore history (only for authenticated users)
      if (userId != null) {
        try {
          _currentHistoryKey = await _authService.saveToHistory(
            userId: userId,
            originalMessage: message,
            responseData: response.toJson(),
          );
        } catch (e) {
          print('HISTORY SAVE ERROR: $e');
        }
      }

      // Animate through agent steps
      _animateTrace();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Animate through agent trace steps one by one
  void _animateTrace() async {
    if (_currentResponse == null) return;
    final totalSteps = _currentResponse!.agentTrace.length;
    for (int i = 0; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      _currentStep = i;
      notifyListeners();
    }
  }

  /// Clear current response (go back to chat)
  void clearResponse() {
    _currentResponse = null;
    _currentHistoryKey = null;
    _errorMessage = null;
    _currentStep = 0;
    notifyListeners();
  }

  /// Manually set the current response (e.g. from history)
  void setResponse(ServiceResponse response, {String? historyKey}) {
    _currentResponse = response;
    _currentHistoryKey = historyKey;
    _currentStep = response.agentTrace.length;
    notifyListeners();
  }

  /// Update the booking record inside the active response
  void setBooking(BookingReceipt booking) {
    if (_currentResponse != null) {
      _currentResponse = ServiceResponse(
        requestId: _currentResponse!.requestId,
        parsedIntent: _currentResponse!.parsedIntent,
        recommendedProviders: _currentResponse!.recommendedProviders,
        booking: booking,
        followup: _currentResponse!.followup,
        agentTrace: _currentResponse!.agentTrace,
        totalProcessingTime: _currentResponse!.totalProcessingTime,
      );
      notifyListeners();
    }
  }

  /// Generate, state-save, and DB-save a booking for a specific provider
  Future<BookingReceipt?> confirmBooking(RankedProvider rp, String userId) async {
    if (_currentResponse == null) return null;

    try {
      // Call backend to execute the booking workflow
      final backendResponse = await _apiService.bookProvider(
        userId: userId,
        provider: {
          'id': rp.provider.id,
          'name': rp.provider.name,
          'phone': rp.provider.phone,
        },
        intent: _currentResponse!.parsedIntent.toJson(),
      );

      final booking = BookingReceipt.fromJson(backendResponse['booking'] ?? {});
      
      // Update state first
      _currentResponse = ServiceResponse(
        requestId: _currentResponse!.requestId,
        parsedIntent: _currentResponse!.parsedIntent,
        recommendedProviders: _currentResponse!.recommendedProviders,
        booking: booking,
        followup: backendResponse['followup'] ?? {},
        agentTrace: _currentResponse!.agentTrace,
        totalProcessingTime: _currentResponse!.totalProcessingTime,
      );
      notifyListeners();

      // Save to Firebase RTDB history
      try {
        final originalMessage = _currentResponse!.parsedIntent.originalInput.isNotEmpty
            ? _currentResponse!.parsedIntent.originalInput
            : 'Booked ${rp.provider.name} for ${_currentResponse!.parsedIntent.serviceType}';

        _currentHistoryKey = await _authService.saveToHistory(
          userId: userId,
          originalMessage: originalMessage,
          responseData: _currentResponse!.toJson(),
        );
      } catch (e) {
        print('BOOKING DB SAVE ERROR: $e');
      }

      return booking;
    } catch (e) {
      print('CONFIRM BOOKING ERROR: $e');
      return null;
    }
  }

  /// Update booking status in local state and DB
  Future<void> updateBookingStatus(String userId, String status) async {
    if (_currentResponse == null || _currentHistoryKey == null || _currentResponse!.booking == null) return;

    final booking = BookingReceipt(
      bookingId: _currentResponse!.booking!.bookingId,
      providerName: _currentResponse!.booking!.providerName,
      serviceType: _currentResponse!.booking!.serviceType,
      location: _currentResponse!.booking!.location,
      scheduledTime: _currentResponse!.booking!.scheduledTime,
      status: status,
      confirmationMessage: _currentResponse!.booking!.confirmationMessage,
      reminderTime: _currentResponse!.booking!.reminderTime,
    );

    // Update state first
    setBooking(booking);

    // Save to Firebase RTDB
    try {
      await _authService.updateBookingStatus(
        userId: userId,
        historyKey: _currentHistoryKey!,
        status: status,
      );
    } catch (e) {
      print('BOOKING STATUS UPDATE DB ERROR: $e');
    }
  }

  /// Check backend health
  Future<bool> checkConnection() async {
    return await _apiService.checkHealth();
  }
}
