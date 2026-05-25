/// History Screen — reads from Realtime Database, Google-themed light UI
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../models/service_models.dart';
import 'results_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service History',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700, fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text('Clear', style: GoogleFonts.inter(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => _confirmClear(context, user?.uid),
            ),
          ),
        ],
      ),
      body: user == null
          ? _buildEmpty('Please sign in to see history.')
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('users/${user.uid}/history')
                  .orderByChild('createdAt')
                  .limitToLast(50)
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return _buildEmpty('Could not load history.\n${snapshot.error}');
                }
                
                final event = snapshot.data;
                if (event == null || event.snapshot.value == null) {
                  return _buildEmpty('No history yet.');
                }

                final dynamic value = event.snapshot.value;
                if (value is! Map) return _buildEmpty('No history yet.');
                
                final Map<dynamic, dynamic> map = value;
                
                // Convert map to list and sort descending by createdAt
                final List<Map<String, dynamic>> docs = [];
                map.forEach((key, val) {
                  if (val is Map) {
                    final item = Map<String, dynamic>.from(val);
                    item['_id'] = key.toString();
                    docs.add(item);
                  }
                });
                
                docs.sort((a, b) {
                  final t1 = a['createdAt'] as int? ?? 0;
                  final t2 = b['createdAt'] as int? ?? 0;
                  return t2.compareTo(t1); // descending
                });

                if (docs.isEmpty) return _buildEmpty('No history yet.');

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final docId = data['_id'] as String;
                    return _buildHistoryCard(context, data, docId, index, user.uid)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 60 * index), duration: 350.ms)
                        .slideX(begin: 0.04, curve: Curves.easeOut);
                  },
                );
              },
            ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────────
  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 36, color: AppColors.primary),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textMuted, height: 1.6,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  // ─── History Card ──────────────────────────────────────────────────────────────
  Widget _buildHistoryCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    int index,
    String userId,
  ) {
    final originalMessage = data['originalMessage'] as String? ?? 'Service request';
    final response = data['response'] as Map<String, dynamic>?;
    final int? ts = data['createdAt'] as int?;
    final dateStr = ts != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(ts))
        : 'Recently';

    // Extract parsed intent data safely
    final parsedIntent = response?['parsed_intent'] as Map<String, dynamic>?;
    final serviceType = (parsedIntent?['service_type'] as String? ?? 'service')
        .replaceAll('_', ' ');
    final location = parsedIntent?['location'] as String? ?? '';

    // Extract booking data
    final booking = response?['booking'] as Map<String, dynamic>?;
    final bookingStatus = booking?['status'] as String? ?? '';
    final providerName = booking?['provider_name'] as String? ?? '';
    final isConfirmed = bookingStatus == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: response != null
              ? () => _openResult(context, response)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ─────────────────────────────────────
                Row(
                  children: [
                    // Service icon
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _serviceIcon(serviceType),
                        color: AppColors.primary, size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceType.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary, letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (location.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.place_rounded,
                                    size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Text(
                                  location,
                                  style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Status badge
                    if (bookingStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConfirmed
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isConfirmed
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          bookingStatus.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.w800,
                            color: isConfirmed ? AppColors.success : AppColors.warning,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                // ── Original message ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          originalMessage,
                          style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                if (providerName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        providerName,
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Footer ────────────────────────────────────────
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted,
                      ),
                    ),
                    if (response != null)
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: AppColors.primary),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openResult(BuildContext context, Map<String, dynamic> responseData) {
    try {
      final response = ServiceResponse.fromJson(responseData);
      context.read<AppProvider>().setResponse(response);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load result: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmClear(BuildContext context, String? userId) async {
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear History?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete all your service history.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseDatabase.instance.ref('users/$userId/history').remove();
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _serviceIcon(String serviceType) {
    final s = serviceType.toLowerCase();
    if (s.contains('ac') || s.contains('hvac')) return Icons.ac_unit_rounded;
    if (s.contains('plumb')) return Icons.plumbing_rounded;
    if (s.contains('electric')) return Icons.electrical_services_rounded;
    if (s.contains('tutor') || s.contains('teacher')) return Icons.school_rounded;
    if (s.contains('beaut') || s.contains('salon')) return Icons.face_rounded;
    if (s.contains('carpen')) return Icons.carpenter_rounded;
    if (s.contains('paint')) return Icons.format_paint_rounded;
    if (s.contains('clean')) return Icons.cleaning_services_rounded;
    if (s.contains('mechan')) return Icons.build_rounded;
    return Icons.miscellaneous_services_rounded;
  }
}
