import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter your username and password.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await AuthService.instance.signIn(username: username, password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Could not sign in.');
    } catch (e) {
      _showError('Could not sign in: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('Welcome back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Sign in to see your events and past responses.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'e.g. jordan_p')),
            const SizedBox(height: 14),
            const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: '••••••••'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/join-event'),
              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
              label: const Text('Continue as Guest'),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(text: "Don't have an account? "),
                      TextSpan(text: 'Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
