import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';

Future<void> showHouseholdSwitcher(BuildContext context) async {
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
              final activeId = state.activeHouseholdId;
              final households = state.myHouseholds;
              return ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text(l10n.myHouseholds)),
                  if (households.isEmpty)
                    ListTile(title: Text(l10n.noHouseholdsYet)),
                  for (final h in households)
                    ListTile(
                      title: Text(h.name),
                      subtitle: activeId == h.id
                          ? Text(l10n.activeHousehold)
                          : null,
                      trailing: activeId == h.id
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(ctx).colorScheme.primary,
                            )
                          : null,
                      onTap: activeId == h.id
                          ? () => Navigator.pop(ctx)
                          : () async {
                              try {
                                await state.switchHousehold(h.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('${l10n.errorGeneric}: $e'),
                                  ),
                                );
                              }
                            },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add_home_outlined),
                    title: Text(l10n.createAnotherHousehold),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      await showCreateOrJoinHouseholdSheet(
                        context,
                        joining: false,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: Text(l10n.joinAnotherHousehold),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      await showCreateOrJoinHouseholdSheet(
                        context,
                        joining: true,
                      );
                    },
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

Future<void> showCreateOrJoinHouseholdSheet(
  BuildContext context, {
  bool joining = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final nameCtrl = TextEditingController(text: 'Our Family');
  final codeCtrl = TextEditingController();
  var isJoining = joining;
  var busy = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> submit() async {
            setModalState(() {
              busy = true;
              error = null;
            });
            final state = ctx.read<AppState>();
            try {
              if (isJoining) {
                await state.joinHousehold(codeCtrl.text);
              } else {
                await state.createHousehold(sentenceCase(nameCtrl.text));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              setModalState(() => error = e.toString());
            } finally {
              setModalState(() => busy = false);
            }
          }

          return FormSheet(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isJoining
                      ? l10n.joinAnotherHousehold
                      : l10n.createAnotherHousehold,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.createHousehold),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.joinHousehold),
                    ),
                  ],
                  selected: {isJoining},
                  onSelectionChanged: busy
                      ? null
                      : (s) => setModalState(() => isJoining = s.first),
                ),
                const SizedBox(height: 16),
                if (isJoining)
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: l10n.inviteCode,
                      border: const OutlineInputBorder(),
                    ),
                  )
                else
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: l10n.householdName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isJoining
                              ? l10n.joinHousehold
                              : l10n.createHousehold,
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  nameCtrl.dispose();
  codeCtrl.dispose();
}
