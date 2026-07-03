import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/huddle_event.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _events => _db.collection('events');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  String _generateEventCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid confusion
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> createEvent({
    required String title,
    required String description,
    required String location,
    required List<DateTime> dates,
    required int startHour,
    required int endHour,
    required int slotMinutes,
    required String creatorUid,
    String? coverImageUrl,
  }) async {
    String code = _generateEventCode();
    while ((await _events.where('eventCode', isEqualTo: code).limit(1).get()).docs.isNotEmpty) {
      code = _generateEventCode();
    }

    final event = HuddleEvent(
      id: '',
      title: title,
      description: description,
      location: location,
      creatorUid: creatorUid,
      eventCode: code,
      dates: dates,
      startHour: startHour,
      endHour: endHour,
      slotMinutes: slotMinutes,
      coverImageUrl: coverImageUrl,
    );

    final docRef = await _events.add(event.toMap());
    await _users.doc(creatorUid).update({
      'eventIds': FieldValue.arrayUnion([docRef.id]),
    });
    return docRef.id;
  }

  Future<void> updateEventCoverImage(String eventId, String url) {
    return _events.doc(eventId).update({'coverImageUrl': url});
  }

  Future<void> updateEventDetails({
    required String eventId,
    required String title,
    required List<DateTime> dates,
  }) {
    return _events.doc(eventId).update({
      'title': title,
      'dates': dates.map((d) => Timestamp.fromDate(d)).toList(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    final eventDoc = await _events.doc(eventId).get();
    if (!eventDoc.exists) return;
    final creatorUid = eventDoc.data()?['creatorUid'] as String?;

    final participantsSnap = await _participants(eventId).get();
    final batch = _db.batch();
    final touchedUids = <String>{};

    for (final doc in participantsSnap.docs) {
      final linkedUid = doc.data()['linkedUid'] as String?;
      if (linkedUid != null && touchedUids.add(linkedUid)) {
        batch.update(_users.doc(linkedUid), {
          'eventIds': FieldValue.arrayRemove([eventId]),
        });
      }
      batch.delete(doc.reference);
    }
    if (creatorUid != null && touchedUids.add(creatorUid)) {
      batch.update(_users.doc(creatorUid), {
        'eventIds': FieldValue.arrayRemove([eventId]),
      });
    }
    batch.delete(_events.doc(eventId));
    await batch.commit();
  }

  Stream<List<HuddleEvent>> watchUserEvents(String uid) {
    return _users.doc(uid).snapshots().asyncExpand((userDoc) {
      final ids = List<String>.from(userDoc.data()?['eventIds'] as List<dynamic>? ?? []);
      if (ids.isEmpty) return Stream.value(<HuddleEvent>[]);
      return _events
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots()
          .map((snap) => snap.docs.map(HuddleEvent.fromDoc).toList());
    });
  }

  Stream<HuddleEvent> watchEvent(String eventId) {
    return _events.doc(eventId).snapshots().map(HuddleEvent.fromDoc);
  }

  Future<HuddleEvent?> findEventByCode(String code) async {
    final snap = await _events
        .where('eventCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return HuddleEvent.fromDoc(snap.docs.first);
  }

  CollectionReference<Map<String, dynamic>> _participants(String eventId) =>
      _events.doc(eventId).collection('participants');

  Stream<List<Participant>> watchParticipants(String eventId) {
    return _participants(eventId).snapshots().map(
          (snap) => snap.docs.map(Participant.fromDoc).toList(),
        );
  }

  Future<Participant?> findParticipantForUser(String eventId, String uid) async {
    final snap = await _participants(eventId).where('linkedUid', isEqualTo: uid).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return Participant.fromDoc(snap.docs.first);
  }

  Future<String> upsertParticipant({
    required String eventId,
    String? participantId,
    required String name,
    required bool isGuest,
    String? linkedUid,
    String? photoUrl,
    String? password,
    required List<String> slots,
    bool hasResponded = true,
  }) async {
    final participant = Participant(
      id: participantId ?? '',
      name: name,
      isGuest: isGuest,
      linkedUid: linkedUid,
      photoUrl: photoUrl,
      password: password,
      slots: slots,
      hasResponded: hasResponded,
    );

    if (participantId != null) {
      await _participants(eventId).doc(participantId).set(participant.toMap(), SetOptions(merge: true));
      return participantId;
    }
    final docRef = await _participants(eventId).add(participant.toMap());
    if (linkedUid != null) {
      await _users.doc(linkedUid).update({
        'eventIds': FieldValue.arrayUnion([eventId]),
      });
    }
    return docRef.id;
  }

  Future<Participant?> guestLogin({
    required String eventId,
    required String name,
    required String password,
  }) async {
    final existing = await _participants(eventId)
        .where('name', isEqualTo: name.trim())
        .where('isGuest', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return Participant.fromDoc(existing.docs.first);
    }

    final id = await upsertParticipant(
      eventId: eventId,
      name: name.trim(),
      isGuest: true,
      password: password.isEmpty ? null : password,
      slots: [],
      hasResponded: false,
    );
    final doc = await _participants(eventId).doc(id).get();
    return Participant.fromDoc(doc);
  }
}
