import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/service_models.dart' hide Provider;
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as ap;
import 'results_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  String _activeFilter = 'All'; // Filters: All, Active, Completed, Cancelled

  final List<String> _filters = ['All', 'Active', 'Completed', 'Cancelled'];

  IconData _serviceIcon(String? serviceType) {
    final type = serviceType?.toLowerCase() ?? '';
    if (type.contains('ac')) return Icons.ac_unit_rounded;
    if (type.contains('plumb')) return Icons.plumbing_rounded;
    if (type.contains('elect')) return Icons.electrical_services_rounded;
    if (type.contains('tutor')) return Icons.school_rounded;
    if (type.contains('beaut')) return Icons.face_rounded;
    if (type.contains('carpent')) return Icons.construction_rounded;
    if (type.contains('paint')) return Icons.format_paint_rounded;
    if (type.contains('clean')) return Icons.cleaning_services_rounded;
    if (type.contains('mechanic')) return Icons.build_circle_rounded;
    return Icons.design_services_rounded;
  }

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      final stringKey = key.toString();
      if (value is Map) {
        return MapEntry(stringKey, _normalizeMap(value));
      } else if (value is List) {
        return MapEntry(stringKey, value.map((item) {
          if (item is Map) {
            return _normalizeMap(item);
          }
          return item;
        }).toList());
      } else {
        return MapEntry(stringKey, value);
      }
    });
  }

  void _openResult(Map<String, dynamic> responseData, {String? historyKey}) {
    try {
      final response = ServiceResponse.fromJson(responseData);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.setResponse(response, historyKey: historyKey);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    } catch (e) {
      print('ERROR PARSING RESPONSE DATA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load details: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ap.AuthProvider>(context);
    final userId = auth.user?.uid;

    if (userId == null) {
      return Center(
        child: Text(
          'Please sign in to view bookings.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 48,
            color: Colors.transparent,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Bookings List from RTDB
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: auth.authService.getHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  );
                }

                final event = snapshot.data;
                if (event == null || event.snapshot.value == null) {
                  return _buildEmptyState();
                }

                // Parse records
                final dataMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
                final records = dataMap.entries.map((e) {
                  final key = e.key as String;
                  final val = Map<String, dynamic>.from(e.value as Map);
                  return {'key': key, ...val};
                }).toList();

                // Sort newest first
                records.sort((a, b) {
                  final tA = a['createdAt'] as int? ?? 0;
                  final tB = b['createdAt'] as int? ?? 0;
                  return tB.compareTo(tA);
                });

                // Apply UI filters on booking status
                // Status mapping:
                // - Active: 'confirmed', 'pending', 'on way'
                // - Completed: 'completed', 'done'
                // - Cancelled: 'cancelled', 'canceled'
                final filteredRecords = records.where((rec) {
                  final response = rec['response'] as Map?;
                  final booking = response != null ? response['booking'] as Map? : null;
                  final status = (booking != null ? booking['status'] as String? : 'pending')?.toLowerCase() ?? 'pending';

                  if (_activeFilter == 'Active') {
                    return status == 'confirmed' || status == 'pending' || status == 'on_way' || status == 'active';
                  } else if (_activeFilter == 'Completed') {
                    return status == 'completed' || status == 'done';
                  } else if (_activeFilter == 'Cancelled') {
                    return status == 'cancelled' || status == 'canceled';
                  }
                  return true;
                }).toList();

                if (filteredRecords.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final item = filteredRecords[index];
                    final originalMessage = item['originalMessage'] as String? ?? '';
                    final createdAt = item['createdAt'] as int? ?? 0;
                    final responseData = _normalizeMap(item['response'] as Map);

                    // Extract service details
                    final intent = responseData['parsed_intent'] as Map?;
                    final serviceType = intent != null ? intent['service_type'] as String? : null;
                    final location = intent != null ? intent['location'] as String? : null;

                    final booking = responseData['booking'] as Map?;
                    final providerName = booking != null ? booking['provider_name'] as String? : null;
                    final bookingStatus = (booking != null ? booking['status'] as String? : 'pending')?.toLowerCase() ?? 'pending';
                    final scheduledTime = booking != null ? booking['scheduled_time'] as String? : null;

                    return _buildBookingCard(
                      originalMessage: originalMessage,
                      createdAt: createdAt,
                      serviceType: serviceType,
                      location: location,
                      providerName: providerName,
                      status: bookingStatus,
                      scheduledTime: scheduledTime,
                      responseData: responseData,
                      index: index,
                      historyKey: item['key'] as String,
                      userId: userId,
                      auth: auth,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String originalMessage,
    required int createdAt,
    required String? serviceType,
    required String? location,
    required String? providerName,
    required String status,
    required String? scheduledTime,
    required Map<String, dynamic> responseData,
    required int index,
    required String historyKey,
    required String userId,
    required ap.AuthProvider auth,
  }) {
    // Determine stepper state
    // Step index: 0=Booked, 1=Confirmed, 2=On Way, 3=Done
    int currentStep = 0;
    if (status == 'confirmed') currentStep = 1;
    if (status == 'on_way') currentStep = 2;
    if (status == 'completed' || status == 'done') currentStep = 3;
    final isCancelled = status == 'cancelled' || status == 'canceled';

    final dateStr = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final relativeTime = DateFormat('MMM dd, yyyy • hh:mm a').format(dateStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Service Icon Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_serviceIcon(serviceType), color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName ?? 'Finding Provider...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        relativeTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip (Interactive Dropdown to update)
                PopupMenuButton<String>(
                  onSelected: (String newStatus) async {
                    try {
                      await auth.authService.updateBookingStatus(
                        userId: userId,
                        historyKey: historyKey,
                        status: newStatus,
                      );
                    } catch (e) {
                      print('ERROR UPDATING STATUS: $e');
                    }
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusChip(status),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Message Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Message:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$originalMessage"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Stepper Timeline (Skip if Cancelled)
          if (!isCancelled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stepperNode('Booked', currentStep >= 0, true),
                  _stepperLine(currentStep >= 1),
                  _stepperNode('Confirmed', currentStep >= 1, currentStep == 1),
                  _stepperLine(currentStep >= 2),
                  _stepperNode('On Way', currentStep >= 2, currentStep == 2),
                  _stepperLine(currentStep >= 3),
                  _stepperNode('Done', currentStep >= 3, currentStep == 3),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1, color: AppColors.divider),

          // Bottom Action Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      location ?? 'Islamabad',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _openResult(responseData, historyKey: historyKey),
                  child: Row(
                    children: [
                      Text(
                        'View details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
  }

  Widget _buildStatusChip(String status) {
    Color bg = AppColors.surfaceElevated;
    Color fg = AppColors.textSecondary;
    String label = status.toUpperCase();

    if (status == 'confirmed') {
      bg = AppColors.success.withOpacity(0.1);
      fg = AppColors.success;
      label = 'CONFIRMED';
    } else if (status == 'pending') {
      bg = AppColors.warning.withOpacity(0.15);
      fg = const Color(0xFFC08400);
      label = 'PENDING';
    } else if (status == 'on_way' || status == 'on way') {
      bg = AppColors.geminiPurple.withOpacity(0.1);
      fg = AppColors.geminiPurple;
      label = 'ON WAY';
    } else if (status == 'completed' || status == 'done') {
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green.shade800;
      label = 'COMPLETED';
    } else if (status == 'cancelled' || status == 'canceled') {
      bg = AppColors.error.withOpacity(0.1);
      fg = AppColors.error;
      label = 'CANCELLED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _stepperNode(String label, bool isReached, bool isCurrent) {
    final Color iconColor = isCurrent
        ? AppColors.primary
        : (isReached ? AppColors.success : AppColors.border);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isReached ? AppColors.success.withOpacity(0.15) : AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary
                    : isReached
                        ? AppColors.success
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: isCurrent || isReached ? FontWeight.w800 : FontWeight.w600,
            color: isCurrent
                ? AppColors.primary
                : isReached
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _stepperLine(bool isActive) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          height: 2.5,
          color: isActive ? AppColors.success : AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_outline_rounded, size: 44, color: AppColors.textMuted.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookings Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your service bookings and task logs will be listed here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
