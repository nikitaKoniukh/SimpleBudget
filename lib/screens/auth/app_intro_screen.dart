import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/sync_theme.dart';
import '../../widgets/onboarding_flow.dart';

class _IntroPage {
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// One-time install tour explaining SyncMonth features.
class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({super.key, required this.onCompleted});

  final Future<void> Function() onCompleted;

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_IntroPage> _pages(AppLocalizations l10n) => [
        _IntroPage(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.introWelcomeTitle,
          body: l10n.introWelcomeBody,
        ),
        _IntroPage(
          icon: Icons.calendar_month_outlined,
          title: l10n.introPlanTitle,
          body: l10n.introPlanBody,
        ),
        _IntroPage(
          icon: Icons.add_circle_outline,
          title: l10n.introLogTitle,
          body: l10n.introLogBody,
        ),
        _IntroPage(
          icon: Icons.groups_outlined,
          title: l10n.introFamilyTitle,
          body: l10n.introFamilyBody,
        ),
        _IntroPage(
          icon: Icons.insights_outlined,
          title: l10n.introTrackTitle,
          body: l10n.introTrackBody,
        ),
      ];

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onCompleted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next(int lastIndex) {
    if (_index >= lastIndex) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final lastIndex = pages.length - 1;
    final isLast = _index >= lastIndex;
    final theme = Theme.of(context);

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _busy ? null : _finish,
                    child: Text(l10n.introSkip),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final page = pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                color: SyncColors.surfaceMint,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: SyncColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Icon(
                                page.icon,
                                size: 52,
                                color: SyncColors.primary,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.body,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: SyncColors.textMuted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                FlowStepProgress(current: _index, total: pages.length),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _next(lastIndex),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isLast ? l10n.introGetStarted : l10n.introNext,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
