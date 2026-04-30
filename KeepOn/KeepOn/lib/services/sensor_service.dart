import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService extends ChangeNotifier {
  static const _stationaryThreshold = 0.35;
  static const _stationaryWindow = Duration(minutes: 10);

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _stationarySince;
  bool _isStationary = false;

  bool get isStationary => _isStationary;

  double get reminderFrequencyMultiplier => _isStationary ? 2 : 1;

  void start() {
    _subscription ??= accelerometerEventStream().listen(
      _handleAccelerometer,
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    final movement = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final now = DateTime.now();
    final looksStill = (movement - 9.8).abs() < _stationaryThreshold;

    if (looksStill) {
      _stationarySince ??= now;
      final stationary = now.difference(_stationarySince!) >= _stationaryWindow;
      if (stationary != _isStationary) {
        _isStationary = stationary;
        notifyListeners();
      }
    } else {
      _stationarySince = null;
      if (_isStationary) {
        _isStationary = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
