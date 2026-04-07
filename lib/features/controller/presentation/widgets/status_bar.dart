import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    required this.connectionLabel,
    required this.countdownLabel,
    required this.flagHolderLabel,
  });

  final String connectionLabel;
  final String countdownLabel;
  final String flagHolderLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusChip(
            label: '연결 상태',
            value: connectionLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusChip(
            label: '카운트다운',
            value: countdownLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusChip(
            label: '현재 깃발',
            value: flagHolderLabel,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
