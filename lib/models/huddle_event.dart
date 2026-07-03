import 'package:cloud_firestore/cloud_firestore.dart';

class HuddleEvent {
  HuddleEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.creatorUid,
    required this.eventCode,
    required this.dates,
    required this.startHour,
    required this.endHour,
    required this.slotMinutes,
    this.coverImageUrl,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String creatorUid;
  final String eventCode;
  final List<DateTime> dates;
  final int startHour;
  final int endHour;
  final int slotMinutes;
  final String? coverImageUrl;

  int get slotsPerDay => ((endHour - startHour) * 60) ~/ slotMinutes;

  factory HuddleEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HuddleEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      creatorUid: data['creatorUid'] as String? ?? '',
      eventCode: data['eventCode'] as String? ?? '',
      dates: (data['dates'] as List<dynamic>? ?? [])
          .map((t) => (t as Timestamp).toDate())
          .toList(),
      startHour: data['startHour'] as int? ?? 18,
      endHour: data['endHour'] as int? ?? 23,
      slotMinutes: data['slotMinutes'] as int? ?? 30,
      coverImageUrl: data['coverImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'creatorUid': creatorUid,
      'eventCode': eventCode,
      'dates': dates.map((d) => Timestamp.fromDate(d)).toList(),
      'startHour': startHour,
      'endHour': endHour,
      'slotMinutes': slotMinutes,
      'coverImageUrl': coverImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class Participant {
  Participant({
    required this.id,
    required this.name,
    required this.isGuest,
    this.linkedUid,
    this.photoUrl,
    this.password,
    required this.slots,
    required this.hasResponded,
  });

  final String id;
  final String name;
  final bool isGuest;
  final String? linkedUid;
  final String? photoUrl;
  final String? password;
  final List<String> slots;
  // True once the participant has actually submitted their availability
  // (even if they selected zero slots). False just means they've joined
  // the event but haven't submitted yet -- distinct from "responded free
  // at no times", which still counts as a response.
  final bool hasResponded;

  factory Participant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Participant(
      id: doc.id,
      name: data['name'] as String? ?? '',
      isGuest: data['isGuest'] as bool? ?? true,
      linkedUid: data['linkedUid'] as String?,
      photoUrl: data['photoUrl'] as String?,
      password: data['password'] as String?,
      slots: List<String>.from(data['slots'] as List<dynamic>? ?? []),
      hasResponded: data['hasResponded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isGuest': isGuest,
      'linkedUid': linkedUid,
      'photoUrl': photoUrl,
      'password': password,
      'slots': slots,
      'hasResponded': hasResponded,
      'respondedAt': FieldValue.serverTimestamp(),
    };
  }
}
