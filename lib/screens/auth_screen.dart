import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  bool _isOTPSent = false;
  bool _isLoading = false;
  final _otpController = TextEditingController();

  void _sendOTP() async {
    setState(() { _isLoading = true; });
    try {
      await context.read<AuthProvider>().sendOTP(_phoneController.text);
      if (mounted) setState(() { _isOTPSent = true; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending OTP: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _verifyOTP() async {
    setState(() { _isLoading = true; });
    try {
      await context.read<AuthProvider>().verifyOTP(
            _phoneController.text,
            _otpController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP or verification failed.')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          color: AppTheme.backgroundDark,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              // Brand Mark
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Mise',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium Chef Meals Delivered.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              
              if (!_isOTPSent) ...[
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_android),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      debugPrint("DEBUG: Get OTP button pressed");
                      if (_phoneController.text.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid phone number')),
                        );
                        return;
                      }
                      _sendOTP();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Get OTP'),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    debugPrint("DEBUG: Triggering Bypass Auth");
                    await context.read<AuthProvider>().devBypassLogin('+919666350033');
                  },
                  child: const Center(child: Text('DEV: Bypass Auth (Admin)', style: TextStyle(color: Colors.red))),
                ),
              ] else ...[
                Text(
                  'Verify Phone',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 4-digit code sent to ${_phoneController.text}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '0000',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyOTP,
                  child: const Text('Verify & Continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    // Logic to bypass and set a mock session/user
                    // For now, we'll just try to trigger a sync with a specific test ID if possible,
                    // but usually we need a real session. 
                    // Let's just mock the login by using the admin number in the controller.
                    _phoneController.text = '9666350033';
                    _otpController.text = '123456'; 
                    _verifyOTP();
                  },
                  child: const Center(child: Text('DEV: Bypass Auth (Admin)', style: TextStyle(color: Colors.red))),
                ),
                TextButton(
                  onPressed: () => setState(() => _isOTPSent = false),
                  child: const Center(child: Text('Change Number')),
                ),
              ],
              
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
