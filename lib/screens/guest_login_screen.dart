import 'package:flutter/material.dart';

import '../mock_data.dart';
import '../models/huddle_event.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class GuestLoginScreen extends StatefulWidget {
  const GuestLoginScreen({super.key});

  @override
  State<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends State<GuestLoginScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(String eventId) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your name to continue.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final participant = await FirestoreService.instance.guestLogin(
        eventId: eventId,
        name: name,
        password: _passwordController.text,
      );
      if (!mounted || participant == null) return;
      Navigator.pushNamed(context, '/availability', arguments: {
        'eventId': eventId,
        'participantId': participant.id,
        'name': participant.name,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not join: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<HuddleEvent>(
              stream: FirestoreService.instance.watchEvent(eventId),
              builder: (context, snapshot) {
                final event = snapshot.data;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Image.network(event?.coverImageUrl ?? MockData.coverGameNight, width: 64, height: 64, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event?.title ?? 'Loading…', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('${event?.dates.length ?? 0} dates proposed',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Join as a guest',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Just this event — no full account needed.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            const Text('Your Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Sam')),
            const SizedBox(height: 14),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                children: [
                  TextSpan(text: 'Password '),
                  TextSpan(text: '(optional)', style: TextStyle(fontWeight: FontWeight.normal, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Leave blank to skip'),
            ),
            const SizedBox(height: 6),
            const Text('Add one if you want to update your response from another device later.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : () => _submit(eventId),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
            ),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signin'),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(text: 'Have an account? '),
                      TextSpan(text: 'Sign in instead', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
