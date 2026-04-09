import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:rubberduck_flutter/src/core/models/control_vector.dart';
import 'package:rubberduck_flutter/src/core/models/movement_command.dart';
import 'package:rubberduck_flutter/src/core/models/session_join_request.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/pubsub_client.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/pubsub_config.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/pubsub_message_codec.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/session_bootstrap_api.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/domain/direction_resolver.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/domain/move_transmission_policy.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/duck_pilot_view_state.dart';

typedef PlayerNameGenerator = String Function();
typedef PilotLogger = void Function(String message);

const kRubberDuckSessionCode = 'rubberduck-room1';

class DuckPilotViewModel extends ChangeNotifier {
  DuckPilotViewModel({
    MoveTransmissionPolicy transmissionPolicy = const MoveTransmissionPolicy(),
    SessionBootstrapApi? bootstrapApi,
    PubSubClient? pubSubClient,
    PlayerNameGenerator? playerNameGenerator,
    PilotLogger? logger,
  }) : _transmissionPolicy = transmissionPolicy,
       _bootstrapApi = bootstrapApi,
       _pubSubClient = pubSubClient,
       _logger = logger ?? _defaultLogger {
    _state = DuckPilotViewState.initial().copyWith(
      playerName: (playerNameGenerator ?? _defaultPlayerNameGenerator)(),
      sessionCode: kRubberDuckSessionCode,
    );
  }

  final MoveTransmissionPolicy _transmissionPolicy;
  final SessionBootstrapApi? _bootstrapApi;
  final PubSubClient? _pubSubClient;
  final PilotLogger _logger;
  DuckPilotViewState _state = DuckPilotViewState.initial();
  DateTime? _lastSentAt;
  ControlVector _lastSentVector = const ControlVector(x: 0, y: 0, active: false);
  MovementDirection _lastSentDirection = MovementDirection.idle;
  MovementCommand? _latestQueuedCommand;
  bool _isRealtimeConnected = false;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<String>? _connectionSubscription;
  int _ackId = 0;

  DuckPilotViewState get state => _state;
  MovementCommand? get latestQueuedCommand => _latestQueuedCommand;

  void onPlayerNameChanged(String value) {
    _state = _state.copyWith(playerName: value, errorMessage: '');
    notifyListeners();
  }

  void onSessionCodeChanged(String value) {
    _state = _state.copyWith(sessionCode: value, errorMessage: '');
    notifyListeners();
  }

  bool submitJoin() {
    if (_state.playerName.trim().isEmpty || _state.sessionCode.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: '플레이어 이름과 세션 코드를 입력하세요.', isJoined: false);
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(
      isJoined: true,
      errorMessage: '',
      connectionLabel: '로컬 모드',
      countdownLabel: '00:08',
      flagHolderLabel: 'Duck 1',
      showReconnectAction: false,
    );
    _log('session.join', 'mode=local player=${_state.playerName} session=${_state.sessionCode}');
    notifyListeners();
    return true;
  }

  Future<bool> submitJoinRealtime() async {
    if (_state.playerName.trim().isEmpty || _state.sessionCode.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: '플레이어 이름과 세션 코드를 입력하세요.', isJoined: false);
      notifyListeners();
      return false;
    }

