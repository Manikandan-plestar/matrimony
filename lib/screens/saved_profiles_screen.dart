import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/interaction_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Saved Matrimonial Profiles Screen
class SavedProfilesScreen extends StatelessWidget {
  const SavedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final interaction = context.watch<InteractionProvider>();
    final savedList = interaction.savedProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Profiles'),
      ),
      body: savedList.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bookmark_outline_rounded, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No Saved Profiles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap the bookmark icon on any profile to save it for later.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: savedList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = savedList[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        p.profilePhotoUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 58,
                          height: 58,
                          color: const Color(0xFFF1EAE0),
                          child: const Icon(Icons.person, color: AppTheme.burgundy),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          '${p.fullName}, ${p.age}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF38BDF8)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${p.occupation} â€¢ ${p.city}'),
                        const SizedBox(height: 2),
                        Text('${p.highestEducation} â€¢ ${p.community}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove_rounded, color: AppTheme.rose),
                      tooltip: 'Remove from Saved',
                      onPressed: () {
                        interaction.toggleSaveProfile(p);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed ${p.fullName} from saved profiles.')),
                        );
                      },
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ProfileDetailsModal(
                          profile: p,
                          onToggleSave: () => interaction.toggleSaveProfile(p),
                          onExpressInterest: () => interaction.expressInterest(p),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}


