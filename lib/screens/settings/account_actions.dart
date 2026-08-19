import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';

void popToRoot(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

Future<void> signOutAndReturnToAuth(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  try {
    await context.read<AppState>().signOut();
    if (!context.mounted) return;
    popToRoot(context);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
  }
}

Future<void> confirmAndLeaveHousehold(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (state.isHouseholdOwner) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveHousehold),
        content: Text(l10n.leaveHouseholdOwnerBlocked),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.leaveHouseholdConfirmTitle),
      content: Text(l10n.leaveHouseholdConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.leaveHousehold),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await context.read<AppState>().leaveHousehold();
    if (!context.mounted) return;
    popToRoot(context);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
  }
}

Future<void> confirmAndDeleteHousehold(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteHouseholdConfirmTitle),
      content: Text(l10n.deleteHouseholdConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.confirmDelete),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await context.read<AppState>().deleteHousehold();
    if (!context.mounted) return;
    popToRoot(context);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
  }
}

Future<void> confirmAndDeleteAccount(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (state.isHouseholdOwner) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountOwnerBlockedTitle),
        content: Text(l10n.deleteAccountOwnerBlockedBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteAccountConfirmTitle),
      content: Text(l10n.deleteAccountConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.confirmDelete),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await runDeleteAccount(context);
}

Future<void> runDeleteAccount(BuildContext context, {String? password}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await context.read<AppState>().deleteAccount(password: password);
    if (!context.mounted) return;
    popToRoot(context);
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    if (e.code == 'requires-recent-login') {
      final needsPassword = context.read<AppState>().auth.providerIds.contains(
        'password',
      );
      if (needsPassword) {
        final entered = await _promptPassword(context);
        if (entered == null || !context.mounted) return;
        await runDeleteAccount(context, password: entered);
        return;
      }
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
  } on StateError catch (e) {
    if (e.message == 'cancelled') return;
    if (!context.mounted) return;
    if (e.message == 'must-delete-household-first') {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteAccountOwnerBlockedTitle),
          content: Text(l10n.deleteAccountOwnerBlockedBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
  }
}

Future<String?> _promptPassword(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final password = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.reauthenticateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.reauthenticateBody),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.password),
            onSubmitted: (value) => Navigator.pop(ctx, value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(l10n.confirmDelete),
        ),
      ],
    ),
  );
  controller.dispose();
  if (password == null || password.isEmpty) return null;
  return password;
}
