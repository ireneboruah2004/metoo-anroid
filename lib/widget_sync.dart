import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

/// Settings for the home-screen SOS widget.
///
/// The widget runs natively and cannot read the encrypted app storage, so the
/// trusted numbers and these settings are copied to a small private file on the
/// phone (done through the `metoo/widget` channel in MainActivity.kt).
class WidgetSync {
  static const _storage = FlutterSecureStorage();
  static const _ch = MethodChannel('metoo/widget');
  static const _kSiren = 'widget_siren_v1';
  static const _kCountdown = 'widget_countdown_v1';
  static const _kDone = 'widget_setup_done_v1';

  static const int defaultCountdown = 5;

  static Future<bool> setupDone() async =>
      (await _storage.read(key: _kDone)) == '1';

  /// Off by default: the person has to switch the siren on herself.
  static Future<bool> sirenEnabled() async =>
      (await _storage.read(key: _kSiren)) == '1';

  static Future<int> countdown() async {
    final n = int.tryParse(await _storage.read(key: _kCountdown) ?? '');
    return math.max(0, math.min(10, n ?? defaultCountdown));
  }

  static Future<void> save({required bool siren, required int countdown}) async {
    await _storage.write(key: _kSiren, value: siren ? '1' : '0');
    await _storage.write(
      key: _kCountdown,
      value: math.max(0, math.min(10, countdown)).toString(),
    );
    await _storage.write(key: _kDone, value: '1');
  }

  /// Copies numbers + settings to the native side. Safe to call any time.
  static Future<void> push(List<Contact> contacts) async {
    try {
      await _ch.invokeMethod('sync', {
        'numbers': contacts.map((c) => c.phone).toList(),
        'siren': await sirenEnabled(),
        'countdown': await countdown(),
      });
    } catch (_) {
      // Not Android, or the channel is missing: nothing to do.
    }
  }

  /// Phone and call-log permission state, as seen by the Android side.
  /// Keys: 'phone' (place calls + see call state), 'calllog' (see if answered).
  static Future<Map<String, bool>> callPerms() async {
    try {
      final m = await _ch.invokeMapMethod<String, bool>('callPerms');
      return {
        'phone': m?['phone'] ?? false,
        'calllog': m?['calllog'] ?? false,
      };
    } catch (_) {
      return {'phone': false, 'calllog': false};
    }
  }

  /// Shows the Android permission dialog for phone and call log.
  static Future<void> requestCallPerms() async {
    try {
      await _ch.invokeMethod('requestCallPerms');
    } catch (_) {}
  }
}
