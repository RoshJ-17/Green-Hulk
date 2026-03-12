// lib/screens/signup_screen.dart
//
// Multi-step registration:
//   Step 1 → Name + Phone + optional Email + Password
//   Step 2 → OTP verification (6-digit code sent to phone)
//   On success → navigate to /main

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ── Step tracking ─────────────────────────────────────────────────────────
  int _step = 1; // 1 = details, 2 = OTP

  // ── Step 1 controllers ────────────────────────────────────────────────────
  final _step1Key              = GlobalKey<FormState>();
  final _nameController        = TextEditingController();
  final _phoneController       = TextEditingController();
  final _emailController       = TextEditingController();  // optional

  bool  _isLoadingStep1        = false;

  // ── Step 2 controllers ────────────────────────────────────────────────────
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _isLoadingStep2 = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Step 1 — send OTP
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _sendOtp() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() => _isLoadingStep1 = true);

    final result = await AuthService.sendOtp(_phoneController.text.trim());

    if (!mounted) return;
    setState(() => _isLoadingStep1 = false);

    if (result != null) {
      setState(() => _step = 2);

      if (result != 'sent' && result != 'mock' && result.length == 6) {
        // Auto-copy OTP to clipboard for convenience
        await Clipboard.setData(ClipboardData(text: result));

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('📱 Your OTP Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Here is your OTP to complete verification.\n(It has been copied to your clipboard!)',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  result,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_phoneController.text.trim()}'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Step 2 — verify OTP + register
  // ═════════════════════════════════════════════════════════════════════════

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyAndRegister() async {
    if (_enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoadingStep2 = true);

    // Register — OTP is verified server-side via POST /auth/register
    final result = await AuthService.registerWithPhone(
      fullName: _nameController.text.trim(),
      phone:    _phoneController.text.trim(),
      otp:      _enteredOtp,
      email:    _emailController.text.trim().isEmpty
                    ? null
                    : _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoadingStep2 = false);

    if (result != null) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. OTP may be incorrect or number already registered.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoadingStep2 = true);
    await AuthService.sendOtp(_phoneController.text.trim());
    if (!mounted) return;
    setState(() => _isLoadingStep2 = false);
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 1 ? 'Create Account' : 'Verify Phone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 1 ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1 UI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // Header
          const Text(
            'Join CropCare',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your details to get started',
            style: TextStyle(fontSize: 15, color: AppTheme.accentGreen),
          ),

          const SizedBox(height: 28),

          // Progress indicator
          _buildStepIndicator(),

          const SizedBox(height: 28),

          // Full Name
          _buildField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your name';
              if (v.trim().length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Phone Number
          _buildField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
              if (v.trim().length < 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email (Optional)
          _buildField(
            controller: _emailController,
            label: 'Email (Optional)',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Enter a valid email address';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 30),

          // Send OTP Button
          ElevatedButton(
            onPressed: _isLoadingStep1 ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoadingStep1
                ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_outlined),
                      SizedBox(width: 8),
                      Text('Send OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          // Already have account
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ',
                  style: TextStyle(fontSize: 15, color: AppTheme.accentGreen)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Login',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 UI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),

        // Header
        const Text(
          'Verify Phone',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the 6-digit code sent to ${_phoneController.text.trim()}',
          style: const TextStyle(fontSize: 15, color: AppTheme.accentGreen),
        ),

        const SizedBox(height: 28),

        _buildStepIndicator(),

        const SizedBox(height: 36),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),

        const SizedBox(height: 36),

        // Verify Button
        ElevatedButton(
          onPressed: _isLoadingStep2 ? null : _verifyAndRegister,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoadingStep2
              ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Verify & Create Account',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 16),

        // Resend
        Center(
          child: TextButton(
            onPressed: _isLoadingStep2 ? null : _resendOtp,
            child: const Text("Didn't receive the code? Resend OTP",
                style: TextStyle(color: AppTheme.accentGreen, fontSize: 14)),
          ),
        ),

        const SizedBox(height: 12),

        // Back to step 1
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _step = 1),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppTheme.primaryGreen),
            label: const Text('Change details',
                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'Details'),
        Expanded(
          child: Container(
            height: 2,
            color: _step == 2 ? AppTheme.primaryGreen : AppTheme.lightGreen,
          ),
        ),
        _stepDot(2, 'Verify'),
      ],
    );
  }

  Widget _stepDot(int n, String label) {
    final active = _step >= n;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '$n',
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppTheme.primaryGreen : Colors.grey,
            )),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 58,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.lightGreen.withValues(alpha: 0.6), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          // Auto-verify when all 6 digits entered
          if (_enteredOtp.length == 6) {
            _verifyAndRegister();
          }
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.accentGreen),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.lightGreen.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accentGreen, width: 2),
      ),
    );
  }
}
