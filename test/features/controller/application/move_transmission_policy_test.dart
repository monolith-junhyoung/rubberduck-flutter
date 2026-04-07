import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/core/models/control_vector.dart';
import 'package:rubberduck_flutter/core/models/movement_command.dart';
import 'package:rubberduck_flutter/features/controller/application/move_transmission_policy.dart';

void main() {
  test('sends active movement on first dispatch and interval boundary', () {
    const policy = MoveTransmissionPolicy();
    final now = DateTime(2026, 4, 7, 18, 0, 0, 100);
    final current = const ControlVector(x: 0.4, y: 0.7, active: true);

    expect(
      policy.shouldSend(
        now: now,
        lastSentAt: null,
        current: current,
        previous: const ControlVector(x: 0, y: 0, active: false),
        currentDirection: MovementDirection.up,
        previousDirection: MovementDirection.idle,
      ),
      isTrue,
    );

    expect(
      policy.shouldSend(
        now: now,
        lastSentAt: now.subtract(const Duration(milliseconds: 120)),
        current: current,
        previous: current,
        currentDirection: MovementDirection.up,
        previousDirection: MovementDirection.up,
      ),
      isTrue,
    );
  });

  test('sends immediately on meaningful direction change', () {
    const policy = MoveTransmissionPolicy();
    final now = DateTime(2026, 4, 7, 18, 0, 0, 100);

    expect(
      policy.shouldSend(
        now: now,
        lastSentAt: now.subtract(const Duration(milliseconds: 20)),
        current: const ControlVector(x: 0.9, y: 0.7, active: true),
        previous: const ControlVector(x: -0.9, y: 0.7, active: true),
        currentDirection: MovementDirection.upRight,
        previousDirection: MovementDirection.upLeft,
      ),
      isTrue,
    );
  });

  test('suppresses unchanged idle traffic', () {
    const policy = MoveTransmissionPolicy();
    final now = DateTime(2026, 4, 7, 18, 0, 0, 100);
    const idle = ControlVector(x: 0, y: 0, active: false);

    expect(
      policy.shouldSend(
        now: now,
        lastSentAt: now.subtract(const Duration(milliseconds: 20)),
        current: idle,
        previous: idle,
        currentDirection: MovementDirection.idle,
        previousDirection: MovementDirection.idle,
      ),
      isFalse,
    );
  });
}
