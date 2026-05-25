import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../models/service_models.dart' hide Provider;
import 'trace_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final response = appProvider.currentResponse;
        if (response == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Results', 
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)
              ),
            ),
            body: Stack(
              children: [
                // Background glow
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 32),
                      Text(
                        'No Active Results',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'There are no service results to display at the moment. Try asking the ServiceBot for a task!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                        label: const Text('Back to Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.border,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Service Results',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 22),
              onPressed: () {
                // Keep the active response so the view plan button in chat remains functional
                // appProvider.clearResponse(); 
                Navigator.pop(context);
              },
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.primary),
                label: Text(
                  'Trace',
                  style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TraceScreen())
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intent Summary Card
                        _buildIntentCard(response.parsedIntent)
                            .animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOut),
                        const SizedBox(height: 24),

                        // Interactive Google Map View
                        _buildGoogleMap(response)
                            .animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                        const SizedBox(height: 24),

                        // Agent Pipeline Mini View
                        _buildAgentPipeline(response.agentTrace, appProvider.currentStep)
                            .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                        const SizedBox(height: 32),

                        // Providers Header
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Top Providers',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22, 
                                fontWeight: FontWeight.w900, 
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (response.recommendedProviders.isEmpty)
                          _buildNoProvidersState(response)
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.08, curve: Curves.easeOut)
                        else
                          ...response.recommendedProviders.asMap().entries.map(
                            (entry) => _buildProviderCard(context, response, entry.value, entry.key)
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 300 + entry.key * 150))
                                .slideX(begin: 0.1, curve: Curves.easeOut),
                          ),
                        const SizedBox(height: 24),

                        if (response.booking != null) ...[
                          _buildBookingCard(context, response.booking!, appProvider)
                              .animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                          const SizedBox(height: 24),
                        ],

                        // Follow-up Info
                        if (response.followup.isNotEmpty)
                          _buildFollowupCard(response.followup)
                              .animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, curve: Curves.easeOut),

                        const SizedBox(height: 60),

                        // Processing Time
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  'Execution Time: ${response.totalProcessingTime.toStringAsFixed(1)}s',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textMuted, 
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          );
        },
      );
    }

  Widget _buildGoogleMap(ServiceResponse response) {
    // Collect coordinates from providers to center the camera position
    double centerLat = 33.6844;
    double centerLng = 73.0479;
    
    if (response.recommendedProviders.isNotEmpty) {
      centerLat = response.recommendedProviders.first.provider.location.lat;
      centerLng = response.recommendedProviders.first.provider.location.lng;
    }

    final markers = response.recommendedProviders.map((rp) {
      final p = rp.provider;
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.location.lat, p.location.lng),
        infoWindow: InfoWindow(
          title: p.name,
          snippet: '${p.serviceType} • Match: ${rp.matchScore.toInt()}%',
        ),
      );
    }).toSet();

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(centerLat, centerLng),
            zoom: 14,
          ),
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }

  Widget _buildNoProvidersState(ServiceResponse response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.search_off_rounded, size: 34, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'No live providers found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Google Maps did not return nearby results for "${response.parsedIntent.serviceType.replaceAll('_', ' ')}" in ${response.parsedIntent.location}. Try a broader area, a different service name, or check the Google Maps API setup.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _intentChip(Icons.location_on_rounded, response.parsedIntent.location),
              _intentChip(Icons.build_circle_rounded, response.parsedIntent.serviceType.replaceAll('_', ' ').toUpperCase()),
              _intentChip(Icons.translate_rounded, response.parsedIntent.languageDetected),
            ],
          ),
        ],
      ),
    );
  }

  void _launchWhatsApp(BuildContext context, RankedProvider rp, ServiceResponse response) async {
    final p = rp.provider;
    // Strip space/plus
    final phone = p.phone.replaceAll(' ', '').replaceAll('+', '').replaceAll('-', '');
    final serviceName = response.parsedIntent.serviceType.toUpperCase();
    final scheduledTime = response.booking?.scheduledTime ?? response.parsedIntent.timePreference;
    final location = response.booking?.location ?? response.parsedIntent.location;
    
    // Construct dynamic AI Generated Message
    final message = Uri.encodeComponent(
      "Hello *${p.name}*! I would like to book your service via *QuickFix*.\n\n"
      "📋 *BOOKING DETAILS*:\n"
      "• *Service Requested*: $serviceName\n"
      "• *Scheduled Time*: $scheduledTime\n"
      "• *Service Address*: $location\n"
      "• *Urgency*: ${response.parsedIntent.urgency.toUpperCase()}\n\n"
      "⚡ *AI-Generated Match Summary*:\n"
      "Verified by QuickFix orchestrator with a Match Score of *${rp.matchScore.toInt()}%*.\n"
      "_${_stripEmojis(rp.reasoning)}_\n\n"
      "Please reply to confirm your availability!"
    );
    
    final url = "https://wa.me/$phone?text=$message";
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp. Please check if WhatsApp is installed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildIntentCard(ParsedIntent intent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INTENT ANALYSIS', 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, 
                          fontWeight: FontWeight.w900, 
                          color: AppColors.primary,
                          letterSpacing: 1.5
                        )
                      ),
                      Text(
                        'User Intent Extraction', 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, 
                          fontWeight: FontWeight.w700, 
                          color: AppColors.textPrimary
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _intentChip(Icons.build_circle_rounded, intent.serviceType.replaceAll('_', ' ').toUpperCase()),
              _intentChip(Icons.location_on_rounded, intent.location),
              _intentChip(Icons.access_time_filled_rounded, intent.timePreference),
              _intentChip(Icons.bolt_rounded, intent.urgency, color: AppColors.accent),
              _intentChip(Icons.translate_rounded, intent.languageDetected),
            ],
          ),
        ],
      ),
    );
  }

  Widget _intentChip(IconData icon, String text, {Color color = AppColors.primary}) {
    final cleanText = _stripEmojis(text);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            cleanText, 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, 
              fontWeight: FontWeight.w800, 
              color: AppColors.textPrimary,
              letterSpacing: 0.2
            )
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPipeline(List<AgentStep> steps, int currentStep) {
    final agentNames = ['Intent', 'Discovery', 'Ranking', 'Booking', 'Follow-Up'];
    final agentIcons = [
      Icons.psychology_rounded, 
      Icons.search_rounded, 
      Icons.leaderboard_rounded, 
      Icons.event_available_rounded, 
      Icons.notifications_active_rounded
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text(
                'AGENT ORCHESTRATION', 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.textMuted,
                  letterSpacing: 1.2
                )
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(agentNames.length, (i) {
              final isActive = i < (currentStep / 2).ceil();
              return Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (i < agentNames.length - 1)
                          Positioned(
                            left: 20,
                            right: -20,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: isActive ? AppColors.primaryGradient : null,
                            color: isActive ? null : AppColors.surfaceLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? Colors.white.withValues(alpha: 0.1) : AppColors.border, 
                              width: 1
                            ),
                          ),
                          child: Icon(
                            agentIcons[i], 
                            color: isActive ? Colors.white : AppColors.textMuted, 
                            size: 16
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      agentNames[i], 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, 
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.textPrimary : AppColors.textMuted
                      )
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, ServiceResponse response, RankedProvider rp, int index) {
    final p = rp.provider;
    final isTop = index == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isTop ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTop ? AppColors.secondary.withValues(alpha: 0.5) : AppColors.border,
          width: isTop ? 2 : 1,
        ),
        boxShadow: [
          if (isTop)
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            if (isTop)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  gradient: AppColors.successGradient,
                ),
                child: Center(
                  child: Text(
                    'BEST MATCH', 
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white,
                      letterSpacing: 1.2
                    )
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar placeholder or Icon
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    p.name, 
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17, 
                                      fontWeight: FontWeight.w800, 
                                      color: AppColors.textPrimary
                                    )
                                  )
                                ),
                                if (p.verified)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.verified_rounded, color: AppColors.info, size: 18),
                                  ),
                              ],
                            ),
                            if (p.nameUrdu.isNotEmpty)
                              Text(
                                p.nameUrdu, 
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, 
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500
                                )
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${rp.matchScore.toInt()}%', 
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, 
                            fontWeight: FontWeight.w800, 
                            color: AppColors.primary
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _statChip(Icons.star_rounded, p.rating.toString(), AppColors.warning),
                      _statChip(Icons.near_me_rounded, '${rp.distanceKm.toStringAsFixed(1)} km', AppColors.secondary),
                      _statChip(Icons.payments_rounded, p.priceRange, AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (rp.reasoning.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _stripEmojis(rp.reasoning), 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, 
                          color: AppColors.textSecondary, 
                          height: 1.5,
                          fontStyle: FontStyle.italic
                        )
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleBooking(context, rp),
                      icon: const Icon(Icons.bookmark_added_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Book Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text, 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, 
              color: color, 
              fontWeight: FontWeight.w700
            )
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade400;
      case 'on_way':
      case 'on way':
        return Colors.purple.shade300;
      case 'completed':
      case 'done':
        return Colors.teal.shade300;
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade400;
      case 'pending':
      default:
        return Colors.orange.shade400;
    }
  }

  Widget _buildBookingCard(BuildContext context, BookingReceipt booking, AppProvider appProvider) {
    final authProvider = Provider.of<ap.AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'anonymous';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOOKING SECURED', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white70,
                        letterSpacing: 1.5
                      )
                    ),
                    Text(
                      'Successfully Booked!', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, 
                        fontWeight: FontWeight.w800, 
                        color: Colors.white
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          _bookingRow('Booking ID', booking.bookingId),
          _bookingRow('Service', booking.serviceType.replaceAll('_', ' ').toUpperCase()),
          _bookingRow('Provider', booking.providerName),
          _bookingRow('Scheduled', booking.scheduledTime),
          _bookingRow('Location', booking.location),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Status',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String newStatus) {
                  appProvider.updateBookingStatus(userId, newStatus);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'pending',
                    child: Text('Pending'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'confirmed',
                    child: Text('Confirmed'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'on_way',
                    child: Text('On Way'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Reminder set for ${booking.reminderTime}', 
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, 
                    fontSize: 12, 
                    fontWeight: FontWeight.w700
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFollowupCard(Map<String, dynamic> followup) {
    final nextAction = followup['next_action'] ?? 'No follow-up scheduled';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI SUGGESTION', 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    color: AppColors.warning,
                    letterSpacing: 1
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  _stripEmojis(nextAction), 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, 
                    color: AppColors.textPrimary, 
                    fontWeight: FontWeight.w600
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Utility to ensure no emojis sneak in from the backend AI responses
  String _stripEmojis(String text) {
    return text.replaceAll(RegExp(r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F018}-\u{1F270}\u{238C}-\u{2454}\u{20D0}-\u{20FF}\u{FE0F}⚡⏱️🔥📍🔧🌐⭐]', unicode: true), '').trim();
  }

  void _handleBooking(BuildContext context, RankedProvider rp) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Prevent double booking for the same request
    if (appProvider.currentResponse?.booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already booked a provider for this request!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show a premium glassmorphic/blur loading indicator first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Securing Booking...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Fetch user details
    final authProvider = Provider.of<ap.AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'anonymous';

    // Call confirmBooking
    final booking = await appProvider.confirmBooking(rp, userId);

    // Dismiss loading indicator
    Navigator.of(context, rootNavigator: true).pop();

    if (booking != null) {
      // Show Premium booking receipt
      if (context.mounted) {
        _showBookingReceipt(context, rp, booking);
      }

      // Schedule simulated proactive notification 7 seconds later
      Future.delayed(const Duration(seconds: 7), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QuickFix Agent Reminder',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your ${booking.serviceType.replaceAll('_', ' ').toUpperCase()} technician (${rp.provider.name}) arrives in 1 hour.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E1E),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      });
    }
  }

  void _showBookingReceipt(BuildContext context, RankedProvider rp, BookingReceipt booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        final response = Provider.of<AppProvider>(context, listen: false).currentResponse;
        
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: BookingReceiptSheet(
            rp: rp,
            booking: booking,
            onWhatsAppNotify: () => _launchWhatsApp(context, rp, response!),
          ),
        );
      },
    );
  }
}

class BookingReceiptSheet extends StatelessWidget {
  final RankedProvider rp;
  final BookingReceipt booking;
  final VoidCallback onWhatsAppNotify;

  const BookingReceiptSheet({
    super.key,
    required this.rp,
    required this.booking,
    required this.onWhatsAppNotify,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Success Checkmark animated
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),

          Text(
            'Booking Confirmed!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 4),
          Text(
            'Your booking request has been successfully processed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // Premium Receipt details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                _receiptRow('Booking ID', '#${booking.bookingId}', isBold: true),
                const Divider(height: 24, color: AppColors.divider),
                _receiptRow('Provider', rp.provider.name),
                const Divider(height: 24, color: AppColors.divider),
                _receiptRow('Service', booking.serviceType.replaceAll('_', ' ').toUpperCase()),
                const Divider(height: 24, color: AppColors.divider),
                _receiptRow('Slot / Time', booking.scheduledTime),
                const Divider(height: 24, color: AppColors.divider),
                _receiptRow('Location', booking.location),
                const Divider(height: 24, color: AppColors.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'CONFIRMED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut),

          const SizedBox(height: 20),

          // Proactive Notification Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Reminder scheduled for 9:00 AM (1 hr before)',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 28),

          // Primary and secondary CTAs
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onWhatsAppNotify();
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Send via WhatsApp',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Close Receipt',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
