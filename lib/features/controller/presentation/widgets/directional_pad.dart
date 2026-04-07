import 'package:flutter/material.dart';

import '../../../../core/models/movement_command.dart';

class DirectionalPad extends StatelessWidget {
  const DirectionalPad({
    super.key,
    required this.onDirectionPressed,
  });

  final ValueChanged<MovementDirection> onDirectionPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          _DirectionRow(
            items: [
              _DirectionItem(MovementDirection.upLeft, '↖'),
              _DirectionItem(MovementDirection.up, '↑'),
              _DirectionItem(MovementDirection.upRight, '↗'),
            ],
            onDirectionPressed: onDirectionPressed,
          ),
          const SizedBox(height: 8),
          _DirectionRow(
            items: [
              _DirectionItem(MovementDirection.left, '←'),
              _DirectionItem(MovementDirection.idle, '•'),
              _DirectionItem(MovementDirection.right, '→'),
            ],
            onDirectionPressed: onDirectionPressed,
          ),
          const SizedBox(height: 8),
          _DirectionRow(
            items: [
              _DirectionItem(MovementDirection.downLeft, '↙'),
              _DirectionItem(MovementDirection.down, '↓'),
              _DirectionItem(MovementDirection.downRight, '↘'),
            ],
            onDirectionPressed: onDirectionPressed,
          ),
        ],
      ),
    );
  }
}

class _DirectionRow extends StatelessWidget {
  const _DirectionRow({
    required this.items,
    required this.onDirectionPressed,
  });

  final List<_DirectionItem> items;
  final ValueChanged<MovementDirection> onDirectionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final item in items) ...[
          _DirectionButton(
            label: item.label,
            onPressed: () => onDirectionPressed(item.direction),
          ),
          if (item != items.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

class _DirectionItem {
  const _DirectionItem(this.direction, this.label);

  final MovementDirection direction;
  final String label;
}
