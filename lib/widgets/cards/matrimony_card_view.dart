import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/matrimony_profile_model.dart';
import '../../utils/app_image_helper.dart';

/// Image-First Matrimonial Profile Card
class MatrimonyCardView extends StatelessWidget {
  final MatrimonyProfileModel profile;
  final VoidCallback onPass;
  final VoidCallback onSave;
  final VoidCallback onInterest;
  final VoidCallback onViewDetails;

  const MatrimonyCardView({
    super.key,
    required this.profile,
    required this.onPass,
    required this.onSave,
    required this.onInterest,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dominant Large Profile Photograph (Image-First)
          GestureDetector(
            onTap: onViewDetails,
            child: AppImageHelper.buildProfileImage(
              url: profile.profilePhotoUrl,
              fullName: profile.fullName,
              gender: profile.gender,
              fit: BoxFit.cover,
              isShielded: profile.isPhotoShielded,
            ),
          ),

          // 2. Subtle Gradient Overlay at bottom for readable text
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Badges: Compatibility Score & Verified Badge
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Match compatibility badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.gold, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.compatibilityScore}% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile ID Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.profileId,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Info Section (Clean & Minimal)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full Name & Age & Verified Checkmark
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${profile.fullName}, ${profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Quick Professional & Location summary
                  Row(
                    children: [
                      const Icon(Icons.work_outline_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          profile.occupation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        '${profile.city}, ${profile.state}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        profile.community,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // const SizedBox(height: 12),

                  // // Tap to View Details Bar
                  // InkWell(
                  //   onTap: onViewDetails,
                  //   borderRadius: BorderRadius.circular(12),
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  //     decoration: BoxDecoration(
                  //       color: Colors.white.withValues(alpha: 0.16),
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  //     ),
                  //     child: const Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 20),
                  //         SizedBox(width: 6),
                  //         Text(
                  //           'Tap to Reveal Full Matrimonial Bio',
                  //           style: TextStyle(
                  //             color: Colors.white,
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 14),

                  // 5. Action Buttons (Pass, Save, Details, Express Interest)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pass Button
                      _buildActionButton(
                        icon: Icons.close_rounded,
                        color: const Color(0xFF94A3B8),
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        size: 46,
                        onTap: onPass,
                      ),

                      // Save / Bookmark Button
                      _buildActionButton(
                        icon: profile.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: profile.isSaved ? AppTheme.gold : Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        size: 46,
                        onTap: onSave,
                      ),

                      // Full Details Info Button
                      _buildActionButton(
                        icon: Icons.info_outline_rounded,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        size: 46,
                        onTap: onViewDetails,
                      ),

                      // Express Interest Heart Button (Primary)
                      _buildActionButton(
                        icon: profile.isInterestSent ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: Colors.white,
                        backgroundColor: AppTheme.rose,
                        size: 54,
                        onTap: onInterest,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required double size,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.48),
      ),
    );
  }
}
