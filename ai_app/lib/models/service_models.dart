/// Data models matching the backend Pydantic schemas

class ParsedIntent {
  final String serviceType;
  final String location;
  final String city;
  final String timePreference;
  final String urgency;
  final String languageDetected;
  final String originalInput;

  ParsedIntent({
    required this.serviceType,
    required this.location,
    this.city = 'Islamabad',
    this.timePreference = 'as soon as possible',
    this.urgency = 'normal',
    this.languageDetected = 'english',
    this.originalInput = '',
  });

  factory ParsedIntent.fromJson(Map<String, dynamic> json) {
    return ParsedIntent(
      serviceType: json['service_type'] ?? 'other',
      location: json['location'] ?? 'unknown',
      city: json['city'] ?? 'Islamabad',
      timePreference: json['time_preference'] ?? 'as soon as possible',
      urgency: json['urgency'] ?? 'normal',
      languageDetected: json['language_detected'] ?? 'english',
      originalInput: json['original_input'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'service_type': serviceType,
    'location': location,
    'city': city,
    'time_preference': timePreference,
    'urgency': urgency,
    'language_detected': languageDetected,
    'original_input': originalInput,
  };
}

class ProviderLocation {
  final String area;
  final String city;
  final double lat;
  final double lng;

  ProviderLocation({
    required this.area,
    required this.city,
    required this.lat,
    required this.lng,
  });

  factory ProviderLocation.fromJson(Map<String, dynamic> json) {
    return ProviderLocation(
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }
}

class Provider {
  final String id;
  final String name;
  final String nameUrdu;
  final String serviceType;
  final List<String> serviceCategories;
  final ProviderLocation location;
  final double rating;
  final int totalReviews;
  final String priceRange;
  final String phone;
  final bool verified;
  final int experienceYears;

  Provider({
    required this.id,
    required this.name,
    this.nameUrdu = '',
    required this.serviceType,
    this.serviceCategories = const [],
    required this.location,
    this.rating = 0,
    this.totalReviews = 0,
    this.priceRange = '',
    this.phone = '',
    this.verified = false,
    this.experienceYears = 0,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameUrdu: json['name_urdu'] ?? '',
      serviceType: json['service_type'] ?? '',
      serviceCategories: List<String>.from(json['service_categories'] ?? []),
      location: ProviderLocation.fromJson(json['location'] ?? {}),
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      priceRange: json['price_range'] ?? '',
      phone: json['phone'] ?? '',
      verified: json['verified'] ?? false,
      experienceYears: json['experience_years'] ?? 0,
    );
  }
}

class RankedProvider {
  final Provider provider;
  final int rank;
  final double distanceKm;
  final double matchScore;
  final String reasoning;

  RankedProvider({
    required this.provider,
    required this.rank,
    this.distanceKm = 0,
    this.matchScore = 0,
    this.reasoning = '',
  });

  factory RankedProvider.fromJson(Map<String, dynamic> json) {
    return RankedProvider(
      provider: Provider.fromJson(json['provider'] ?? {}),
      rank: json['rank'] ?? 0,
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      matchScore: (json['match_score'] ?? 0).toDouble(),
      reasoning: json['reasoning'] ?? '',
    );
  }
}

class BookingReceipt {
  final String bookingId;
  final String providerName;
  final String serviceType;
  final String location;
  final String scheduledTime;
  final String status;
  final String confirmationMessage;
  final String reminderTime;

  BookingReceipt({
    required this.bookingId,
    required this.providerName,
    required this.serviceType,
    required this.location,
    required this.scheduledTime,
    this.status = 'pending',
    this.confirmationMessage = '',
    this.reminderTime = '',
  });

  factory BookingReceipt.fromJson(Map<String, dynamic> json) {
    return BookingReceipt(
      bookingId: json['booking_id'] ?? '',
      providerName: json['provider_name'] ?? '',
      serviceType: json['service_type'] ?? '',
      location: json['location'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '',
      status: json['status'] ?? 'pending',
      confirmationMessage: json['confirmation_message'] ?? '',
      reminderTime: json['reminder_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'provider_name': providerName,
    'service_type': serviceType,
    'location': location,
    'scheduled_time': scheduledTime,
    'status': status,
    'confirmation_message': confirmationMessage,
    'reminder_time': reminderTime,
  };
}

class AgentStep {
  final int stepNumber;
  final String agentName;
  final String action;
  final String inputSummary;
  final String outputSummary;
  final String reasoning;
  final String timestamp;

  AgentStep({
    required this.stepNumber,
    required this.agentName,
    required this.action,
    this.inputSummary = '',
    this.outputSummary = '',
    this.reasoning = '',
    this.timestamp = '',
  });

  factory AgentStep.fromJson(Map<String, dynamic> json) {
    return AgentStep(
      stepNumber: json['step_number'] ?? 0,
      agentName: json['agent_name'] ?? '',
      action: json['action'] ?? '',
      inputSummary: json['input_summary'] ?? '',
      outputSummary: json['output_summary'] ?? '',
      reasoning: json['reasoning'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'step_number': stepNumber,
    'agent_name': agentName,
    'action': action,
    'input_summary': inputSummary,
    'output_summary': outputSummary,
    'reasoning': reasoning,
    'timestamp': timestamp,
  };
}

class ServiceResponse {
  final String requestId;
  final ParsedIntent parsedIntent;
  final List<RankedProvider> recommendedProviders;
  final BookingReceipt? booking;
  final Map<String, dynamic> followup;
  final List<AgentStep> agentTrace;
  final double totalProcessingTime;

  ServiceResponse({
    required this.requestId,
    required this.parsedIntent,
    this.recommendedProviders = const [],
    this.booking,
    this.followup = const {},
    this.agentTrace = const [],
    this.totalProcessingTime = 0,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    final traceData = json['agent_trace'];
    List<AgentStep> steps = [];
    if (traceData is Map && traceData['steps'] != null) {
      steps = (traceData['steps'] as List)
          .map((s) => AgentStep.fromJson(s))
          .toList();
    }

    return ServiceResponse(
      requestId: json['request_id'] ?? '',
      parsedIntent: ParsedIntent.fromJson(json['parsed_intent'] ?? {}),
      recommendedProviders: (json['recommended_providers'] as List? ?? [])
          .map((p) => RankedProvider.fromJson(p))
          .toList(),
      booking: json['booking'] != null
          ? BookingReceipt.fromJson(json['booking'])
          : null,
      followup: Map<String, dynamic>.from(json['followup'] ?? {}),
      agentTrace: steps,
      totalProcessingTime:
          (json['total_processing_time'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'parsed_intent': parsedIntent.toJson(),
    'recommended_providers': recommendedProviders
        .map((p) => {
          'rank': p.rank,
          'distance_km': p.distanceKm,
          'match_score': p.matchScore,
          'reasoning': p.reasoning,
          'provider': {
            'id': p.provider.id,
            'name': p.provider.name,
            'service_type': p.provider.serviceType,
            'rating': p.provider.rating,
            'price_range': p.provider.priceRange,
            'phone': p.provider.phone,
            'verified': p.provider.verified,
            'location': {
              'area': p.provider.location.area,
              'city': p.provider.location.city,
              'lat': p.provider.location.lat,
              'lng': p.provider.location.lng,
            },
          },
        })
        .toList(),
    'booking': booking?.toJson(),
    'followup': followup,
    'agent_trace': {
      'steps': agentTrace.map((s) => s.toJson()).toList(),
    },
    'total_processing_time': totalProcessingTime,
  };
}
