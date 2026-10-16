import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/interaction_model.dart';
import '../providers/interaction_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Unified Interests Screen managing Sent & Received Interests with Withdrawal Action
class InterestsScreen extends StatefulWidget {
  final int initialTabIndex; // 0 = Sent, 1 = Received

  const InterestsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _withdrawingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Open profile details bottom sheet
  void _openProfileModal(InterestItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileDetailsModal(
        profile: item.profile,
        onToggleSave: () {
          context.read<InteractionProvider>().toggleSaveProfile(item.profile);
        },
        onExpressInterest: () {},
      ),
    );
  }

  /// Confirmation dialog before withdrawing a pending sent interest
  Future<void> _confirmWithdraw(InterestItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.rose.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.undo_rounded, color: AppTheme.rose, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Withdraw Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to withdraw your interest in ${item.profile.fullName}?',
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text(
              'This interest request will be cancelled and will no longer appear as pending for both you and the candidate.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Request', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Withdraw Interest'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _withdrawingIds.add(item.id);
      });
      try {
        final success = await context.read<InteractionProvider>().withdrawInterest(item);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.burgundy,
                content: Text('Interest request in ${item.profile.fullName} has been withdrawn.'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.error,
                content: Text('Could not withdraw request. It may have already been processed.'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.error,
              content: Text('Error withdrawing request: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _withdrawingIds.remove(item.id);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final interaction = context.watch<InteractionProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Interests & Invitations'),
      ),
      body: Column(
        children: [
          // Modern Segmented Pill Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.burgundy,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.burgundy.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.outbox_rounded, size: 17),
                      const SizedBox(width: 7),
                      Text('Sent (${interaction.sentInterests.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.move_to_inbox_rounded, size: 17),
                      const SizedBox(width: 7),
                      Text('Received (${interaction.receivedInterests.length})'),
                      if (interaction.pendingReceivedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tabController.index == 1 ? Colors.white : AppTheme.rose,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${interaction.pendingReceivedCount}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _tabController.index == 1 ? AppTheme.burgundy : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Subheader Info Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(
                  _tabController.index == 0 ? Icons.info_outline_rounded : Icons.mark_email_unread_outlined,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _tabController.index == 0
                        ? 'Pending sent expressions can be withdrawn at any time.'
                        : 'Review candidate invitations and respond to mutual interest.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Sent Interests Tab
                _buildSentList(interaction),

                // 2. Received Interests Tab
                _buildReceivedList(interaction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: SENT INTERESTS
  // ==========================================
  Widget _buildSentList(InteractionProvider provider) {
    final list = provider.sentInterests;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.outbox_rounded, size: 48, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Interests Sent Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore Groom and Bride discovery feeds and tap the heart icon or swipe right to express interest.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final p = item.profile;
        final isProcessingWithdrawal = _withdrawingIds.contains(item.id);

        return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Candidate Summary Row (Tap to open full details modal)
                InkWell(
                  onTap: () => _openProfileModal(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      // Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          p.profilePhotoUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 58,
                            height: 58,
                            color: const Color(0xFFF1EAE0),
                            child: Icon(
                              p.gender == 'Groom' ? Icons.male_rounded : Icons.female_rounded,
                              color: AppTheme.burgundy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name, Age, Occupation, Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${p.fullName}, ${p.age}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF38BDF8)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.occupation} • ${p.city}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.highestEducation} • ${p.community}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // View Profile Icon
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.6, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Status & Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    _buildStatusBadge(item.status),

                    // Withdraw Action Button (Visible ONLY for pending sent requests)
                    if (item.status == InterestStatus.pending) ...[
                      OutlinedButton.icon(
                        onPressed: isProcessingWithdrawal ? null : () => _confirmWithdraw(item),
                        icon: isProcessingWithdrawal
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.rose),
                              )
                            : const Icon(Icons.undo_rounded, size: 15),
                        label: Text(
                          isProcessingWithdrawal ? 'Withdrawing...' : 'Withdraw Request',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.rose,
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          backgroundColor: const Color(0xFFFFF1F2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else if (item.status == InterestStatus.accepted) ...[
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/matches'),
                        icon: const Icon(Icons.favorite_rounded, size: 15, color: AppTheme.rose),
                        label: const Text(
                          'View Match',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.rose),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: RECEIVED INTERESTS
  // ==========================================
  Widget _buildReceivedList(InteractionProvider provider) {
    final list = provider.receivedInterests;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline_rounded, size: 48, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Interests Received',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'When other matrimonial candidates express interest in your profile, their requests will appear here for you to accept or decline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final p = item.profile;

        return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Candidate Summary Row (Tap to open full details modal)
                InkWell(
                  onTap: () => _openProfileModal(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          p.profilePhotoUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 58,
                            height: 58,
                            color: const Color(0xFFF1EAE0),
                            child: Icon(
                              p.gender == 'Groom' ? Icons.male_rounded : Icons.female_rounded,
                              color: AppTheme.burgundy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${p.fullName}, ${p.age}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF38BDF8)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.occupation} • ${p.city}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.highestEducation} • ${p.community}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.6, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Actions or Final Status
                if (item.status == InterestStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.declineInterest(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Declined interest from ${p.fullName}.'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            provider.acceptInterest(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.burgundy,
                                content: Text('Accepted interest from ${p.fullName}! Added to My Matches.'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.burgundy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Accept Interest', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else if (item.status == InterestStatus.withdrawn) ...[
                  // Sender withdrew request safeguard
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'This interest request was cancelled by the sender',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.status == InterestStatus.accepted
                          ? AppTheme.success.withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.status == InterestStatus.accepted ? Icons.check_circle_rounded : Icons.cancel_outlined,
                          size: 15,
                          color: item.status == InterestStatus.accepted ? AppTheme.success : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.status == InterestStatus.accepted
                              ? 'Interest Accepted • Added to Matches'
                              : 'Declined',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: item.status == InterestStatus.accepted ? AppTheme.success : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Status badge helper
  Widget _buildStatusBadge(InterestStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case InterestStatus.pending:
        bg = AppTheme.goldLight;
        fg = const Color(0xFF854D0E);
        label = 'Awaiting Response';
        icon = Icons.schedule_rounded;
        break;
      case InterestStatus.accepted:
        bg = AppTheme.success.withValues(alpha: 0.15);
        fg = AppTheme.success;
        label = 'Interest Accepted! 🎉';
        icon = Icons.check_circle_rounded;
        break;
      case InterestStatus.declined:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Declined';
        icon = Icons.cancel_outlined;
        break;
      case InterestStatus.withdrawn:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Withdrawn';
        icon = Icons.undo_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
