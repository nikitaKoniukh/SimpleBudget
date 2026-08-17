import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/share_helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _shareInvite(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final household = state.household;
    if (household == null) return;
    final message = l10n.inviteShareMessage(
      household.inviteCode,
      household.name,
    );
    await SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final household = state.household;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.household),
            subtitle: Text(household?.name ?? '—'),
          ),
          ListTile(
            title: Text(l10n.members),
            subtitle: Text('${household?.memberIds.length ?? 0}'),
          ),
          ListTile(
            title: Text(l10n.invitePartner),
            subtitle: Text(household?.inviteCode ?? '—'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: household == null
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: household.inviteCode),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.inviteCopied)),
                      );
                    },
            ),
          ),
          ListTile(
            title: Text(l10n.shareInvite),
            leading: const Icon(Icons.ios_share),
            onTap: household == null ? null : () => _shareInvite(context),
          ),
          ListTile(
            title: Text(l10n.exportCsv),
            leading: const Icon(Icons.table_view_outlined),
            onTap: household == null
                ? null
                : () => exportAndShareMonthCsv(context),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.language),
            subtitle: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'ru', label: Text('Русский')),
              ],
              selected: {state.localeCode},
              onSelectionChanged: (s) => state.setLocale(s.first),
            ),
          ),
          ListTile(
            title: Text(l10n.currency),
            subtitle: const Text('₪ ILS'),
          ),
          ListTile(
            title: Text(l10n.manageCategories),
            subtitle: Text('${state.categories.length}'),
          ),
          ListTile(
            title: Text(l10n.duplicateMonth),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final next = await state.duplicateCurrentMonth();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.monthCreated}: $next')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.errorGeneric}: $e')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.signOut),
            leading: const Icon(Icons.logout),
            onTap: () => state.auth.signOut(),
          ),
        ],
      ),
    );
  }
}
