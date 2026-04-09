import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/gyro_input_service.dart';

void main() {
  test('maps accelerometer tilt delta into a clamped active vector', () {
    final vector = TiltVectorMapper.fromAccelerometerDelta(
      xDelta: 4.9,
      yDelta: -2.45,
      gravityScale: 4.9,
      deadZone: 0.1,
    );

    expect(vector.active, isTrue);
    expect(vector.x, 1);
    expect(vector.y, closeTo(-0.5, 0.001));
  });

  test('returns idle vector when tilt delta is inside dead zone', () {
    final vector = TiltVectorMapper.fromAccelerometerDelta(
      xDelta: 0.02,
      yDelta: -0.03,
      gravityScale: 4.9,
      deadZone: 0.1,
    );

    expect(vector.active, isFalse);
    expect(vector.isIdle, isTrue);
  });
}
