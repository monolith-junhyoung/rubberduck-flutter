import 'package:flutter/material.dart';
import 'package:rubberduck_flutter/src/app/theme/app_colors.dart';
import 'package:rubberduck_flutter/src/core/models/control_vector.dart';
import 'package:rubberduck_flutter/src/core/models/movement_command.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/presentation/widgets/vector_feedback.dart';

class GyroHoldPad extends StatelessWidget {
  const GyroHoldPad({
    required this.vector,
    required this.direction,
    required this.isActive,
    required this.onHoldStart,
    required this.onHoldEnd,
    super.key,
  });

  final ControlVector vector;
  final MovementDirection direction;
  final bool isActive;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onHoldStart(),
      onPointerUp: (_) => onHoldEnd(),
      onPointerCancel: (_) => onHoldEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.panelBorder,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xE6121B30),
              Color(0xF0080E18),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 224,
              height: 224,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.duckGlow,
                    blurRadius: 34,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/img_duck_pilot.png',
                  width: 188,
                  height: 144,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 18),
            VectorFeedback(
              vector: vector,
              direction: direction,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
