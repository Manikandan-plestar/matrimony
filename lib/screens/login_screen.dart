import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';

/// Login screen — email input → OTP verify → main app
///
/// This screen handles both new registration and login in one unified flow.
/// Step 1: Enter email → request OTP
/// Step 2: Enter 6-digit OTP → verify → authenticated session
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Step 1: email, Step 2: OTP
  int _step = 1;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String? _errorText;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (mounted) setState(() {});
    });
    _otpController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!(_formKey1.currentState?.validate() ?? false)) return;
    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.requestOtp(_emailController.text.trim());

    if (!mounted) return;
    setState(() { _isBusy = false; });

    if (result.success) {
      setState(() { _step = 2; });
    } else {
      setState(() { _errorText = result.message; });
    }
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey2.currentState?.validate() ?? false)) return;
    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() { _isBusy = false; });

    if (!result.success) {
      setState(() { _errorText = result.message; });
      return;
    }

    // Seed profile into ProfileProvider and load discovery feeds
    final profileProvider = context.read<ProfileProvider>();
    if (result.profile != null) {
      profileProvider.seedProfileFromApi(result.profile);
    } else {
      // Fetch separately in case it was created before
      await profileProvider.fetchMyProfile();
    }

    // Load all other real data concurrently
    if (mounted) {
      await Future.wait([
        context.read<DiscoveryProvider>().fetchAllProfiles(),
        context.read<InteractionProvider>().fetchAll(),
        context.read<NotificationProvider>().fetchNotifications(),
      ]);
    }

    // Navigate to main app
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo area
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.roseLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.burgundy, width: 2),
                      ),
                      child: const Center(
                        child: Text('💍', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vows & Souls',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.burgundy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find Your Forever Match',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              if (_step == 1) _buildEmailStep() else _buildOtpStep(),

              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in or Create Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your email address to receive a verification code.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: AppTheme.textSecondary, size: 20),
                      tooltip: 'Clear',
                      onPressed: () {
                        _emailController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email address.';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isBusy ? null : _requestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.burgundy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isBusy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Send Verification Code',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Verification Code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              children: [
                const TextSpan(text: 'A 6-digit code was sent to '),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.burgundy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 14,
              color: AppTheme.burgundy,
            ),
            decoration: InputDecoration(
              labelText: 'Verification Code',
              hintText: '● ● ● ● ● ●',
              counterText: '',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: _otpController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: AppTheme.textSecondary, size: 20),
                      tooltip: 'Clear',
                      onPressed: () {
                        _otpController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) return 'Please enter the 6-digit code.';
              if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return 'Code must contain only digits.';
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isBusy ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.burgundy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isBusy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Verify & Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _isBusy
                  ? null
                  : () => setState(() {
                        _step = 1;
                        _otpController.clear();
                        _errorText = null;
                      }),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Change email address'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _isBusy ? null : _requestOtp,
              child: const Text('Resend Code', style: TextStyle(color: AppTheme.burgundy)),
            ),
          ),
        ],
      ),
    );
  }
}
