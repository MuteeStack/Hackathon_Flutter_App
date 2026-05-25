import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../models/service_models.dart';

class TraceScreen extends StatelessWidget {
  const TraceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final response = appProvider.currentResponse;
        final steps = response?.agentTrace ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.border,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                const Icon(Icons.account_tree_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Agent Trace',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: steps.isEmpty
              ? Center(
                  child: Text(
                    'No trace data available',
                    style: GoogleFonts.inter(color: AppColors.textMuted)
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: steps.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHeader(response!, steps.length).animate().fadeIn().slideY(begin: 0.1);
                    }
                    final step = steps[index - 1];
                    return _buildStepCard(step, index - 1, steps.length)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 150 * index))
                        .slideX(begin: 0.05);
                  },
                ),
        );
      },
    );
  }

  Widget _buildHeader(ServiceResponse response, int totalSteps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Execution Metrics', 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, 
                  fontWeight: FontWeight.w800, 
                  color: AppColors.textPrimary
                )
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _metricBox('TOTAL STEPS', '$totalSteps', AppColors.primary),
              const SizedBox(width: 12),
              _metricBox('LATENCY', '${response.totalProcessingTime.toStringAsFixed(1)}s', AppColors.secondary),
              const SizedBox(width: 12),
              _metricBox('AGENTS', '5', AppColors.warning),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Input: "${response.parsedIntent.originalInput}"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, 
                      color: AppColors.textSecondary, 
                      fontStyle: FontStyle.italic,
                      height: 1.4
                    )
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              value, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, 
                fontWeight: FontWeight.w800, 
                color: color
              )
            ),
            Text(
              label, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9, 
                fontWeight: FontWeight.w700, 
                color: AppColors.textMuted,
                letterSpacing: 0.5
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(AgentStep step, int index, int total) {
    final agentColors = {
      'Intent Understanding Agent': AppColors.primary,
      'Provider Discovery Agent': const Color(0xFF0EA5E9),
      'Matching & Ranking Agent': AppColors.warning,
      'Booking Agent': AppColors.secondary,
      'Follow-Up Agent': AppColors.accent,
    };
    final color = agentColors[step.agentName] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, 
                        fontWeight: FontWeight.w800, 
                        color: color
                      )
                    ),
                  ),
                ),
                if (index < total - 1)
                  Container(
                    width: 2, 
                    height: 120, 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          step.agentName.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9, 
                            fontWeight: FontWeight.w800, 
                            color: color,
                            letterSpacing: 0.5
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step.action,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, 
                      fontWeight: FontWeight.w700, 
                      color: AppColors.textPrimary
                    )
                  ),
                  const SizedBox(height: 12),
                  if (step.inputSummary.isNotEmpty) ...[
                    _stepInfo('Input', step.inputSummary, Icons.login_rounded),
                    const SizedBox(height: 8),
                  ],
                  if (step.outputSummary.isNotEmpty)
                    _stepInfo('Output', step.outputSummary, Icons.logout_rounded),
                  if (step.reasoning.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: color, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.reasoning,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, 
                                color: AppColors.textSecondary, 
                                height: 1.5,
                                fontStyle: FontStyle.italic
                              )
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
        ],
      ),
    );
  }

  Widget _stepInfo(String label, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ', 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, 
                    fontWeight: FontWeight.w800, 
                    color: AppColors.textMuted
                  )
                ),
                TextSpan(
                  text: content, 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, 
                    fontWeight: FontWeight.w500, 
                    color: AppColors.textSecondary
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
