import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rubberduck_flutter/src/app/theme/app_colors.dart';
import 'package:rubberduck_flutter/src/core/config/runtime_configuration.dart';
import 'package:rubberduck_flutter/src/core/models/control_vector.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/gyro_input_service.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/pubsub_client.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/session_bootstrap_api.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/duck_pilot_view_model.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/widgets/correction_controls.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/widgets/debug_log_panel.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/widgets/gyro_hold_pad.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/widgets/status_bar.dart';

class DuckPilotPage extends StatefulWidget {
  const DuckPilotPage({
    super.key,
    this.runtimeConfig = const RuntimeConfiguration(),
  });

  final RuntimeConfiguration runtimeConfig;

  @override
  State<DuckPilotPage> createState() => _DuckPilotPageState();
}

class _DuckPilotPageState extends State<DuckPilotPage> with WidgetsBindingObserver {
  late final DuckPilotViewModel _viewModel = DuckPilotViewModel(
    bootstrapApi: widget.runtimeConfig.isRealtimeReady
        ? DirectClientAccessBootstrapApi(
            clientAccessUrl: widget.runtimeConfig.pubSubClientAccessUrl,
          )
        : null,
    pubSubClient:
        widget.runtimeConfig.isRealtimeReady ? WebSocketPubSubClient() : null,
  );
  final TiltInputService _gyroInputService = AccelerometerTiltInputService();
  StreamSubscription<ControlVector>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.runtimeConfig.autoJoinOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_attemptAutoJoin());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return Scaffold(
          body: Stack(
            children: [
              const _GridBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Azure Web Pub/Sub',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duck Control',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            widget.runtimeConfig.statusLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.runtimeConfig.runtimeModeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StatusBar(
                        connectionLabel: state.connectionLabel,
                        countdownLabel: state.countdownLabel,
                        flagHolderLabel: state.flagHolderLabel,
                      ),
                      const SizedBox(height: 18),
                      GyroHoldPad(
                        vector: state.currentVector,
                        direction: state.resolvedDirection,
                        isActive: state.gyroHoldActive,
                        onHoldStart: _onHoldStart,
                        onHoldEnd: _viewModel.onHoldEnded,
                      ),
                      const SizedBox(height: 18),
                      CorrectionControls(
                        onLeftPressed: _viewModel.onCorrectionLeft,
                        onStopPressed: _viewModel.onStopPressed,
                        onRightPressed: _viewModel.onCorrectionRight,
                      ),
                      if (state.showReconnectAction) ...[
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _attemptAutoJoin,
                          child: const Text('재연결'),
                        ),
                      ],
                      const SizedBox(height: 18),
                      DebugLogPanel(logs: state.debugLogs),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onHoldStart() {
    _viewModel.onHoldStarted();
    _gyroSubscription?.cancel();
    _gyroSubscription = _gyroInputService.watchVectors().listen(
      _viewModel.onGyroVectorChanged,
    );
  }

  Future<void> _attemptAutoJoin() async {
    if (!widget.runtimeConfig.isRealtimeReady) {
      _viewModel.submitJoin();
      return;
    }

    await _viewModel.submitJoinRealtime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewModel.onAppLifecycleChanged(state);
    if (state != AppLifecycleState.resumed) {
      _gyroSubscription?.cancel();
      _gyroSubscription = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gyroSubscription?.cancel();
    _viewModel.dispose();
    super.dispose();
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgTop,
            AppColors.bgBottom,
          ],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x10FFFFFF)
      ..strokeWidth = 1;

    const gap = 28.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
