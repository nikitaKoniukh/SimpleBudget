import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/money.dart';

/// Pushes month hero/overview data into Android/iOS quick-log home-screen widgets.
abstract final class QuickLogWidgetService {
  static const appGroupId = 'group.com.yetzira.syncmonth';
  static const compactAndroidName = 'QuickLogCompactWidgetProvider';
  static const extendedAndroidName = 'QuickLogExtendedWidgetProvider';
  static const compactQualifiedName =
      'com.yetzira.syncmonth.QuickLogCompactWidgetProvider';
  static const extendedQualifiedName =
      'com.yetzira.syncmonth.QuickLogExtendedWidgetProvider';
  static const compactIosName = 'QuickLogCompactWidget';
  static const extendedIosName = 'QuickLogExtendedWidget';

  static String? _fingerprint;

  static bool _isRtlLocale(String localeCode) =>
      localeCode == 'he' || localeCode == 'ar';

  /// Format ₪ using the app locale so amount bidi matches label alignment.
  static String _formatWidgetIls(
    double amount,
    String localeCode, {
    int decimalDigits = 2,
  }) {
    final rtl = _isRtlLocale(localeCode);
    final format = NumberFormat.currency(
      locale: rtl ? (localeCode == 'he' ? 'he_IL' : 'ar') : 'en_IL',
      symbol: '₪',
      decimalDigits: decimalDigits,
    );
    return format.format(amount);
  }

  static bool get _isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static Future<void> _ensureAppGroup() async {
    if (!Platform.isIOS) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> sync(AppState state) async {
    if (!_isSupported) return;

    final l10n = AppLocalizations(state.localeCode);
    final rtl = _isRtlLocale(state.localeCode);
    final payload = <String, String>{
      'actionLabel': l10n.widgetLogSpend,
      'actionLabelShort': '+',
      'layoutRtl': rtl ? '1' : '0',
    };

    final monthReady = state.isSignedIn &&
        state.hasHousehold &&
        state.hasMonthSelected &&
        state.monthId != null &&
        state.budgetDataReady &&
        !state.loading;

    if (state.loading ||
        (state.isSignedIn && state.hasHousehold && !state.budgetDataReady)) {
      payload['title'] = 'SyncMonth';
      payload['status'] = '…';
      payload['ready'] = '0';
    } else if (!state.isSignedIn) {
      payload['title'] = 'SyncMonth';
      payload['status'] = l10n.widgetSignInToLog;
      payload['ready'] = '0';
    } else if (!state.hasHousehold) {
      payload['title'] = 'SyncMonth';
      payload['status'] = l10n.widgetNeedHousehold;
      payload['ready'] = '0';
    } else if (!monthReady) {
      payload['title'] = 'SyncMonth';
      payload['status'] = l10n.noMonthSelected;
      payload['ready'] = '0';
    } else {
      final totals = state.totals;
      final remaining = totals.spendRemaining;
      final isOver = remaining < 0;
      final heroAmount = isOver ? -remaining : remaining;
      final monthDate = dateFromMonthId(state.monthId!);
      final locale = state.localeCode;

      payload['title'] = l10n.monthTitle(monthDate);
      payload['status'] = state.monthId!;
      payload['ready'] = '1';
      payload['heroLabel'] = isOver ? l10n.overLabel : l10n.remaining;
      payload['heroAmount'] = _formatWidgetIls(heroAmount, locale);
      payload['heroAmountCompact'] =
          _formatWidgetIls(heroAmount, locale, decimalDigits: 0);
      payload['heroIsOver'] = isOver ? '1' : '0';
      payload['incomeLabel'] = l10n.income;
      payload['incomeAmount'] = _formatWidgetIls(totals.income, locale);
      payload['spentLabel'] = l10n.spentLabel;
      payload['spentAmount'] = _formatWidgetIls(totals.actual, locale);
      payload['savedLabel'] = l10n.savedLabel;
      payload['savedAmount'] = _formatWidgetIls(totals.savedThisMonth, locale);
      payload['budgetLabel'] = l10n.budget;
      payload['budgetAmount'] = _formatWidgetIls(totals.planned, locale);
    }

    final fingerprint =
        payload.entries.map((e) => '${e.key}=${e.value}').join('|');
    if (fingerprint == _fingerprint) return;

    try {
      await _ensureAppGroup();
      await Future.wait([
        for (final entry in payload.entries)
          HomeWidget.saveWidgetData<String>(entry.key, entry.value),
      ]);
      await Future.wait([
        HomeWidget.updateWidget(
          name: compactAndroidName,
          androidName: compactAndroidName,
          qualifiedAndroidName: compactQualifiedName,
          iOSName: compactIosName,
        ),
        HomeWidget.updateWidget(
          name: extendedAndroidName,
          androidName: extendedAndroidName,
          qualifiedAndroidName: extendedQualifiedName,
          iOSName: extendedIosName,
        ),
      ]);
      _fingerprint = fingerprint;
    } catch (e, st) {
      debugPrint('QuickLogWidgetService.sync failed: $e\n$st');
    }
  }

  static Future<bool> isPinSupported() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pinCompact() => _pin(
        name: compactAndroidName,
        qualifiedName: compactQualifiedName,
      );

  static Future<bool> pinExtended() => _pin(
        name: extendedAndroidName,
        qualifiedName: extendedQualifiedName,
      );

  static Future<bool> _pin({
    required String name,
    required String qualifiedName,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final supported = await isPinSupported();
      if (!supported) return false;
      await HomeWidget.requestPinWidget(
        name: name,
        qualifiedAndroidName: qualifiedName,
      );
      return true;
    } catch (e, st) {
      debugPrint('QuickLogWidgetService.pin failed: $e\n$st');
      return false;
    }
  }
}
