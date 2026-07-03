import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: uid == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: AuthService.instance.userProfileStream(uid),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final username = data?['username'] as String? ?? '';
                  final photoUrl = data?['photoUrl'] as String?;
                  final eventIds = List<String>.from(data?['eventIds'] as List<dynamic>? ?? []);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      const Text('Profile',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                      child: photoUrl == null
                                          ? const Icon(Icons.person_rounded, size: 40, color: Colors.white)
                                          : null,
                                    ),
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
                                      child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            Text('@$username', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        margin: EdgeInsets.zero,
                        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance
                              .collection('events')
                              .where('creatorUid', isEqualTo: uid)
                              .get(),
                          builder: (context, createdSnap) {
                            final created = createdSnap.data?.docs.length ?? 0;
                            final joined = (eventIds.length - created).clamp(0, eventIds.length);
                            return Row(
                              children: [
                                _StatColumn(value: '$created', label: 'Created', divider: true),
                                _StatColumn(value: '$joined', label: 'Joined', divider: false),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                              child: const _ProfileRow(icon: Icons.person_outline_rounded, label: 'Edit Profile'),
                            ),
                            const Divider(height: 1),
                            const _ProfileRow(icon: Icons.notifications_none_rounded, label: 'Notifications'),
                            const Divider(height: 1),
                            const _ProfileRow(icon: Icons.help_outline_rounded, label: 'Help & Support', showDivider: false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        margin: EdgeInsets.zero,
                        child: GestureDetector(
                          onTap: () async {
                            await AuthService.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                            }
                          },
                          child: const _ProfileRow(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            color: AppColors.danger,
                            showChevron: false,
                            showDivider: false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label, required this.divider});
  final String value;
  final String label;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: divider
            ? const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFF3F4F6))))
            : null,
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
    this.showChevron = true,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool showChevron;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color == AppColors.danger ? color : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color))),
          if (showChevron) const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }
}
