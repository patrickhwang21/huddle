import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 56),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('Huddle',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Find a time that works\nfor everyone — no more group texts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              transform: Matrix4.translationValues(0, -32, 0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/signin'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Sign In'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/join-event'),
                    icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: const Text('Join with Event Code'),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(text: "Don't have an account? "),
                          TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
