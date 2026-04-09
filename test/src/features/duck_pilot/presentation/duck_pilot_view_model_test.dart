import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:rubberduck_flutter/src/core/models/control_vector.dart';
import 'package:rubberduck_flutter/src/core/models/movement_command.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/duck_pilot_view_model.dart';

void main() {
  test('initial state seeds a random player name and fixed session code', () {
    final viewModel = DuckPilotViewModel(
      playerNameGenerator: () => 'duck-4821',
    );

    expect(viewModel.state.playerName, 'duck-4821');
    expect(viewModel.state.sessionCode, 'rubberduck-room1');
    expect(viewModel.state.isJoined, isFalse);
  });

  test('configured defaults enter joined local state without overlay input', () {
    final viewModel = DuckPilotViewModel(
      playerNameGenerator: () => 'duck-4821',
    );

    final joined = viewModel.submitJoin();

    expect(joined, isTrue);
    expect(viewModel.state.isJoined, isTrue);
    expect(viewModel.state.connectionLabel, '로컬 모드');
    expect(viewModel.state.flagHolderLabel, 'Duck 1');
    expect(viewModel.state.playerName, 'duck-4821');
    expect(viewModel.state.sessionCode, 'rubberduck-room1');
  });

  test('hold start and end toggle gyro activation safely', () {
    final viewModel = DuckPilotViewModel();

    viewModel.onHoldStarted();
    expect(viewModel.state.gyroHoldActive, isTrue);

    viewModel.onGyroVectorChanged(
      const ControlVector(
        x: -0.2,
        y: 0.7,
        active: true,
      ),
    );

    expect(viewModel.state.currentVector.isIdle, isFalse);
    expect(viewModel.state.resolvedDirection, MovementDirection.up);

    viewModel.onHoldEnded();

    expect(viewModel.state.gyroHoldActive, isFalse);
    expect(viewModel.state.currentVector.isIdle, isTrue);
    expect(viewModel.state.resolvedDirection, MovementDirection.idle);
  });

  test('correction buttons force left right and stop states', () {
    final viewModel = DuckPilotViewModel();

    viewModel.onCorrectionLeft();
    expect(viewModel.state.resolvedDirection, MovementDirection.left);

    viewModel.onCorrectionRight();
    expect(viewModel.state.resolvedDirection, MovementDirection.right);

    viewModel.onStopPressed();
    expect(viewModel.state.currentVector.isIdle, isTrue);
    expect(viewModel.state.resolvedDirection, MovementDirection.idle);
  });

  test('background lifecycle change forces stop and clears hold state', () {
    final viewModel = DuckPilotViewModel();

    viewModel.onHoldStarted();
    viewModel.onGyroVectorChanged(
      const ControlVector(
        x: 0.3,
        y: 0.8,
        active: true,
      ),
    );

    viewModel.onAppLifecycleChanged(AppLifecycleState.paused);

    expect(viewModel.state.gyroHoldActive, isFalse);
    expect(viewModel.state.currentVector.isIdle, isTrue);
    expect(viewModel.state.resolvedDirection, MovementDirection.idle);
  });

  test('writes tilt logs for movement updates', () {
    final logs = <String>[];
    final viewModel = DuckPilotViewModel(
      logger: logs.add,
    );

    viewModel.onHoldStarted();
    viewModel.onGyroVectorChanged(
      const ControlVector(
        x: 0.4,
        y: 0.8,
        active: true,
      ),
    );

    expect(logs.any((log) => log.contains('tilt.update')), isTrue);
    expect(logs.any((log) => log.contains('direction=up')), isTrue);
    expect(
      viewModel.state.debugLogs.any((log) => log.contains('tilt.update')),
      isTrue,
    );
    expect(viewModel.state.lastSendSummary, '-');
    expect(viewModel.state.lastReceiveSummary, '-');
    expect(viewModel.state.lastAckSummary, '-');
    expect(viewModel.state.connectionSummary, 'idle');
  });
}
