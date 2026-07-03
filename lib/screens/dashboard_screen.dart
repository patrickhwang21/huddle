import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../mock_data.dart';
import '../models/huddle_event.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/avatar_stack.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showPast = false;

  bool _isPast(HuddleEvent event) {
    if (event.dates.isEmpty) return false;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final latest = event.dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.isBefore(startOfToday);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('My Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: const CircleAvatar(radius: 20, backgroundColor: Color(0xFFEEF2FF), child: Icon(Icons.person_rounded, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showPast = false),
                    child: _FilterChip(label: 'Upcoming', selected: !_showPast),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showPast = true),
                    child: _FilterChip(label: 'Past', selected: _showPast),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  if (uid == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    StreamBuilder<List<HuddleEvent>>(
                      stream: FirestoreService.instance.watchUserEvents(uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final events = (snapshot.data ?? []).where((e) => _isPast(e) == _showPast).toList();
                        if (events.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_available_outlined, size: 40, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(_showPast ? 'No past events found' : 'No events yet',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _showPast
                                        ? 'Events move here once their dates have passed.'
                                        : 'Create one or join with an event code.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: events.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, i) => _EventCard(event: events[i], currentUid: uid),
                        );
                      },
                    ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: FloatingActionButton(
                      onPressed: () => Navigator.pushNamed(context, '/create-event'),
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.currentUid});

  final HuddleEvent event;
  final String currentUid;

  String get _dateLabel {
    if (event.dates.isEmpty) return 'No dates yet';
    final sorted = [...event.dates]..sort();
    final fmt = DateFormat('MMM d');
    if (sorted.length == 1) return '${fmt.format(sorted.first)} · pick a time';
    return '${fmt.format(sorted.first)}–${fmt.format(sorted.last).split(' ').last} · pick a time';
  }

  Future<void> _showManageSheet(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                title: const Text('Edit event'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('Delete event', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (action == 'edit') {
      Navigator.pushNamed(context, '/edit-event', arguments: event.id);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete this event?'),
          content: Text('"${event.title}" and everyone\'s availability will be permanently deleted. This can\'t be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        try {
          await FirestoreService.instance.deleteEvent(event.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete event: $e')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = event.creatorUid == currentUid;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/availability', arguments: event.id),
        onLongPress: isCreator ? () => _showManageSheet(context) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              event.coverImageUrl ?? MockData.coverGameNight,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(_dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Organizer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder(
                    stream: FirestoreService.instance.watchParticipants(event.id),
                    builder: (context, snapshot) {
                      final participants = snapshot.data ?? [];
                      final avatars = participants
                          .where((p) => p.photoUrl != null)
                          .take(3)
                          .map((p) => p.photoUrl!)
                          .toList();
                      final responded = participants.where((p) => p.hasResponded).length;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AvatarStack(imageUrls: avatars, extraCount: (participants.length - avatars.length).clamp(0, 99)),
                          Text('$responded/${participants.length} responded',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
