import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DebugLogPanel extends StatelessWidget {
  const DebugLogPanel({
    super.key,
    required this.logs,
  });

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    final visibleLogs = logs.reversed.take(8).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.panelBorder),
        color: const Color(0xCC0C1322),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Debug Log',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                logs.isEmpty ? '아직 로그 없음' : '${logs.length} entries',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          children: [
            if (visibleLogs.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '로그가 쌓이면 여기 표시됩니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              )
            else
              for (final log in visibleLogs)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      log,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
