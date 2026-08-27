import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'screens/home/root_shell.dart';
import 'theme/sync_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const SyncMonthApp());
}

class SyncMonthApp extends StatelessWidget {
  const SyncMonthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final locale = Locale(state.localeCode);
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
            home: const RootShell(),
          );
        },
      ),
    );
  }
}
