import 'package:flutter/material.dart';

import '../../../core/models/game_session_state.dart';
import '../../../core/models/movement_command.dart';
import '../../../core/models/player_status.dart';
import 'widgets/directional_pad.dart';

class ControllerHomePage extends StatelessWidget {
  const ControllerHomePage({super.key});

  GameSessionState get mockState => GameSessionState(
        sessionName: '청소난투 테스트 세션',
        connectionLabel: '서버 연결 대기',
        countdownSeconds: 5,
        lastTriggeredObstacle: '배수구 대기',
        players: const [
          PlayerStatus(
            playerId: 'duck-1',
            displayName: 'Duck 1',
            flagHoldDuration: Duration(seconds: 18),
            isHoldingFlag: true,
            hadFlagAtEnd: false,
            isConnected: true,
            lastInputLabel: 'upRight',
          ),
          PlayerStatus(
            playerId: 'duck-2',
            displayName: 'Duck 2',
            flagHoldDuration: Duration(seconds: 12),
            isHoldingFlag: false,
            hadFlagAtEnd: false,
            isConnected: true,
            lastInputLabel: 'left',
          ),
          PlayerStatus(
            playerId: 'duck-3',
            displayName: 'Duck 3',
            flagHoldDuration: Duration(seconds: 9),
            isHoldingFlag: false,
            hadFlagAtEnd: false,
            isConnected: true,
            lastInputLabel: 'idle',
          ),
          PlayerStatus(
            playerId: 'duck-4',
            displayName: 'Duck 4',
            flagHoldDuration: Duration(seconds: 4),
            isHoldingFlag: false,
            hadFlagAtEnd: true,
            isConnected: false,
            lastInputLabel: 'down',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final state = mockState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('청소난투 콘솔'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SessionOverview(state: state),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PlayerStatusPanel(players: state.players),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ControllerPanel(
                              onDirectionPressed: _handleDirectionPressed,
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      children: [
                        _PlayerStatusPanel(players: state.players),
                        const SizedBox(height: 16),
                        _ControllerPanel(
                          onDirectionPressed: _handleDirectionPressed,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDirectionPressed(MovementDirection direction) {
    debugPrint('movement pressed: $direction');
  }
}

class _SessionOverview extends StatelessWidget {
  const _SessionOverview({required this.state});

  final GameSessionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.sessionName,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatusChip(
                  label: '연결 상태',
                  value: state.connectionLabel,
                ),
                _StatusChip(
                  label: '시작 카운트다운',
                  value: '${state.countdownSeconds}초',
                ),
                _StatusChip(
                  label: '최근 장애물',
                  value: state.lastTriggeredObstacle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatusPanel extends StatelessWidget {
  const _PlayerStatusPanel({required this.players});

  final List<PlayerStatus> players;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '플레이어 상태',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final player in players) ...[
              _PlayerStatusTile(player: player),
              if (player != players.last) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerStatusTile extends StatelessWidget {
  const _PlayerStatusTile({required this.player});

  final PlayerStatus player;

  @override
  Widget build(BuildContext context) {
    final holdSeconds = player.flagHoldDuration.inSeconds;

    return Row(
      children: [
        CircleAvatar(
          child: Text(player.displayName.replaceAll('Duck ', 'D')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.displayName),
              const SizedBox(height: 4),
              Text(
                '깃발 보유 ${holdSeconds}s · 입력 ${player.lastInputLabel}',
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(player.isHoldingFlag ? '깃발 보유 중' : '일반 상태'),
            const SizedBox(height: 4),
            Text(player.isConnected ? 'connected' : 'offline'),
          ],
        ),
      ],
    );
  }
}

class _ControllerPanel extends StatelessWidget {
  const _ControllerPanel({required this.onDirectionPressed});

  final ValueChanged<MovementDirection> onDirectionPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이동 컨트롤',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '현재는 버튼 기반 입력만 연결되어 있다. 자이로스코프 입력은 다음 단계에서 이 패드와 같은 이벤트 모델로 연결한다.',
            ),
            const SizedBox(height: 16),
            Center(
              child: DirectionalPad(
                onDirectionPressed: onDirectionPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E1F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
