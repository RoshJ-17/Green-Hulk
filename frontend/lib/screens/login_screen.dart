import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _step = 1; // 1 = Phone input, 2 = OTP input
  
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoadingStep1 = false;
  bool _isLoadingStep2 = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();
  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingStep1 = true);

    final result = await AuthService.sendOtp(_phone);

    if (!mounted) return;
    setState(() => _isLoadingStep1 = false);

    if (result != null) {
      setState(() => _step = 2);

      // If backend returned the OTP directly (demo mode), show it in a dialog
      if (result != 'sent' && result != 'mock' && result.length == 6) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('📱 Your OTP'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SMS delivery is in demo mode. Use this OTP:'),
                const SizedBox(height: 12),
                Text(
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
            content: Text('OTP sent to $_phone'),
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

  Future<void> _verifyAndLogin() async {
    if (_enteredOtp.length < 6) return;
    setState(() => _isLoadingStep2 = true);

    final result = await AuthService.verifyOtp(_phone, _enteredOtp);

    if (!mounted) return;
    setState(() => _isLoadingStep2 = false);

    if (result != null && result['accessToken'] != null) {
      context.read<AppState>().setLoggedIn(true);
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoadingStep2 = true);
    await AuthService.sendOtp(_phone);
    if (!mounted) return;
    setState(() => _isLoadingStep2 = false);
    for (final c in _otpControllers) c.clear();
    _otpFocusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent!'), backgroundColor: AppTheme.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _step == 1 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          // App Icon + Title
          Center(
            child: Column(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 15, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/app_icon.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.agriculture, size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('CropCare',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const SizedBox(height: 4),
                const Text('Diagnose crop diseases with AI',
                    style: TextStyle(fontSize: 15, color: AppTheme.accentGreen)),
              ],
            ),
          ),

          const SizedBox(height: 52),

          Text(context.read<AppState>().tr('welcome_back'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          const SizedBox(height: 4),
          Text(context.read<AppState>().tr('login_to_continue'),
              style: const TextStyle(fontSize: 15, color: AppTheme.accentGreen)),
          const SizedBox(height: 28),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your mobile number';
              if (v.trim().length != 10) return 'Enter a valid 10-digit number';
              return null;
            },
            decoration: InputDecoration(
              labelText: context.read<AppState>().tr('mobile_number'),
              prefixText: '+91  ',
              prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.accentGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightGreen.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentGreen, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: _isLoadingStep1 ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isLoadingStep1
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_outlined),
            label: const Text('Send OTP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: AppTheme.accentGreen, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.person_outline, color: AppTheme.accentGreen),
            label: Text(context.read<AppState>().tr('continue_as_guest'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? ",
                  style: TextStyle(fontSize: 15, color: AppTheme.accentGreen)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: Text(context.read<AppState>().tr('create_account'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 UI (OTP)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),

        IconButton(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGreen, size: 28),
          onPressed: () => setState(() => _step = 1),
        ),

        const SizedBox(height: 24),

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

        const SizedBox(height: 36),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),

        const SizedBox(height: 36),

        // Verify Button
        ElevatedButton(
          onPressed: _isLoadingStep2 ? null : _verifyAndLogin,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoadingStep2
              ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Verify & Login',
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
            _verifyAndLogin();
          }
        },
      ),
    );
  }
}
