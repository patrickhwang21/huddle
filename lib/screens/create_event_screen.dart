import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final List<DateTime> _dates = [];
  int _startHour = 18;
  int _endHour = 23;
  int _durationIndex = 1; // 15 / 30 / 60 min
  File? _cover;
  bool _submitting = false;

  static const _durations = [15, 30, 60];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _cover = File(picked.path));
  }

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

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickHour({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (isStart ? _startHour : _endHour) % 24, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startHour = picked.hour;
        } else {
          // An end time that's at or before the start time (e.g. start 7 PM,
          // end 12 AM) means it rolls past midnight into the next day.
          _endHour = picked.hour <= _startHour ? picked.hour + 24 : picked.hour;
        }
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Give your event a title.');
      return;
    }
    if (_dates.isEmpty) {
      _showError('Add at least one candidate date.');
      return;
    }
    if (_endHour <= _startHour) {
      _showError('End time must be after start time.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      final eventId = await FirestoreService.instance.createEvent(
        title: title,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        dates: _dates,
        startHour: _startHour,
        endHour: _endHour,
        slotMinutes: _durations[_durationIndex],
        creatorUid: uid,
      );

      if (_cover != null) {
        final url = await StorageService.instance.uploadEventCover(eventId, _cover!);
        await FirestoreService.instance.updateEventCoverImage(eventId, url);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/availability', arguments: eventId);
    } catch (e) {
      _showError('Could not create event: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatHour(int hour) {
    final normalized = hour % 24;
    final period = normalized >= 12 ? 'PM' : 'AM';
    final h = normalized % 12 == 0 ? 12 : normalized % 12;
    return '$h:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('New Event'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Cover Image'),
            GestureDetector(
              onTap: _pickCover,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 130,
                      width: double.infinity,
                      color: const Color(0xFFF3F4F6),
                      child: _cover != null
                          ? Image.file(_cover!, height: 130, width: double.infinity, fit: BoxFit.cover)
                          : null,
                    ),
                    if (_cover != null) Container(color: Colors.black.withValues(alpha: 0.25)),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.textSecondary, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _Label('Event Title'),
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Friday Game Night')),
            const SizedBox(height: 16),
            const _Label('Description'),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Board games + pizza, bring a controller!'),
            ),
            const SizedBox(height: 16),
            const _Label('Location'),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined, size: 18), hintText: "Jordan's Apartment"),
            ),
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
            const SizedBox(height: 18),
            const _Label('Time Window'),
            Row(
              children: [
                Expanded(child: _TimeBox(label: 'Start', value: _formatHour(_startHour), onTap: () => _pickHour(isStart: true))),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeBox(
                    label: 'End',
                    value: _endHour >= 24 ? '${_formatHour(_endHour)} (next day)' : _formatHour(_endHour),
                    onTap: () => _pickHour(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < _durations.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _durationChip('${_durations[i]} min', i),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Event & Get Code'),
          ),
        ),
      ),
    );
  }

  Widget _durationChip(String label, int index) {
    final selected = _durationIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationIndex = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
        ),
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

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              ),
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      );
}
