import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/interaction_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Profile Visitors & Analytics Screen
/// Displays total views, total bookmarks, day/week/month filter controls,
/// periodic statistics, and the recent visitors log.
class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InteractionProvider>().fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final interaction = context.watch<InteractionProvider>();
    final analytics = interaction.analytics;
    final selectedPeriod = interaction.selectedPeriod; // 'day', 'week', 'month'
    final isLoading = interaction.isLoadingAnalytics;
    final visitors = interaction.visitors;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile Visitors & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Analytics',
            onPressed: () => interaction.fetchAnalytics(selectedPeriod),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => interaction.fetchAnalytics(selectedPeriod),
        color: AppTheme.burgundy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Overall Lifetime KPIs
              Row(
                children: [
                  Expanded(
                    child: _buildMetricKpiCard(
                      title: 'Total Views',
                      value: '${analytics.totalViews}',
                      icon: Icons.visibility_rounded,
                      color: AppTheme.burgundy,
                      bgColor: AppTheme.roseLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricKpiCard(
                      title: 'Saved Profiles',
                      value: '${analytics.totalSaves}',
                      icon: Icons.bookmark_rounded,
                      color: const Color(0xFFD97706),
                      bgColor: AppTheme.goldLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Filter Control Header: Day | Week | Month
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Activity Analytics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.burgundy),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPeriodSubtitle(selectedPeriod),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Filter Pills: Day | Week | Month
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildFilterTab(
                            title: 'Day',
                            periodKey: 'day',
                            selectedPeriod: selectedPeriod,
                            onTap: () => interaction.fetchAnalytics('day'),
                          ),
                          _buildFilterTab(
                            title: 'Week',
                            periodKey: 'week',
                            selectedPeriod: selectedPeriod,
                            onTap: () => interaction.fetchAnalytics('week'),
                          ),
                          _buildFilterTab(
                            title: 'Month',
                            periodKey: 'month',
                            selectedPeriod: selectedPeriod,
                            onTap: () => interaction.fetchAnalytics('month'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected Period Counts
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cream,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8D7CA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.burgundy),
                                    SizedBox(width: 6),
                                    Text('Views', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${analytics.periodViews}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.burgundy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getPeriodCaption(selectedPeriod),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cream,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8D7CA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bookmark_outline_rounded, size: 16, color: Color(0xFFD97706)),
                                    SizedBox(width: 6),
                                    Text('Saves', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${analytics.periodSaves}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getPeriodCaption(selectedPeriod),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Quick Comparison Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatSummary('Daily', '${analytics.daily.views}v • ${analytics.daily.saves}s'),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        _buildStatSummary('Weekly', '${analytics.weekly.views}v • ${analytics.weekly.saves}s'),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        _buildStatSummary('Monthly', '${analytics.monthly.views}v • ${analytics.monthly.saves}s'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3. Visitor Log Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Profile Visitors',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${visitors.length} Visitors',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Visitors List or Empty View
              if (visitors.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.visibility_off_outlined, size: 52, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No Profile Visitors Yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Candidates who view your matrimony profile details will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visitors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final v = visitors[index];
                    final p = v.profile;

                    return InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ProfileDetailsModal(
                            profile: p,
                            onToggleSave: () {
                              context.read<InteractionProvider>().toggleSaveProfile(p);
                            },
                            onExpressInterest: () {
                              context.read<InteractionProvider>().expressInterest(p);
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                p.profilePhotoUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: const Color(0xFFF1EAE0),
                                  child: Icon(
                                    p.gender == 'Groom' ? Icons.male_rounded : Icons.female_rounded,
                                    color: AppTheme.burgundy,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p.fullName}, ${p.age}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.occupation} • ${p.city}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Viewed ${v.visitCount} ${v.visitCount == 1 ? "time" : "times"}',
                                    style: const TextStyle(
                                      color: AppTheme.burgundy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String title,
    required String periodKey,
    required String selectedPeriod,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedPeriod == periodKey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppTheme.burgundy : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatSummary(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  String _getPeriodSubtitle(String period) {
    switch (period) {
      case 'week':
        return 'Activity recorded over the last 7 days';
      case 'month':
        return 'Activity recorded during this calendar month';
      case 'day':
      default:
        return "Activity recorded for today's date";
    }
  }

  String _getPeriodCaption(String period) {
    switch (period) {
      case 'week':
        return 'in last 7 days';
      case 'month':
        return 'this month';
      case 'day':
      default:
        return 'today';
    }
  }
}
