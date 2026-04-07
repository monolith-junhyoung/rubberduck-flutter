import '../../../core/models/control_vector.dart';
import '../../../core/models/movement_command.dart';

abstract final class DirectionResolver {
  static const double deadZone = 0.18;
  static const double diagonalThreshold = 0.42;

  static MovementDirection resolve(ControlVector vector) {
    if (!vector.active || vector.magnitude <= deadZone) {
      return MovementDirection.idle;
    }

    final horizontal = vector.x;
    final vertical = vector.y;
    final absHorizontal = horizontal.abs();
    final absVertical = vertical.abs();

    if (absHorizontal >= diagonalThreshold && absVertical >= diagonalThreshold) {
      if (horizontal < 0 && vertical > 0) {
        return MovementDirection.upLeft;
      }
      if (horizontal > 0 && vertical > 0) {
        return MovementDirection.upRight;
      }
      if (horizontal < 0 && vertical < 0) {
        return MovementDirection.downLeft;
      }
      return MovementDirection.downRight;
    }

    if (absHorizontal > absVertical) {
      return horizontal < 0 ? MovementDirection.left : MovementDirection.right;
    }

    return vertical < 0 ? MovementDirection.down : MovementDirection.up;
  }
}
