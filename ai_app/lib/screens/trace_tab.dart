import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants.dart';
import '../providers/app_provider.dart';

class TraceTab extends StatelessWidget {
  final VoidCallback? onSwitchToChat;
  const TraceTab({super.key, this.onSwitchToChat});

  Color _agentColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('intent')) return AppColors.info;
    if (n.contains('discovery')) return const Color(0xFF0EA5E9); // Sky blue
    if (n.contains('rank') || n.contains('match')) return AppColors.warning;
    if (n.contains('book')) return AppColors.geminiPurple;
    if (n.contains('follow')) return AppColors.primary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final response = provider.currentResponse;

    if (response == null) {
      return _buildEmptyState(context);
    }

    final totalSteps = response.agentTrace.length;
    final currentStep = provider.currentStep;
    final traceSteps = response.agentTrace;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Agent Trace Logs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            // Live / Completed Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: currentStep < totalSteps
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: currentStep < totalSteps ? AppColors.primary : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => currentStep < totalSteps ? c.repeat(reverse: true) : c.stop())
                   .scaleXY(begin: 0.7, end: 1.3, duration: 600.ms),
                  const SizedBox(width: 4),
                  Text(
                    currentStep < totalSteps ? 'LIVE' : 'COMPLETED',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: currentStep < totalSteps ? AppColors.primary : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Metrics Card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
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
                      _metricCol('Processing Time', '${response.totalProcessingTime}s', Icons.timer_outlined),
                      _metricCol('Active Agents', '5 Agents', Icons.smart_button_rounded),
                      _metricCol('Total Steps', '$totalSteps Steps', Icons.format_list_numbered_rtl),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.psychology_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '"${response.parsedIntent.originalInput}"',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ── Timeline Section ─────────────────────────────────────────────
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: traceSteps.length,
              itemBuilder: (context, index) {
                final step = traceSteps[index];
                final stepNum = step.stepNumber;
                final isPassed = currentStep >= stepNum;
                final isLast = index == traceSteps.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator column
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isPassed ? _agentColor(step.agentName) : AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPassed ? _agentColor(step.agentName) : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : Text(
                                    '$stepNum',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2.5,
                            height: 220, // Tall connector line
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isPassed ? _agentColor(step.agentName) : AppColors.divider,
                                  currentStep >= (stepNum + 1)
                                      ? _agentColor(traceSteps[index + 1].agentName)
                                      : AppColors.divider,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Step detail card
                    Expanded(
                      child: Opacity(
                        opacity: isPassed ? 1.0 : 0.4,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPassed ? _agentColor(step.agentName).withOpacity(0.3) : AppColors.border,
                              width: isPassed ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              if (isPassed)
                                BoxShadow(
                                  color: _agentColor(step.agentName).withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Agent Name Badge & Time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _agentColor(step.agentName).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      step.agentName.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: _agentColor(step.agentName),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    step.timestamp.split('T').last.substring(0, 5),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Action Title
                              Text(
                                step.action,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Summaries
                              _summarySection('Input Summary', step.inputSummary),
                              const SizedBox(height: 6),
                              _summarySection('Output Summary', step.outputSummary),

                              if (step.reasoning.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (bounds) => AppColors.geminiGradient.createShader(bounds),
                                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'REASONING',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textSecondary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        step.reasoning,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 6),
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _summarySection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            child: Icon(Icons.analytics_outlined, size: 44, color: AppColors.textMuted.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Trace Logs',
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
              'Run an AI service search request from the Chat tab to view step-by-step agent traces in real time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onSwitchToChat,
            icon: const Icon(Icons.chat_bubble_rounded, size: 16),
            label: const Text('Start Chatting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
