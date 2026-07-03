import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/huddle_event.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _titleController = TextEditingController();
  final List<DateTime> _dates = [];

  bool _initialized = false;
  late String _eventId;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _eventId = ModalRoute.of(context)!.settings.arguments as String;
  }

  void _prefill(HuddleEvent event) {
    if (_titleController.text.isEmpty && _dates.isEmpty) {
      _titleController.text = event.title;
      _dates.addAll(event.dates);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _addDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && !_dates.any((d) => _isSameDay(d, picked))) {
      setState(() => _dates.add(picked));
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Give your event a title.');
      return;
    }
    if (_dates.isEmpty) {
      _showError('Add at least one candidate date.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.updateEventDetails(eventId: _eventId, title: title, dates: _dates);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Event'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<HuddleEvent>(
        stream: FirestoreService.instance.watchEvent(_eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          _prefill(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Event Title'),
                TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Friday Game Night')),
                const SizedBox(height: 18),
                const _Label('Candidate Dates'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in _dates)
                      GestureDetector(
                        onTap: () => setState(() => _dates.remove(d)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(DateFormat('EEE, MMM d').format(d),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _addDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: AppColors.textMuted),
                            SizedBox(width: 4),
                            Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
      );
}
