import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/huddle_event.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/invite_sheet.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static const _levelColors = [Color(0xFFF3F4F6), Color(0xFFC7D2FE), Color(0xFF818CF8), Color(0xFF4F46E5), Color(0xFF3730A3)];

  String _formatHour(int hour) {
    final normalized = hour % 24;
    final period = normalized >= 12 ? 'PM' : 'AM';
    final h = normalized % 12 == 0 ? 12 : normalized % 12;
    return '$h $period';
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Results'),
        actions: [
          StreamBuilder<HuddleEvent>(
            stream: FirestoreService.instance.watchEvent(eventId),
            builder: (context, snap) {
              final event = snap.data;
              return IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Invite',
                onPressed: event == null ? null : () => showInviteSheet(context, event),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<HuddleEvent>(
        stream: FirestoreService.instance.watchEvent(eventId),
        builder: (context, eventSnap) {
          if (!eventSnap.hasData) return const Center(child: CircularProgressIndicator());
          final event = eventSnap.data!;
          final dates = [...event.dates]..sort();
          final rowCount = event.slotsPerDay;
          final hourLabels = [for (var h = event.startHour; h < event.endHour; h++) _formatHour(h)];
          final rowsPerHour = rowCount ~/ hourLabels.length.clamp(1, rowCount);

          return StreamBuilder(
            stream: FirestoreService.instance.watchParticipants(eventId),
            builder: (context, participantsSnap) {
              final participants = participantsSnap.data ?? [];
              final total = participants.length;

              final counts = <String, int>{};
              for (final p in participants) {
                for (final slot in p.slots) {
                  counts[slot] = (counts[slot] ?? 0) + 1;
                }
              }
              String? bestKey;
              var bestCount = 0;
              counts.forEach((key, count) {
                if (count > bestCount) {
                  bestCount = count;
                  bestKey = key;
                }
              });

              String? bestLabel;
              if (bestKey != null && dates.isNotEmpty) {
                final parts = bestKey!.split('-');
                final col = int.parse(parts[0]);
                final row = int.parse(parts[1]);
                if (col < dates.length) {
                  final startMinutes = event.startHour * 60 + row * event.slotMinutes;
                  final endMinutes = startMinutes + event.slotMinutes;
                  final start = TimeOfDay(hour: (startMinutes ~/ 60) % 24, minute: startMinutes % 60);
                  final end = TimeOfDay(hour: (endMinutes ~/ 60) % 24, minute: endMinutes % 60);
                  final crossesMidnight = startMinutes >= 24 * 60;
                  bestLabel =
                      '${DateFormat('EEE, MMM d').format(dates[col])} · ${start.format(context)}–${end.format(context)}'
                      '${crossesMidnight ? ' (next day)' : ''}';
                }
              }

              final responded = participants.where((p) => p.hasResponded).toList();
              final notResponded = participants.where((p) => !p.hasResponded).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (bestKey != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Text('BEST TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857), letterSpacing: 0.5)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(bestLabel ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AvatarStack(
                                imageUrls: participants.where((p) => p.photoUrl != null).take(3).map((p) => p.photoUrl!).toList(),
                              ),
                              Text('$bestCount of $total free', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(18)),
                      child: const Text('No one has marked their availability yet.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  const SizedBox(height: 20),
                  if (dates.isNotEmpty) ...[
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        for (final d in dates)
                          Expanded(child: Text(DateFormat('EEE M/d').format(d), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF0F0F3))),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var row = 0; row < rowCount; row++)
                            Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 24,
                                  child: rowsPerHour > 0 && row % rowsPerHour == 0 && row ~/ rowsPerHour < hourLabels.length
                                      ? Transform.translate(
                                          offset: const Offset(0, -6),
                                          child: Text(hourLabels[row ~/ rowsPerHour], textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        )
                                      : null,
                                ),
                                for (var col = 0; col < dates.length; col++)
                                  Expanded(
                                    child: Builder(builder: (context) {
                                      final key = '$col-$row';
                                      final count = counts[key] ?? 0;
                                      final level = total == 0 ? 0 : ((count / total) * 4).ceil().clamp(0, 4);
                                      final isBest = key == bestKey;
                                      return Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _levelColors[level],
                                          border: Border.all(color: isBest ? AppColors.success : Colors.white, width: isBest ? 2 : 1),
                                        ),
                                      );
                                    }),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Fewer free', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        for (final c in _levelColors) Container(width: 16, height: 12, margin: const EdgeInsets.only(right: 2), color: c),
                        const SizedBox(width: 4),
                        const Text('More free', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 22),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Who's in", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (notResponded.isNotEmpty)
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Reminders are coming in a future update.'))),
                          child: Text('Remind All (${notResponded.length})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final p in responded)
                    _ParticipantRow(name: p.name, isGuest: p.isGuest, photoUrl: p.photoUrl, responded: true),
                  for (final p in notResponded)
                    _ParticipantRow(name: p.name, isGuest: p.isGuest, photoUrl: p.photoUrl, responded: false),
                  if (participants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No one has joined this event yet.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.name, required this.isGuest, required this.photoUrl, required this.responded});
  final String name;
  final bool isGuest;
  final String? photoUrl;
  final bool responded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Opacity(
            opacity: responded ? 1 : 0.5,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null ? const Icon(Icons.person_rounded, size: 18, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: responded ? AppColors.textPrimary : AppColors.textMuted),
                children: [
                  TextSpan(text: name),
                  if (isGuest) const TextSpan(text: ' (guest)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ),
          if (responded)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
            )
          else
            GestureDetector(
              onTap: () =>
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminders are coming in a future update.'))),
              child: const Text('Remind', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}
