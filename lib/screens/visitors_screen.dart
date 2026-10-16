import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/interaction_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Profile Visitors Screen
class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final visitors = context.watch<InteractionProvider>().visitors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Visitors'),
      ),
      body: visitors.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.visibility_off_outlined, size: 56, color: AppTheme.textMuted),
                  SizedBox(height: 12),
                  Text('No Profile Visitors Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Candidates who view your bio will appear here.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visitors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                        onToggleSave: () {},
                        onExpressInterest: () {},
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(p.profilePhotoUrl, width: 54, height: 54, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.fullName}, ${p.age}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('${p.occupation} â€¢ ${p.city}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'Viewed ${v.visitCount} times â€¢ Recently active',
                                style: const TextStyle(color: AppTheme.burgundy, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}


