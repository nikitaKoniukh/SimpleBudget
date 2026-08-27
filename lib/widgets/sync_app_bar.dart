import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../navigation/adaptive_page_route.dart';
import '../providers/app_state.dart';
import '../screens/home/create_month_flow.dart';
import '../screens/household/household_sheets.dart';
import '../screens/settings/settings_screen.dart';
import '../theme/sync_theme.dart';
import '../utils/money.dart';

enum SyncAppBarKind { home, tab, page, modal, flow }

/// Modern transparent app bar — large titles, glass action buttons, light context links.
class SyncAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SyncAppBar._({
    required this.kind,
    this.title,
    this.showBack = true,
    this.showSettings = true,
    this.onClose,
    this.onBack,
  });

  /// Home tab — large month title, household link, glass actions.
  factory SyncAppBar.home() =>
      const SyncAppBar._(kind: SyncAppBarKind.home);

  /// Main tab screens — screen label + month/household context.
  factory SyncAppBar.tab({
    required String title,
    bool showSettings = true,
  }) =>
      SyncAppBar._(
        kind: SyncAppBarKind.tab,
        title: title,
        showSettings: showSettings,
      );

  /// Pushed routes — back, page title, context subtitle.
  factory SyncAppBar.page({
    required String title,
    bool showBack = true,
    VoidCallback? onBack,
  }) =>
      SyncAppBar._(
        kind: SyncAppBarKind.page,
        title: title,
        showBack: showBack,
        onBack: onBack,
      );

  /// Full-screen modal flows — close button and step title.
  factory SyncAppBar.modal({
    required String title,
    VoidCallback? onClose,
  }) =>
      SyncAppBar._(
        kind: SyncAppBarKind.modal,
        title: title,
        onClose: onClose,
      );

  /// Multi-step flows — back only; titles live in the page hero.
  factory SyncAppBar.flow({VoidCallback? onBack}) =>
      SyncAppBar._(
        kind: SyncAppBarKind.flow,
        onBack: onBack,
      );

  final SyncAppBarKind kind;
  final String? title;
  final bool showBack;
  final bool showSettings;
  final VoidCallback? onClose;
  final VoidCallback? onBack;

  double get _contentHeight => switch (kind) {
        SyncAppBarKind.home => 92,
        SyncAppBarKind.tab => 80,
        SyncAppBarKind.page => 76,
        SyncAppBarKind.modal => 56,
        SyncAppBarKind.flow => 48,
      };

  @override
  Size get preferredSize {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final topPadding = view.padding.top / view.devicePixelRatio;
    return Size.fromHeight(_contentHeight + topPadding);
  }

  void _openSettings(BuildContext context) {
    pushAdaptivePage(context, const SettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topPadding + _contentHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SyncColors.surface.withValues(alpha: 0.97),
              SyncColors.surface.withValues(alpha: 0.82),
              SyncColors.surface.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
            child: switch (kind) {
              SyncAppBarKind.home => _HomeContent(
                  l10n: l10n,
                  state: state,
                  theme: theme,
                  onOpenSettings: () => _openSettings(context),
                ),
              SyncAppBarKind.tab => _TabContent(
                  l10n: l10n,
                  state: state,
                  theme: theme,
                  title: title!,
                  showSettings: showSettings,
                  onOpenSettings: () => _openSettings(context),
                ),
              SyncAppBarKind.page => _PageContent(
                  l10n: l10n,
                  state: state,
                  theme: theme,
                  title: title!,
                  showBack: showBack,
                  onBack: onBack,
                ),
              SyncAppBarKind.modal => _ModalContent(
                  theme: theme,
                  title: title!,
                  onClose: onClose ?? () => Navigator.pop(context),
                ),
              SyncAppBarKind.flow => _FlowContent(onBack: onBack),
            },
          ),
        ),
      ),
    );
  }
}

