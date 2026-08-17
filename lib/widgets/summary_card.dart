import 'package:flutter/material.dart';

import '../utils/money.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.emphasis = false,
    this.negative = false,
  });

  final String label;
  final double amount;
  final bool emphasis;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueColor = negative
        ? colorScheme.error
        : emphasis
            ? colorScheme.primary
            : colorScheme.onSurface;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              formatIls(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DifferenceText extends StatelessWidget {
  const DifferenceText({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final isNeg = value < 0;
    final color = isNeg
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF2E7D32);
    return Text(
      formatIls(value),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        backgroundColor: isNeg ? color.withValues(alpha: 0.12) : null,
      ),
    );
  }
}