    final bootstrapApi = _bootstrapApi;
    final pubSubClient = _pubSubClient;
    if (bootstrapApi == null || pubSubClient == null) {
      _state = _state.copyWith(errorMessage: '실시간 연결 구성이 없습니다.', connectionLabel: '연결 실패', showReconnectAction: true);
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(errorMessage: '', connectionLabel: '연결 중');
    _log('session.join', 'mode=realtime player=${_state.playerName} session=${_state.sessionCode}');
    notifyListeners();

    try {
      final request = SessionJoinRequest(
        playerName: _state.playerName,
        sessionCode: _state.sessionCode,
        deviceId: 'local-device',
      );
      await _connectionSubscription?.cancel();
      _connectionSubscription = pubSubClient.connectionEvents.listen(_onConnectionEvent);
      final config = await bootstrapApi.createConnection(SessionBootstrapRequest.fromJoinRequest(request));
      await pubSubClient.connect(config);
      await _messageSubscription?.cancel();
      _messageSubscription = pubSubClient.messages.listen(_onInboundMessage);
      await pubSubClient.joinGroup(config.group, ackId: _nextAckId());
      final joinPayload = PubSubMessageCodec.encodeJoin(request, ackId: _nextAckId());
      _log('pubsub.send', jsonEncode(joinPayload));
      _state = _state.copyWith(lastSendSummary: 'join');
      await pubSubClient.publish(joinPayload);
      _applyRealtimeJoinSuccess(config);
      _isRealtimeConnected = true;
      _log('session.join', 'status=connected playerId=${config.userId} group=${config.group}');
      notifyListeners();
      return true;
    } catch (_) {
      _isRealtimeConnected = false;
      _state = _state.copyWith(
        isJoined: false,
        connectionLabel: '연결 실패',
        errorMessage: '실시간 연결에 실패했습니다.',
        showReconnectAction: true,
      );
      _log('session.join', 'status=failed');
      notifyListeners();
      return false;
    }
  }

  void onHoldStarted() {
    _state = _state.copyWith(gyroHoldActive: true);
    notifyListeners();
  }

  void onGyroVectorChanged(ControlVector vector) {
    if (!_state.gyroHoldActive) {
      return;
    }

    final activeVector = vector.copyWith(active: true);
    _state = _state.copyWith(currentVector: activeVector, resolvedDirection: DirectionResolver.resolve(activeVector));
    _log(
      'tilt.update',
      'x=${activeVector.x.toStringAsFixed(2)} '
          'y=${activeVector.y.toStringAsFixed(2)} '
          'magnitude=${activeVector.magnitude.toStringAsFixed(2)} '
          'direction=${_state.resolvedDirection.name} '
          'active=${activeVector.active}',
    );
    _queueCommandIfNeeded(source: 'gyro');
    notifyListeners();
  }

  void onHoldEnded() {
    _state = _state.copyWith(gyroHoldActive: false);
    _applyStop(notify: false);
    notifyListeners();
  }

  void onCorrectionLeft() {
    _applyCorrection(const ControlVector(x: -1, y: 0, active: true));
  }

  void onCorrectionRight() {
    _applyCorrection(const ControlVector(x: 1, y: 0, active: true));
  }

  void onStopPressed() {
    _applyStop(notify: true);
  }

