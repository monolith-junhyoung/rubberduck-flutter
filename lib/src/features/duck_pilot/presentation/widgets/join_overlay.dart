import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class JoinOverlay extends StatelessWidget {
  const JoinOverlay({
    super.key,
    required this.errorMessage,
    required this.onPlayerNameChanged,
    required this.onSessionCodeChanged,
    required this.onJoinPressed,
  });

  final String errorMessage;
  final ValueChanged<String> onPlayerNameChanged;
  final ValueChanged<String> onSessionCodeChanged;
  final VoidCallback onJoinPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xF0141D30),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.panelBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 26,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '세션 입장',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: onPlayerNameChanged,
                decoration: const InputDecoration(
                  labelText: '플레이어 이름',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: onSessionCodeChanged,
                decoration: const InputDecoration(
                  labelText: '세션 코드',
                ),
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFF8F8F),
                      ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onJoinPressed,
                child: const Text('입장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
