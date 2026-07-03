import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/huddle_event.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/invite_sheet.dart';

/// The core screen: an interactive grid where a participant marks which
/// half-hour blocks they're free for each candidate date. Supports both
/// a single tap (toggle one cell) and drag-across (paint several cells at
/// once), matching the When2meet-style interaction the app is modeled on.
class AvailabilityGridScreen extends StatefulWidget {
  const AvailabilityGridScreen({super.key});

  @override
  State<AvailabilityGridScreen> createState() => _AvailabilityGridScreenState();
}

class _AvailabilityGridScreenState extends State<AvailabilityGridScreen> {
  static const _cellHeight = 26.0;
  static const _labelColWidth = 40.0;

  bool _initialized = false;
  late String _eventId;
  String? _participantId;
  String _participantName = '';
  String? _photoUrl;
  bool _isGuest = false;

  final Set<String> _selected = {};
  bool _dragSelecting = true;
  final Set<String> _dragTouched = {};
  bool _loadingParticipant = true;
  bool _saving = false;

  final ScrollController _scrollController = ScrollController();
  final Map<int, Offset> _activePointers = {};
  bool _gridDragActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      _eventId = args['eventId'] as String;
      _participantId = args['participantId'] as String?;
      _participantName = args['name'] as String? ?? '';
      _isGuest = true;
      _loadingParticipant = false;
    } else {
      _eventId = args as String;
      _isGuest = false;
      _loadExistingRegisteredParticipant();
    }
  }

  Future<void> _loadExistingRegisteredParticipant() async {
    final uid = AuthService.instance.currentUser!.uid;
    final profile = await AuthService.instance.currentUserProfile();
    _participantName = profile?['username'] as String? ?? '';
    _photoUrl = profile?['photoUrl'] as String?;
    final existing = await FirestoreService.instance.findParticipantForUser(_eventId, uid);
    if (existing != null) {
      _participantId = existing.id;
      _selected.addAll(existing.slots);
    }
    if (mounted) setState(() => _loadingParticipant = false);
  }

  String _key(int col, int row) => '$col-$row';

  /// [localPos] is relative to the cell area only (the label column is a
  /// separate widget, not included in this coordinate space).
  void _handlePointer(Offset localPos, double cellAreaWidth, int dateCount, int rowCount, {required bool isStart}) {
    final colWidth = cellAreaWidth / dateCount;
    final col = (localPos.dx / colWidth).floor().clamp(0, dateCount - 1);
    final row = (localPos.dy / _cellHeight).floor().clamp(0, rowCount - 1);
    final k = _key(col, row);
    if (_dragTouched.contains(k)) return;
    _dragTouched.add(k);
    if (isStart) {
      _dragSelecting = !_selected.contains(k);
    }
    setState(() {
      if (_dragSelecting) {
        _selected.add(k);
      } else {
        _selected.remove(k);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _hourLabels(HuddleEvent event) {
    return [for (var h = event.startHour; h < event.endHour; h++) _formatHour(h)];
  }

  String _formatHour(int hour) {
    final normalized = hour % 24;
    final period = normalized >= 12 ? 'PM' : 'AM';
    final h = normalized % 12 == 0 ? 12 : normalized % 12;
    return '$h $period';
  }

  Future<void> _save(HuddleEvent event) async {
    setState(() => _saving = true);
    try {
      final uid = _isGuest ? null : AuthService.instance.currentUser!.uid;
      final id = await FirestoreService.instance.upsertParticipant(
        eventId: _eventId,
        participantId: _participantId,
        name: _participantName,
        isGuest: _isGuest,
        linkedUid: uid,
        photoUrl: _photoUrl,
        slots: _selected.toList(),
      );
      _participantId = id;
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/results', arguments: _eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: StreamBuilder<HuddleEvent>(
          stream: FirestoreService.instance.watchEvent(_eventId),
          builder: (context, snap) => Text(snap.data?.title ?? '', style: const TextStyle(fontSize: 15)),
        ),
        actions: [
          StreamBuilder<HuddleEvent>(
            stream: FirestoreService.instance.watchEvent(_eventId),
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
      body: _loadingParticipant
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<HuddleEvent>(
              stream: FirestoreService.instance.watchEvent(_eventId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final event = snapshot.data!;
                final dates = [...event.dates]..sort();
                final rowCount = event.slotsPerDay;
                final hourLabels = _hourLabels(event);
                final rowsPerHour = rowCount ~/ hourLabels.length.clamp(1, rowCount);

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: _gridDragActive ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(event.location.isEmpty ? 'No location set' : event.location,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('When are you free?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 12),
                            if (dates.isEmpty)
                              const Text('This event has no candidate dates yet.', style: TextStyle(color: AppColors.textMuted))
                            else ...[
                              Row(
                                children: [
                                  const SizedBox(width: _labelColWidth),
                                  for (final d in dates)
                                    Expanded(
                                      child: Text(DateFormat('EEE M/d').format(d),
                                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cellAreaWidth = constraints.maxWidth - _labelColWidth;
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFF0F0F3)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    // The hour-label column is deliberately left outside the
                                    // Listener below, so dragging on the labels (an area with
                                    // no time blocks) scrolls the page normally instead of
                                    // fighting the selection gesture - this is the fix for
                                    // "large time window makes selecting hard to do".
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            for (var row = 0; row < rowCount; row++)
                                              SizedBox(
                                                width: _labelColWidth,
                                                height: _cellHeight,
                                                child: rowsPerHour > 0 && row % rowsPerHour == 0 && row ~/ rowsPerHour < hourLabels.length
                                                    ? Transform.translate(
                                                        offset: const Offset(0, -7),
                                                        child: Text(hourLabels[row ~/ rowsPerHour],
                                                            textAlign: TextAlign.right,
                                                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                                      )
                                                    : null,
                                              ),
                                          ],
                                        ),
                                        Expanded(
                                          child: Listener(
                                            behavior: HitTestBehavior.opaque,
                                            onPointerDown: (event) {
                                              _activePointers[event.pointer] = event.position;
                                              setState(() => _gridDragActive = true);
                                              // Only the first finger paints cells; a second
                                              // finger switches to two-finger scroll instead.
                                              if (_activePointers.length == 1) {
                                                _dragTouched.clear();
                                                _handlePointer(event.localPosition, cellAreaWidth, dates.length, rowCount, isStart: true);
                                              }
                                            },
                                            onPointerMove: (event) {
                                              if (_activePointers.length >= 2) {
                                                final previous = _activePointers[event.pointer];
                                                _activePointers[event.pointer] = event.position;
                                                if (previous != null && _scrollController.hasClients) {
                                                  final dy = event.position.dy - previous.dy;
                                                  final position = _scrollController.position;
                                                  final newOffset =
                                                      (position.pixels - dy).clamp(position.minScrollExtent, position.maxScrollExtent);
                                                  _scrollController.jumpTo(newOffset);
                                                }
                                              } else if (_activePointers.length == 1) {
                                                _activePointers[event.pointer] = event.position;
                                                _handlePointer(event.localPosition, cellAreaWidth, dates.length, rowCount, isStart: false);
                                              }
                                            },
                                            onPointerUp: (event) {
                                              _activePointers.remove(event.pointer);
                                              _dragTouched.clear();
                                              if (_activePointers.isEmpty) setState(() => _gridDragActive = false);
                                            },
                                            onPointerCancel: (event) {
                                              _activePointers.remove(event.pointer);
                                              _dragTouched.clear();
                                              if (_activePointers.isEmpty) setState(() => _gridDragActive = false);
                                            },
                                            child: Column(
                                              children: [
                                                for (var row = 0; row < rowCount; row++)
                                                  Row(
                                                    children: [
                                                      for (var col = 0; col < dates.length; col++)
                                                        Expanded(
                                                          child: Container(
                                                            height: _cellHeight,
                                                            decoration: BoxDecoration(
                                                              color: _selected.contains(_key(col, row)) ? AppColors.primary : Colors.white,
                                                              border: Border.all(color: const Color(0xFFF0F0F3), width: 1),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
                                const SizedBox(width: 6),
                                const Text("You're free", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(width: 16),
                                Container(width: 12, height: 12, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(3))),
                                const SizedBox(width: 6),
                                const Text('Not free', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Icon(Icons.touch_app_outlined, size: 13, color: AppColors.textMuted),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text('Tap a cell, or drag across several to select',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              const Expanded(child: Text('Tap Save when you\'re done', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
              StreamBuilder<HuddleEvent>(
                stream: FirestoreService.instance.watchEvent(_eventId),
                builder: (context, snapshot) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 22)),
                    onPressed: (_saving || !snapshot.hasData) ? null : () => _save(snapshot.data!),
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Availability'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
