import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/control_vector.dart';
import '../../../../core/models/movement_command.dart';

class VectorFeedback extends StatelessWidget {
  const VectorFeedback({
    super.key,
    required this.vector,
    required this.direction,
  });

  final ControlVector vector;
  final MovementDirection direction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hold to steer',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'x ${vector.x.toStringAsFixed(2)} · y ${vector.y.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          direction.name,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accentSoft,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
