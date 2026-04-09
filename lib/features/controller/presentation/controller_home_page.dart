import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/runtime/runtime_controller_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/control_vector.dart';
import '../application/controller_view_model.dart';
import '../application/gyro_input_service.dart';
import '../../../infrastructure/pubsub/pubsub_client.dart';
import '../../../infrastructure/pubsub/session_bootstrap_api.dart';
import 'widgets/correction_controls.dart';
import 'widgets/debug_log_panel.dart';
import 'widgets/gyro_hold_pad.dart';
import 'widgets/status_bar.dart';

class ControllerHomePage extends StatefulWidget {
  const ControllerHomePage({
    super.key,
    this.runtimeConfig = const RuntimeControllerConfig(),
  });

  final RuntimeControllerConfig runtimeConfig;

  @override
  State<ControllerHomePage> createState() => _ControllerHomePageState();
}

class _ControllerHomePageState extends State<ControllerHomePage>
    with WidgetsBindingObserver {
  late final ControllerViewModel _viewModel = ControllerViewModel(
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
