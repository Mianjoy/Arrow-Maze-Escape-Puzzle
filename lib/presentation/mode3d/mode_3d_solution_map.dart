import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// Muestra el orden de solución garantizado del mapa aleatorio actual.
Future<void> showMode3dSolutionMap(
  BuildContext context, {
  required CubeSurfaceBoard board,
  required List<Identifier> solutionOrder,
}) {
  final strings = AppStringsScope.of(context);
  final escape = board.escapePoint.position;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.boardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.map_outlined, color: AppColors.textPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.mode3dSolutionMapTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strings.mode3dSolutionMapHint,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.mode3dEscapeLabel(
                  escape.face.name.toUpperCase(),
                  escape.row,
                  escape.column,
                ),
                style: const TextStyle(
                  color: Color(0xFFB26A00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.mode3dSolutionOrderTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < solutionOrder.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.arrow,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Color(0xFFEEF0F4), fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        solutionOrder[i].value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                strings.mode3dMultiFaceHint,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
