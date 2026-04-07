import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/models/control_vector.dart';

abstract class TiltInputService {
  Stream<ControlVector> watchVectors();
}

class AccelerometerTiltInputService implements TiltInputService {
  AccelerometerTiltInputService({
    this.samplingPeriod = SensorInterval.gameInterval,
    this.gravityScale = 4.9,
    this.deadZone = 0.08,
  });

  final Duration samplingPeriod;
  final double gravityScale;
  final double deadZone;

  @override
  Stream<ControlVector> watchVectors() {
    AccelerometerEvent? baseline;

    return accelerometerEventStream(samplingPeriod: samplingPeriod).map((event) {
      baseline ??= event;
      return TiltVectorMapper.fromAccelerometerDelta(
        xDelta: event.x - baseline!.x,
        yDelta: event.y - baseline!.y,
        gravityScale: gravityScale,
        deadZone: deadZone,
      );
    });
  }
}

abstract final class TiltVectorMapper {
  static ControlVector fromAccelerometerDelta({
    required double xDelta,
    required double yDelta,
    required double gravityScale,
    required double deadZone,
  }) {
    final normalizedX = _clamp(xDelta / gravityScale);
    final normalizedY = _clamp(yDelta / gravityScale);

    final active = normalizedX.abs() >= deadZone || normalizedY.abs() >= deadZone;
    if (!active) {
      return const ControlVector(
        x: 0,
        y: 0,
        active: false,
      );
    }

    return ControlVector(
      x: normalizedX,
      y: normalizedY,
      active: true,
    );
  }

  static double _clamp(double value) {
    if (value > 1) {
      return 1;
    }
    if (value < -1) {
      return -1;
    }
    return value;
  }
}