  void onAppLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _applyStop(notify: true);
    }
  }

  void _applyCorrection(ControlVector vector) {
    final direction = DirectionResolver.resolve(vector);
    _state = _state.copyWith(currentVector: vector, resolvedDirection: direction);
    _log('control.correction', 'direction=${direction.name}');
    _queueCommandIfNeeded(source: 'button');
    notifyListeners();
  }

  void _applyStop({required bool notify}) {
    const idleVector = ControlVector(x: 0, y: 0, active: false);
    _state = _state.copyWith(
      gyroHoldActive: false,
      currentVector: idleVector,
      resolvedDirection: MovementDirection.idle,
    );
    _log('control.stop', 'direction=idle');
    _queueCommandIfNeeded(source: 'button');
    if (notify) {
      notifyListeners();
    }
  }

  void _queueCommandIfNeeded({required String source}) {
    final now = DateTime.now();
    final current = _state.currentVector;
    final direction = _state.resolvedDirection;
    final shouldSend = _transmissionPolicy.shouldSend(
      now: now,
      lastSentAt: _lastSentAt,
      current: current,
      previous: _lastSentVector,
      currentDirection: direction,
      previousDirection: _lastSentDirection,
    );

    if (!shouldSend) {
      return;
    }

    _latestQueuedCommand = MovementCommand(
      playerId: _state.playerId,
      sessionCode: _state.sessionCode,
      vector: current,
      direction: direction,
      active: current.active,
      source: source,
      sentAt: now,
    );
    _lastSentAt = now;
    _lastSentVector = current;
    _lastSentDirection = direction;

    final client = _pubSubClient;
    if (_isRealtimeConnected && client != null) {
      final payload = direction == MovementDirection.idle || !current.active
          ? PubSubMessageCodec.encodeStop(_latestQueuedCommand!, 'stop', ackId: _nextAckId())
          : PubSubMessageCodec.encodeMove(_latestQueuedCommand!, ackId: _nextAckId());
      _log('pubsub.send', jsonEncode(payload));
      final outboundType = (payload['data'] as Map<String, Object?>)['type'] as String? ?? '-';
      _state = _state.copyWith(lastSendSummary: outboundType);
      if (direction == MovementDirection.idle || !current.active) {
        unawaited(client.publish(payload));
      } else {
        unawaited(client.publish(payload));
      }
    }
  }

  void _applyRealtimeJoinSuccess(PubSubConfig config) {
    _state = _state.copyWith(
      isJoined: true,
      errorMessage: '',
      connectionLabel: '실시간 연결',
      countdownLabel: '00:08',
      flagHolderLabel: '대기',
      playerId: config.userId,
      showReconnectAction: false,
    );
  }

  void _onInboundMessage(Map<String, dynamic> message) {
    _log('pubsub.recv', jsonEncode(message));
    final inboundType = message['event'] as String? ?? message['type'] as String? ?? '-';
    _state = _state.copyWith(lastReceiveSummary: inboundType);
    final decoded = PubSubMessageCodec.decodeInbound(message);
    if (decoded == null) {
      notifyListeners();
      return;
    }

    switch (decoded.eventType) {
      case InboundEventType.sessionState:
        _state = _state.copyWith(
          connectionLabel: (decoded.data['connectionLabel'] as String?) ?? _state.connectionLabel,
          countdownLabel: (decoded.data['countdown'] as String?) ?? _state.countdownLabel,
        );
        notifyListeners();
        break;
      case InboundEventType.flagState:
        _state = _state.copyWith(flagHolderLabel: (decoded.data['holderLabel'] as String?) ?? _state.flagHolderLabel);
        notifyListeners();
        break;
      case InboundEventType.playerAssignment:
        _state = _state.copyWith(playerId: (decoded.data['playerId'] as String?) ?? _state.playerId);
        notifyListeners();
        break;
      case InboundEventType.ack:
        _state = _state.copyWith(lastAckSummary: 'ack:${decoded.data['ackId']}/${decoded.data['success']}');
        _log('pubsub.ack', 'ackId=${decoded.data['ackId']} success=${decoded.data['success']}');
        notifyListeners();
        break;
    }
  }

  void _onConnectionEvent(String event) {
    _log('pubsub.connection', event);
    _state = _state.copyWith(connectionSummary: event);
    if (event == 'connected') {
      _state = _state.copyWith(connectionLabel: '실시간 연결', showReconnectAction: false);
      notifyListeners();
      return;
    }
    if (event == 'closed' || event.startsWith('error:')) {
      _isRealtimeConnected = false;
      _state = _state.copyWith(connectionLabel: '연결 끊김', showReconnectAction: true);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    unawaited(_pubSubClient?.disconnect());
    super.dispose();
  }

  void _log(String tag, String message) {
    final nextLogs = List<String>.from(_state.debugLogs)..add('[$tag] $message');
    if (nextLogs.length > 40) {
      nextLogs.removeRange(0, nextLogs.length - 40);
    }
    _state = _state.copyWith(debugLogs: nextLogs);
    _logger('[$tag] $message');
  }

  static String _defaultPlayerNameGenerator() {
    final value = Random().nextInt(9000) + 1000;
    return 'duck-$value';
  }

  static void _defaultLogger(String message) {
    debugPrint(message);
  }

  int _nextAckId() {
    _ackId += 1;
    return _ackId;
  }
}
