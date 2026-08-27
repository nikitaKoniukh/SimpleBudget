import 'package:flutter/material.dart';

import '../theme/sync_theme.dart';

class FlowStepProgress extends StatelessWidget {
  const FlowStepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                color: i <= current
                    ? SyncColors.primary
                    : SyncColors.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class FlowOnboardingHeader extends StatelessWidget {
  const FlowOnboardingHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 64,
          color: SyncColors.primary.withValues(alpha: 0.85),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SyncColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

class FlowOptionCard extends StatelessWidget {
  const FlowOptionCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? SyncColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? SyncColors.primary : SyncColors.textMuted,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected
            ? Icon(Icons.check_circle, color: SyncColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
