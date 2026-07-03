import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  File? _photo;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('Please fill in a username and password.');
      return;
    }
    if (password != _confirmController.text) {
      _showError('Passwords don\'t match.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await AuthService.instance.signUp(username: username, password: password);
      final uid = AuthService.instance.currentUser!.uid;
      if (_photo != null) {
        final url = await StorageService.instance.uploadProfilePhoto(uid, _photo!);
        await AuthService.instance.updateProfilePhoto(uid, url);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Could not create account.');
    } catch (e) {
      _showError('Could not create account: $e');
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
            const Text('Create your account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Track your events and see your response history anytime.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                            image: _photo != null
                                ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _photo == null
                              ? const Icon(Icons.person_rounded, size: 48, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add a profile picture', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Username'),
            TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'e.g. jordan_p')),
            const SizedBox(height: 14),
            const _FieldLabel('Password'),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: '••••••••'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Confirm Password'),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(hintText: '••••••••'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/signin'),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
    );
  }
}
