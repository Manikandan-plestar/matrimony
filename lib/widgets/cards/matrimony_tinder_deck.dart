import 'package:flutter/material.dart';
import '../../models/matrimony_profile_model.dart';
import 'matrimony_card_view.dart';

/// Reusable Matrimony Tinder Swipe Deck (Adapted from the original project's gesture engine)
class MatrimonyTinderDeck extends StatefulWidget {
  final List<MatrimonyProfileModel> profiles;
  final Function(MatrimonyProfileModel profile) onToggleSave;
  final Function(MatrimonyProfileModel profile) onExpressInterest;
  final Function(MatrimonyProfileModel profile) onViewDetails;
  final Future<bool> Function(MatrimonyProfileModel profile, String action)? onSwipe;
  final VoidCallback? onReset;

  const MatrimonyTinderDeck({
    super.key,
    required this.profiles,
    required this.onToggleSave,
    required this.onExpressInterest,
    required this.onViewDetails,
    this.onSwipe,
    this.onReset,
  });

  @override
  State<MatrimonyTinderDeck> createState() => _MatrimonyTinderDeckState();
}

class _MatrimonyTinderDeckState extends State<MatrimonyTinderDeck>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  bool _isAnimatingOffscreen = false;
  bool _swipingNext = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animController.addListener(() {
      setState(() {
        _dragOffset = _slideAnimation.value;
        _dragAngle = _rotateAnimation.value;
      });
    });
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isAnimatingOffscreen) {
          setState(() {
            if (_swipingNext) {
              if (widget.profiles.isNotEmpty) {
                _currentIndex = (_currentIndex + 1) % widget.profiles.length;
              }
            } else {
              if (widget.profiles.isNotEmpty) {
                _currentIndex = (_currentIndex - 1 + widget.profiles.length) % widget.profiles.length;
              }
            }
            _dragOffset = Offset.zero;
            _dragAngle = 0.0;
            _isAnimatingOffscreen = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant MatrimonyTinderDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profiles.length != oldWidget.profiles.length) {
      if (_currentIndex >= widget.profiles.length && widget.profiles.isNotEmpty) {
        _currentIndex = widget.profiles.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_animController.isAnimating) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_animController.isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
      final screenWidth = MediaQuery.of(context).size.width;
      _dragAngle = (_dragOffset.dx / screenWidth) * 0.22;
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_animController.isAnimating) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25;
    final vx = details.velocity.pixelsPerSecond.dx;

    if (_dragOffset.dx < -threshold || vx < -450) {
      // Swiped Right-to-Left (Dragged Left): Pass -> Next Profile
      if (widget.profiles.isNotEmpty) {
        final profile = widget.profiles[_currentIndex];
        if (widget.onSwipe != null) {
          final allowed = await widget.onSwipe!(profile, 'pass');
          if (!allowed) {
            _animateBackToCenter();
            return;
          }
        }
      }
      if (widget.profiles.length > 1) {
        _animateSwipe(const Offset(-650, 0), -0.32, isNext: true);
      } else {
        _animateBackToCenter();
      }
    } else if (_dragOffset.dx > threshold || vx > 450) {
      // Swiped Left-to-Right (Dragged Right): Show Previous Profile!
      // Do NOT send interest request (only heart icon tap sends interest)
      if (widget.profiles.length > 1) {
        _animateSwipe(const Offset(650, 0), 0.32, isNext: false);
      } else {
        _animateBackToCenter();
      }
    } else {
      _animateBackToCenter();
    }
  }

  void _animateSwipe(Offset targetOffset, double targetAngle, {required bool isNext}) {
    _swipingNext = isNext;
    _isAnimatingOffscreen = true;
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad));

    _rotateAnimation = Tween<double>(
      begin: _dragAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad));

    _animController.forward(from: 0.0);
  }

  void _animateBackToCenter() {
    _isAnimatingOffscreen = false;
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _rotateAnimation = Tween<double>(
      begin: _dragAngle,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _animController.forward(from: 0.0);
  }

  Future<void> _manualPass() async {
    if (_animController.isAnimating || widget.profiles.isEmpty) return;
    final profile = widget.profiles[_currentIndex];
    if (widget.onSwipe != null) {
      final allowed = await widget.onSwipe!(profile, 'pass');
      if (!allowed) return;
    }
    if (widget.profiles.length > 1) {
      _animateSwipe(const Offset(-650, 0), -0.3, isNext: true);
    }
  }

  Future<void> _manualInterest() async {
    if (_animController.isAnimating || widget.profiles.isEmpty) return;
    final profile = widget.profiles[_currentIndex];
    if (widget.onSwipe != null) {
      final allowed = await widget.onSwipe!(profile, 'interest');
      if (!allowed) return;
    }
    widget.onExpressInterest(profile);
    if (widget.profiles.length > 1) {
      _animateSwipe(const Offset(650, 0), 0.3, isNext: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text(
                'No Profiles Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your search filters to discover more matches.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (widget.onReset != null)
                OutlinedButton.icon(
                  onPressed: widget.onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Filters'),
                ),
            ],
          ),
        ),
      );
    }

    final topProfile = widget.profiles[_currentIndex % widget.profiles.length];
    final prevProfile = widget.profiles.length > 1
        ? widget.profiles[(_currentIndex - 1 + widget.profiles.length) % widget.profiles.length]
        : null;
    final nextProfile = widget.profiles.length > 1
        ? widget.profiles[(_currentIndex + 1) % widget.profiles.length]
        : null;
    final behindProfile = _dragOffset.dx > 0 ? prevProfile : nextProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Next / Previous card behind (subtle scale 0.94 & slight offset)
          if (behindProfile != null)
            Transform.translate(
              offset: const Offset(0, 16),
              child: Transform.scale(
                scale: 0.94,
                child: Opacity(
                  opacity: 0.65,
                  child: MatrimonyCardView(
                    profile: behindProfile,
                    onPass: () {},
                    onSave: () {},
                    onInterest: () {},
                    onViewDetails: () {},
                  ),
                ),
              ),
            ),

          // 2. Active top draggable card
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _dragAngle,
                child: MatrimonyCardView(
                  profile: topProfile,
                  onPass: _manualPass,
                  onSave: () => widget.onToggleSave(topProfile),
                  onInterest: _manualInterest,
                  onViewDetails: () => widget.onViewDetails(topProfile),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
