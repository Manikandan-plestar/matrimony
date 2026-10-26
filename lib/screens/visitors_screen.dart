import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/interaction_model.dart';
import '../providers/interaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Profile Visitors & Weekly Analytics Screen
/// Features an interactive 7-day Sunday-to-Saturday weekly profile-view bar chart,
/// week navigation with future date bounds, and per-day visitor inspection.
/// Requires the ₹499 Unlimited Swipe Plan to access.
class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  bool _isPurchasingPlatform = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subProvider = context.read<SubscriptionProvider>();
      subProvider.fetchStatus().then((_) {
        if (mounted && subProvider.isUnlimited) {
          context.read<InteractionProvider>().fetchWeeklyAnalytics();
        }
      });
    });
  }

  Future<void> _handlePlatformPurchase() async {
    setState(() => _isPurchasingPlatform = true);
    final subProvider = context.read<SubscriptionProvider>();
    final interaction = context.read<InteractionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await subProvider.purchasePlatformPayment();

    if (mounted) {
      setState(() => _isPurchasingPlatform = false);
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.burgundy,
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
          ),
        );
        await interaction.fetchWeeklyAnalytics(forceRefresh: true);
      } else if (!result.isCancelled) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text(result.message),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final interaction = context.watch<InteractionProvider>();

    // Premium Paywall gate: Only users with the ₹499 plan can view visitors & analytics
    if (!subscription.isUnlimited) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Profile Visitors'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF800020), Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _buildPremiumPaywall(context, subscription),
      );
    }
    final analytics = interaction.analytics;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile Visitors & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Analytics',
            onPressed: () => interaction.fetchWeeklyAnalytics(forceRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => interaction.fetchWeeklyAnalytics(forceRefresh: true),
        color: AppTheme.burgundy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Lifetime KPIs
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

              // 2. Interactive Weekly Profile Views Bar Chart
              _buildWeeklyChartCard(interaction),

              const SizedBox(height: 22),

              // 3. Selected Day Breakdown & Recent Visitors on that Date
              _buildSelectedDayVisitorsSection(interaction),

              const SizedBox(height: 30),
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

  Widget _buildWeeklyChartCard(InteractionProvider interaction) {
    final chart = interaction.weeklyChart;
    final isLoading = interaction.isLoadingWeeklyChart;
    final error = interaction.weeklyChartError;
    final sunday = interaction.selectedWeekStart;
    final canGoNext = interaction.canGoToNextWeek;
    final weekRangeStr = _formatWeekRange(sunday);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Chart Header: Title & Weekly Total Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppTheme.burgundy, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Weekly Profile Views',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (chart != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.roseLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.rose),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_rounded, size: 13, color: AppTheme.burgundy),
                      const SizedBox(width: 4),
                      Text(
                        '${chart.totalViews} ${chart.totalViews == 1 ? "view" : "views"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.burgundy,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Week Navigation Controls (Previous, Range, Next)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Week
                InkWell(
                  onTap: isLoading ? null : () => interaction.goToPreviousWeek(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left_rounded, size: 20, color: AppTheme.burgundy),
                        SizedBox(width: 2),
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.burgundy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected Week Date Range (Sun - Sat)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      weekRangeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),

                // Next Week (disabled if at current week)
                InkWell(
                  onTap: (!canGoNext || isLoading) ? null : () => interaction.goToNextWeek(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: canGoNext ? AppTheme.burgundy : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: canGoNext ? AppTheme.burgundy : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Chart Container
          if (isLoading && chart == null)
            const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.burgundy),
              ),
            )
          else if (error != null && chart == null)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 36),
                  const SizedBox(height: 8),
                  Text(error, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.burgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => interaction.fetchWeeklyAnalytics(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (chart != null)
            _buildInteractive7Bars(chart, interaction)
          else
            const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInteractive7Bars(WeeklyChartDataModel chart, InteractionProvider interaction) {
    final days = chart.days;
    if (days.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('No data for this week.')),
      );
    }

    final maxViews = days.map((d) => d.views).fold(0, (prev, curr) => curr > prev ? curr : prev);
    const double maxBarHeight = 120.0;

    return SizedBox(
      height: maxBarHeight + 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(days.length, (index) {
          final day = days[index];
          final isSelected = index == interaction.selectedDayIndex;
          final views = day.views;

          // Height scaling: subtle baseline representation for 0 views
          double barHeight;
          if (maxViews == 0 || views == 0) {
            barHeight = 5.0;
          } else {
            barHeight = (views / maxViews) * maxBarHeight;
            if (barHeight < 14.0) barHeight = 14.0;
          }

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Interactive selection only — does NOT count as a profile view
                interaction.selectDay(index);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View count badge above bar
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: views > 0 || isSelected ? 1.0 : 0.35,
                    child: Text(
                      views.toString(),
                      style: TextStyle(
                        fontSize: isSelected ? 12 : 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppTheme.burgundy : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Vertical Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 24 : 18,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: views > 0
                          ? LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isSelected
                                  ? [AppTheme.burgundy, const Color(0xFFC43D75)]
                                  : [
                                      AppTheme.burgundy.withValues(alpha: 0.55),
                                      AppTheme.burgundy.withValues(alpha: 0.85),
                                    ],
                            )
                          : null,
                      color: views == 0
                          ? (isSelected ? AppTheme.rose : const Color(0xFFE2E8F0))
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.burgundy,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected && views > 0
                          ? [
                              BoxShadow(
                                color: AppTheme.burgundy.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Day Label & Date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.burgundy : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day.dayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _getDayOfMonth(day.date),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                            color: isSelected ? Colors.white70 : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedDayVisitorsSection(InteractionProvider interaction) {
    final selectedDay = interaction.selectedDay;
    final dayVisitors = interaction.visitorsForSelectedDay;

    if (selectedDay == null) return const SizedBox.shrink();

    final dateTitle = _formatFullDate(selectedDay.date);
    final viewsCount = selectedDay.views;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Banner Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8D7CA)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.roseLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available_rounded, color: AppTheme.burgundy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viewsCount == 0
                          ? '0 profile views recorded'
                          : '$viewsCount profile ${viewsCount == 1 ? "view" : "views"} recorded',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: viewsCount > 0 ? AppTheme.burgundy : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Visitors on this Day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            if (dayVisitors.isNotEmpty)
              Text(
                '${dayVisitors.length} ${dayVisitors.length == 1 ? "Visitor" : "Visitors"}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Visitors list or Day Zero state
        if (viewsCount == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.visibility_off_outlined, size: 44, color: AppTheme.textMuted),
                SizedBox(height: 10),
                Text(
                  'No profile views on this day.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No candidates viewed your profile on this selected date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          )
        else if (dayVisitors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.burgundy),
                const SizedBox(height: 10),
                Text(
                  '$viewsCount Views Logged',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Detailed candidate profiles are available for published member accounts.',
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
            itemCount: dayVisitors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final v = dayVisitors[index];
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
      ],
    );
  }

  String _formatWeekRange(DateTime sunday) {
    final saturday = sunday.add(const Duration(days: 6));
    final startFmt = DateFormat('MMM d');
    final endFmt = DateFormat('MMM d, yyyy');
    if (sunday.year != saturday.year) {
      return '${DateFormat('MMM d, yyyy').format(sunday)} – ${endFmt.format(saturday)}';
    }
    return '${startFmt.format(sunday)} – ${endFmt.format(saturday)}';
  }

  String _formatFullDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _getDayOfMonth(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        return int.parse(parts[2]).toString();
      }
    } catch (_) {}
    return '';
  }

  /// Premium Paywall View shown to Free users when attempting to access Profile Visitors
  Widget _buildPremiumPaywall(BuildContext context, SubscriptionProvider subscription) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // 1. Hero Card with glowing Burgundy & Gold theme
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B0014), Color(0xFF800020), Color(0xFFA51D35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF800020).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFDF00),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Unlock Profile Visitors & Analytics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'See who viewed your profile, detailed weekly stats, candidate profile details, and enjoy unlimited swipes!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFDF00).withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: Color(0xFFFFDF00), size: 18),
                      SizedBox(width: 8),
                      Text(
                        '₹499 • 1 Year Unlimited Access (365 Days)',
                        style: TextStyle(
                          color: Color(0xFFFFDF00),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. What's Included Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.burgundy, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'What\'s Included with ₹499 Plan (1 Year)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPaywallFeatureRow(
                  icon: Icons.all_inclusive_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  title: 'Unlimited Profile Swipes',
                  description: 'No daily 10-swipe limit. Discover and connect with unlimited prospective matches for 365 days.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildPaywallFeatureRow(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppTheme.burgundy,
                  iconBg: AppTheme.roseLight,
                  title: 'Weekly Profile Visitor Statistics',
                  description: 'Interactive Sunday-to-Saturday daily chart showing exactly how many people viewed your profile.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildPaywallFeatureRow(
                  icon: Icons.account_circle_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Full Visitor Profile Details',
                  description: 'View full photos, education, profession, horoscope, and express interest directly.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Locked Interactive Chart Teaser
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weekly View Trends Preview',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.roseLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_rounded, size: 12, color: AppTheme.burgundy),
                          SizedBox(width: 4),
                          Text('LOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.burgundy)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Blurred chart bars placeholder
                SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTeaserBar('Sun', 35),
                      _buildTeaserBar('Mon', 60),
                      _buildTeaserBar('Tue', 85),
                      _buildTeaserBar('Wed', 45),
                      _buildTeaserBar('Thu', 75),
                      _buildTeaserBar('Fri', 90),
                      _buildTeaserBar('Sat', 65),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Unlock to view exact view counts and full profile cards for each day',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Production In-App Purchase Action (Apple IAP on iOS, Google Pay on Android)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isPurchasingPlatform ? null : _handlePlatformPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F1F1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              child: _isPurchasingPlatform
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Platform.isIOS ? Icons.apple : Icons.payment_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Platform.isIOS
                              ? 'Pay with Apple In-App Purchase • ₹499'
                              : 'Pay with Google Pay • ₹499',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. Reassurance badges
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded, size: 15, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                'Valid for 1 Full Year • In-App Purchase Protection • 100% Secure',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaywallFeatureRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeaserBar(String day, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.burgundy.withValues(alpha: 0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
