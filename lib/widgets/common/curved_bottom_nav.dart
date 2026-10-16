import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable Curved Scooped Bottom Navigation Bar with Center Animated Publish/Match Button
class CurvedMatrimonyBottomNav extends StatefulWidget {
  final int currentIndex; // 0 = Groom, 1 = Center Publish, 2 = Bride
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const CurvedMatrimonyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  @override
  State<CurvedMatrimonyBottomNav> createState() => _CurvedMatrimonyBottomNavState();
}

class _CurvedMatrimonyBottomNavState extends State<CurvedMatrimonyBottomNav>
    with SingleTickerProviderStateMixin {
  Timer? _iconCycleTimer;
  bool _showingAddIcon = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startIconCycle();
  }

  void _startIconCycle() {
    _iconCycleTimer?.cancel();
    _iconCycleTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _showingAddIcon = !_showingAddIcon;
        });
      }
    });
  }

  @override
  void dispose() {
    _iconCycleTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Groom Tab (Left)
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  label: 'Groom',
                  activeIcon: Icons.male_rounded,
                  inactiveIcon: Icons.male_outlined,
                  isSelected: widget.currentIndex == 0,
                  onTap: () => widget.onTap(0),
                ),
              ),

              // 2. Center Publish / Match Action (Elevated Animated Button)
              GestureDetector(
                onTap: widget.onCenterTap,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.burgundy, AppTheme.rose],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.rose.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: _showingAddIcon
                          ? const Icon(
                              Icons.add_rounded,
                              key: ValueKey('add_icon'),
                              color: Colors.white,
                              size: 30,
                            )
                          : const Icon(
                              Icons.favorite_rounded,
                              key: ValueKey('heart_icon'),
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                ),
              ),

              // 3. Bride Tab (Right)
              Expanded(
                child: _buildNavItem(
                  index: 2,
                  label: 'Bride',
                  activeIcon: Icons.female_rounded,
                  inactiveIcon: Icons.female_outlined,
                  isSelected: widget.currentIndex == 2,
                  onTap: () => widget.onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.roseLight : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppTheme.burgundy : AppTheme.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.burgundy : AppTheme.textMuted,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
