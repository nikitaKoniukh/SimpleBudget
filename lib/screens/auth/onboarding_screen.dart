import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../settings/account_actions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController(text: 'Our Family');
  final _code = TextEditingController();
  bool _joining = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = context.read<AppState>();
    try {
      if (_joining) {
        await state.joinHousehold(_code.text);
      } else {
        await state.createHousehold(sentenceCase(_name.text));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.household)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.createHousehold),
                  ),
                  ButtonSegment(value: true, label: Text(l10n.joinHousehold)),
                ],
                selected: {_joining},
                onSelectionChanged: (s) => setState(() => _joining = s.first),
              ),
              const SizedBox(height: 24),
              if (_joining)
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.inviteCode,
                    border: const OutlineInputBorder(),
                  ),
                )
              else
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.householdName,
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _joining ? l10n.joinHousehold : l10n.createHousehold,
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => signOutAndReturnToAuth(context),
                child: Text(l10n.signOut),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => confirmAndDeleteAccount(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.deleteAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
