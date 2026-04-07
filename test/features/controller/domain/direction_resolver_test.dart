import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/core/models/control_vector.dart';
import 'package:rubberduck_flutter/core/models/movement_command.dart';
import 'package:rubberduck_flutter/features/controller/domain/direction_resolver.dart';

void main() {
  test('resolves idle when vector is inside dead zone', () {
    expect(
      DirectionResolver.resolve(
        const ControlVector(
          x: 0,
          y: 0,
          active: false,
        ),
      ),
      MovementDirection.idle,
    );
  });

  test('resolves diagonal vectors to 8-direction movement', () {
    expect(
      DirectionResolver.resolve(
        const ControlVector(
          x: 0.8,
          y: 0.7,
          active: true,
        ),
      ),
      MovementDirection.upRight,
    );
  });

  test('resolves dominant axis vectors to cardinal movement', () {
    expect(
      DirectionResolver.resolve(
        const ControlVector(
          x: -0.9,
          y: 0.1,
          active: true,
        ),
      ),
      MovementDirection.left,
    );
  });
}
