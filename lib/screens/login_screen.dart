import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common/wedding_pattern_background.dart';
import '../widgets/modals/terms_conditions_modal.dart';

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
  bool _isRegisterMode = false; // false = Sign In, true = Create Account
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String? _errorText;
  String? _infoText;
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

  String get _normalizedEmail => _emailController.text.trim().toLowerCase();

  Future<void> _requestOtp() async {
    if (!(_formKey1.currentState?.validate() ?? false)) return;
    setState(() {
      _isBusy = true;
      _errorText = null;
      _infoText = null;
    });

    final auth = context.read<AuthProvider>();
    final action = _isRegisterMode ? 'register' : 'login';
    final result = await auth.requestOtp(_normalizedEmail, action: action);

    if (!mounted) return;
    setState(() { _isBusy = false; });

    if (result.success) {
      setState(() { _step = 2; });
    } else {
      if (result.code == 'ACCOUNT_EXISTS') {
        // Direct the user to the existing email-verification login flow
        setState(() {
          _isRegisterMode = false;
          _infoText = 'An account with this email already exists. Switched to Sign In — tap Continue to get your code.';
          _errorText = null;
        });
      } else {
        setState(() { _errorText = result.message; });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey2.currentState?.validate() ?? false)) return;
    setState(() {
      _isBusy = true;
      _errorText = null;
      _infoText = null;
    });

    final auth = context.read<AuthProvider>();
    final action = _isRegisterMode ? 'register' : 'login';
    final result = await auth.verifyOtp(
      _normalizedEmail,
      _otpController.text.trim(),
      action: action,
    );

    if (!mounted) return;
    setState(() { _isBusy = false; });

    if (!result.success) {
      if (result.code == 'ACCOUNT_EXISTS') {
        setState(() {
          _isRegisterMode = false;
          _errorText = 'An account with this email already exists. Switched to Sign In mode.';
        });
      } else {
        setState(() { _errorText = result.message; });
      }
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
        context.read<SubscriptionProvider>().fetchStatus(),
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
      body: WeddingPatternBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo area
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.burgundy.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/matrimonyer_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 18),
                    const Text(
                      'Matrimonyer',
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

              if (_infoText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _infoText!,
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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

              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'By continuing, you agree to our ',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                    InkWell(
                      onTap: () => showTermsConditionsModal(context, initialTab: 0),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.burgundy,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.burgundy,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      ' & ',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                    InkWell(
                      onTap: () => showTermsConditionsModal(context, initialTab: 1),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.burgundy,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.burgundy,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          // Mode Selector: Sign In vs Create Account
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_isRegisterMode) {
                        setState(() {
                          _isRegisterMode = false;
                          _errorText = null;
                          _infoText = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isRegisterMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isRegisterMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: !_isRegisterMode ? FontWeight.bold : FontWeight.w500,
                          color: !_isRegisterMode ? AppTheme.burgundy : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!_isRegisterMode) {
                        setState(() {
                          _isRegisterMode = true;
                          _errorText = null;
                          _infoText = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isRegisterMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isRegisterMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _isRegisterMode ? FontWeight.bold : FontWeight.w500,
                          color: _isRegisterMode ? AppTheme.burgundy : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isRegisterMode ? 'Create Your Account' : 'Welcome Back',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _isRegisterMode
                ? 'Enter your email address to register. One normalized email address corresponds to exactly one account.'
                : 'Enter your registered email address to receive your login code.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
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
