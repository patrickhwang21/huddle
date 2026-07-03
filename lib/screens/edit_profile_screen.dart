import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _existingPhotoUrl;
  File? _newPhoto;
  bool _loading = true;
  bool _saving = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.currentUserProfile();
    _usernameController.text = profile?['username'] as String? ?? '';
    _existingPhotoUrl = profile?['photoUrl'] as String?;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showError('Username can\'t be empty.');
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      await AuthService.instance.updateUsername(uid, username);
      if (_newPhoto != null) {
        final url = await StorageService.instance.uploadProfilePhoto(uid, _newPhoto!);
        await AuthService.instance.updateProfilePhoto(uid, url);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || next.isEmpty) {
      _showError('Fill in both password fields.');
      return;
    }
    if (next.length < 6) {
      _showError('New password must be at least 6 characters.');
      return;
    }
    if (next != confirm) {
      _showError('New passwords don\'t match.');
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await AuthService.instance.changePassword(currentPassword: current, newPassword: next);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Current password is incorrect.',
        'weak-password' => 'New password is too weak.',
        _ => 'Could not update password: ${e.message}',
      };
      _showError(message);
    } catch (e) {
      _showError('Could not update password: $e');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                              image: _newPhoto != null
                                  ? DecorationImage(image: FileImage(_newPhoto!), fit: BoxFit.cover)
                                  : (_existingPhotoUrl != null
                                      ? DecorationImage(image: NetworkImage(_existingPhotoUrl!), fit: BoxFit.cover)
                                      : null),
                            ),
                            child: (_newPhoto == null && _existingPhotoUrl == null)
                                ? const Icon(Icons.person_rounded, size: 56, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Tap to change photo', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'e.g. jordan_p')),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Change Password',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Enter current password'),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'At least 6 characters'),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Re-enter new password'),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _changingPassword ? null : _changePassword,
                    child: _changingPassword
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Update Password'),
                  ),
                ],
              ),
            ),
    );
  }
}
