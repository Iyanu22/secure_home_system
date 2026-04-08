import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InactivityService {
  // Singleton pattern — one global instance of the service
  static final InactivityService _instance = InactivityService._internal();
  factory InactivityService() => _instance;
  InactivityService._internal();

  Timer? _timer;
  Duration _timeout = const Duration(minutes: 10);

  /// Initialize inactivity trackingc
  void initialize({Duration? timeout}) {
    _timeout = timeout ?? _timeout;
    _startTimer();
  }

  /// Reset or restart the inactivity timer whenever user interacts
  void userActivityDetected() {
    _resetTimer();
  }

  /// Start the inactivity timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, _handleInactivity);
  }

  /// Reset timer on activity
  void _resetTimer() {
    _timer?.cancel();
    _startTimer();
  }

  /// Action taken after inactivity timeout
  Future<void> _handleInactivity() async {
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint("🔒 User signed out due to inactivity.");
    } catch (e) {
      debugPrint("⚠️ Inactivity sign-out error: $e");
    }
  }

  /// Dispose timer when not needed
  void dispose() {
    _timer?.cancel();
  }
}