/// Glass-blur circular action — modern "liquid glass" affordance on controls only.
class _GlassIconAction extends StatelessWidget {
  const _GlassIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SyncColors.frostedBlur,
            sigmaY: SyncColors.frostedBlur,
          ),
          child: Material(
            color: SyncColors.glassButton,
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 20, color: SyncColors.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text-only context switcher — no pill background, cleaner hierarchy.
class _ContextLink extends StatelessWidget {
  const _ContextLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: SyncColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: SyncColors.textMuted.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.l10n,
    required this.state,
  });

  final AppLocalizations l10n;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasMonthSelected && state.household == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (state.hasMonthSelected) ...[
          Flexible(
            child: _ContextLink(
              label: l10n.monthTitle(dateFromMonthId(state.monthId!)),
              onTap: () => showSelectMonthSheet(context),
            ),
          ),
        ],
        if (state.hasMonthSelected && state.household != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '·',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: SyncColors.textMuted.withValues(alpha: 0.5),
                  ),
            ),
          ),
        if (state.household != null)
          Flexible(
            child: _ContextLink(
              label: state.household!.name,
              onTap: () => showHouseholdSwitcher(context),
            ),
          ),
      ],
    );
  }
}

class _ContextSubtitle extends StatelessWidget {
  const _ContextSubtitle({
    required this.l10n,
    required this.state,
  });

  final AppLocalizations l10n;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (state.hasMonthSelected) {
      parts.add(l10n.monthTitle(dateFromMonthId(state.monthId!)));
    }
    if (state.household != null) {
      parts.add(state.household!.name);
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: SyncColors.textMuted,
            letterSpacing: 0.1,
          ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.l10n,
    required this.state,
    required this.theme,
    required this.onOpenSettings,
  });

  final AppLocalizations l10n;
  final AppState state;
  final ThemeData theme;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final hasMonth = state.hasMonthSelected;
    final monthId = state.monthId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: hasMonth
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: AlignmentDirectional.centerStart,
                            clipBehavior: Clip.none,
                            children: [
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        child: Text(
                          l10n.monthTitle(dateFromMonthId(monthId!)),
                          key: ValueKey(monthId),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            letterSpacing: -0.4,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        l10n.appTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
            if (hasMonth) ...[
              _GlassIconAction(
                icon: Icons.calendar_today_outlined,
                tooltip: l10n.selectMonth,
                onPressed: () => showSelectMonthSheet(context),
              ),
              const SizedBox(width: 8),
            ],
            _GlassIconAction(
              icon: Icons.settings_outlined,
              tooltip: l10n.settings,
              onPressed: onOpenSettings,
            ),
          ],
        ),
        if (state.household != null) ...[
          const SizedBox(height: 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _ContextLink(
              label: state.household!.name,
              onTap: () => showHouseholdSwitcher(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.l10n,
    required this.state,
    required this.theme,
    required this.title,
    required this.showSettings,
    required this.onOpenSettings,
  });

  final AppLocalizations l10n;
  final AppState state;
  final ThemeData theme;
  final String title;
  final bool showSettings;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showSettings)
              _GlassIconAction(
                icon: Icons.settings_outlined,
                tooltip: l10n.settings,
                onPressed: onOpenSettings,
              ),
          ],
        ),
        const SizedBox(height: 2),
        _ContextRow(l10n: l10n, state: state),
      ],
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.l10n,
    required this.state,
    required this.theme,
    required this.title,
    required this.showBack,
    this.onBack,
  });

  final AppLocalizations l10n;
  final AppState state;
  final ThemeData theme;
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            if (showBack) ...[
              _GlassIconAction(
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (showBack) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 50),
            child: _ContextSubtitle(l10n: l10n, state: state),
          ),
        ] else ...[
          const SizedBox(height: 2),
          _ContextSubtitle(l10n: l10n, state: state),
        ],
      ],
    );
  }
}

class _FlowContent extends StatelessWidget {
  const _FlowContent({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: _GlassIconAction(
        icon: Icons.arrow_back_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBack ?? () => Navigator.maybePop(context),
      ),
    );
  }
}

class _ModalContent extends StatelessWidget {
  const _ModalContent({
    required this.theme,
    required this.title,
    required this.onClose,
  });

  final ThemeData theme;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconAction(
          icon: Icons.close_rounded,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onClose,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
