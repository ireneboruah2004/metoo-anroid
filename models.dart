/// Normalises an Indian mobile number to +91XXXXXXXXXX where possible.
String normalizePhone(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.startsWith('+')) return cleaned;
  if (cleaned.length == 10) return '+91$cleaned';
  if (cleaned.length == 11 && cleaned.startsWith('0')) {
    return '+91${cleaned.substring(1)}';
  }
  if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
  return cleaned;
}

bool isValidPhone(String normalized) =>
    RegExp(r'^\+?[0-9]{10,14}$').hasMatch(normalized);

class Contact {
  final String name;
  final String phone;
  const Contact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory Contact.fromJson(Map<String, dynamic> j) =>
      Contact(name: j['name'] as String, phone: j['phone'] as String);
}

class Complaint {
  final String id;
  final DateTime createdAt;
  final String when;
  final String place;
  final String details;
  final String accused;
  final String contactPhone;

  const Complaint({
    required this.id,
    required this.createdAt,
    required this.when,
    required this.place,
    required this.details,
    required this.accused,
    required this.contactPhone,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'when': when,
        'place': place,
        'details': details,
        'accused': accused,
        'contactPhone': contactPhone,
      };

  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        when: (j['when'] ?? '') as String,
        place: (j['place'] ?? '') as String,
        details: (j['details'] ?? '') as String,
        accused: (j['accused'] ?? '') as String,
        contactPhone: (j['contactPhone'] ?? '') as String,
      );

  String get savedOn {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${createdAt.year}-${two(createdAt.month)}-${two(createdAt.day)} '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }

  String toShareText() {
    final lines = <String>[
      'Complaint record (MeToo)',
      'Saved on: $savedOn',
      'When it happened: ${when.isEmpty ? 'not stated' : when}',
      'Place: ${place.isEmpty ? 'not stated' : place}',
      'What happened: $details',
      'Person(s) involved: ${accused.isEmpty ? 'not stated' : accused}',
      'Contact number: ${contactPhone.isEmpty ? 'not given' : contactPhone}',
    ];
    return lines.join('\n');
  }
}
