import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CorrectionControls extends StatelessWidget {
  const CorrectionControls({
    super.key,
    required this.onLeftPressed,
    required this.onStopPressed,
    required this.onRightPressed,
  });

  final VoidCallback onLeftPressed;
  final VoidCallback onStopPressed;
  final VoidCallback onRightPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ControlButton(
            label: '좌',
            isStop: false,
            onPressed: onLeftPressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ControlButton(
            label: '정지',
            isStop: true,
            onPressed: onStopPressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ControlButton(
            label: '우',
            isStop: false,
            onPressed: onRightPressed,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.isStop,
    required this.onPressed,
  });

  final String label;
  final bool isStop;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.panelBorder),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isStop
                ? const [
                    AppColors.stopButtonTop,
                    AppColors.stopButtonBottom,
                  ]
                : const [
                    Color(0xFF202A42),
                    Color(0xFF131B2E),
                  ],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
