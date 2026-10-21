import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';
import 'widget_sync.dart';

/// Everything is stored on the phone only, in the platform keystore/keychain.
class Store {
  static const _storage = FlutterSecureStorage();
  static const _kContacts = 'contacts_v1';
  static const _kComplaints = 'complaints_v1';

  static final ValueNotifier<int> contactCount = ValueNotifier<int>(0);

  static Future<List<Contact>> contacts() async {
    final raw = await _storage.read(key: _kContacts);
    final list = raw == null
        ? <Contact>[]
        : (jsonDecode(raw) as List)
            .map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    contactCount.value = list.length;
    return list;
  }

  static Future<void> saveContacts(List<Contact> items) async {
    await _storage.write(
      key: _kContacts,
      value: jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    contactCount.value = items.length;
    // The home-screen widget keeps its own copy of the numbers.
    await WidgetSync.push(items);
  }

  static Future<List<Complaint>> complaints() async {
    final raw = await _storage.read(key: _kComplaints);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Complaint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> saveComplaints(List<Complaint> items) => _storage.write(
        key: _kComplaints,
        value: jsonEncode(items.map((e) => e.toJson()).toList()),
      );
}
