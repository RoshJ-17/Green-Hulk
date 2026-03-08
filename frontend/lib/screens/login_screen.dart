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
  final _formKey        = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoggingIn     = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoggingIn = true);

    final result = await AuthService.loginWithPhone(phone: _phone);

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (result != null) {
      context.read<AppState>().setLoggedIn(true);
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your number and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  //  App Icon + Title 
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
                    onPressed: _isLoggingIn ? null : _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isLoggingIn
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: Text(context.read<AppState>().tr('login'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            ),
          ),
        ),
      ),
    );
  }
}
