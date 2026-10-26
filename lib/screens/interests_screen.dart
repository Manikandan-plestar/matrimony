import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/interaction_model.dart';
import '../models/matrimony_profile_model.dart';
import '../providers/interaction_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Unified Interests & Connections Screen managing 3 Tabs:
/// 1. Sent
/// 2. Connection (Default)
/// 3. Request
class InterestsScreen extends StatefulWidget {
  final int initialTabIndex; // 0 = Sent, 1 = Connection, 2 = Request

  const InterestsScreen({super.key, this.initialTabIndex = 1});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _withdrawingIds = {};
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InteractionProvider>().fetchAll();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Open profile details bottom sheet
  void _openProfileModal(MatrimonyProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileDetailsModal(
        profile: profile,
        onToggleSave: () {
          context.read<InteractionProvider>().toggleSaveProfile(profile);
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
              'This interest request will be cancelled and immediately removed from your Sent list.',
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
      setState(() => _withdrawingIds.add(item.id));
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
          setState(() => _withdrawingIds.remove(item.id));
        }
      }
    }
  }

  /// Confirmation dialog before removing an active connection
  Future<void> _confirmRemoveConnection(MatchItem match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_remove_rounded, color: AppTheme.error, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remove Connection',
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
              'Remove connection with ${match.profile.fullName}?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'This relationship will be permanently removed from Connection for both participants, revoking full contact and profile access.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove Connection'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _processingIds.add(match.id));
      try {
        final success = await context.read<InteractionProvider>().removeConnection(match);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.burgundy,
                content: Text('Connection with ${match.profile.fullName} removed.'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.error,
                content: Text('Failed to remove connection. Please try again.'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.error,
              content: Text('Error: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingIds.remove(match.id));
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
        title: const Text('Interests & Connections'),
      ),
      body: Column(
        children: [
          // 3-Tab Selector: Sent | Connection | Request
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.burgundy,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                // Tab 0: Sent
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.outbox_rounded, size: 16),
                      const SizedBox(width: 5),
                      Text('Sent (${interaction.sentInterests.length})'),
                    ],
                  ),
                ),

                // Tab 1: Connection (Default)
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 16),
                      const SizedBox(width: 5),
                      Text('Connection (${interaction.connectionCount})'),
                    ],
                  ),
                ),

                // Tab 2: Request (Renamed from Received)
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.move_to_inbox_rounded, size: 16),
                      const SizedBox(width: 5),
                      Text('Request (${interaction.receivedInterests.length})'),
                      if (interaction.pendingReceivedCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tabController.index == 2 ? Colors.white : AppTheme.rose,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${interaction.pendingReceivedCount}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _tabController.index == 2 ? AppTheme.burgundy : Colors.white,
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
                  _tabController.index == 0
                      ? Icons.info_outline_rounded
                      : _tabController.index == 1
                          ? Icons.verified_user_outlined
                          : Icons.mark_email_unread_outlined,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _tabController.index == 0
                        ? 'Pending sent expressions can be withdrawn at any time.'
                        : _tabController.index == 1
                            ? 'Mutual accepted connections with full matrimonial bio visibility.'
                            : 'Review candidate invitations and respond to mutual interest.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Tab Views: Sent | Connection | Request
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Sent
                RefreshIndicator(
                  color: AppTheme.burgundy,
                  onRefresh: () => interaction.fetchAll(),
                  child: _buildSentList(interaction),
                ),

                // Tab 1: Connection
                RefreshIndicator(
                  color: AppTheme.burgundy,
                  onRefresh: () => interaction.fetchAll(),
                  child: _buildConnectionList(interaction),
                ),

                // Tab 2: Request
                RefreshIndicator(
                  color: AppTheme.burgundy,
                  onRefresh: () => interaction.fetchAll(),
                  child: _buildRequestList(interaction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: SENT REQUESTS
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.outbox_rounded, size: 48, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Sent Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore discovery feeds and express interest to connect with matrimonial candidates.',
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final p = item.profile;
        final isWithdrawing = _withdrawingIds.contains(item.id);

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
                InkWell(
                  onTap: () => _openProfileModal(p),
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
                          errorBuilder: (_, __, ___) => Container(
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
                              '${p.highestEducation} • ${p.religion}',
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

                // Status Strip & Withdraw Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(item.status),
                    if (item.status == InterestStatus.pending)
                      OutlinedButton.icon(
                        onPressed: isWithdrawing ? null : () => _confirmWithdraw(item),
                        icon: isWithdrawing
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.rose),
                              )
                            : const Icon(Icons.undo_rounded, size: 14),
                        label: Text(
                          isWithdrawing ? 'Withdrawing...' : 'Withdraw',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.rose,
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          backgroundColor: const Color(0xFFFFF1F2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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
  // TAB 1: CONNECTION (ACCEPTED MATCHES)
  // ==========================================
  Widget _buildConnectionList(InteractionProvider provider) {
    final list = provider.matches;

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
                child: const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Connections Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'When you or a candidate accepts an interest request, your mutual connection will appear here.',
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = list[index];
        final p = match.profile;
        final isRemoving = _processingIds.contains(match.id);

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
                // Candidate Summary (Tap to open full details modal)
                InkWell(
                  onTap: () => _openProfileModal(p),
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
                          errorBuilder: (_, __, ___) => Container(
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${match.compatibilityScore}% Compatibility',
                                    style: const TextStyle(
                                      color: Color(0xFF854D0E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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

                // Connection Strip with Remove Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.success),
                          SizedBox(width: 5),
                          Text(
                            'Connected',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isRemoving ? null : () => _confirmRemoveConnection(match),
                      icon: isRemoving
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error),
                            )
                          : const Icon(Icons.person_remove_rounded, size: 14),
                      label: Text(
                        isRemoving ? 'Removing...' : 'Remove',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        backgroundColor: const Color(0xFFFFF1F2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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
  // TAB 2: REQUEST (INCOMING REQUESTS)
  // ==========================================
  Widget _buildRequestList(InteractionProvider provider) {
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
                'No Incoming Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'When candidates express interest in your matrimony profile, their requests will appear here for you to accept or decline.',
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final p = item.profile;
        final isProcessing = _processingIds.contains(item.id);

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
                // Candidate Summary (Tap to open full details modal)
                InkWell(
                  onTap: () => _openProfileModal(p),
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
                          errorBuilder: (_, __, ___) => Container(
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
                              '${p.highestEducation} • ${p.religion}',
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

                // Actions: Accept / Reject
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _processingIds.add(item.id));
                                final ok = await provider.declineInterest(item);
                                if (mounted) {
                                  setState(() => _processingIds.remove(item.id));
                                  if (ok) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Declined interest from ${p.fullName}.')),
                                    );
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _processingIds.add(item.id));
                                final ok = await provider.acceptInterest(item);
                                if (mounted) {
                                  setState(() => _processingIds.remove(item.id));
                                  if (ok) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.burgundy,
                                        content: Text('Accepted interest from ${p.fullName}! Added to Connection.'),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.burgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
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
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case InterestStatus.accepted:
        bg = AppTheme.success.withValues(alpha: 0.15);
        fg = AppTheme.success;
        label = 'Accepted';
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
      case InterestStatus.removed:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Removed';
        icon = Icons.person_remove_rounded;
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
