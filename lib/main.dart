import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'screens/auth/app_intro_screen.dart';
import 'screens/home/quick_log_overlay_screen.dart';
import 'screens/home/root_shell.dart';
import 'services/app_intro_prefs.dart';
import 'services/quick_log_launch.dart';
import 'services/quick_log_widget_service.dart';
import 'theme/sync_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await QuickLogLaunch.init();
  final introCompleted = await AppIntroPrefs.isCompleted();
  runApp(SyncMonthApp(introCompleted: introCompleted));
}

class SyncMonthApp extends StatefulWidget {
  const SyncMonthApp({super.key, this.introCompleted = false});

  final bool introCompleted;

  @override
  State<SyncMonthApp> createState() => _SyncMonthAppState();
}

class _SyncMonthAppState extends State<SyncMonthApp> {
  late bool _introCompleted = widget.introCompleted;

  Future<void> _finishIntro() async {
    await AppIntroPrefs.markCompleted();
    if (mounted) setState(() => _introCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          unawaited(QuickLogWidgetService.sync(state));
          final locale = Locale(state.localeCode);
          return ValueListenableBuilder<bool>(
            valueListenable: QuickLogLaunch.spendOverlay,
            builder: (context, quickLogSpend, _) {
              return MaterialApp(
                title: 'SyncMonth',
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('ru'),
                  Locale('he'),
                  Locale('es'),
                  Locale('fr'),
                  Locale('uk'),
                  Locale('ar'),
                  Locale('de'),
                ],
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: buildSyncTheme(),
                home: quickLogSpend
                    ? const QuickLogOverlayScreen()
                    : !_introCompleted
                        ? AppIntroScreen(onCompleted: _finishIntro)
                        : const RootShell(),
              );
            },
          );
        },
      ),
    );
  }
}
