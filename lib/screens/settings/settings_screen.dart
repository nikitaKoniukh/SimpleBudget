import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/share_helpers.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';
import '../home/month_actions.dart';
import '../overview/overview_screen.dart';
import 'account_actions.dart';
import 'recurring_bills_screen.dart';

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

  Future<void> _editHouseholdName(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final household = state.household;
    if (household == null) return;
    final nameCtrl = TextEditingController(text: household.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editHouseholdName),
        content: TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.householdName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = sentenceCase(nameCtrl.text);
    if (name.isEmpty) return;
    try {
      await context.read<AppState>().updateHouseholdName(name);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final household = state.household;

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.settings)),
        body: ListView(
          children: [
            ListTile(
              title: Text(l10n.household),
              subtitle: Text(household?.name ?? '—'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: household == null
                  ? null
                  : () => _editHouseholdName(context),
            ),
            ListTile(
              title: Text(l10n.members),
              subtitle: Text(
                household == null
                    ? '—'
                    : household.memberIds
                        .map(state.memberLabel)
                        .join(', '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: household == null
                  ? null
                  : () => _showMembers(context),
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
              onTap: !state.hasMonthSelected
                  ? null
                  : () => exportAndShareMonthCsv(context),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.language),
              subtitle: SegmentedButton<String>(
                segments: [
                  const ButtonSegment(value: 'en', label: Text('English')),
                  const ButtonSegment(value: 'ru', label: Text('Русский')),
                  ButtonSegment(value: 'he', label: Text(l10n.hebrew)),
                ],
                selected: {state.localeCode},
                onSelectionChanged: (s) => state.setLocale(s.first),
              ),
            ),
            ListTile(
              title: Text(l10n.reports),
              leading: const Icon(Icons.insights_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: !state.hasMonthSelected
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OverviewScreen(),
                        ),
                      );
                    },
            ),
            ListTile(
              title: Text(l10n.recurringBills),
              leading: const Icon(Icons.event_repeat_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecurringBillsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(l10n.addMonth),
              trailing: const Icon(Icons.chevron_right),
              onTap: !state.canEditPlan
                  ? null
                  : () => showCreateMonthDialog(context),
            ),
            ListTile(
              title: Text(l10n.startNextMonth),
              trailing: const Icon(Icons.chevron_right),
              onTap: !state.hasMonthSelected || !state.canEditPlan
                  ? null
                  : () async {
                      try {
                        final next = await state.duplicateCurrentMonth();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.monthCreated}: $next'),
                          ),
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
            if (!state.isHouseholdOwner)
              ListTile(
                title: Text(l10n.leaveHousehold),
                leading: const Icon(Icons.logout),
                onTap: () => confirmAndLeaveHousehold(context),
              ),
            ListTile(
              title: Text(l10n.signOut),
              leading: const Icon(Icons.logout),
              onTap: () => signOutAndReturnToAuth(context),
            ),
            if (state.isHouseholdOwner)
              ListTile(
                title: Text(
                  l10n.deleteHousehold,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                leading: Icon(
                  Icons.home_work_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                onTap: () => confirmAndDeleteHousehold(context),
              ),
            ListTile(
              title: Text(
                l10n.deleteAccount,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              leading: Icon(
                Icons.person_remove_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => confirmAndDeleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showMembers(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetMaxHeight(ctx)),
        child: SafeArea(
          child: Consumer<AppState>(
            builder: (ctx, state, _) {
              final household = state.household;
              if (household == null) return const SizedBox.shrink();
              return ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text(l10n.members)),
                  for (final uid in household.memberIds)
                    ListTile(
                      title: Text(state.memberLabel(uid)),
                      subtitle: Text(
                        household.isOwnedBy(uid)
                            ? l10n.roleOwner
                            : household.roleFor(uid) == 'viewer'
                                ? l10n.roleViewer
                                : l10n.roleEditor,
                      ),
                      trailing: state.isHouseholdOwner &&
                              uid != state.currentUid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.roleViewer,
                                  icon: Icon(
                                    household.roleFor(uid) == 'viewer'
                                        ? Icons.visibility
                                        : Icons.edit_outlined,
                                  ),
                                  onPressed: () {
                                    final next =
                                        household.roleFor(uid) == 'viewer'
                                            ? 'editor'
                                            : 'viewer';
                                    state.setMemberRole(uid, next);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                  ),
                                  onPressed: () => state.removeMember(uid),
                                ),
                              ],
                            )
                          : null,
                    ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
