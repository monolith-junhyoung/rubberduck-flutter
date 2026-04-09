import '../../../core/models/control_vector.dart';
import '../../../core/models/movement_command.dart';

class MoveTransmissionPolicy {
  const MoveTransmissionPolicy({
    this.interval = const Duration(milliseconds: 100),
    this.magnitudeDeltaThreshold = 0.18,
  });

  final Duration interval;
  final double magnitudeDeltaThreshold;

  bool shouldSend({
    required DateTime now,
    required DateTime? lastSentAt,
    required ControlVector current,
    required ControlVector previous,
    required MovementDirection currentDirection,
    required MovementDirection previousDirection,
  }) {
    if (lastSentAt == null && current.active) {
      return true;
    }

    if (!current.active &&
        !previous.active &&
        currentDirection == MovementDirection.idle &&
        previousDirection == MovementDirection.idle) {
      return false;
    }

    if (currentDirection != previousDirection) {
      return true;
    }

    final magnitudeDelta = (current.magnitude - previous.magnitude).abs();
    if (magnitudeDelta >= magnitudeDeltaThreshold) {
      return true;
    }

    if (lastSentAt == null) {
      return current.active;
    }

    return now.difference(lastSentAt) >= interval && current.active;
  }
}
