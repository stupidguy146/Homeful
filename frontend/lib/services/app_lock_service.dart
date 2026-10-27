import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Local-only app lock: a 6-digit PIN (stored hashed) plus optional biometric
/// unlock. Nothing here is sent to the server — it guards access to the app on
/// this device only.
///
/// On web, biometrics are unavailable; the PIN is still supported.
class AppLockService {
  static const _kPinHash = 'app_lock_pin_hash';
  static const _kPinSalt = 'app_lock_pin_salt';
  static const _kBiometric = 'app_lock_biometric_enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  AppLockService({FlutterSecureStorage? storage, LocalAuthentication? localAuth})
      : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Whether a PIN has been configured on this device.
  Future<bool> hasPin() async {
    try {
      final hash = await _storage.read(key: _kPinHash);
      return hash != null && hash.isNotEmpty;
    } catch (_) {
      // secure storage unavailable (e.g. during tests) → treat as no PIN
      return false;
    }
  }

  /// Hash a PIN with a per-device salt (SHA-256). PIN is never stored in clear.
  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Persist a new PIN (overwrites any existing one).
  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: _hash(pin, salt));
  }

  /// Verify an entered PIN against the stored hash.
  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final hash = await _storage.read(key: _kPinHash);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  /// Clear PIN + biometric (e.g. on logout/reset).
  Future<void> clear() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kBiometric);
  }

  Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: _kBiometric)) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBiometric, value: enabled ? 'true' : 'false');
  }

  /// Whether this device can do fingerprint/face auth. Always false on web.
  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Prompt the OS biometric sheet. Returns true on success.
  Future<bool> authenticateBiometric(String reason) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
